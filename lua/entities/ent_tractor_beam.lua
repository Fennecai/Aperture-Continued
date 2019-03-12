AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_ent")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Excursion Funnel"
ENT.IsAperture 		= true
ENT.IsConnectable 	= true

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end

local FUNNEL_WITDH 				= 60
local FUNNEL_EFFECT_MODEL_SIZE 	= 320 * 1.3
local FUNNEL_SMOOTHING_IN		= 100

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Enable")
	self:NetworkVar("Bool", 1, "Reverse")
	self:NetworkVar("Bool", 2, "StartEnabled")
	self:NetworkVar("Bool", 3, "StartReversed")
	self:NetworkVar("Bool", 4, "Toggle")
end

if SERVER then

	function ENT:RemoveTrails()
		if IsValid(self.TA_Trail1) then self.TA_Trail1:Remove() end
		if IsValid(self.TA_Trail2) then self.TA_Trail2:Remove() end
		if IsValid(self.TA_Trail3) then self.TA_Trail3:Remove() end
	end

	function ENT:SetupTrails()
		local trailWidth = 150
		local trailWidthEnd = 0
		
		self:RemoveTrails()

		local enable = self:GetEnable()
		local reverse = self:GetReverse()
		timer.Simple(0.15, function()
			if not IsValid(self) then return end

			self:RemoveTrails()
			
			if enable then
				local color = reverse and LIB_APERTURE.FUNNEL_REVERSE_COLOR or LIB_APERTURE.FUNNEL_COLOR
				local material = reverse and "trails/beam_hotred_add_oriented.vmt" or "trails/beam_hotblue_add_oriented.vmt"
				
				self.TA_Trail1 = util.SpriteTrail(self, 1, color, false, trailWidth, trailWidthEnd, 1, 1 / (trailWidth + trailWidthEnd) * 0.5, material)
				self.TA_Trail2 = util.SpriteTrail(self, 3, color, false, trailWidth, trailWidthEnd, 1, 1 / (trailWidth + trailWidthEnd) * 0.5, material) 
				self.TA_Trail3 = util.SpriteTrail(self, 4, color, false, trailWidth, trailWidthEnd, 1, 1 / (trailWidth + trailWidthEnd) * 0.5, material) 
			end
		end)
	end

end --SERVER

function ENT:Enable(enable)
	if self:GetEnable() != enable then
		if enable then
			self:EmitSound("TA:TractorBeamStart")
			self:EmitSound("TA:TractorBeamLoop")
			if self:GetReverse() then
				self:PlaySequence("forward", 1.0)
			else
				self:PlaySequence("back", 1.0)
			end
		else
			self:CheckForLeave()
			self:EmitSound( "TA:TractorBeamEnd" )
			self:StopSound("TA:TractorBeamLoop")
			self:PlaySequence("idle", 1.0)
		end
		
		self:SetEnable(enable)
		self:SetupTrails()
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

function ENT:Reverse(reverse)
	if self:GetReverse() != reverse then
		if self:GetEnable() then
			if reverse then
				self:PlaySequence("forward", 1.0)
			else
				self:PlaySequence("back", 1.0)
			end
			
			self:EmitSound("TA:TractorBeamMiddle")
		end
		
		self:SetReverse(reverse)
		self:SetupTrails()
	end
end

function ENT:ReverseEX(reverse)
	if self:GetToggle() then
		if reverse then
			self:Reverse(not self:GetReverse())
		end
		return true
	end
	
	if self:GetStartReversed() then reverse = !reverse end
	self:Reverse(reverse)
end

