AddCSLuaFile()
DEFINE_BASECLASS("base_aperture_floor_button")

ENT.PrintName		= "Wired Button (Normal)"
ENT.Spawnable		= false
ENT.AdminOnly		= false
ENT.Category		= "Aperture Science"

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED
local PortalButtons = PortalButtons

if ( WireAddon ) then
	ENT.WireDebugName = "Wired Portal Button (Normal)"
end

if CLIENT then return end

local AcceptedModels = nil
function ENT:Initialize()
	self:SetModel( "models/portal_custom/portal_button_custom.mdl" )
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )

	if !AcceptedModels and PortalButtons then
		AcceptedModels = PortalButtons.GetAcceptedObjects()["All"] or {}
	end

	self.BaseClass.Initialize(self)
end

function ENT:OnUpdateSettings()
	self:CreatePhys("models/portal_custom/portal_button_custom_phy.mdl")
	if !IsValid( self.ButtonPhysEnt ) then
		self:Remove()
		return
	end

	self.PressTriggerHeight = 17
	self.PressTriggerSize = 17
	self.UsePlayerTrigger = true
	self.PressTraceCount = 4
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

			ent_old:PhysWake()
		end
	end
	
	if IsValid(ent_new) then
		self:EnableButtonPhys(false)

		if !ent_new:IsPlayer() then
			local model = ent_new:GetModel()
			local skin = ent_new:GetSkin()
			local skindata = AcceptedModels[model] or {}

			local SkinChange = (skindata.on or {})[skin]
			if SkinChange then
				ent_new:SetSkin(SkinChange)
			end

			ent_new:PhysWake()
		end
	end
end

function ENT:OnTurnOn()
	self:SetSkin(1)
	self:SetAnim(3)

	self:EnableButtonPhys( false )
end

function ENT:OnTurnOFF()
	self:SetSkin(0)
	self:SetAnim(1)

	self:EnableButtonPhys( true )
end