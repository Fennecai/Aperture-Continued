AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_ent")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Thermal Discouragement Beam Catcher"
ENT.IsAperture 		= true
ENT.IsConnectable 	= true

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Key")
	self:NetworkVar("Bool", 1, "On")
	self:NetworkVar("Int", 2, "Timer")
end

function ENT:ModelToStartCoord()
	local modelToStartCoord = {
		["models/aperture/laser_catcher_center.mdl"] = Vector(20, 0, 0),
		["models/aperture/laser_catcher.mdl"] = Vector(20, 0, -14),
		["models/aperture/laser_receptacle.mdl"] = Vector(0, 0, 20)
	}
	return modelToStartCoord[self:GetModel()]
end

function ENT:Activated(on)
	if self:GetOn() != on then
		if on then
			self:SetSkin(1)
			self:EmitSound("TA:LaserCatcherOn")
			sound.Play("TA:LaserCatcherOn", self:LocalToWorld(Vector(25, 0, 0)))
			self:MakeSoundEntity("TA:LaserCatcherLoop", self:LocalToWorld(Vector(25, 0, 0)), self)
			self:PlaySequence("spin", 1.0)

			numpad.Activate(self:GetPlayer(), self:GetKey(), true)
			if WireAddon then Wire_TriggerOutput(self, "Activated", 1) end
		else
			self:SetSkin( 0 )
			sound.Play("TA:LaserCatcherOff", self:LocalToWorld(Vector(25, 0, 0)))
			self:RemoveSoundEntity("TA:LaserCatcherLoop")
			self:PlaySequence("idle", 1.0)
			
			numpad.Deactivate(self:GetPlayer(), self:GetKey(), false)
			if WireAddon then Wire_TriggerOutput(self, "Activated", 0) end
		end
		
		self:SetOn(on)
	end
end

function ENT:Initialize()
	self.BaseClass.Initialize( self )
	
	if CLIENT then return end
	
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:GetPhysicsObject():EnableMotion(false)

	self.LastHittedByLaser = 0
	
	if not WireAddon then return end
	self.Outputs = WireLib.CreateSpecialOutputs(self, {"Activated"}, {"NORMAL"})
	
	return true
end

function ENT:Draw()
	self:DrawModel()
	
	if self:GetOn() then
		local radius = 64
		local offset = self:ModelToStartCoord()
		radius = radius * math.Rand(0.9, 1.1)
		render.SetMaterial(Material("particle/laser_beam_glow"))
		render.DrawSprite(self:LocalToWorld(offset), radius, radius, Color(255, 255, 255))
	end
end

-- no more client side
if CLIENT then return end

function ENT:Think()
	self:NextThink(CurTime() + 0.1)
	
	if CurTime() < self.LastHittedByLaser + 0.2 then
		self:Activated(true)
	else
		self:Activated(false)
	end

	return true
end

function ENT:Setup()
	if not WireAddon then return end
	Wire_TriggerOutput(self, "Activated", 0)
end

function ENT:OnRemove()
	self:RemoveSoundEntity("TA:LaserCatcherLoop")
end
