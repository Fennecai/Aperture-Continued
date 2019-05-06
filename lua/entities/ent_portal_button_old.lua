AddCSLuaFile()
DEFINE_BASECLASS("base_aperture_floor_button")

ENT.PrintName = "Wired Button (Old)"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.Category = "Aperture Science"

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED
local PortalButtons = PortalButtons

if (WireAddon) then
	ENT.WireDebugName = "Wired Portal Button (Old)"
end

if CLIENT then
	return
end

local AcceptedModels = nil
function ENT:Initialize()
	self:SetModel("models/portal_custom/underground_floor_button_custom.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetUseType(SIMPLE_USE)

	if not AcceptedModels and PortalButtons then
		AcceptedModels = PortalButtons.GetAcceptedObjects()["All"] or {}
	end

	self.BaseClass.Initialize(self)
end

function ENT:OnUpdateSettings()
	self:CreatePhys("models/portal_custom/underground_floor_button_custom_phy.mdl")
	if not IsValid(self.ButtonPhysEnt) then
		self:Remove()
		return
	end

	self.PressTriggerHeight = 17
	self.PressTriggerSize = 32
	self.UsePlayerTrigger = true
	self.PressTraceCount = 8
end

function ENT:Filter(ent)
	if not AcceptedModels then
		return false
	end
	if not AcceptedModels[ent:GetModel()] then
		return false
	end

	return true
end

local StopVector = Vector()

function ENT:OnChangePressEnt(ent_new, ent_old)
	if not AcceptedModels then
		return
	end

	if IsValid(ent_old) then
		if not ent_old:IsPlayer() then
			ent_old:PhysWake()
		end
	end

	if IsValid(ent_new) then
		self:EnableButtonPhys(false)

		if not ent_new:IsPlayer() then
			ent_new:PhysWake()
		end
	end
end

function ENT:OnTurnOn()
	self:SetAnim(3)
	self:EnableButtonPhys(false)
end

function ENT:OnTurnOFF()
	self:SetAnim(1)
	self:EnableButtonPhys(true)
end
