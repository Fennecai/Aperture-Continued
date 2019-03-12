AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_field")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Material Emancipation Grill"
ENT.FieldColor 		= Color(120, 230, 255)
ENT.InUnFizzable	= true

local FIELD_HEIGHT = 120

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end

function ENT:Initialize()

	self.BaseClass.Initialize(self)
	
	if SERVER then
		self:PhysicsInitStatic(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		
		if self:GetStartEnabled() then self:Enable(true) end
		self.ProjectedWalls = {}
		self:SetNWFloat("TA:FieldFlash", 0)
		if not WireAddon then return end
		self.Inputs = Wire_CreateInputs(self, {"Enable"})
	end

	if CLIENT then
		
	end
end

function ENT:Think()
	self.BaseClass.Think(self)
	
	if CLIENT then
		if self:GetNWFloat("TA:FieldFlash") > 0 then
			local flash = (1 + self:GetNWFloat("TA:FieldFlash") / 15)
			local color = Color(self.FieldColor.r * flash, self.FieldColor.g * flash, self.FieldColor.b * flash)
			for k,v in pairs(self.FieldsEntities) do
				v:SetColor(color)
			end
		end
		return
	end
	self:NextThink(CurTime())
	
	if self:GetNWFloat("TA:FieldFlash") > 0 then
		self:SetNWFloat("TA:FieldFlash", self:GetNWFloat("TA:FieldFlash") - 1)
	end
	
	return true
end

function ENT:Draw()
	self.BaseClass.Draw(self)
end

function ENT:Drawing()
	local secondEmitter = self:GetSecondEmitter()
	if not IsValid(secondEmitter) then return end
	if not self:GetEnable() then return end

	--Approach object field effect
	local closesEntities = {}
	local tracer = util.TraceHull({
		start = self:LocalToWorld(Vector()),
		endpos = secondEmitter:LocalToWorld(Vector()),
		filter = function(ent)
			if not ent.IsAperture
				and ent != self 
				and ent != secondEmitter 
				and not ent:IsPlayer() 
				and not ent:IsNPC() then
				table.insert(closesEntities, ent)
			end

			return false
		end,
		ignoreworld = true,
		mins = -Vector(1, 1, 1) * FIELD_HEIGHT,
		maxs = Vector(1, 1, 1) * FIELD_HEIGHT,
		mask = MASK_SHOT_HULL
	})
	
	local clipNormalUp = -self:GetUp()
	local clipPosUp = clipNormalUp:Dot(self:LocalToWorld(Vector( 0, 0, FIELD_HEIGHT / 2)))

	local clipNormalDown = self:GetUp()
	local clipPosDown = clipNormalDown:Dot(self:LocalToWorld(Vector(0, 0, -FIELD_HEIGHT / 2)))
	
	render.SetMaterial(Material("models/aperture/effects/fizzler_approach"))
	
	local oldEC = render.EnableClipping(true)
	render.PushCustomClipPlane(clipNormalUp, clipPosUp)
	render.PushCustomClipPlane(clipNormalDown, clipPosDown)
	
	for _, ent in pairs(closesEntities) do
		local localEntPos = self:WorldToLocal(ent:GetPos())
		local distToField = math.abs(localEntPos.x)
		localEntPos = Vector(0, localEntPos.y, localEntPos.z)
		
		local rad = math.min(FIELD_HEIGHT, ent:GetModelRadius() * 6)
		local alpha = math.max(0, math.min(1, (75 - distToField) / 50)) * 255
		local dir = self:GetForward()
		local flash = (1 + self:GetNWFloat("TA:FieldFlash") / 15)
		local color = Color(math.min(self.FieldColor.r * flash, 255), math.min(self.FieldColor.g * flash, 255), math.min(self.FieldColor.b * flash, 255))
		color.a = alpha
		LIB_MATH_TA:NormalFlipZeros(dir)
		render.DrawQuadEasy(self:LocalToWorld(localEntPos), dir, rad, rad, color, 0)
	end

	render.PopCustomClipPlane()
	render.PopCustomClipPlane()
	render.EnableClipping(oldEC)
end

-- no more client side
if CLIENT then return end

function ENT:HandleEntity(ent)
	if not self:GetEnable() then return end

	if ent.InUnFizzable then return end
	if ent == self:GetSecondEmitter() then return end

	-- if it portal gun projectile
	if ent:GetClass() == "projectile_portal_ball" then
		local ang = ent:GetAngles()
		ang:RotateAroundAxis(ent:GetForward(), 90)
		ang.y = self:GetAngles().y + 90
		
		if GetConVarNumber("portal_beta_borders") >= 1 then
			ParticleEffect("portal_"..ent:GetNWInt("Kind", TYPE_BLUE).."_cleanser_", ent:GetPos(), ang)
		else
			ParticleEffect("portal_"..ent:GetNWInt("Kind", TYPE_BLUE).."_cleanser", ent:GetPos(), ang)
		end
		ent:Remove()
		
		self:SetNWFloat("TA:FieldFlash", 25)
		return
	end
	
	-- if it player with portal gun
	if ent:IsPlayer() and ent:Alive() then
		local plyweap = ent:GetActiveWeapon()
		if IsValid(plyweap) and plyweap:GetClass() == "weapon_portalgun" and plyweap.CleanPortals then
			plyweap:CleanPortals()
		end
		
		return
	end
	
	if ent.UnFizzable then return end
	if ent:IsPlayer() then return end
	if ent:IsNPC() then return end
	if ent:GetClass() == "prop_ragdoll" then return end
	if not IsValid(ent:GetPhysicsObject()) then return end
	if ent:GetModel() == "models/blackops/portal_sides.mdl" then return end
	
	LIB_APERTURE:DissolveEnt(ent)
end
