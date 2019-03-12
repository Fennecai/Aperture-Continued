AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_ent")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Thermal Discouragement Beam Emitter"
ENT.IsAperture 		= true
ENT.IsConnectable 	= true

ENT.LASER_BBOX 		= 1
ENT.MAX_REFLECTIONS = 256

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Enable")
	self:NetworkVar("Bool", 1, "Toggle")
	self:NetworkVar("Bool", 2, "StartEnabled")
end

function ENT:ModelToStartCoord()
	local modelToStartCoord = {
		["models/aperture/laser_emitter_center.mdl"] = Vector(30, 0, 0),
		["models/aperture/laser_emitter.mdl"] = Vector(30, 0, -14)
	}
	return modelToStartCoord[self:GetModel()]
end

function ENT:Enable(enable)
	if self:GetEnable() != enable then
		if enable then
			self:MakeSoundEntity("TA:LaserBurn", self:LocalToWorld(Vector(25, 0, 0)))
			self:MakeSoundEntity("TA:LaserStart", self:LocalToWorld(Vector(25, 0, 0)), self)
		else
			self:RemoveSoundEntity("TA:LaserBurn")
			self:RemoveSoundEntity("TA:LaserStart")
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
		self.Inputs = Wire_CreateInputs(self, {"Enable"})
	end

	if CLIENT then
		
	end
	
	self.TA_FilterEntities 	= { }
	self.TA_PassagesCount 	= 0
end


if CLIENT then
	local laserSpriteCount = 32
	local laserSpriteRadius = 40
	-- Beam shoot effect
	function ENT:DrawMuzzleEffect(startpos, dir)
		for i = 1,laserSpriteCount do
			local radius = laserSpriteRadius * (1 - i / laserSpriteCount) * math.Rand(0.9, 1.1)
			render.SetMaterial(Material("particle/laser_beam_glow"))
			render.DrawSprite(startpos + dir * i * (1 + (i - 1) / 80), radius, radius, Color(255, 255, 255))
		end
	end
end

function ENT:DamageEntity(ent, startpos, endpos)
	if not IsValid(ent) then return end

	if not timer.Exists("TA:DamageEntity"..ent:EntIndex()) then
		ent:TakeDamage(4, self, self) 
		ent:EmitSound("TA:LaserBodyBurn")
		timer.Create("TA:DamageEntity"..ent:EntIndex(), 0.25, 1, function() end)
	end

	if ent:IsPlayer() and ent:IsOnGround() then
		local dir = (endpos - startpos):GetNormalized()
		
		-- Forces Player away from the laser
		local angles = dir:Angle()
		local center = ent:LocalToWorld(ent:GetPhysicsObject():GetMassCenter())
		local forceDirLocal = WorldToLocal(center, Angle(), startpos, angles)
		forceDirLocal.x = 0
		
		local forceDir = LocalToWorld(forceDirLocal, Angle(), Vector(), angles)
		forceDir.z = 0
		forceDir = forceDir:GetNormalized() * math.max(0, 40 - forceDir:Length())
		ent:SetVelocity(forceDir * 20)
	end
end

function ENT:HandleEntities(ent, startpos, endpos)
	if ent:IsPlayer() or ent:IsNPC() then
		self:DamageEntity(ent, startpos, endpos)
	elseif ent:GetModel() == "models/aperture/laser_receptacle.mdl" then
		ent.LastHittedByLaser = CurTime()
	end
end

