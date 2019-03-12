AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_ent")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Portal Spawner"
ENT.IsAperture 		= true
ENT.IsConnectable 	= true

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Enable")
	self:NetworkVar("Bool", 1, "Toggle")
	self:NetworkVar("Bool", 2, "StartEnabled")
	self:NetworkVar("Int", 3, "PortalType")
end

function ENT:Enable(enable)
	if self:GetEnable() != enable then
		if enable then
			local portalType = self:GetPortalType()
			self:OpenPortal(portalType)
			self:SetSkin(portalType)
		else
			self:ClearPortal()
			self:SetSkin(0)
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

function ENT:ClearPortal()
	local portal = self:GetNWEntity("PortalEntity")
	if not IsValid(portal) then return end
	portal:Remove()
	if not IsValid(portal:GetOther()) then return end
	portal:GetOther():SetNWEntity("Potal:Other", nil)
	portal:GetOther():SetNWBool("Potal:Linked", false)
end

function ENT:OpenPortal(portalType)
	if portalType == 0 then return end

	if not TYPE_BLUE or not TYPE_BLUE then return end
	
	local orangePortalEnt = self.Owner:GetNWEntity("Portal:Orange", nil)
	local bluePortalEnt = self.Owner:GetNWEntity("Portal:Blue", nil)
	local entToUse = portalType == TYPE_BLUE and bluePortalEnt or orangePortalEnt
	local otherEnt = portalType == TYPE_BLUE and orangePortalEnt or bluePortalEnt
	local pos = self:LocalToWorld(Vector())
	local ang = self:LocalToWorldAngles(Angle())
	if not IsValid(entToUse) then
		local portal = ents.Create("prop_portal")
		if not IsValid(portal) then return end
		portal:SetPos(pos)
		portal:SetAngles(ang)
		portal:Spawn()
		portal:Activate()
		portal:SetMoveType(MOVETYPE_NONE)
		portal:SetActivatedState(true)
		portal:SetType(portalType)
		portal:SuccessEffect()
		self:SetNWEntity("PortalEntity", portal)
	   
		if portalType == TYPE_BLUE then
			self.Owner:SetNWEntity("Portal:Blue", portal)
			portal:SetNetworkedBool("blue", true, true)
		else
			self.Owner:SetNWEntity("Portal:Orange", portal)
			portal:SetNetworkedBool("blue", false, true)
		end
	   
		entToUse = portal
	   
		if IsValid(otherEnt) then entToUse:LinkPortals(otherEnt) end
	else
		self:SetNWEntity("PortalEntity", entToUse)
		entToUse:MoveToNewPos(pos, ang)
		entToUse:SuccessEffect()
	end
end

function ENT:Think()
	self:NextThink(CurTime() + 0.1)
	
	if CLIENT then return end
	
	return true
end

-- no more client side
if CLIENT then return end

function ENT:TriggerInput(iname, value)
	if not WireAddon then return end
	
	if iname == "Enable" then self:ToggleEnable(tobool(value)) end
end

numpad.Register("PortalFrame_Enable", function(pl, ent, keydown)
	if not IsValid(ent) then return false end
	ent:EnableEX(keydown)
	return true
end)

function ENT:OnRemove()
	self:ClearPortal()
end

