AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_ent")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Portal Rocket Turret"

local TURRET_STATE_DISABLED			= 1
local TURRET_STATE_DEPLOY 			= 2
local TURRET_STATE_SEARCH			= 3
local TURRET_STATE_LOCKING			= 4
local TURRET_STATE_PREPARE_SHOOT	= 5
local TURRET_STATE_SHOOT			= 6
local TURRET_STATE_PREPARE_RETRACT	= 7
local TURRET_STATE_RETRACT 			= 8

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Enable")
	self:NetworkVar("Bool", 1, "Toggle")
	self:NetworkVar("Bool", 2, "StartEnabled")
	self:NetworkVar("Int", 3, "TurretState")
	self:NetworkVar("Entity", 4, "Target")
	self:NetworkVar("Angle", 5, "TurretAngles")
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

if SERVER then
	function ENT:ShootRocket(pos, ang)
		local rocket = ents.Create("portal_rocket_turret_missile")
		if not IsValid(rocket) then return end
		rocket:SetPos(pos)
		rocket:SetAngles(ang)
		rocket:Spawn()
		if IsValid(rocket:GetPhysicsObject()) then rocket:GetPhysicsObject():SetVelocity(ang:Forward() * 600) end
		self:EmitSound("TA:RTurretLaunch")
		rocket.RTurret = self
		rocket.OriginalTarget = self:GetTarget()
		self.TurretLaunchedRocket = rocket
		self:PlaySequence("fire", 1)
	end

	function ENT:RotateTurret(angle, speed)
		local turretAngles = self:GetTurretAngles()
		local pitch = turretAngles.pitch - math.AngleDifference(turretAngles.pitch, angle.pitch + 2) / speed
		local yaw = turretAngles.yaw - math.AngleDifference(turretAngles.yaw, angle.yaw - 90) / speed
		
		self:SetTurretAngles(Angle(pitch, yaw, 0))
	end

	function ENT:RotateTurretPoint(pos, speed)
		local center = self:LocalToWorld(Vector(0, 0, 20))
		local dirAng = (pos - center):Angle()
		local offset = Vector(0, 10, 0)
		offset:Rotate(dirAng + Angle(90, 0, 0))
		center = center + offset
		
		dirAng = (pos - center):Angle()
		local angle = self:WorldToLocalAngles(dirAng)
		self:RotateTurret(angle, speed)
	end
end

