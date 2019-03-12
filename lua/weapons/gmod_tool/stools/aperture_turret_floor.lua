TOOL.Tab 		= "Aperture"
TOOL.Category 	= "Puzzle elements"
TOOL.Name 		= "#tool.aperture_turret_floor.name"

TOOL.ClientConVar["keyenable"] = "45"
TOOL.ClientConVar["startenabled"] = "0"
TOOL.ClientConVar["toggle"] = "0"
TOOL.ClientConVar["model"] = "models/npcs/turret/turret.mdl"

local UP = Vector(0, 0, 1)

if CLIENT then
	language.Add("tool.aperture_turret_floor.name", "Floor Turret")
	language.Add("tool.aperture_turret_floor.desc", "A Turret will protect specific places from any hostile")
	language.Add("tool.aperture_turret_floor.0", "Left click to place")
	language.Add("tool.aperture_turret_floor.enable", "Enable")
	language.Add("tool.aperture_turret_floor.startenabled", "Enabled")
	language.Add("tool.aperture_turret_floor.startenabled.help", "Turret will be enabled when placed")
	language.Add("tool.aperture_turret_floor.toggle", "Toggle")
end

local ModelToTurretType = {
	["models/npcs/turret/turret.mdl"] = "npc_portal_turret_floor",
	["models/npcs/turret/turret_skeleton.mdl"] = "npc_portal_turret_defective",
	["models/npcs/turret/turret_backwards.mdl"] = "npc_portal_turret_defective",
	["models/aperture/rocket_sentry.mdl"] = "npc_portal_rocket_turret",
}

local function GetTurretTypeByModel(model)
	return ModelToTurretType[model]
end

local function MakePortalTurretFloor(ply, pos, ang, model, key_enable, startenabled, toggle, data)
	local turretType = GetTurretTypeByModel(model)
	if not turretType then return end
	local ent = ents.Create(GetTurretTypeByModel(model))
	if not IsValid(ent) then return end
	
	duplicator.DoGeneric(ent, data)
	ent:SetModel(model)
	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:SetMoveType(MOVETYPE_NONE)
	ent.Owner = ply
	ent:SetStartEnabled(tobool(startenabled))
	ent:SetToggle(tobool(toggle))
	ent:Spawn()
	
	-- initializing numpad inputs
	ent.NumDown = numpad.OnDown(ply, key_enable, "PortalTurretFloor_Enable", ent, true)
	ent.NumUp = numpad.OnUp(ply, key_enable, "PortalTurretFloor_Enable", ent, false)

	-- saving data
	local ttable = {
		key_enable = key_enable,
		ply = ply,
		startenabled = startenabled,
		toggle = toggle,
	}

	table.Merge(ent:GetTable(), ttable)

	if IsValid(ply) then
		ply:AddCleanup("#tool.aperture_turret_floor.name", ent)
	end
	
	return ent
end

if SERVER then
	duplicator.RegisterEntityClass("npc_portal_turret_floor", MakePortalTurretFloor, "pos", "ang", "model", "key_enable", "startenabled", "toggle", "data")
	duplicator.RegisterEntityClass("npc_portal_turret_floor_defective", MakePortalTurretFloor, "pos", "ang", "model", "key_enable", "startenabled", "toggle", "data")
end

