AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_turret")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Portal Turret Defective"

ENT.TurretEyePos 				= Vector(11.7, 0, 36.8)
ENT.TurretSoundFound 			= "TA:TurretDefectiveActivateVO"
ENT.TurretSoundSearch 			= "TA:TurretDetectiveAutoSearth"
ENT.TurretSoundAutoSearch 		= "TA:TurretDetectiveAutoSearth"
ENT.TurretRetract				= ""
ENT.TurretSoundFizzle 			= ""
ENT.TurretSoundPickup 			= ""
ENT.CantShoot					= true

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end

function ENT:Initialize()

	self.BaseClass.Initialize(self)
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		
		if self:GetStartEnabled() then self:Enable(true) end

		if not WireAddon then return end
		self.Inputs = Wire_CreateInputs(self, {"Enable"})
	end

	if CLIENT then
		
	end
end

-- no more client side
if CLIENT then return end

function ENT:Think()
	self.BaseClass.Think(self)
	
	self:NextThink(CurTime())
	
	-- Finding arount turret any entitie with ammo type, and giving turret the ability to shoot
	if self.CantShoot then
		local entities = ents.FindInSphere(self:GetPos(), 100)
		for k,v in pairs(entities) do
			local class = v:GetClass() and v:GetClass():lower() or ""
			if string.find(class, "ammo") then
				if IsValid(v.Player) then LIB_APERTURE.ACHIEVEMENTS:AchievAchievement(v.Player, "im_not_defective") end
				self.CantShoot = false
				v:Remove()
			end
		end
	end
	
	return true
end
