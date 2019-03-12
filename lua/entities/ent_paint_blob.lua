AddCSLuaFile()

ENT.Type 			= "anim"
ENT.Base 			= "base_entity"
ENT.RenderGroup 	= RENDERGROUP_BOTH

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "PaintRadius")
	self:NetworkVar("Int", 1, "PaintType")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/aperture/paint_blob.mdl")
		self:SetRenderMode(RENDERMODE_TRANSALPHA)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
		self.TA_PrevPos = self:GetPos()
		self:GetPhysicsObject():EnableCollisions(false)
	end
end

function ENT:HandleEntities(ent)
	if ent:GetClass() != self:GetClass() and ent:GetClass() != "prop_portal" and not ent.IsConnectable and IsValid(ent:GetPhysicsObject()) then
		local paintType = self:GetPaintType()
		local center = ent:LocalToWorld(ent:GetPhysicsObject():GetMassCenter())
		local trace = util.TraceLine({
			start = self:GetPos(),
			endpos = center,
			filter = function(fent) if fent:GetClass() != self:GetClass() and fent != ent then return true end end
		})
		if trace.Hit then return end
		
		if ent:IsPlayer() then
			local rad = self:GetPaintRadius()
			local effectRad = math.Rand(rad / 2, rad)
			if not self.IsFromPaintGun or self:GetOwner() != ent and self.IsFromPaintGun then
				LIB_APERTURE:PaintPlayerScreen(ent, paintType, effectRad)
			end
		else
			if paintType == PORTAL_PAINT_WATER then
				LIB_APERTURE:ClearPaintedEntity(ent)
			else
				LIB_APERTURE:PaintEntity(ent, paintType)
			end
			
			-- extinguish if paint type is water
			if paintType == PORTAL_PAINT_WATER and ent:IsOnFire() then
				ent:Extinguish()
				print(self.Owner)
				LIB_APERTURE.ACHIEVEMENTS:AchievAchievement(self.Owner, "firefighter")
			end
		end
	end
end

function ENT:PaintSplat(pos, normal, radius, velocity)
	local paintType = self:GetPaintType()
	local effectdata = EffectData()
	effectdata:SetOrigin(pos)
	effectdata:SetNormal(normal)
	effectdata:SetRadius(self:GetPaintRadius())
	effectdata:SetColor(paintType)
	
	if radius >= 150 then
		self:EmitSound("TA:PaintSplatBig")
		util.Effect("paint_bomb_effect", effectdata)
	else
		self:EmitSound("TA:PaintSplat")
		util.Effect("paint_splat_effect", effectdata)
	end
	
	local color = LIB_APERTURE:PaintTypeToColor(paintType)
	-- local direction = normal == Vector(0, 0, 1) and Vector(velocity.x, velocity.y, 0):GetNormalized() or nil
	-- local viscosity = normal == Vector(0, 0, 1) and 1 - math.abs(velocity:GetNormalized().z) or 1

	local paintDat = {
		paintType = paintType,
		radius = radius,
		hardness = 0.6,
		color = color,
		viscosity = viscosity,
		direction = direction
	}
	if paintType == PORTAL_PAINT_WATER then
		LIB_PAINT:PaintSplat(pos + normal, paintDat, true)
	else
		LIB_PAINT:PaintSplat(pos + normal, paintDat, false)
	end
	
	-- handling entities around splat
	local findResult = ents.FindInSphere(pos, radius)
	
	for k,v in pairs(findResult) do
		self:HandleEntities(v)
	end
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Think()

	self:NextThink(CurTime() + 0.1)
	
	-- blob animation
	if CLIENT then
		local rotation = (CurTime() + self:EntIndex() * 10) * 4
		local scale = Vector(1 + math.cos(rotation) / 4, 1 + math.sin(rotation) / 4, 1) * self:GetPaintRadius() / 150
		local mat = Matrix()
		mat:Scale(scale)
		self:EnableMatrix("RenderMultiply", mat)

		self:SetAngles(Angle(rotation * 10, rotation * 20, 0))
		
		-- no more client side
		return true
	end
	
	-- removing puddle when it is under water
	if self:WaterLevel() == 3 then
		local traceWater = util.TraceLine({
			start = self:GetPos() + Vector(0, 0, 50),
			endpos = self:GetPos(),
			mask = MASK_WATER,
			collisiongroup = COLLISION_GROUP_DEBRIS
		})

		local effectdata = EffectData()
		effectdata:SetOrigin(traceWater.HitPos)
		effectdata:SetNormal(Vector(0, 0, 1))
		effectdata:SetRadius(self:GetPaintRadius())
		effectdata:SetColor(self:GetPaintType())
		util.Effect("paint_splat_effect", effectdata)

		effectdata:SetOrigin(traceWater.HitPos)
		effectdata:SetScale(self:GetPaintRadius() / 10)

		util.Effect("WaterSplash", effectdata)
		self:Remove()
	end	
	
	local trace = util.TraceLine({
		start = self.TA_PrevPos,
		endpos = self:GetPos(),
		filter = function(ent)
			if not ent.IsAperture and ent != self:GetOwner() then return true end
		end
	})
	
	if trace.HitSky then 
		self:Remove()
		return
	end

	self.TA_PrevPos = self:GetPos()
	if trace.Hit then
		local traceEnt = trace.Entity
		if IsValid(traceEnt) and traceEnt:GetClass() == "prop_portal" and IsValid(traceEnt:GetNWEntity("Potal:Other")) then
			local other = traceEnt:GetNWEntity("Potal:Other")
			self.TA_PrevPos = other:GetPos()
			self:NextThink(CurTime() + 1)
			return true
		else
			local velocity = self:GetVelocity()
			self:SetPos(trace.HitPos + trace.HitNormal)
			self:PaintSplat(trace.HitPos, trace.HitNormal, self:GetPaintRadius(), velocity)
			self:SetNoDraw(true)
			self:GetPhysicsObject():EnableMotion(false)

			timer.Simple(1, function() if IsValid(self) then self:Remove() end end)
			self:NextThink(CurTime() + 10)
		end
	elseif trace.Fraction == 0 or not util.IsInWorld(self:GetPos()) then self:Remove() return end
	
	return true
end
