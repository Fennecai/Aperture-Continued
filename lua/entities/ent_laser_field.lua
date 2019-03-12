AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_field")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Discouragement Field"
ENT.FieldColor 		= Color(255, 255, 255)
ENT.FieldMaterial	= "models/aperture/effects/laserplane"
ENT.FieldStrech		= true

local FIELD_HEIGHT = 120

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end

function ENT:Initialize()

	self.BaseClass.Initialize(self)
	
	if SERVER then
		self:PhysicsInitStatic(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		
		if self:GetStartEnabled() then self:Enable(true) end
		
		if not WireAddon then return end
		self.Inputs = Wire_CreateInputs(self, {"Enable"})
	end

	if CLIENT then
		
	end
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	if CLIENT then return end
	self:NextThink(CurTime() + 0.1)
	
	return true
end

function ENT:Draw()
	self.BaseClass.Draw(self)
end

-- no more client side
if CLIENT then return end

function ENT:HandleEntity(ent)
	if not self:GetEnable() then return end

	if ent.IsAperture then return end
	if ent == self:GetSecondEmitter() then return end
	if not IsValid(ent:GetPhysicsObject()) then return end
	if ent:GetModel() == "models/blackops/portal_sides.mdl" then return end
	
	ent:TakeDamage(ent:Health(), self, self)
	if ent:IsPlayer() and ent:Alive() then
		LIB_APERTURE.ACHIEVEMENTS:AchievAchievement(ent, "chromium")
	end
end
