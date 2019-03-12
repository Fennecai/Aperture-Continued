AddCSLuaFile( )
ENT.Type = "anim"
ENT.PrintName		= "Rocket Turret Missile"
ENT.Category		= "Aperture Science"
ENT.Spawnable 		= false
ENT.AutomaticFrameAdvance = true

-- no more client side
if CLIENT then return end

function ENT:Initialize()
	self:SetModel("models/aperture/rocket.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	self:GetPhysicsObject():EnableGravity(false)
	self:SetNotSolid(true)
	self:EmitSound("TA:RocketMissileFly")
	self.TA_PrevPos = self:GetPos()
end

function ENT:Explode(trace)
	local effectdata = EffectData()
	effectdata:SetOrigin(trace.HitPos)
	effectdata:SetNormal(trace.HitNormal)
	util.Effect("Explosion", effectdata)

	util.BlastDamage(self, self, trace.HitPos, 150, 100) 
	self:Remove()
end

function ENT:Think()
	self:NextThink(CurTime())
	
	local trace = util.TraceLine({
		start = self.TA_PrevPos,
		endpos = self:GetPos(),
		mask = MASK_SHOT,
		filter = {self, self.RTurret}
	})
	self.TA_PrevPos = self:GetPos()
	if IsValid(trace.Entity) and trace.Entity:GetClass() == "prop_portal" then
		local portal = trace.Entity
		local pos, ang = LIB_APERTURE:GetPortalTransform(self:GetPos(), self:GetAngles(), portal, true)
		local vel = LIB_APERTURE:GetPortalRotateVector(self:GetVelocity(), portal, true)
		self:SetPos(pos)
		self:SetAngles(ang)
		self:GetPhysicsObject():SetVelocity(vel)
		
		self:NextThink(CurTime() + 0.1)
		timer.Simple(0.1, function()
			if not IsValid(self) then return end
			self.TA_PrevPos = self:GetPos()
		end)
	elseif trace.Hit then
		self:Explode(trace)
	end
	
	if trace.HitSky then 
		self:Remove()
		return
	end

	local effectdata = EffectData()
	effectdata:SetOrigin(self:LocalToWorld(Vector(-10, 0, 0)))
	effectdata:SetAngles(self:LocalToWorldAngles(Angle(180, 0, 0)))
	effectdata:SetScale(1)
	util.Effect("MuzzleEffect", effectdata)

	return true
end

function ENT:OnRemove()
	self:StopSound("TA:RocketMissileFly")
end
