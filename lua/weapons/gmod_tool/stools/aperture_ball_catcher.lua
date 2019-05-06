TOOL.Tab = "Aperture"
TOOL.Category = "Puzzle elements"
TOOL.Name = "#tool.aperture_ball_catcher.name"

TOOL.ClientConVar["keygroup"] = "45"

local CATCHER_MODEL = "models/aperture/combine_ball_catcher.mdl"

if CLIENT then
	language.Add("tool.aperture_ball_catcher.name", "Energy Pellet Catcher")
	language.Add("tool.aperture_ball_catcher.desc", "Catches High-energy pellets and powers things it is connected to.")
	language.Add("tool.aperture_ball_catcher.0", "Left click to place")
	language.Add("tool.aperture_ball_catcher.enable", "Key to simulate")
end

if SERVER then
	function MakePortalBallCatcher(ply, pos, ang, key_group, data)
		local ent = ents.Create("ent_portal_ball_catcher")
		if not IsValid(ent) then
			return
		end

		duplicator.DoGeneric(ent, data)

		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:SetMoveType(MOVETYPE_NONE)
		ent:SetKey(key_group)
		ent:SetPlayer(ply)
		ent:Spawn()

		-- saving data
		local ttable = {
			key_enable = key_enable,
			ply = ply,
			startenabled = startenabled,
			toggle = toggle
		}

		table.Merge(ent:GetTable(), ttable)

		if IsValid(ply) then
			ply:AddCleanup("#tool.aperture_ball_catcher.name", ent)
		end

		return ent
	end

	duplicator.RegisterEntityClass("ent_ball_catcher", MakePortalBallCatcher, "pos", "ang", "key_group", "data")
end

function TOOL:LeftClick(trace)
	-- Ignore if place target is Alive
	--if ( trace.Entity and ( trace.Entity:IsPlayer() or trace.Entity:IsNPC() or APERTURESCIENCE:GASLStuff( trace.Entity ) ) ) then return false end

	if CLIENT then
		return true
	end

	-- if not APERTURESCIENCE.ALLOWING.paint and not self:GetOwner():IsSuperAdmin() then self:GetOwner():PrintMessageHUD_PRINTTALK, "This tool is disabled" return end

	local ply = self:GetOwner()
	local key_group = self:GetClientNumber("keygroup")
	local pos = trace.HitPos
	local ang = trace.HitNormal:Angle()
	local ent = MakePortalBallCatcher(ply, pos, ang, key_group)

	undo.Create("Hight Energy Pellet Catcher")
	undo.AddEntity(ent)
	undo.SetPlayer(ply)
	undo.Finish()

	return true, ent
end

function TOOL:UpdateGhostPortalBallCatcher(ent, ply)
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
	local ang = trace.HitNormal:Angle()

	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:SetNoDraw(false)
end

function TOOL:RightClick(trace)
end

function TOOL:Think()
	local mdl = CATCHER_MODEL
	if not util.IsValidModel(mdl) then
		self:ReleaseGhostEntity()
		return
	end

	if not IsValid(self.GhostEntity) or self.GhostEntity:GetModel() ~= mdl then
		self:MakeGhostEntity(mdl, Vector(0, 0, 0), Angle(0, 0, 0))
	end

	self:UpdateGhostPortalBallCatcher(self.GhostEntity, self:GetOwner())
end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", {Description = "#tool.aperture_ball_catcher.desc"})
	CPanel:AddControl("Numpad", {Label = "#tool.aperture_ball_catcher.enable", Command = "aperture_ball_catcher_keygroup"})
end
