TOOL.Tab = "Aperture"
TOOL.Category = "Puzzle elements"
TOOL.Name = "#tool.aperture_paint_dropper.name"

TOOL.ClientConVar["model"] = "models/aperture/paint_dropper.mdl"
TOOL.ClientConVar["keyenable"] = "45"
TOOL.ClientConVar["startenabled"] = "0"
TOOL.ClientConVar["toggle"] = "0"
TOOL.ClientConVar["paint_type"] = "1"
TOOL.ClientConVar["paint_radius"] = "50"
TOOL.ClientConVar["paint_flow_type"] = "3"
TOOL.ClientConVar["paint_launch_speed"] = "0"

local PAINT_MAX_LAUNCH_SPEED = 1000

if CLIENT then
	language.Add("tool.aperture_paint_dropper.name", "Gel Dropper")
	language.Add("tool.aperture_paint_dropper.desc", "The Gel Dropper will deploy the specified gel type")
	language.Add("tool.aperture_paint_dropper.0", "Left click to place")
	language.Add("tool.aperture_paint_dropper.enable", "Enable")
	language.Add("tool.aperture_paint_dropper.paintType", "Gel Type")
	language.Add("tool.aperture_paint_dropper.paintFlowType", "Gel Flow Type")
	language.Add("tool.aperture_paint_dropper.paintLaunchSpeed", "Gel Launch Speed")
	language.Add("tool.aperture_paint_dropper.startenabled", "Enabled")
	language.Add("tool.aperture_paint_dropper.startenabled.help", "Gel Dropper will start to deploy gel when placed")
	language.Add("tool.aperture_paint_dropper.toggle", "Toggle")
end

local function FlowTypeToInfo(flowType)
	local flowTypeToInfo = {
		[1] = {amount = 96, radius = 50},
		[2] = {amount = 97, radius = 75},
		[3] = {amount = 98, radius = 120},
		[4] = {amount = 10, radius = 200},
		[5] = {amount = 80, radius = 1}
	}
	return flowTypeToInfo[flowType]
end

if SERVER then
	function MakePaintDropper(
		ply,
		pos,
		ang,
		model,
		key_enable,
		startenabled,
		toggle,
		paintType,
		paintFlowType,
		paintLaunchSpeed,
		data)
		local flowInfo = FlowTypeToInfo(paintFlowType)
		local ent = ents.Create("ent_paint_dropper")
		if not IsValid(ent) then
			return
		end

		duplicator.DoGeneric(ent, data)

		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:SetMoveType(MOVETYPE_NONE)
		ent:SetModel(model)
		ent.Owner = ply
		ent:SetStartEnabled(tobool(startenabled))
		ent:SetToggle(tobool(toggle))
		ent:SetPaintType(paintType)
		ent:SetPaintRadius(flowInfo.radius)
		ent:SetPaintAmount(flowInfo.amount)
		ent:SetPaintLaunchSpeed(paintLaunchSpeed)

		local paintInfo = LIB_APERTURECONTINUED:PaintTypeToInfo(paintType)
		if paintInfo.DROPPER_MATERIAL then
			ent:SetMaterial(paintInfo.DROPPER_MATERIAL)
		else
			ent:SetColor(LIB_APERTURECONTINUED:PaintTypeToColor(paintType))
		end

		ent:Spawn()

		-- initializing numpad inputs
		ent.NumDown = numpad.OnDown(ply, key_enable, "PaintDropper_Enable", ent, true)
		ent.NumUp = numpad.OnUp(ply, key_enable, "PaintDropper_Enable", ent, false)

		-- saving data
		local ttable = {
			key_enable = key_enable,
			model = model,
			ply = ply,
			startenabled = startenabled,
			toggle = toggle,
			paintType = paintType,
			paintFlowType = paintFlowType,
			paintLaunchSpeed = paintLaunchSpeed
		}

		table.Merge(ent:GetTable(), ttable)

		if IsValid(ply) then
			ply:AddCleanup("#tool.aperture_paint_dropper.name", ent)
		end

		return ent
	end

	duplicator.RegisterEntityClass(
		"ent_paint_dropper",
		MakePaintDropper,
		"pos",
		"ang",
		"model",
		"key_enable",
		"startenabled",
		"toggle",
		"paintType",
		"paintFlowType",
		"paintLaunchSpeed",
		"data"
	)
end

