AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_ent")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Gel Dropper"
ENT.IsAperture 		= true
ENT.IsConnectable 	= true

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Enable")
	self:NetworkVar("Bool", 1, "StartEnabled")
	self:NetworkVar("Bool", 2, "Toggle")
	self:NetworkVar("Int", 3, "PaintType")
	self:NetworkVar("Int", 4, "PaintRadius")
	self:NetworkVar("Int", 5, "PaintAmount")
	self:NetworkVar("Int", 6, "PaintLaunchSpeed")
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

function ENT:Initialize()

	self.BaseClass.Initialize(self)
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		if self:GetStartEnabled() then self:Enable(true) end
		
		if not WireAddon then return end
		self.Inputs = Wire_CreateInputs(self, {"Enable", "Gel Radius", "Gel Amount", "Gel Launch Speed"})
	end

	if CLIENT then
		
	end
end

-- No more client side
if CLIENT then return end

function ENT:Think()
	
	self.BaseClass.Think(self)

	self:NextThink(CurTime() + 1)
	if self:GetEnable() then
		self:NextThink(CurTime() + math.max(1, 100 - self:GetPaintAmount()) / 50)
		self:MakePuddle()
	end	
	
	return true
end

function ENT:MakePuddle()

	-- Randomize makes random size between maxsize and minsize by selected procent
	local radius = self:GetPaintRadius()
	local launchSpeed = self:GetPaintLaunchSpeed()
	local randSize = math.Rand(-1, 1) * radius / 4

	local rad = math.max(LIB_APERTURE.GEL_MINSIZE, math.min(LIB_APERTURE.GEL_MAXSIZE, radius + randSize))
	local randomSpread = VectorRand():GetNormalized() * (LIB_APERTURE.GEL_MAXSIZE - rad) * (launchSpeed / LIB_APERTURE.GEL_MAX_LAUNCH_SPEED)
	local velocity = -self:GetUp() * launchSpeed + randomSpread
	local maxRad = (40 - (rad / LIB_APERTURE.GEL_MAXSIZE) * 40) / 4
	local pos = self:LocalToWorld(Vector(0, 0, -(maxRad + 5)) + VectorRand() * maxRad)
	
	local paint_blob = LIB_APERTURE:MakePaintBlob(self:GetPaintType(), pos, velocity, rad)
	if IsValid(self.Owner) and self.Owner:IsPlayer() then paint_blob:SetOwner(self.Owner) end
	
	return ent
end

function ENT:TriggerInput( iname, value )
	if not WireAddon then return end

	if iname == "Enable" then self:Enable(tobool(value)) end
	if iname == "Gel Radius" then self:SetPaintRadius(value) end
	if iname == "Gel Amount" then self:SetPaintAmount(value) end
	if iname == "Gel Launch Speed" then self:PaintLaunchSpeed(value) end
end

numpad.Register("PaintDropper_Enable", function(pl, ent, keydown)
	if not IsValid(ent) then return false end
	ent:EnableEX(keydown)
	return true
end)