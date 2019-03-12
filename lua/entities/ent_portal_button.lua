AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_ent")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Pillar Button"
ENT.IsAperture 		= true
ENT.IsConnectable 	= true

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end
if SERVER then
	function ENT:ModelToInfo()
		local modelToInfo = {
			["models/aperture/button.mdl"] = {sounddown = "TA:ButtonClick", soundup = "TA:ButtonUp", animdown = "down", animup = "up"},
			["models/aperture/underground_button.mdl"] = {sounddown = "TA:OldButtonClick", soundup = "TA:OldButtonUp", animdown = "press", animup = "release"}
		}
		return modelToInfo[self:GetModel()]
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Key")
	self:NetworkVar("Bool", 1, "On")
	self:NetworkVar("Int", 2, "Timer")
end

function ENT:Press(on, ply)
	local info = self:ModelToInfo()
	if self:GetOn() != on then
		if on then
			self:EmitSound(info.sounddown)
			self:PlaySequence(info.animdown, 1.0)
			
			numpad.Activate(self:GetPlayer(), self:GetKey(), true)
			if WireAddon then Wire_TriggerOutput(self, "Activated", 1) end
		else
			self:EmitSound(info.soundup)
			self:PlaySequence(info.animup, 1.0)
			
			numpad.Deactivate(self:GetPlayer(), self:GetKey(), false)
			if WireAddon then Wire_TriggerOutput(self, "Activated", 0) end
		end
		
		self:SetOn(on)
	end
	
	if IsValid(ply) and ply:IsPlayer() then
		if not ply.PressedButtonCount or CurTime() > (ply.LastPressedButton + 2) then
			ply.LastPressedButton = CurTime()
			ply.PressedButtonCount = 1
		else
			ply.PressedButtonCount = ply.PressedButtonCount + 1
		end
		
		if ply.PressedButtonCount > 5 then
			LIB_APERTURE.ACHIEVEMENTS:AchievAchievement(ply, "buttonmaniac")
		end
	end
end

function ENT:Initialize()

	self.BaseClass.Initialize( self )
	
	if CLIENT then return end
	
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:GetPhysicsObject():EnableMotion(false)

	if not WireAddon then return end
	self.Outputs = WireLib.CreateSpecialOutputs(self, {"Activated"}, {"NORMAL"})
	
	return true
end

function ENT:Draw()
	self:DrawModel()
end

-- no more client side
if CLIENT then return end

function ENT:Use(activator, caller, usetype, val)
	if not IsValid(caller) then return end
	if timer.Exists("TA:Button_Block"..self:EntIndex()) then return end
	
	timer.Create("TA:Button_Block"..self:EntIndex(), 1, 1, function() end)
	
	if not timer.Exists("TA:Button_Timer"..self:EntIndex()) then
		self:Press(true, caller)
	end
	
	timer.Create("TA:Button_Timer"..self:EntIndex(), self:GetTimer(), 1, function()
		if IsValid(self) then
			self:Press(false)
		end
	end)
end

function ENT:Setup()
	if not WireAddon then return end
	Wire_TriggerOutput(self, "Activated", 0)
end

function ENT:OnRemove()
	timer.Remove("TA:Button_Timer"..self:EntIndex())	
	timer.Remove("TA:Button_Block"..self:EntIndex())	
end
