AddCSLuaFile( )
DEFINE_BASECLASS("base_anim")

ENT.PrintName 		= "PotatOS"
ENT.Category 		= "Aperture Science"
ENT.Spawnable 		= true
ENT.Editable		= true
ENT.RenderGroup 	= RENDERGROUP_BOTH
ENT.AutomaticFrameAdvance = true

function ENT:Draw()
	self:DrawModel()
	
	local pos = self:LocalToWorld(Vector( 1.8, 4.7, 7))

	render.SetMaterial(Material("sprites/orangecore2"))
	render.DrawSprite(pos, 4, 4, Color( 255, 255, 255, 255))  
end

function ENT:SpawnFunction(ply, trace, className)
	if not trace.Hit then return end
	local ent = ents.Create(className)
	if not IsValid(ent) then return end
	ent:SetPos(trace.HitPos + trace.HitNormal * 10)
	ent:SetAngles(trace.HitNormal:Angle())
	ent:Spawn()
	ent.Owner = ply

	return ent
end

-- no more client side
if CLIENT then return end

function ENT:Initialize()
	self:SetModel("models/aperture/potatos_wmodel.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:GetPhysicsObject():Wake()
end

function ENT:Think()
	self:NextThink(CurTime() + 1)
	if self.Burned then return end
	
	if not self:IsOnFire() then
		if not timer.Exists("TA:Timer_PotatoOS_Chat"..self:EntIndex()) then
			timer.Create("TA:Timer_PotatoOS_Chat"..self:EntIndex(), 15, 1, function() end)
			self:EmitSound("TA:PotatoOSChat")
		end
	else
		self.Burned = true
		LIB_APERTURE.ACHIEVEMENTS:AchievAchievement(self.Owner, "fried_potato")
		self:EmitSound("TA:PotatoOSBurn")
	end
	
	return true
end

function ENT:OnRemove()
	timer.Remove("TA:Timer_PotatoOS_Chat"..self:EntIndex())
end
