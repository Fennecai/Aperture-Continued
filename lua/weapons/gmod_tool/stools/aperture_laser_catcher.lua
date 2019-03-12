TOOL.Tab 		= "Aperture"
TOOL.Category 	= "Puzzle elements"
TOOL.Name 		= "#tool.aperture_laser_catcher.name"

TOOL.ClientConVar["model"] 		= "models/aperture/laser_emitter.mdl"
TOOL.ClientConVar["keygroup"] 	= "45"
TOOL.ClientConVar["timer"] 		= "1"

if CLIENT then
	language.Add("tool.aperture_laser_catcher.name", "Thermal Discouragement Beam Catcher")
	language.Add("tool.aperture_laser_catcher.desc", "A beam catcher that can catch thermal discouragement beam to activate other stuff")
	language.Add("tool.aperture_laser_catcher.enable", "Key to simulate")
	language.Add("tool.aperture_laser_catcher.timer", "Time before release")
	language.Add("tool.aperture_laser_catcher.0", "Left click to use")
end


function TOOL:ModelToOffsets(model)
	local modelToOffsets = {
		["models/aperture/laser_catcher.mdl"] = {z = -12, ang = Angle()},
		["models/aperture/laser_catcher_center.mdl"] = {z = -11.5, ang = Angle()},
		["models/aperture/laser_receptacle.mdl"] = {z = 3.5, ang = Angle(90, 0, 0)},
	}
	return modelToOffsets[model]
end

local function MakePortalLaserCatcher(ply, pos, ang, model, key_group, data)
	local ent = ents.Create("ent_portal_laser_catcher")
	if not IsValid(ent) then return end
	
	duplicator.DoGeneric(ent, data)
	
	ent:SetModel(model)
	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:SetMoveType(MOVETYPE_NONE)
	ent:SetPlayer(ply)
	ent:SetKey(key_group)
	ent:Spawn()
	
	-- saving data
	local ttable = {
		model = model,
		key_group = key_group,
		ply = ply,
		data = data,
	}

	table.Merge(ent:GetTable(), ttable)

	if IsValid(ply) then
		ply:AddCleanup("#tool.aperture_laser_catcher.name", ent)
	end
	
	return ent
end

function TOOL:LeftClick(trace)
	-- Ignore if place target is Alive
	//if ( trace.Entity and ( trace.Entity:IsPlayer() || trace.Entity:IsNPC() || APERTURESCIENCE:GASLStuff( trace.Entity ) ) ) then return false end

	if CLIENT then return true end
	
	-- if not APERTURESCIENCE.ALLOWING.paint and not self:GetOwner():IsSuperAdmin() then self:GetOwner():PrintMessageHUD_PRINTTALK, "This tool is disabled" return end

	local ply = self:GetOwner()
	local model = self:GetClientInfo("model")
	local key_group = self:GetClientNumber("keygroup")
	local offsets = self:ModelToOffsets(model)
	local pos = trace.HitPos + trace.HitNormal * offsets.z
	local ang = trace.HitNormal:Angle() + offsets.ang
	local ent = MakePortalLaserCatcher(ply, pos, ang, model, key_group)
		
	undo.Create("Thermal Discouragement Beam Catcher")
		undo.AddEntity(ent)
		undo.SetPlayer(ply)
	undo.Finish()
	
	return true, ent
end

function TOOL:UpdateGhostLaserEmitter(ent, ply)
	if not IsValid(ent) then return end

	local trace = ply:GetEyeTrace()
	if not trace.Hit or trace.Entity and (trace.Entity:IsPlayer() or trace.Entity:IsNPC() or trace.Entity.IsAperture) then
		ent:SetNoDraw(true)
		return
	end
	
	local curPos = ent:GetPos()
	local model = self:GetClientInfo("model")
	local offsets = self:ModelToOffsets(model)
	local pos = trace.HitPos + trace.HitNormal * offsets.z
	local ang = trace.HitNormal:Angle() + offsets.ang

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
		self:MakeGhostEntity(mdl, Vector(0, 0, 0), Angle(0, 0, 0))
	end

	self:UpdateGhostLaserEmitter(self.GhostEntity, self:GetOwner())
end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", {Description = "#tool.aperture_laser_catcher.desc"})
	CPanel:AddControl("PropSelect", {ConVar = "aperture_laser_catcher_model", Models = list.Get("PortalLaserCatcherModels"), Height = 1}) 
	CPanel:AddControl("Numpad", {Label = "#tool.aperture_laser_catcher.enable", Command = "aperture_laser_catcher_keygroup"})
end

list.Set("PortalLaserCatcherModels", "models/aperture/laser_catcher.mdl", {})
list.Set("PortalLaserCatcherModels", "models/aperture/laser_catcher_center.mdl", {})
list.Set("PortalLaserCatcherModels", "models/aperture/laser_receptacle.mdl", {})