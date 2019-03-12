AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_ent")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Base Aperture Turret"
ENT.IsAperture 		= true

ENT.TurretSoundFound 			= ""
ENT.TurretSoundSearch 			= ""
ENT.TurretSoundFizzle 			= ""
ENT.TurretSoundPickup 			= ""
ENT.TurretDrawLaserbeam			= true
ENT.TurretEyePos 				= Vector()
ENT.TurretDisabled 				= ""

local TURRET_STATE_IDLE 			= 1
local TURRET_STATE_PREPARE_DEPLOY 	= 2
local TURRET_STATE_DEPLOY 			= 3
local TURRET_STATE_SHOOT 			= 4
local TURRET_STATE_SEARCH 			= 5
local TURRET_STATE_PREPARE_RETRACT 	= 6
local TURRET_STATE_RETRACT 			= 7
local TURRET_STATE_PANIC 			= 8
local TURRET_STATE_PANIC_LIGHTER 	= 9
local TURRET_STATE_EXPLODE		 	= 10

local TURRET_TARGET_DEGRESE	= 60

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
	self:NetworkVar("Float", 6, "TurretOpen")
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
	function ENT:RotateTurret(angle, speed)
		local turretAngles = self:GetTurretAngles()
		local pitch = turretAngles.pitch - math.AngleDifference(turretAngles.pitch, angle.pitch) / speed
		local yaw = turretAngles.yaw - math.AngleDifference(turretAngles.yaw, angle.yaw) / speed
		
		pitch = math.max(-TURRET_TARGET_DEGRESE, math.min(TURRET_TARGET_DEGRESE, pitch))
		yaw = math.max(-TURRET_TARGET_DEGRESE, math.min(TURRET_TARGET_DEGRESE, yaw))
		
		self:SetTurretAngles(Angle(pitch, yaw, 0))
	end

	function ENT:RotateTurretPoint(pos, speed)
		local center = self:LocalToWorld(self:GetPhysicsObject():GetMassCenter())
		local dirAng = (pos - center):Angle()
		local angle = self:WorldToLocalAngles(dirAng)
		self:RotateTurret(angle, speed)
	end
end

function ENT:Initialize()
	self.BaseClass.BaseClass.Initialize(self)
	
	if SERVER then
		self:SetTurretState(TURRET_STATE_IDLE)
	end
	
	if CLIENT then
	
	end
end

function ENT:Drawing()
	if not LIB_APERTURE then return end
	if not self:GetEnable() then return end
	if not self.TurretDrawLaserbeam then return end
	if self:GetNWBool("TA:TurretDifferent") then return end
	
	local angles = self:GetTurretAngles()
	local wangles = self:LocalToWorldAngles(angles)
	local eyePos = self:LocalToWorld(self.TurretEyePos)
	
	local points = LIB_APERTURE:GetAllPortalPassagesAng(eyePos, wangles, 0, self)

	render.SetMaterial(Material("effects/redlaser1"))
	for k,v in pairs(points) do
		local startpos = v.startpos
		local endpos = v.endpos
		local distance = startpos:Distance(endpos)
		render.DrawBeam(startpos, endpos, 1, distance / 100, 1, Color(255, 255, 255))
	end
end

function ENT:Draw()
	self:DrawModel()
	
	if not self:GetEnable() then return end
end

function ENT:IsTurretKnockout()
	local angles = self:GetAngles()
	return (angles.pitch < -60 or angles.pitch > 60) or (angles.roll < -60 or angles.roll > 60)
end

if SERVER then
			
	function ENT:TurretShootBullets(startpos, dir)
		self:FireBullets({
			Attacker = self,
			Damage = 7,
			Force = 1,
			Dir = dir,
			Spread = Vector(math.Rand(-1, 1), math.Rand(-1, 1)) * 0.05,
			Src = startpos
		}, 
		false)
	end
	
	function ENT:TurretMuzzleEffect(startpos, dir)
		local effectdata = EffectData()
		effectdata:SetOrigin(startpos)
		effectdata:SetNormal(dir)
		util.Effect("turret_muzzle", effectdata)
	end
	
	function ENT:Shoot(angle)
		if timer.Exists("TA:TurretShooting"..self:EntIndex()) then return end
		if self.CantShoot then
			timer.Create("TA:TurretShooting"..self:EntIndex(), 2, 1, function() end)
			self:EmitSound("TA:TurretDryFire")
			return
		end
		
		timer.Create("TA:TurretShooting"..self:EntIndex(), 0.1, 1, function() end)
		local boneBase = self:LookupBone("Aim_LR")
		local pos = self:GetBonePosition(boneBase)
		local forward = angle:Forward()
		local right = angle:Right()
		local posR = pos + forward * 10 + right * 10
		local posL = pos + forward * 10 - right * 10
		self:TurretMuzzleEffect(posR, forward)
		self:TurretMuzzleEffect(posL, forward)
		self:EmitSound("TA:TurretShoot")
		self:TurretShootBullets(posR, forward)
		self:TurretShootBullets(posL, forward)
	end
	
	function ENT:CheckFoShoot()
		local target = self:GetTarget()
		local eyePos = self:LocalToWorld(self.TurretEyePos)
		local angles = self:GetTurretAngles()
		local wangles = self:LocalToWorldAngles(angles)
		local dir = wangles:Forward()
		self:Shoot(wangles)
	end
