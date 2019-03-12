AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_ent")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Crusher"
ENT.IsAperture 		= true
ENT.IsConnectable 	= true

local CRUSHER_HIT_RANGE = 400
local CRUSHER_HIT_WIDTH = 100

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Enable")
	self:NetworkVar("Bool", 1, "Toggle")
	self:NetworkVar("Bool", 2, "StartEnabled")
	self:NetworkVar("Bool", 3, "Busy")
	self:NetworkVar("Int", 4, "Length")
end

function ENT:Enable(enable)
	if self:GetEnable() != enable then
		if enable then
			
		else
			
		end
		
		self:SetEnable(enable)
	end
end

function ENT:EnableEX(enable)
	if self:GetToggle() then
		if enable then
			self:Enable(not self:GetEnable())
		end
		return true
	end
	
	if self:GetStartEnabled() then enable = !enable end
	self:Enable(enable)
end

function ENT:CleateCrusher()
	local ent = ents.Create("prop_portal_phys_anim")
	if not IsValid(ent) then return end
	ent:SetModel("models/aperture/crusher.mdl")
	ent:SetPos(self:LocalToWorld(Vector(0, 0, 0)))
	ent:SetAngles(self:LocalToWorldAngles(Angle(0, 0, 0)))
	ent:SetMoveType(MOVETYPE_NONE)
	ent:Spawn()
	self:DeleteOnRemove(ent)
	ent:DeleteOnRemove(self)
	self:SetNWEntity("TA:PhysPannel", ent)
	ent:GetPhysicsObject():EnableMotion(false)
	constraint.NoCollide(ent, self, 0, 0) 
end

function ENT:Initialize()

	self.BaseClass.Initialize(self)
	
	if SERVER then
		self:SetModel("models/aperture/crusher_box.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetBusy(false)
		if self:GetStartEnabled() then self:Enable(true) end
		self:GetPhysicsObject():EnableMotion(false)
		
		self:CleateCrusher()
		
		if not WireAddon then return end
		self.Inputs = Wire_CreateInputs(self, {"Enable"})
	end

	if CLIENT then
		
	end
end

if CLIENT then return end -- no more client side

function ENT:TriggerInput(iname, value)
	if not WireAddon then return end
	
	if iname == "Enable" then self:Enable(tobool(value)) end
end

function ENT:TransformPlate()
	local plate = self:GetNWEntity("TA:PhysPannel")
	local length = self:GetLength()
	plate:SetAngles(self:GetAngles())
	
	if self.SmashStartTime then
		local time = CurTime() - self.SmashStartTime
		if time <= 0.6 then plate:SetPos(self:LocalToWorld(Vector((time / 0.6) * length, 0, 0)))
		elseif time <= 1.6 then plate:SetPos(self:LocalToWorld(Vector(length, 0, 0))) 
		elseif time > 1.8 and time < 4 then
			local time = 1 - (time - 1.8) / (4 - 1.8)
			time = 0.5 - math.cos(time * math.pi) / 2
			plate:SetPos(self:LocalToWorld(Vector(time * length, 0, 0))) 
		elseif time > 4 then self.SmashStartTime = false end
	else
		plate:SetPos(self:GetPos())
	end
end

function ENT:Think()
	if not IsValid(self) then return end
	self:NextThink(CurTime())

	self:StartSmash()
	self:TransformPlate()
	
	return true
end

function ENT:DamageEntities()
	local length = self:GetLength()
	local min = self:LocalToWorld(Vector(220, -CRUSHER_HIT_WIDTH, -CRUSHER_HIT_WIDTH))
	local max = self:LocalToWorld(Vector(length + 220, CRUSHER_HIT_WIDTH, CRUSHER_HIT_WIDTH))
	OrderVectors(min, max)
	
	local entities = ents.FindInBox(max, min)
	for k,v in pairs(entities) do
		if LIB_APERTURE:IsValidHealthEntity(v) then v:TakeDamage(250, self, self) end
		if v:GetClass() == "prop_monster_box" then
			LIB_APERTURE.ACHIEVEMENTS:AchievAchievement(self.Founder, "good_idea")
		end
	end
end

function ENT:Smash()
	self:DamageEntities()
	sound.Play("TA:CrusherSmash", self:GetPos() + self:GetForward() * 100, 75, 100, 1) 
	util.ScreenShake(self:GetPos(), 100, 10, 1, 1500)
end

function ENT:StartSmash()
	if not self:GetEnable() then return end
	if not IsValid(self) then return end
	if self:GetBusy() then return end
	local plate = self:GetNWEntity("TA:PhysPannel")
	self:SetBusy(true)
	self.SmashStartTime = CurTime()
	timer.Simple(0.5, function () if IsValid(self) then self:Smash() end end)
	timer.Simple(1.5, function() 
		if not IsValid(self) then return end
		sound.Play("TA:CrusherOpen", self:GetPos() + self:GetForward() * 100, 75, 100, 1) 
	end)
	
	timer.Simple(plate:PlaySequence("smash", 1.0) + 0.25, function() if IsValid(self) then self:SetBusy(false) end end)
end

numpad.Register("PortalCrusher_Enable", function(pl, ent, keydown)
	if not IsValid(ent) then return false end
	ent:EnableEX(keydown)
	return true
end)