function ENT:Initialize()

	self.BaseClass.Initialize(self)
	
	if SERVER then
		self:SetModel("models/aperture/tractor_beam.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		
		self.FunnelUpdate = {}
		self.EntitiesInFunnel = {}
		self.FunnelEnteredEntities = {}
		
		if self:GetStartEnabled() then self:Enable(true) end
		if self:GetStartReversed() then self:Reverse(true) end
		//self:SetReverse(true)

		if not WireAddon then return end
		self.Inputs = Wire_CreateInputs(self, {"Enable", "Reverse"})
	end

	if CLIENT then
		self.BaseRotation = 0
		self.FieldEffects = {}
	end
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Drawing()

	-- Skipping tick if it disabled
	if not self:GetEnable() then return end

	local reverse = self:GetReverse()
	local color = reverse and LIB_APERTURE.FUNNEL_REVERSE_COLOR or LIB_APERTURE.FUNNEL_COLOR
	local dir = reverse and -1 or 1
	local material = reverse and Material("effects/particle_ring_pulled_add_oriented_reverse") or Material("effects/particle_ring_pulled_add_oriented")

	//render.SuppressEngineLighting(true) 
	render.SetColorModulation(color.r / 255, color.g / 255, color.b / 255)
	render.OverrideDepthEnable(true, false)
	render.SetLightingMode(2)
	if self.FieldEffects then
		for k,v in pairs(self.FieldEffects) do v:DrawModel() end
	end
	//render.SuppressEngineLighting(false) 
	render.SetColorModulation(1, 1, 1)
	render.OverrideDepthEnable(false, false)
	render.SetLightingMode(0)

	-- Tractor beam particle effect
	if not timer.Exists("TA:TractorBeamEffect"..self:EntIndex()) then
		local effectdata = EffectData()
		effectdata:SetEntity(self)
		effectdata:SetMagnitude(2.5)
		effectdata:SetRadius(40)
		effectdata:SetColor(reverse and 1 or 0)
		util.Effect("tractor_beam_effect", effectdata)

		timer.Create("TA:TractorBeamEffect"..self:EntIndex(), 0.05, 1, function() end)
	end
	
	local quadRadius = 140
	render.OverrideDepthEnable(true, false)
	render.SetLightingMode(2)
	render.SetMaterial(material)
	for k,v in pairs(self.PassagesDat) do
		local direction = (v.endpos - v.startpos):GetNormalized()
		
			-- Beam begin effect
		if k > 1 then
			render.DrawQuadEasy(v.startpos + direction, direction, quadRadius, quadRadius, color, CurTime() * 10 * -dir)
			render.DrawQuadEasy(v.startpos + direction, direction, quadRadius, quadRadius, color, CurTime() * 10 * -dir + 120)
			render.DrawQuadEasy(v.startpos + direction, direction, quadRadius, quadRadius, color, CurTime() * 10 * -dir * 2)
		end
		
		-- Beam end effect
		render.DrawQuadEasy(v.endpos - direction, -direction, quadRadius, quadRadius, color, CurTime() * 10 * -dir)
		render.DrawQuadEasy(v.endpos - direction, -direction, quadRadius, quadRadius, color, CurTime() * 10 * -dir + 120)
		render.DrawQuadEasy(v.endpos - direction, -direction, quadRadius, quadRadius, color, CurTime() * 10 * -dir * 2)
	end
	render.OverrideDepthEnable(false, false)
	render.SetLightingMode(0)

end

if CLIENT then
	function ENT:Think()			

		--self.BaseClass.Think( self )
		local reverse = self:GetReverse()
		local color = reverse and LIB_APERTURE.FUNNEL_REVERSE_COLOR or LIB_APERTURE.FUNNEL_COLOR
		local dir = reverse and -1 or 1
		local angle = reverse and -90 or 90
		local offset = reverse and FUNNEL_EFFECT_MODEL_SIZE or 0
		
		local penetrateVal = 0
		local passagesPoints = LIB_APERTURE:GetAllPortalPassagesAng(self:GetPos(), self:LocalToWorldAngles(Angle(-90, 0, 0)), nil, self, true)
		
		local requireToSpawn = #passagesPoints
		for k,v in pairs(passagesPoints) do
			local distance = v.startpos:Distance(v.endpos)
			local offsetV = penetrateVal == 0 and 0 or FUNNEL_EFFECT_MODEL_SIZE - penetrateVal
			requireToSpawn = requireToSpawn + math.floor((distance + offsetV) / FUNNEL_EFFECT_MODEL_SIZE)
			penetrateVal = math.ceil(distance / FUNNEL_EFFECT_MODEL_SIZE) * FUNNEL_EFFECT_MODEL_SIZE - distance + penetrateVal
			if penetrateVal > FUNNEL_EFFECT_MODEL_SIZE then penetrateVal = penetrateVal - FUNNEL_EFFECT_MODEL_SIZE end
			if penetrateVal < 0 then penetrateVal = penetrateVal + FUNNEL_EFFECT_MODEL_SIZE end
		end
		
		if #self.FieldEffects != requireToSpawn or not self:GetEnable() then
			for k, v in pairs(self.FieldEffects) do v:Remove() end
			self.FieldEffects = { }
		end
		
		if self:GetEnable() then
			self.PassagesDat = passagesPoints
			
			penetrateVal = 0
			local itterator = 0
			for k,v in pairs(passagesPoints) do
				local direction = (v.endpos - v.startpos):GetNormalized()
				local _, angles = LocalToWorld(Vector(), Angle(angle, 0, 0), Vector(), v.angles)
				local distance = v.startpos:Distance(v.endpos)
				local offsetV = penetrateVal == 0 and 0 or FUNNEL_EFFECT_MODEL_SIZE - penetrateVal

				for i = 0,(distance + offsetV), FUNNEL_EFFECT_MODEL_SIZE do
					itterator = itterator + 1
					local pos = v.startpos + (i - offsetV + offset) * direction
					if table.Count(self.FieldEffects) != requireToSpawn then
						local c_Model = ClientsideModel("models/aperture/effects/tractor_beam_field_effect.mdl")
						c_Model:SetPos(pos)
						c_Model:SetAngles(angles)
						c_Model:SetNoDraw(true)
						c_Model:Spawn()
						table.insert(self.FieldEffects, c_Model)
						
						local scale = Vector(1, 1, 1 * 1.3)
						local mat = Matrix()
						mat:Scale(scale)
						c_Model:EnableMatrix("RenderMultiply", mat)
					else
						local c_Model = self.FieldEffects[itterator]
						c_Model:SetPos(pos)
						c_Model:SetAngles(angles)
					end
				end
				
				penetrateVal = math.ceil(distance / FUNNEL_EFFECT_MODEL_SIZE) * FUNNEL_EFFECT_MODEL_SIZE - distance + penetrateVal
				if penetrateVal > FUNNEL_EFFECT_MODEL_SIZE then penetrateVal = penetrateVal - FUNNEL_EFFECT_MODEL_SIZE end
				if penetrateVal < 0 then penetrateVal = penetrateVal + FUNNEL_EFFECT_MODEL_SIZE end

			end
			
			self.BaseRotation = self.BaseRotation + FrameTime() * dir * 150
			if self.BaseRotation > 360 then self.BaseRotation = self.BaseRotation - 360 end
			if self.BaseRotation < -360 then self.BaseRotation = self.BaseRotation + 360 end
			self:ManipulateBoneAngles(1, Angle(self.BaseRotation, 0, 0))
			self:ManipulateBoneAngles(10, Angle(self.BaseRotation, 0, 0))
			self:ManipulateBoneAngles(17, Angle(self.BaseRotation, 0, 0))
			self:ManipulateBoneAngles(9, Angle(self.BaseRotation, 0, 0)) 
			self:ManipulateBoneAngles(8, Angle(self.BaseRotation * 2, 0, 0)) -- center
		end

		if LocalPlayer():GetNWBool("Aperture_Funnel_Entered") then
			LocalPlayer():SetVelocity(-physenv.GetGravity())
		end
	end
	
	function ENT:OnRemove()
		for k, v in pairs(self.FieldEffects) do v:Remove() end
	end
	
	return true -- No more client side
end

-- Handling entering
function ENT:OnEnterFunnel(ent)
	if not IsValid(ent) then return end

	if ent:IsPlayer() then
		ent:EmitSound("TA:TractorBeamEnter")
		ent:SetNWBool("Aperture_Funnel_Entered", true)
		
	elseif IsValid(ent:GetPhysicsObject()) then
		local physObj = ent:GetPhysicsObject()
		physObj:EnableGravity(false)
	end
end

-- Handling exiting
function ENT:OnLeaveFunnel(ent)
	if not IsValid(ent) then return end
	
	if ent:IsPlayer() then
		ent:StopSound("TA:TractorBeamEnter")
		ent:SetNWBool("Aperture_Funnel_Entered", false)
	elseif IsValid(ent:GetPhysicsObject()) then
		local physObj = ent:GetPhysicsObject()
		physObj:EnableGravity(true)
	end
end

function ENT:HandleEntity(ent, beamStart, beamEnd, beamAng, beamDirection, isLast)
	if not IsValid(ent) then return end
	
	local reverse = self:GetReverse()
	local dir = reverse and -1 or 1

	-- Removing entity from table if it still in funnel
	if self.EntitiesInFunnel[ent:EntIndex()] then self.EntitiesInFunnel[ent:EntIndex()] = nil end
	
	local centerPos = IsValid(ent:GetPhysicsObject()) and ent:LocalToWorld(ent:GetPhysicsObject():GetMassCenter()) or ent:GetPos()
	local paintBarrerRollValue = CurTime() * 4 + ent:EntIndex() * 10
	local tractorBeamMovingSpeed = LIB_APERTURE.FUNNEL_MOVE_SPEED * dir
	if isLast then
		local distCenterToEnd = self:GetReverse() and centerPos:Distance(beamStart) or centerPos:Distance(beamEnd)
		local entRadius = ent:BoundingRadius()
		tractorBeamMovingSpeed = math.min(1, (distCenterToEnd - entRadius / 2) / FUNNEL_SMOOTHING_IN) * tractorBeamMovingSpeed
	end
	
	local localCenterPos = WorldToLocal(centerPos, Angle(), beamStart, beamAng)
	localCenterPos = Vector(0, localCenterPos.y, localCenterPos.z)
	localCenterPos:Rotate(beamAng)
	
	local offset = -localCenterPos * 2
	
	-- Handling entering into Funnel
	if not self.FunnelEnteredEntities[ent:EntIndex()] then
		self.FunnelEnteredEntities[ent:EntIndex()] = true
		
		self:OnEnterFunnel(ent)
	end
	
	if ent:IsPlayer() then
		-- Player moving while in the funnel
		local movingDir = Vector()
		
		if ent:KeyDown(IN_FORWARD) then movingDir = movingDir + Vector(1, 0, 0) end
		if ent:KeyDown(IN_BACK) then movingDir = movingDir - Vector(1, 0, 0) end
		if ent:KeyDown(IN_MOVELEFT) then movingDir = movingDir + Vector(0, 1, 0) end
		if ent:KeyDown(IN_MOVERIGHT) then movingDir = movingDir - Vector(0, 1, 0) end
		
		-- Slowdown player in the funnel when they moving
		if ent:KeyDown(IN_FORWARD)
			or ent:KeyDown(IN_BACK) 
			or ent:KeyDown(IN_MOVERIGHT) 
			or ent:KeyDown(IN_MOVELEFT) then
			tractorBeamMovingSpeed = 0
				
			-- Removing player forward/back funnel moving possibilities
			local ply_moving = movingDir * 100
			ply_moving:Rotate(ent:EyeAngles())
			local ply_moving_cutted_local = WorldToLocal(ply_moving, Angle(), Vector(), beamDirection:Angle())
			ply_moving_cutted_local = Vector(0, ply_moving_cutted_local.y, ply_moving_cutted_local.z)
			local ply_moving = LocalToWorld(ply_moving_cutted_local, Angle(), Vector(), beamDirection:Angle())
			offset = ply_moving
		end

		ent:SetVelocity(-physenv.GetGravity())
		ent:SetVelocity(beamDirection * tractorBeamMovingSpeed + offset - ent:GetVelocity())
		
	elseif ent:IsNPC() then
		ent:SetVelocity(beamDirection * tractorBeamMovingSpeed + offset - ent:GetVelocity())
		
	elseif IsValid(ent:GetPhysicsObject()) then
		local physObj = ent:GetPhysicsObject()
		physObj:SetVelocity(beamDirection * tractorBeamMovingSpeed + offset - ent:GetVelocity() / 10)
	end
end

function ENT:CheckForLeave()

	if not self.EntitiesInFunnel then return end
	
	-- Handling funnel exiting
	for k,v in pairs(self.EntitiesInFunnel) do
		self:OnLeaveFunnel(v)
		
		if IsValid(v) then
			self.FunnelEnteredEntities[v:EntIndex()] = false
		end
	end
end

function ENT:Think()

	self:NextThink(CurTime())
	local reverse = self:GetReverse()
	local color = reverse and LIB_APERTURE.FUNNEL_REVERSE_COLOR or LIB_APERTURE.FUNNEL_COLOR
	local angle = reverse and -90 or 90
	
	self.BaseClass.Think(self)
	
	-- Skip this tick if exursion funnel is disabled and removing effect if possible
	if not self:GetEnable() then
		return
	end
	
	local passagesPoints = LIB_APERTURE:GetAllPortalPassages(self:GetPos(), self:GetUp(), nil, self, true)
	local handleEntities = { }
	for k,v in pairs(passagesPoints) do
		util.TraceHull({
			start = v.startpos,
			endpos = v.endpos,
			ignoreworld = true,
			filter = function(ent)
			
				if ent != self and ent:GetClass() != "prop_portal" then
					if not ent:IsPlayer() and not ent:IsNPC() and IsValid(ent:GetPhysicsObject()) and not ent:GetPhysicsObject():IsMotionEnabled() then
					else
						local isLast = false
						if ent:GetClass() != "ent_paint_blob" then
							if self:GetReverse() then
								if k == 1 then isLast = true end
							else
								if k == #passagesPoints then isLast = true end
							end
						end
						self:HandleEntity(ent, v.startpos, v.endpos, v.angles, (v.endpos - v.startpos):GetNormalized(), isLast)
						table.insert(handleEntities, ent:EntIndex(), ent)
					end
				end
			end,
			mins = -Vector(1, 1, 1) * FUNNEL_WITDH,
			maxs = Vector(1, 1, 1) * FUNNEL_WITDH,
			mask = MASK_SHOT_HULL
		})
	end
	
	self:CheckForLeave()
	self.EntitiesInFunnel = handleEntities		
	
	local color = self:GetReverse() and LIB_APERTURE.FUNNEL_REVERSE_COLOR or LIB_APERTURE.FUNNEL_COLOR
	local angle = self:GetReverse() and -1 or 1
	local adding = self:GetReverse() and 320 or 0

	return true
end

function ENT:TriggerInput(iname, value)
	if not WireAddon then return end
	
	if iname == "Enable" then self:EnableEX(tobool(value)) end
	if iname == "Reverse" then self:ReverseEX(tobool(value)) end
end

numpad.Register("Tractorbeam_Enable", function(pl, ent, keydown)
	if not IsValid(ent) then return false end
	ent:EnableEX(keydown)
	return true
end)

numpad.Register("Tractorbeam_Reverse", function(pl, ent, keydown)
	if not IsValid(ent) then return false end

	ent:ReverseEX(keydown)
	return true
end)

function ENT:OnRemove()
	self:CheckForLeave()
	self:StopSound("TA:TractorBeamLoop")
end
