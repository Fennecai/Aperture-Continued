AddCSLuaFile( )

ENT.Base 			= "base_anim"

ENT.Editable		= true
ENT.PrintName		= "Cake is Lie"
ENT.Category		= "Aperture Science"
ENT.Spawnable 		= true
ENT.AutomaticFrameAdvance = true

function ENT:SpawnFunction(ply, trace, className)
	if not trace.Hit then return end
	
	if not ply.TA_Counter_CakeSpawned then ply.TA_Counter_CakeSpawned = 0 end
	if ply.TA_Counter_CakeSpawned < 100 then
		ply.TA_Counter_CakeSpawned = ply.TA_Counter_CakeSpawned + 1
		return
	end
	if ply.TA_Counter_CakeSpawned == 100 then LIB_APERTURE.ACHIEVEMENTS:AchievAchievement(ply, "cake") end
	
	local ent = ents.Create(className)
	ent:SetPos(trace.HitPos)
	ent:SetAngles(trace.HitNormal:Angle() + Angle(90, 0, 0))
	ent:Spawn()
	
	return ent
end

function ENT:Think()
	self:NextThink(CurTime() + 0.1)
	
	return true
end
-- no more client side
if CLIENT then return end

function ENT:Initialize()
	self:SetModel("models/aperture/cake.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:GetPhysicsObject():Wake()
end

function ENT:Use(activator, caller)
	if IsValid(caller) and caller:IsPlayer() then
		if caller:Health() < 100 then caller:SetHealth(100) end
		self:Remove()
	end
end
