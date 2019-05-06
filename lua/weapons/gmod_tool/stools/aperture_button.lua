TOOL.Tab = "Aperture"
TOOL.Category = "Puzzle elements"
TOOL.Name = "#tool.aperture_button.name"

TOOL.ClientConVar["model"] = "models/aperture/button.mdl"
TOOL.ClientConVar["keygroup"] = "45"
TOOL.ClientConVar["timer"] = "1"

if CLIENT then
	language.Add("tool.aperture_button.name", "Button")
	language.Add("tool.aperture_button.desc", "A button that activates other stuff when pressed.")
	language.Add("tool.aperture_button.enable", "Key to simulate")
	language.Add("tool.aperture_button.timer", "Time before release")
	language.Add("tool.aperture_button.0", "Left click to place")
end

local function MakePortalButton(ply, model, pos, ang, model, key_group, time, data)
	local ent = ents.Create("ent_portal_button")
	if not IsValid(ent) then
		return
	end

	duplicator.DoGeneric(ent, data)

	ent:SetModel(model)
	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:SetMoveType(MOVETYPE_NONE)
	ent:SetPlayer(ply)
	ent:SetTimer(time)
	ent:SetKey(key_group)
	ent:Spawn()

	-- saving data
	local ttable = {
		model = model,
		key_group = key_group,
		ply = ply,
		time = time,
		data = data
	}

	table.Merge(ent:GetTable(), ttable)

	if IsValid(ply) then
		ply:AddCleanup("#tool.aperture_button.name", ent)
	end

	return ent
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
	local key_group = self:GetClientNumber("keygroup")
	local time = self:GetClientNumber("timer")

	local pos = trace.HitPos
	local ang = trace.HitNormal:Angle() + Angle(90, 0, 0)
	local angle = ang

	if trace.HitNormal == Vector(0, 0, 1) or trace.HitNormal == Vector(0, 0, -1) then
		_,
			angle = WorldToLocal(Vector(), (trace.HitPos - ply:GetPos()):Angle(), Vector(), ang)
		angle = Angle(0, angle.y + 180, 0)
		_,
			angle = LocalToWorld(Vector(), angle, Vector(), ang)
	end

	local ent = MakePortalButton(ply, model, pos, angle, model, key_group, time)

	undo.Create("Button")
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
	local pos = trace.HitPos
	local ang = trace.HitNormal:Angle() + Angle(90, 0, 0)
	local angle = ang
	if trace.HitNormal == Vector(0, 0, 1) or trace.HitNormal == Vector(0, 0, -1) then
		_,
			angle = WorldToLocal(Vector(), (trace.HitPos - ply:GetPos()):Angle(), Vector(), ang)
		angle = Angle(0, angle.y + 180, 0)
		_,
			angle = LocalToWorld(Vector(), angle, Vector(), ang)
	end

	ent:SetPos(pos)
	ent:SetAngles(angle)
	ent:SetNoDraw(false)
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

function TOOL:RightClick(trace)
end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", {Description = "#tool.aperture_button.desc"})
	CPanel:AddControl(
		"PropSelect",
		{ConVar = "aperture_button_model", Models = list.Get("PortalButtonModels"), Height = 1}
	)
	CPanel:AddControl("Numpad", {Label = "#tool.aperture_button.enable", Command = "aperture_button_keygroup"})
	CPanel:NumSlider("#tool.aperture_button.timer", "aperture_button_timer", 1, 60)
end

list.Set("PortalButtonModels", "models/aperture/button.mdl", {})
list.Set("PortalButtonModels", "models/aperture/underground_button.mdl", {})
