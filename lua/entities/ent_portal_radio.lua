AddCSLuaFile( )
DEFINE_BASECLASS("base_anim")

ENT.PrintName		= "Radio"
ENT.Category		= "Aperture Science"
ENT.Editable		= true
ENT.Spawnable		= true
ENT.RenderGroup 	= RENDERGROUP_BOTH
ENT.AutomaticFrameAdvance = true

function ENT:SpawnFunction(ply, trace, className)
	if not trace.Hit then return end
	
	local ent = ents.Create(className)
	if not IsValid(ent) then return end
	ent:SetPos(trace.HitPos + trace.HitNormal * 10)
	ent:SetAngles(ply:GetAngles() + Angle(0, 180, 0))
	ent:Spawn()
	ent:Activate()
	ent.Owner = ply
	
	return ent
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Enable")
end

function ENT:Initialize()
	if CLIENT then return end
	
	self:SetModel("models/aperture/radio_reference.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:GetPhysicsObject():Wake()
	self.Radio_Counter = 0
	
	return true
end

-- no more client side
if CLIENT then return end

function ENT:Use(activator, caller)
	if IsValid(caller) and caller:IsPlayer() then
		if timer.Exists("TA_Radio_Block"..self:EntIndex()) then return end
		timer.Create( "TA_Radio_Block"..self:EntIndex(), 1, 1, function() end )
		self:SetEnable(not self:GetEnable())
		
		if self:GetEnable() then
			if math.random(1, 20 - self.Radio_Counter) == 1 then
				self:EmitSound( "TA:RadioStrangeNoice" )
				self.Radio_Counter = 0
				LIB_APERTURE.ACHIEVEMENTS:AchievAchievement(self.Owner, "radio")
			else
				self:EmitSound( "TA:RadioLoop" )
			end
			
			self.Radio_Counter = self.Radio_Counter + 1
		else
			self:StopSound( "TA:RadioLoop" )
			self:StopSound( "TA:RadioStrangeNoice" )
		end
	end
end

function ENT:OnRemove()
	timer.Remove("TA_Radio_Block"..self:EntIndex())
	self:StopSound("TA:RadioLoop")
	self:StopSound("TA:RadioStrangeNoice")
end