function TOOL:LeftClick(trace)
	-- Ignore if place target is Alive
	//if ( trace.Entity and ( trace.Entity:IsPlayer() || trace.Entity:IsNPC() || APERTURESCIENCE:GASLStuff( trace.Entity ) ) ) then return false end

	if CLIENT then return true end
	
	-- if not APERTURESCIENCE.ALLOWING.paint and not self:GetOwner():IsSuperAdmin() then self:GetOwner():PrintMessageHUD_PRINTTALK, "This tool is disabled" return end
	
	local model = self:GetClientInfo("model")
	local normal = trace.HitNormal
	if math.Round(normal.z) != 1 and model != "models/aperture/rocket_sentry.mdl" then
		PrintMessage(HUD_PRINTCENTER, "Wrong surface! You need to place it on the floor.")
		return
	end
	
	local ply = self:GetOwner()
	local key_enable = self:GetClientNumber("keyenable")
	local startenabled = self:GetClientNumber("startenabled")
	local toggle = self:GetClientNumber("toggle")
	local pos = trace.HitPos
	local ang = trace.HitNormal:Angle() + Angle(90, 0, 0)
	if trace.HitNormal == UP then
		local angle = ang
		_, angle = WorldToLocal(Vector(), (trace.HitPos - ply:GetPos()):Angle(), Vector(), ang)
		if model == "models/aperture/rocket_sentry.mdl" then angle = angle - Angle(0, 90, 0) end
		angle = Angle(0, angle.y, 0)
		_, ang = LocalToWorld(Vector(), angle, Vector(), ang)
	end
	local ent = MakePortalTurretFloor(ply, pos, ang, model, key_enable, startenabled, toggle)
		
	undo.Create("Floor Turret")
		undo.AddEntity(ent)
		undo.SetPlayer(ply)
	undo.Finish()
	
	return true, ent
end

function TOOL:UpdateGhostPortalTurretFloor(ent, ply)
	if not IsValid(ent) then return end

	local trace = ply:GetEyeTrace()
	if not trace.Hit or trace.Entity and (trace.Entity:IsPlayer() or trace.Entity:IsNPC() or trace.Entity.IsAperture) then
		ent:SetNoDraw(true)
		return
	end
	local model = self:GetClientInfo("model")
	local normal = trace.HitNormal
	local curPos = ent:GetPos()
	local pos = trace.HitPos
	local ang = trace.HitNormal:Angle() + Angle(90, 0, 0)
	if trace.HitNormal == UP then
		local _, angle = WorldToLocal(Vector(), (trace.HitPos - ply:GetPos()):Angle(), Vector(), ang)
		if model == "models/aperture/rocket_sentry.mdl" then angle = angle - Angle(0, 90, 0) end
		angle = Angle(0, angle.y, 0)
		_, ang = LocalToWorld(Vector(), angle, Vector(), ang)
	end
	
	if math.Round(normal.z) == 1 or model == "models/aperture/rocket_sentry.mdl" then
		ent:SetColor(Color(255, 255, 255, ent:GetColor().a))
	else
		ent:SetColor(Color(255, 0, 0, ent:GetColor().a))
	end
	
	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:SetNoDraw(false)
end

function TOOL:RightClick( trace )

end

function TOOL:Think()
	local mdl = self:GetClientInfo("model")
	if not util.IsValidModel(mdl) then self:ReleaseGhostEntity() return end

	if not IsValid(self.GhostEntity) or self.GhostEntity:GetModel() != mdl then
		self:MakeGhostEntity(mdl, Vector(), Angle())
	end

	self:UpdateGhostPortalTurretFloor(self.GhostEntity, self:GetOwner())
end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(cPanel)
	cPanel:AddControl("Header", {Description = "#tool.aperture_turret_floor.desc"})
	cPanel:AddControl("PropSelect", {ConVar = "aperture_turret_floor_model", Models = list.Get("PortalTurretFloorModels"), Height = 1})
	cPanel:AddControl("CheckBox", {Label = "#tool.aperture_turret_floor.startenabled", Command = "aperture_turret_floor_startenabled", Help = true})
	cPanel:AddControl("Numpad", {Label = "#tool.aperture_turret_floor.enable", Command = "aperture_turret_floor_keyenable"})
	cPanel:AddControl("CheckBox", {Label = "#tool.aperture_turret_floor.toggle", Command = "aperture_turret_floor_toggle"})
end

list.Set("PortalTurretFloorModels", "models/npcs/turret/turret.mdl", {})
list.Set("PortalTurretFloorModels", "models/npcs/turret/turret_skeleton.mdl", {})
list.Set("PortalTurretFloorModels", "models/npcs/turret/turret_backwards.mdl", {})
list.Set("PortalTurretFloorModels", "models/aperture/rocket_sentry.mdl", {})