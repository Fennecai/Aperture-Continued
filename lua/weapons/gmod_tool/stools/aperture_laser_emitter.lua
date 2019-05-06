TOOL.Tab = "Aperture"
TOOL.Category = "Puzzle elements"
TOOL.Name = "#tool.aperture_laser_emitter.name"

TOOL.ClientConVar["model"] = "models/aperture/laser_emitter.mdl"
TOOL.ClientConVar["keyenable"] = "45"
TOOL.ClientConVar["startenabled"] = "0"
TOOL.ClientConVar["toggle"] = "0"

if CLIENT then
	language.Add("tool.aperture_laser_emitter.name", "Laser")
	language.Add(
		"tool.aperture_laser_emitter.desc",
		"A Thermal Discouragement Beam Emitter that shoots a laser beam. not to be confused for a lazor. thats completely different."
	)
	language.Add("tool.aperture_laser_emitter.0", "Left click to place")
	language.Add("tool.aperture_laser_emitter.enable", "Enable")
	language.Add("tool.aperture_laser_emitter.startenabled", "Enabled")
	language.Add(
		"tool.aperture_laser_emitter.startenabled.help",
		"Thermal Discouragement Beam Emitter will be enabled when placed"
	)
	language.Add("tool.aperture_laser_emitter.toggle", "Toggle")
end

if SERVER then
	function MakeApertureLaserEmitter(ply, pos, ang, model, key_enable, startenabled, toggle, data)
		local ent = ents.Create("ent_portal_laser_emitter")
		if not IsValid(ent) then
			return
		end

		duplicator.DoGeneric(ent, data)

		ent:SetModel(model)
		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:SetMoveType(MOVETYPE_NONE)
		ent:SetStartEnabled(tobool(startenabled))
		ent:SetToggle(tobool(toggle))
		ent.Player = ply
		ent:Spawn()

		-- initializing numpad inputs
		ent.NumDown = numpad.OnDown(ply, key_enable, "PortalLaserEmitter_Enable", ent, true)
		ent.NumUp = numpad.OnUp(ply, key_enable, "PortalLaserEmitter_Enable", ent, false)

		-- saving data
		local ttable = {
			model = model,
			key_enable = key_enable,
			ply = ply,
			startenabled = startenabled,
			toggle = toggle
		}

		table.Merge(ent:GetTable(), ttable)

		if IsValid(ply) then
			ply:AddCleanup("#tool.aperture_laser_emitter.name", ent)
		end

		return ent
	end

	duplicator.RegisterEntityClass(
		"ent_portal_laser_emitter",
		MakeApertureLaserEmitter,
		"pos",
		"ang",
		"model",
		"key_enable",
		"startenabled",
		"toggle",
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

	local pos = trace.HitPos - trace.HitNormal * 12
	local ang = trace.HitNormal:Angle()

	local ent = MakeApertureLaserEmitter(ply, pos, ang, model, key_enable, startenabled, toggle)

	undo.Create("#tool.aperture_laser_emitter.name")
	undo.AddEntity(ent)
	undo.SetPlayer(ply)
	undo.Finish()

	return true, ent
end

function TOOL:UpdateGhostLaserEmitter(ent, ply)
	if not IsValid(ent) then
		return
	end

	local trace = ply:GetEyeTrace()
	if not trace.Hit or trace.Entity and (trace.Entity:IsPlayer() or trace.Entity:IsNPC() or trace.Entity.IsAperture) then
		ent:SetNoDraw(true)
		return
	end

	local curPos = ent:GetPos()
	local pos = trace.HitPos - trace.HitNormal * 12
	local ang = trace.HitNormal:Angle()

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
		self:MakeGhostEntity(mdl, Vector(0, 0, 0), Angle(0, 0, 0))
	end

	self:UpdateGhostLaserEmitter(self.GhostEntity, self:GetOwner())
end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", {Description = "#tool.aperture_laser_emitter.desc"})
	CPanel:AddControl(
		"PropSelect",
		{
			Label = "#tool.aperture_laser_emitter.model",
			ConVar = "aperture_laser_emitter_model",
			Models = list.Get("PortalLaserEmiterModels"),
			Height = 0
		}
	)
	CPanel:AddControl(
		"CheckBox",
		{Label = "#tool.aperture_laser_emitter.startenabled", Command = "aperture_laser_emitter_startenabled", Help = true}
	)
	CPanel:AddControl(
		"Numpad",
		{Label = "#tool.aperture_laser_emitter.enable", Command = "aperture_laser_emitter_keyenable"}
	)
	CPanel:AddControl(
		"CheckBox",
		{Label = "#tool.aperture_laser_emitter.toggle", Command = "aperture_laser_emitter_toggle"}
	)
end

list.Set("PortalLaserEmiterModels", "models/aperture/laser_emitter.mdl", {})
list.Set("PortalLaserEmiterModels", "models/aperture/laser_emitter_center.mdl", {})