end

function ENT:Think()
	if not LIB_APERTURE then return end
	self:NextThink(CurTime())

	if CLIENT then
		local turretsBone = self:LookupBone("Aim_LR")
		local turretAntenna = self:LookupBone("cables_antenna_bone")
		local turretLeftBone = self:LookupBone("LFT_Wing")
		local turretRightBone = self:LookupBone("RT_Wing")
		local turretRGun1 = self:LookupBone("RT_Gun1")
		local turretRGun2 = self:LookupBone("RT_Gun2")
		local turretLGun1 = self:LookupBone("LFT_Gun1")
		local turretLGun2 = self:LookupBone("LFT_Gun2")
		local turretOpen = self:GetTurretOpen()
		
		local angle = self:GetTurretAngles()
		angle = Angle(angle.yaw, 0, angle.pitch)
		if turretsBone then self:ManipulateBoneAngles(turretsBone, angle) end
		-- wings
		if turretLeftBone then self:ManipulateBonePosition(turretLeftBone, Vector(-turretOpen, 0, 0) * 8) end
		if turretRightBone then self:ManipulateBonePosition(turretRightBone, Vector(turretOpen, 0, 0) * 8) end
		-- antenna
		if turretAntenna then self:ManipulateBonePosition(turretAntenna, Vector(0, turretOpen, 0) * 15) end
		-- guns
		if turretRGun1 then self:ManipulateBonePosition(turretRGun1, Vector(0, 0, turretOpen) * 4) end
		if turretRGun2 then self:ManipulateBonePosition(turretRGun2, Vector(0, 0, turretOpen) * 4) end
		if turretLGun1 then self:ManipulateBonePosition(turretLGun1, Vector(0, 0, turretOpen) * 4) end
		if turretLGun2 then self:ManipulateBonePosition(turretLGun2, Vector(0, 0, turretOpen) * 4) end
		
		return true
	end

	-- SERVER side
	local turretState = self:GetTurretState()
	local eyePos = self:LocalToWorld(self.TurretEyePos)
	local target, center
	if self:GetEnable() then target, center = LIB_APERTURE:FindClosestAliveInConeIncludingPortalPassages(eyePos, self:GetForward(), 2000, TURRET_TARGET_DEGRESE) end
	if IsValid(target) then
		local _, trace = LIB_APERTURE:GetAllPortalPassages(eyePos, (center - eyePos), nil, self)
		if not IsValid(trace.Entity) or trace.Entity != target then target = nil end
		if self.TurretDifferent then target = nil end
	end
	
	if (not self:GetEnable() and not self:IsTurretKnockout() or self.TurretDifferent) and turretState == TURRET_STATE_SEARCH then
		-- Retracting turret
		self:SetTurretState(TURRET_STATE_PREPARE_RETRACT)
	end
	
	if IsValid(target) then
		-- Deploy turret
		if turretState == TURRET_STATE_IDLE then
			self:SetTurretState(TURRET_STATE_PREPARE_DEPLOY)
			self:SetTarget(target)
			timer.Remove("TA:TurretAutoSearch"..self:EntIndex())
		end
	end
	
	if self:GetEnable() then
		-- if player Hold turret
		if self:IsPlayerHolding() then
			if turretState != TURRET_STATE_PANIC_LIGHTER and turretState != TURRET_STATE_SHOOT then
				self:SetTurretState(TURRET_STATE_PANIC_LIGHTER)
				if self.TurretSoundPickup then self:EmitSound(self.TurretSoundPickup) end
				timer.Remove("TA:StopSearching"..self:EntIndex())
				timer.Remove("TA:KnockoutTime"..self:EntIndex())
				timer.Remove("TA:PrepareDeploy"..self:EntIndex())
				timer.Remove("TA:TurretReleaseTarget"..self:EntIndex())
				timer.Remove("TA:TurretActivatePing"..self:EntIndex())
			end
		elseif turretState == TURRET_STATE_PANIC_LIGHTER then
			self:SetTurretState(TURRET_STATE_SEARCH)
		end
		
		if self:IsTurretKnockout() then
			if turretState != TURRET_STATE_PANIC then
				self:SetTurretState(TURRET_STATE_PANIC)
				timer.Create("TA:KnockoutTime"..self:EntIndex(), 3, 1, function()
					if self.TurretDisabled then self:EmitSound(self.TurretDisabled) end
					if not IsValid(self) then return end
					self:SetTurretState(TURRET_STATE_PREPARE_RETRACT)
					self:Enable(false)
					self:EmitSound("TA:TurretDie")
				end)
				
				timer.Remove("TA:StopSearching"..self:EntIndex())
				timer.Remove("TA:PrepareDeploy"..self:EntIndex())
				timer.Remove("TA:TurretReleaseTarget"..self:EntIndex())
				timer.Remove("TA:TurretActivatePing"..self:EntIndex())
			end
		elseif turretState == TURRET_STATE_PANIC then
			self:SetTurretState(TURRET_STATE_SEARCH)
			timer.Remove("TA:KnockoutTime"..self:EntIndex())
		end
	end
	
	if turretState == TURRET_STATE_PREPARE_DEPLOY then
		if not timer.Exists("TA:PrepareDeploy"..self:EntIndex()) then
			timer.Create("TA:PrepareDeploy"..self:EntIndex(), 1, 1, function()
				if not IsValid(self) then return end
				self:EmitSound("TA:TurretDeploy")
				if self.TurretSoundFound != "" then self:EmitSound(self.TurretSoundFound) end
				
				self:SetTurretState(TURRET_STATE_DEPLOY)
				timer.Simple(1, function()
					if not IsValid(self) then return end
					self:SetTurretState(TURRET_STATE_SHOOT)
				end)
			end)
		end
	elseif turretState == TURRET_STATE_PREPARE_RETRACT then
		self:RotateTurret(Angle(), 20)
		if not timer.Exists("TA:PrepareRetract"..self:EntIndex()) then
			timer.Create("TA:PrepareRetract"..self:EntIndex(), 1.5, 1, function()
				if not IsValid(self) then return end
				
				self:EmitSound("TA:TurretRetract")
				if self.TurretRetract != "" then self:EmitSound(self.TurretRetract) end
				
				self:SetTurretState(TURRET_STATE_RETRACT)
				timer.Simple(1, function()
					if not IsValid(self) then return end
					self:SetTurretState(TURRET_STATE_IDLE)
					timer.Remove("TA:StopSearching"..self:EntIndex())
					timer.Create("TA:TurretAutoSearch"..self:EntIndex(), 3, 1, function()
						if not IsValid(self) then return end
						if self.TurretSoundAutoSearch != "" then self:EmitSound(self.TurretSoundAutoSearch) end
					end)
				end)
			end)
		end
	elseif turretState == TURRET_STATE_SEARCH then
		local specCurTime = CurTime() * 2 + self:EntIndex() * 5
		local pitch = math.cos(specCurTime * 1.5 + self:EntIndex() * 10) * 30
		local yaw = math.sin(specCurTime) * 40
		self:RotateTurret(Angle(pitch, yaw, 0), 10)
		-- Turret ping sound
		if not timer.Exists("TA:TurretPing"..self:EntIndex()) then
			self:EmitSound("TA:TurretPing")
			timer.Create("TA:TurretPing"..self:EntIndex(), 1, 1, function() end)
		end
		
		if IsValid(target) then
			if not timer.Exists("TA:StartShoot"..self:EntIndex()) then
				timer.Create("TA:StartShoot"..self:EntIndex(), 0.5, 1, function()
					if not IsValid(self) then return end
					self:SetTarget(target)
					self:SetTurretState(TURRET_STATE_SHOOT)
				end)
			end
			timer.Remove("TA:StopSearching"..self:EntIndex())
			
		elseif not timer.Exists("TA:StopSearching"..self:EntIndex()) then
			timer.Create("TA:StopSearching"..self:EntIndex(), 5, 1, function()
				if not IsValid(self) then return end
				self:SetTurretState(TURRET_STATE_PREPARE_RETRACT)
			end)
		end
	elseif turretState == TURRET_STATE_SHOOT then
		if IsValid(target) then
			-- local center = IsValid(target:GetPhysicsObject()) and target:LocalToWorld(target:GetPhysicsObject():GetMassCenter()) or target:GetPos()
			if not self.LockingSound then
				self.LockingSound = true
				self:EmitSound("TA:TurretActivate")
			end
			self:SetTarget(target)
			self:RotateTurretPoint(center, 5)
			
			timer.Remove("TA:TurretReleaseTarget"..self:EntIndex())
			self:CheckFoShoot()
		else
			target = self:GetTarget()
			if not timer.Exists("TA:TurretReleaseTarget"..self:EntIndex()) then
				timer.Create("TA:TurretReleaseTarget"..self:EntIndex(), 0.25, 1, function()
					if not IsValid(self) then return end
					
					if self.TurretSoundSearch != "" then self:EmitSound(self.TurretSoundSearch) end
					self.LockingSound = false
					self:SetTurretState(TURRET_STATE_SEARCH)
					self:SetTarget(NULL)
				end)
			end
		end
	elseif turretState == TURRET_STATE_PANIC then
		local specCurTime = CurTime() * 10 + self:EntIndex() * 5
		local pitch = math.cos(specCurTime * 1.5 + self:EntIndex() * 10) * 30
		local yaw = math.sin(specCurTime) * 40
		local turretOpen = self:GetTurretOpen()
		self:RotateTurret(Angle(pitch, yaw, 0), 10)
		self:CheckFoShoot()
		if turretOpen < 1 then self:SetTurretOpen(turretOpen + 2 * FrameTime()) else self:SetTurretOpen(1) end
		
	elseif turretState == TURRET_STATE_PANIC_LIGHTER then
		local specCurTime = CurTime() * 2 + self:EntIndex() * 5
		local pitch = math.cos(specCurTime * 1.5 + self:EntIndex() * 10) * 30
		local yaw = math.sin(specCurTime) * 40
		local turretOpen = self:GetTurretOpen()
		self:RotateTurret(Angle(pitch, yaw, 0), 10)
		if turretOpen < 1 then self:SetTurretOpen(turretOpen + 2 * FrameTime()) else self:SetTurretOpen(1) end
		if not timer.Exists("TA:TurretActivatePing"..self:EntIndex()) then
			if math.random(1, 2) == 1 then self:EmitSound("TA:TurretActivate") else self:EmitSound("TA:TurretPing") end
			timer.Create("TA:TurretActivatePing"..self:EntIndex(), 1 + math.Rand(0, 1), 1, function() end)
		end
		if IsValid(target) then
			if not timer.Exists("TA:StartShoot"..self:EntIndex()) then
				timer.Create("TA:StartShoot"..self:EntIndex(), 0.5, 1, function()
					if not IsValid(self) then return end
					self:SetTarget(target)
					self:SetTurretState(TURRET_STATE_SHOOT)
				end)
			end
		end
		
	elseif turretState == TURRET_STATE_DEPLOY then
		local turretOpen = self:GetTurretOpen()
		if turretOpen < 1 then self:SetTurretOpen(turretOpen + 2 * FrameTime()) else self:SetTurretOpen(1) end
	elseif turretState == TURRET_STATE_RETRACT then
		local turretOpen = self:GetTurretOpen()
		if turretOpen > 0 then self:SetTurretOpen(turretOpen - 2 * FrameTime()) else self:SetTurretOpen(0) end
	end
	
	if self:IsOnFire() and turretState != TURRET_STATE_EXPLODE then
		self:SetTurretState(TURRET_STATE_EXPLODE)
		if self.TurretDisabled then self:EmitSound(self.TurretDisabled) end
		timer.Simple(3, function()
			if not IsValid(self) then return end
			local effectdata = EffectData()
			effectdata:SetOrigin(self:GetPos())
			effectdata:SetNormal(Vector(0, 0, 1))
			util.Effect("Explosion", effectdata)

			util.BlastDamage(self, self, self:GetPos(), 150, 100) 
			self:Remove()
		end)
	end
	
	return true
end

function ENT:OnFizzle()
	if self.TurretSoundFizzle != "" then self:EmitSound(self.TurretSoundFizzle) end
	self:Enable(false)
end

function ENT:OnRemove()
	if CLIENT then

	end
end

if CLIENT then return end -- no more client side

function ENT:TriggerInput(iname, value)
	if not WireAddon then return end

	if iname == "Enable" then self:Enable(tobool(value)) end
end

numpad.Register("PortalTurretFloor_Enable", function(pl, ent, keydown)
	if not IsValid(ent) then return false end
	ent:EnableEX(keydown)
	return true
end)