function ENT:DoLaser(startpos, ang, ignore)

	self.TA_PassagesCount = self.TA_PassagesCount + 1
	if self.TA_PassagesCount >= self.MAX_REFLECTIONS then return end
	if self.TA_PassagesCount > 50 and SERVER then
		LIB_APERTURE.ACHIEVEMENTS:AchievAchievement(self.Player, "laser_show")
	end

	local drawEndEffect = true
	local filter = {ignore, "models/aperture/laser_receptacle.mdl"}
	local points, trace = LIB_APERTURE:GetAllPortalPassagesAng(startpos, ang, nil, filter)

	if IsValid(trace.Entity) then
		local ent = trace.Entity
		-- if hit laser catcher
		if ent:GetClass() == "ent_portal_laser_catcher" then
			drawEndEffect = false
			ent.LastHittedByLaser = CurTime()
		end
	end
		
	for k,v in pairs(points) do
		if CLIENT then
			//render.OverrideDepthEnable(true, false)
			//render.SetLightingMode(2)
			render.SetMaterial(Material("sprites/purplelaser1")) 
			render.DrawBeam(v.startpos, v.endpos, 60, 1, v.startpos:Distance(v.endpos) / 50, Color(255, 255, 255))
			//render.OverrideDepthEnable(false, false)
			//render.SetLightingMode(0)
		end
		
		if SERVER then
			util.TraceHull({
				start = v.startpos,
				endpos = v.endpos,
				ignoreworld = true,
				filter = function(ent)
					if ent != self and ent:GetClass() != "prop_portal" then
						self:HandleEntities(ent, v.startpos, v.endpos)
					end
				end,
				mins = -Vector(1, 1, 1) * self.LASER_BBOX,
				maxs = Vector(1, 1, 1) * self.LASER_BBOX,
				mask = MASK_SHOT_HULL
			})
		end
	end
	
	local cellPos = LIB_MATH_TA:ConvertToGrid(trace.HitPos, LIB_PAINT.PAINT_INFO_SIZE)
	local paintInfo = LIB_PAINT:GetCellPaintInfo(cellPos)
	local ent = trace.Entity
	if (paintInfo and paintInfo.paintType == PORTAL_PAINT_REFLECTION)
		or IsValid(ent) and IsValid(ent) and ent:GetNWInt("TA:PaintType") and ent:GetNWInt("TA:PaintType") == PORTAL_PAINT_REFLECTION then
		
		local normal = trace.HitNormal
		local lastPointInfo = points[#points]
		if lastPointInfo then 
			local direction = (lastPointInfo.endpos - lastPointInfo.startpos):GetNormalized()
			LIB_MATH_TA:NormalFlipZeros(normal)
			
			local reflectionDir = normal:Dot(-direction) * normal * 2 + direction 
			return self:DoLaser(trace.HitPos, reflectionDir:Angle())
		end
	end

	if IsValid(trace.Entity) then
		if ent:GetModel() == "models/aperture/reflection_cube.mdl" and not ent.isClone and not self.TA_FilterEntities[ent] then
			if CLIENT then
				self:DrawMuzzleEffect(ent:GetPos(), ent:GetForward())
			end
			self.TA_FilterEntities[ent] = true
			return self:DoLaser(ent:LocalToWorld(Vector(20, 0, 0)), ent:GetAngles(), ent)
		end
	end
		
	-- returning last tracer hit position
	return trace, drawEndEffect
end


function ENT:Draw()
	self:DrawModel()
end

function ENT:ClearData()
	self.TA_FilterEntities = {}
	self.TA_PassagesCount = 0
end

function ENT:Drawing()
	-- skip if disabled
	if not self:GetEnable() then return end
	local startpos = self:LocalToWorld(self:ModelToStartCoord())
	-- clearing data
	self:DrawMuzzleEffect(startpos + self:GetForward() * 5, self:GetForward())
	self:ClearData()
	local endtrace = self:DoLaser(startpos, self:GetAngles(), self)
end

-- no more client side
if CLIENT then return end

function ENT:Think()
	self:NextThink(CurTime())
	
	-- skip if disabled
	if not self:GetEnable() then return end

	self:ClearData()
	local startPos = self:LocalToWorld(self:ModelToStartCoord())
	local endtrace, effect = self:DoLaser(startPos, self:GetAngles(), self)
	if not endtrace then return true end
	
	self:MoveSoundEntity("TA:LaserBurn", endtrace.HitPos + endtrace.HitNormal)
		
	if not timer.Exists("TA:LaserSparksEffect"..self:EntIndex()) and effect then 
		timer.Create( "TA:LaserSparksEffect"..self:EntIndex(), 0.05, 1, function() end )

		local effectdata = EffectData()
		effectdata:SetOrigin(endtrace.HitPos)
		effectdata:SetNormal(endtrace.HitNormal)
		util.Effect("StunstickImpact", effectdata)
	end

	return true
end

function ENT:TriggerInput(iname, value)
	if not WireAddon then return end

	if iname == "Enable" then self:Enable(tobool(value)) end
end

numpad.Register("PortalLaserEmitter_Enable", function(pl, ent, keydown)
	if not IsValid(ent) then return false end
	ent:EnableEX(keydown)
	return true
end)

function ENT:OnRemove()
	self:RemoveSoundEntity("TA:LaserBurn")
	self:RemoveSoundEntity("TA:LaserStart")
end
