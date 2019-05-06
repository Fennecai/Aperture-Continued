TOOL.Tab = "Aperture"
TOOL.Category = "Puzzle elements"
TOOL.Name = "#tool.aperture_floor_button.name"

TOOL.ClientConVar["model"] = "models/props/laser_emitter.mdl"
TOOL.ClientConVar["keygroup"] = "45"

if CLIENT then
	language.Add("tool.aperture_floor_button.name", "Floor button")
	language.Add(
		"tool.aperture_floor_button.desc",
		"Floor button that can activate other stuff when something or someone stands on it"
	)
	language.Add("tool.aperture_floor_button.enable", "Key to simulate")
	language.Add("tool.aperture_floor_button.0", "Left click to place")
end

function TOOL:ModelToEntity(mdl)
	local modelToEntity = {
		["models/portal_custom/ball_button_custom.mdl"] = "ent_portal_button_ball",
		["models/portal_custom/box_socket_custom.mdl"] = "ent_portal_button_box",
		["models/portal_custom/portal_button_custom.mdl"] = "ent_portal_button_normal",
		["models/portal_custom/underground_floor_button_custom.mdl"] = "ent_portal_button_old",
		["models/props_h2f/portal_button.mdl"] = "ent_portal_button_h2f"
	}
	return modelToEntity[mdl]
end

if SERVER then
	function MakePortalFloorButton(ply, pos, ang, class, key_group, hitent, data)
		local ent = ents.Create(class)
		if not IsValid(ent) then
			return
		end

		duplicator.DoGeneric(ent, data)

		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:SetMoveType(MOVETYPE_NONE)
		ent.Owner = pl
		ent.CanUpdateSettings = true
		ent:SetKey(key_group)
		ent:SetPlayer(ply)
		ent:Spawn()
		ent:Activate()
		constraint.Weld(ent, hitent, 0, 0, 0, false, false)

		-- saving data
		local ttable = {
			class = class,
			key_group = key_group,
			ply = ply
		}

		table.Merge(ent:GetTable(), ttable)

		if IsValid(ply) then
			ply:AddCleanup("#tool.aperture_floor_button.name", ent)
		end

		return ent
	end

	duplicator.RegisterEntityClass(
		"ent_portal_button_ball",
		MakePortalFloorButton,
		"pos",
		"ang",
		"class",
		"key_group",
		"data"
	)
	duplicator.RegisterEntityClass(
		"ent_portal_button_box",
		MakePortalFloorButton,
		"pos",
		"ang",
		"class",
		"key_group",
		"data"
	)
	duplicator.RegisterEntityClass(
		"ent_portal_button_normal",
		MakePortalFloorButton,
		"pos",
		"ang",
		"class",
		"key_group",
		"data"
	)
	duplicator.RegisterEntityClass(
		"ent_portal_button_old",
		MakePortalFloorButton,
		"pos",
		"ang",
		"class",
		"key_group",
		"data"
	)
	duplicator.RegisterEntityClass(
		"ent_portal_button_h2f",
		MakePortalFloorButton,
		"pos",
		"ang",
		"class",
		"key_group",
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
	local key_group = self:GetClientNumber("keygroup")

	local pos = trace.HitPos
	local ang = trace.HitNormal:Angle() + Angle(90, 0, 0)
	local hitent = trace.Entity
	local class = self:ModelToEntity(model)
	local ent = MakePortalFloorButton(ply, pos, ang, class, key_group, hitent)

	undo.Create("#tool.aperture_floor_button.name")
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
	CPanel:AddControl("Header", {Description = "#tool.aperture_floor_button.desc"})
	CPanel:AddControl(
		"PropSelect",
		{
			Label = "#tool.aperture_floor_button.model",
			ConVar = "aperture_floor_button_model",
			Models = list.Get("PortalFloorButtonModels"),
			Height = 0
		}
	)
	CPanel:AddControl("Numpad", {Label = "#tool.aperture_floor_button.enable", Command = "aperture_floor_button_keygroup"})
end

list.Set("PortalFloorButtonModels", "models/portal_custom/ball_button_custom.mdl", {})
list.Set("PortalFloorButtonModels", "models/portal_custom/box_socket_custom.mdl", {})
list.Set("PortalFloorButtonModels", "models/portal_custom/portal_button_custom.mdl", {})
list.Set("PortalFloorButtonModels", "models/portal_custom/underground_floor_button_custom.mdl", {})
list.Set("PortalFloorButtonModels", "models/props_h2f/portal_button.mdl", {})