function TOOL:LeftClick(trace)
	-- Ignore if place target is Alive
	--if ( trace.Entity and ( trace.Entity:IsPlayer() or trace.Entity:IsNPC() or APERTURESCIENCE:GASLStuff( trace.Entity ) ) ) then return false end

	if CLIENT then
		return true
	end

	-- if not APERTURESCIENCE.ALLOWING.paint and not self:GetOwner():IsSuperAdmin() then self:GetOwner():PrintMessageHUD_PRINTTALK, "This tool is disabled" return end

	local ply = self:GetOwner()
	local model = self:GetClientInfo("model")
	local key_enable = self:GetClientNumber("keyenable")
	local startenabled = self:GetClientNumber("startenabled")
	local toggle = self:GetClientNumber("toggle")
	local paintType = self:GetClientNumber("paint_type")
	local paintFlowType = self:GetClientNumber("paint_flow_type")
	local paintLaunchSpeed = self:GetClientNumber("paint_launch_speed")

	local pos = trace.HitPos
	local ang = trace.HitNormal:Angle() - Angle(90, 0, 0)

	local ent =
		MakePaintDropper(ply, pos, ang, model, key_enable, startenabled, toggle, paintType, paintFlowType, paintLaunchSpeed)

	undo.Create("#tool.aperture_paint_dropper.name")
	undo.AddEntity(ent)
	undo.SetPlayer(ply)
	undo.Finish()

	return true, ent
end

function TOOL:UpdateGhostPaintDropper(ent, ply)
	if not IsValid(ent) then
		return
	end

	local trace = ply:GetEyeTrace()
	if not trace.Hit or trace.Entity and (trace.Entity:IsPlayer() or trace.Entity:IsNPC() or trace.Entity.IsAperture) then
		ent:SetNoDraw(true)
		return
	end

	local curPos = ent:GetPos()
	local pos = trace.HitPos
	local ang = trace.HitNormal:Angle() - Angle(90, 0, 0)

	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:SetNoDraw(false)
end

function TOOL:RightClick(trace)
end

function TOOL:Think()
	local mdl = self:GetClientInfo("model")
	if not util.IsValidModel(mdl) then
		self:ReleaseGhostEntity()
		return
	end

	if not IsValid(self.GhostEntity) or self.GhostEntity:GetModel() ~= mdl then
		self:MakeGhostEntity(mdl, Vector(), Angle())
	end

	if IsValid(self.GhostEntity) then
		local alpha = self.GhostEntity:GetColor().a
		local paintType = self:GetClientNumber("paint_type")
		local paintInfo = LIB_APERTURECONTINUED:PaintTypeToInfo(paintType)
		if paintInfo.DROPPER_MATERIAL then
			self.GhostEntity:SetColor(Color(255, 255, 255, alpha))
			self.GhostEntity:SetMaterial(paintInfo.DROPPER_MATERIAL)
		else
			local paintColor = LIB_APERTURECONTINUED:PaintTypeToColor(paintType)
			local color = Color(paintColor.r, paintColor.g, paintColor.b, alpha)
			self.GhostEntity:SetColor(color)
		end
	end

	self:UpdateGhostPaintDropper(self.GhostEntity, self:GetOwner())
end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", {Description = "#tool.aperture_paint_dropper.desc"})

	local combobox = CPanel:ComboBox("#tool.aperture_paint_dropper.paintType", "aperture_paint_dropper_paint_type")
	for k, v in pairs(LIB_APERTURECONTINUED.PAINT_TYPES) do
		if not v.NAME then
			break
		end
		combobox:AddChoice(v.NAME, k)
	end

	local combobox =
		CPanel:ComboBox("#tool.aperture_paint_dropper.paintFlowType", "aperture_paint_dropper_paint_flow_type")
	combobox:AddChoice("Light", 1)
	combobox:AddChoice("Medium", 2)
	combobox:AddChoice("Hard", 3)
	combobox:AddChoice("Bomb", 4)
	combobox:AddChoice("Drip", 5)

	CPanel:NumSlider(
		"#tool.aperture_paint_dropper.paintLaunchSpeed",
		"aperture_paint_dropper_paint_launch_speed",
		0,
		PAINT_MAX_LAUNCH_SPEED
	)
	CPanel:AddControl(
		"PropSelect",
		{ConVar = "aperture_paint_dropper_model", Models = list.Get("PortalPaintDropperModels"), Height = 1}
	)
	CPanel:AddControl(
		"CheckBox",
		{Label = "#tool.aperture_paint_dropper.startenabled", Command = "aperture_paint_dropper_startenabled", Help = true}
	)
	CPanel:AddControl(
		"Numpad",
		{Label = "#tool.aperture_paint_dropper.enable", Command = "aperture_paint_dropper_keyenable"}
	)
	CPanel:AddControl(
		"CheckBox",
		{Label = "#tool.aperture_paint_dropper.toggle", Command = "aperture_paint_dropper_toggle"}
	)
end

list.Set("PortalPaintDropperModels", "models/aperture/paint_dropper.mdl", {})
list.Set("PortalPaintDropperModels", "models/aperture/underground_paintdropper.mdl", {})
