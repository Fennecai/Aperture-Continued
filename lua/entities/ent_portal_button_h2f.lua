AddCSLuaFile()
DEFINE_BASECLASS("base_aperture_floor_button")

ENT.PrintName = "Wired Button (square)"
ENT.Spawnable = false
ENT.AdminOnly = false
ENT.Category = "Aperture Science"

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED
local PortalButtons = PortalButtons

if (WireAddon) then
	ENT.WireDebugName = "Wired Portal Button (square)"
end

if CLIENT then
	return
end

local AcceptedModels = nil
function ENT:Initialize()
	self:SetModel("models/props_h2f/portal_button.mdl")
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
	self:CreatePhys("models/props_h2f/portal_button.mdl")
	if not IsValid(self.ButtonPhysEnt) then
		self:Remove()
		return
	end

	self.PressTriggerHeight = 17
	self.PressTriggerSize = 17
	self.UsePlayerTrigger = true
	self.PressTraceCount = 4
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

function ENT:OnChangePressEnt(ent_new, ent_old)
	if not AcceptedModels then
		return
	end

	if IsValid(ent_old) then
		if not ent_old:IsPlayer() then
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
				phys:EnableGravity(true)

				self.CurEntMat = nil
				phys:Wake()
			end
		end
	end
	if IsValid(ent_new) then
		self:EnableButtonPhys(false)
		if not ent_new:IsPlayer() then
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
				phys:EnableGravity(true)
				phys:Wake()
			end
		end
	end
end

function ENT:OnTurnOn()
	self:SetSkin(0)
	self:SetAnim("Down")

	self:EnableButtonPhys(false)
end

function ENT:OnTurnOFF()
	self:SetSkin(0)
	self:SetAnim("Up")

	self:EnableButtonPhys(true)
end
