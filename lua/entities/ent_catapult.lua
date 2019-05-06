AddCSLuaFile()
DEFINE_BASECLASS("base_aperture_ent")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName = "Aerial Faith Plate"
ENT.IsAperture = true
ENT.IsConnectable = true

ENT.drawtrajectory = false
local CATAPULT_WIDTH = 50
local CATAPULT_LENGTH = 50

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end

function ENT:SetupDataTables()
	self:NetworkVar("Vector", 0, "LandPoint")
	self:NetworkVar("Float", 1, "LaunchHeight")
	self:NetworkVar("Bool", 2, "Enable")
	self:NetworkVar("Bool", 3, "StartEnabled")
	self:NetworkVar("Float", 4, "TimeOfFlight")
	self:NetworkVar("Vector", 5, "LaunchVector")
	self:NetworkVar("Bool", 6, "Toggle")
end

if SERVER then
	function FixMinMax(min, max)
		local smin = Vector(min)
		local smax = Vector(max)

		if min.x > max.x then
			min.x = smax.x
			max.x = smin.x
		end
		if min.y > max.y then
			min.y = smax.y
			max.y = smin.y
		end
		if min.z > max.z then
			min.z = smax.z
			max.z = smin.z
		end
	end

	function ENT:CreateTrigger()
		local ent = ents.Create("trigger_aperture_fizzler")
		if not IsValid(ent) then
			ent:Remove()
		end
		if self:GetModel() == "models/portal_custom/faithplate_slim.mdl" then
			local vec1 = self:LocalToWorld(Vector(CATAPULT_WIDTH / 2, CATAPULT_LENGTH, 5))
			local vec2 = self:LocalToWorld(-Vector(CATAPULT_WIDTH / 2, CATAPULT_LENGTH, 5))
			FixMinMax(vec1, vec2)
			ent:SetPos(self:GetPos())
			ent:SetParent(self)
			ent:SetBounds(vec1, vec2)
			ent:Spawn()
			self.CatapultTrigger = ent
		else
			local vec1 = self:LocalToWorld(Vector(CATAPULT_WIDTH, CATAPULT_LENGTH, 5))
			local vec2 = self:LocalToWorld(-Vector(CATAPULT_WIDTH, CATAPULT_LENGTH, 5))
			FixMinMax(vec1, vec2)
			ent:SetPos(self:GetPos())
			ent:SetParent(self)
			ent:SetBounds(vec1, vec2)
			ent:Spawn()
			self.CatapultTrigger = ent
		end
	end
end

function ENT:Enable(enable)
	if self:GetEnable() ~= enable then
		if enable then
			self:SetSkin(0)
		else
			self:SetSkin(1)
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

	if self:GetStartEnabled() then
		enable = not enable
	end
	self:Enable(enable)
end

function ENT:Initialize()
	self.BaseClass.Initialize(self)

	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)

		self:SetSkin(1)
		if self:GetStartEnabled() then
			self:Enable(true)
		end

		self:CreateTrigger()

		if not WireAddon then
			return
		end
		self.Inputs = Wire_CreateInputs(self, {"Enable"})
	end

	if CLIENT then
	end
end

function ENT:Think()
	self:NextThink(CurTime() + 0.1)

	if CLIENT then
		return
	end
	local triggerEnt = self.CatapultTrigger
	local vec1 = Vector(CATAPULT_WIDTH, CATAPULT_LENGTH, 30)
	local vec2 = -Vector(CATAPULT_WIDTH, CATAPULT_LENGTH, 0)
	vec1:Rotate(self:GetAngles())
	vec2:Rotate(self:GetAngles())
	FixMinMax(vec1, vec2)
	triggerEnt:SetPos(self:GetPos())
	triggerEnt:SetBounds(vec1, vec2)

	return true
end

function ENT:HandleEntity(ent)
	if not self:GetEnable() then
		return
	end
	if self:GetLandPoint() == Vector() then
		return
	end
	if self.LaunchCooldown then
		return
	end
	if ent == self then
		return
	end
	if ent.IsAperture then
		return
	end
	if not IsValid(ent:GetPhysicsObject()) then
		return
	end
	if ent:GetCollisionGroup() ~= COLLISION_GROUP_NONE and ent:GetCollisionGroup() ~= COLLISION_GROUP_PLAYER then
		return
	end

	-- launch init
	self:LaunchEntity(ent)

	-- achievement of flying turret
	if
		ent:GetClass() == "ent_portal_floor_turret" or ent:GetClass() == "ent_portal_defective_turret" or
			ent:GetClass() == "ent_portal_turret_different"
	 then
	-- APERTURESCIENCE:GiveAchievement( ent.Owner, 3 )
	end

	self.LaunchCooldown = true
	timer.Simple(
		1,
		function()
			self.LaunchCooldown = false
		end
	)
