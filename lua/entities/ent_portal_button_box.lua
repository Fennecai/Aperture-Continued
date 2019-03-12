AddCSLuaFile()
DEFINE_BASECLASS("base_aperture_floor_button")

ENT.PrintName		= "Wired Button (Box)"
ENT.Spawnable		= false
ENT.AdminOnly		= false
ENT.Category		= "Aperture Science"

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED
local PortalButtons = PortalButtons

if ( WireAddon ) then
	ENT.WireDebugName = "Wired Portal Button (Box)"
end

if CLIENT then return end

local AcceptedModels = nil
function ENT:Initialize()
	self:SetModel( "models/portal_custom/box_socket_custom.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )

	if !AcceptedModels and PortalButtons then
		AcceptedModels = PortalButtons.GetAcceptedObjects()["Cupes"] or {}
	end

	self.BaseClass.Initialize(self)
end

function ENT:OnUpdateSettings()
	self.PressTriggerHeight = 11
	self.PressTriggerSize = 18
	self.UsePlayerTrigger = false
	self.PressTraceCount = 3
end

function ENT:Filter( ent )
	if !AcceptedModels then return false end
	if !AcceptedModels[ent:GetModel()] then return false end

	return true
end

function ENT:OnChangePressEnt(ent_new, ent_old)
	if !AcceptedModels then return end

	if IsValid(ent_old) then
		if !ent_old:IsPlayer() then
			local model = ent_old:GetModel()
			local skin = ent_old:GetSkin()
			local skindata = AcceptedModels[model] or {}

			local SkinChange = (skindata.off or {})[skin]
			if SkinChange then
				ent_old:SetSkin(SkinChange)
			end

			local phys = ent_old:GetPhysicsObject()
			if IsValid(phys) then
				if string.lower(self.CurEntMat) == "default" then -- "default" is not working
					self.CurEntMat = nil
				end
				
				phys:SetMaterial(self.CurEntMat or "Plastic_Box")
				phys:EnableGravity( true )

				self.CurEntMat = nil
				phys:Wake()
			end
		end
	end
	
	if IsValid(ent_new) then
		if !ent_new:IsPlayer() then
			local model = ent_new:GetModel()
			local skin = ent_new:GetSkin()
			local skindata = AcceptedModels[model] or {}

			local SkinChange = (skindata.on or {})[skin]
			if SkinChange then
				ent_new:SetSkin(SkinChange)
			end

			local phys = ent_new:GetPhysicsObject()
			if IsValid(phys) then
				self.CurEntMat = phys:GetMaterial()
				phys:SetMaterial("ice")
				phys:EnableGravity( true )
				phys:Wake() 
			end
		end
	end
end

function ENT:OnTurnOn()
	self:SetSkin(1)
	self:SetAnim(1)
end

function ENT:OnTurnOFF()
	self:SetSkin(0)
	self:SetAnim(2)
end