function ENT:Initialize()

	self.BaseClass.Initialize(self)
	
	if SERVER then
		self:SetModel("models/aperture/rocket_sentry.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)

		self:PlaySequence("inactive", 1)
		self:SetTurretState(TURRET_STATE_DISABLED)
		if self:GetStartEnabled() then self:Enable(true) end
		if not WireAddon then return end
		self.Inputs = Wire_CreateInputs(self, {"Enable"})
	end

	if CLIENT then
		
	end
end

function ENT:TransfortTurret()
	local angle = self:GetTurretAngles()
	local rootLR = self:LookupBone("Rot_LR")
	local rootUD = self:LookupBone("Rot_UD")
	local arm1Bone = self:LookupBone("Arm_1")
	local arm2Bone = self:LookupBone("Arm_2")
	local arm3Bone = self:LookupBone("Arm_3")
	local arm4Bone = self:LookupBone("Arm_4")
	
	local ang1 =  math.abs(math.sin(math.rad(angle.yaw / 2)))
	local ang2 =  math.max(0, math.cos(math.rad(angle.yaw + 180)))
	if rootLR then self:ManipulateBoneAngles(rootLR, Angle(angle.yaw, 0, 0)) end
	if rootUD then self:ManipulateBoneAngles(rootUD, Angle(0, -angle.pitch, 0)) end
	if arm1Bone then self:ManipulateBoneAngles(arm1Bone, Angle(0, ang1 * -90, 0)) end
	if arm2Bone then self:ManipulateBoneAngles(arm2Bone, Angle(0, ang1 * 90 - ang2 * 135, 0)) end
	if arm3Bone then self:ManipulateBoneAngles(arm3Bone, Angle(0, ang1 * 35 + ang2 * 135, 0)) end
	if arm4Bone then self:ManipulateBoneAngles(arm4Bone, Angle(0, ang1 * -35, 0)) end
end

function ENT:Think()
	if not LIB_APERTURE then return end
	self:NextThink(CurTime())

	if CLIENT then
		self:TransfortTurret()
		return true
	end
	
	local pos = self:LocalToWorld(Vector(0, 0, 30))
	local target, center = NULL, Vector()
	if self:GetEnable() then target, center = LIB_APERTURE:FindClosestAliveInSphereIncludingPortalPassages(pos, 2000) end
	if IsValid(target) then
	
		local _, trace = LIB_APERTURE:GetAllPortalPassages(pos, (center - pos), nil, self)
		if not IsValid(trace.Entity) or trace.Entity != target then target = nil end
	end

	-- SERVER side
	local turretState = self:GetTurretState()
	if self:GetEnable() then
		-- Deploying turret
		if turretState == TURRET_STATE_DISABLED then
			self:SetTurretState(TURRET_STATE_DEPLOY)
			self:EmitSound("npc/scanner/cbot_discharge1.wav")
			timer.Simple(3, function()
				if not IsValid(self) then return end
				self:EmitSound("npc/scanner/combat_scan1.wav")
			end)
			timer.Simple(self:PlaySequence("open", 1), function()
				if not IsValid(self) then return end
				self:SetTurretState(TURRET_STATE_SEARCH)
			end)
		end
	elseif turretState == TURRET_STATE_SEARCH or turretState == TURRET_STATE_LOCKING then
		-- Retracting turret
		self:SetTurretState(TURRET_STATE_PREPARE_RETRACT)
		timer.Simple(1.5, function()
			if not IsValid(self) then return end			
			self:SetTurretState(TURRET_STATE_RETRACT)
			self:EmitSound("npc/scanner/cbot_discharge1.wav")
			self:RotateTurret(Angle(-2, 90, 0), 1)
			timer.Simple(self:PlaySequence("close", 1), function()
				if not IsValid(self) then return end
				self:SetTurretState(TURRET_STATE_DISABLED)
			end)
		end)
	end
	
	if turretState == TURRET_STATE_PREPARE_RETRACT then
		self:RotateTurret(Angle(-2, 90, 0), 20)
		self.TurretLookingPoint = nil
	elseif turretState == TURRET_STATE_SEARCH then
		if IsValid(target) then
			self:SetTarget(target)
			self:SetTurretState(TURRET_STATE_LOCKING)
		end
		
		if not timer.Exists("TA:ChangeTurretLooking"..self:EntIndex()) then
			timer.Create("TA:ChangeTurretLooking"..self:EntIndex(), 5, 1, function() end)
			self.RandomLookingDir = Vector(math.Rand(-1, 1), math.Rand(-1, 1), math.Rand(-0.25, 1)):GetNormalized()
		end
		
		self.TurretLookingPoint = self:GetPos() + self.RandomLookingDir * 100
			
	elseif turretState == TURRET_STATE_LOCKING then
		if IsValid(target) then
			local ang = self:GetTurretAngles()
			ang = ang + Angle(-2, 90, 0)
			local wang = self:LocalToWorldAngles(ang)
			local _, traceBeam = LIB_APERTURE:GetAllPortalPassagesAng(pos, wang, 0, self)
			
			self.TurretLookingPoint = center
			
			if IsValid(traceBeam.Entity) and traceBeam.Entity == target and not timer.Exists("TA:RTurretCooldown"..self:EntIndex()) then
				self:EmitSound("TA:RTurretLock")
				self:SetSkin(1)
				self:SetTurretState(TURRET_STATE_PREPARE_SHOOT)
				timer.Simple(2, function()
					if not IsValid(self) then return end
					self:TransfortTurret()
					local laserBeamBone = self:LookupBone("Gun_casing")
					local bpos, bang = self:GetBonePosition(laserBeamBone)
					self:SetSkin(2)
					self:SetTurretState(TURRET_STATE_SHOOT)
					self:ShootRocket(bpos, bang)
				end)
			end
		else
			self:SetTurretState(TURRET_STATE_SEARCH)
		end
	elseif turretState == TURRET_STATE_SHOOT then
		if not IsValid(self.TurretLaunchedRocket) then
			self:SetTurretState(TURRET_STATE_SEARCH)
			self:SetSkin(0)
			self:PlaySequence("load", 1)
			timer.Create("TA:RTurretCooldown"..self:EntIndex(), 2, 1, function() end)
		end
	end
	
	if self.TurretLookingPoint then
		self:RotateTurretPoint(self.TurretLookingPoint, 50)
	end
	
	return true
end

function ENT:Drawing()
	if not LIB_APERTURE then return end
	if not self:GetEnable() then return end
	local turretState = self:GetTurretState()
	if turretState == TURRET_STATE_DEPLOY then return end
	if turretState == TURRET_STATE_RETRACT then return end
	if turretState == TURRET_STATE_PREPARE_RETRACT then return end
	if turretState == TURRET_STATE_DISABLED then return end
	local laserBeamBone = self:LookupBone("Gun_casing")
	local pos, ang = self:GetBonePosition(laserBeamBone)
	local points = LIB_APERTURE:GetAllPortalPassagesAng(pos, ang, 0, self)

	render.SetMaterial(Material("effects/bluelaser1"))
	for k,v in pairs(points) do
		local startpos = v.startpos
		local endpos = v.endpos
		local distance = startpos:Distance(endpos)
		render.DrawBeam(startpos, endpos, 2, distance / 100, 1, Color(255, 255, 255))
	end
end

-- no more client side
if CLIENT then return end