end

-- no more client side
if CLIENT then
	return
end

function ENT:CalculateTrajectory()
	local destination = self:GetLandPoint()
	local pos = self:GetPos()

	if self:GetModel() == "models/portal_custom/faithplate_slim.mdl" then
		pos = pos + Vector(48, -4, 0)
	end
	local direction = Angle()
	local height = self:GetLaunchHeight()
	local distXY = Vector(destination.x, destination.y):Distance(Vector(pos.x, pos.y))
	local difZ = destination.z - pos.z
	local gravity = -physenv.GetGravity().z
	local force = 100
	local dist = 0
	local angle = 0
	local time = 0

	local brk = 0
	local isReversed = false

	repeat
		brk = brk + 1
		if brk > 1000000 then
			return
		end
		local angOffset = (distXY - dist)
		angle = angle + angOffset / 5000

		local velX = math.cos((90 - angle) * math.pi / 180) * force
		local velZ = math.sin((90 - angle) * math.pi / 180) * force
		local maxZ = (velZ * velZ) / (2 * gravity)

		if height and height > 0 and math.abs(maxZ - height) > 20 then
			force = force + (height - maxZ)
		end

		if maxZ > difZ then
			time = velZ / gravity -- time to lift up
			time = time + math.sqrt((maxZ - difZ) * 2 / gravity)
			dist = velX * time
		else
			time = velZ * gravity -- time to lift up
			time = time + math.sqrt((maxZ + difZ) / 2 * gravity)
			dist = velX / time
		end

		-- if doesn't found add force
		if not (dist == dist) or dist == 0 or math.abs(angle) > 360 then
			if angle > 360 then
				angle = angle - 360
			elseif angle < -360 then
				angle = angle + 360
			end
			force = force + math.max(10, math.abs(angOffset / 100))
		end
	until math.abs(dist - distXY) < 1 and dist ~= 0 and time > 0

	if isReversed then
		direction = Angle(-angle, (destination - self:GetPos()):Angle().y, 0)
	else
		direction = Angle(-90 + angle, (destination - self:GetPos()):Angle().y, 0)
	end

	local velocity = direction:Forward() * force

	self:SetTimeOfFlight(time)
	self:SetLaunchVector(velocity)

	return force, time
end

function ENT:SetLandingPoint(point)
	self:SetLandPoint(point)
	self:CalculateTrajectory()
end

function ENT:LaunchEntity(entity)
	if not IsValid(entity) then
		return
	end

	local force = self.LaunchForce
	local time = self:GetTimeOfFlight()

	local velOffset = (self:GetPos() - entity:GetPos()) / time
	local velocity = self:GetLaunchVector() + velOffset

	if self:GetModel() == "models/portal_custom/faithplate_slim.mdl" then
		--print("Please disregaurd any recent error message just now about an animation sequence not playing or whatever; this is not a bug.")
		self:PlaySequence("launch_up", 1.0)
	else
		self:PlaySequence("straightup", 1.0)
	end
	sound.Play("TA:CatapultLaunch", self:LocalToWorld(Vector(0, 0, 100)), 75, 100, 1)

	if entity:IsPlayer() then
		entity:SetVelocity(velocity - entity:GetVelocity())
	elseif IsValid(entity:GetPhysicsObject()) then
		-- Making entity really heavy
		local entityPhys = entity:GetPhysicsObject()
		if not timer.Exists("TA:EntityMass" .. entity:EntIndex()) then
			entity.TA_LastMass = entityPhys:GetMass()
			entityPhys:SetMass(50000)
		end
		entity:GetPhysicsObject():SetVelocity(velocity)

		-- Reseting entity mass
		timer.Create(
			"TA:EntityMass" .. entity:EntIndex(),
			self:GetTimeOfFlight(),
			1,
			function()
				if IsValid(entity) and entity.TA_LastMass then
					entityPhys:SetMass(entity.TA_LastMass)
				end
			end
		)
	end
end

function ENT:TriggerInput(iname, value)
	if not WireAddon then
		return
	end

	if iname == "Enable" then
		self:Enable(tobool(value))
	end
end

numpad.Register(
	"PortalCatapult_Enable",
	function(pl, ent, keydown)
		if not IsValid(ent) then
			return false
		end
		ent:EnableEX(keydown)
		return true
	end
)
