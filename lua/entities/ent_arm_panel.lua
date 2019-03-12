AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_ent")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Arm Panel"
ENT.IsAperture 		= true
ENT.IsConnectable 	= true

ENT.ArmPanelSpeed	= 1
ENT.DofLength1		= 38
ENT.DofLength2Min	= 47
ENT.DofLength2Max	= 90

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Enable")
	self:NetworkVar("Bool", 1, "Toggle")
	self:NetworkVar("Bool", 2, "StartEnabled")
	self:NetworkVar("Vector", 3, "ArmPos")
	self:NetworkVar("Angle", 4, "ArmAng")
	self:NetworkVar("Vector", 5, "ArmPosition")
	self:NetworkVar("Angle", 6, "ArmAngle")
end

function ENT:Enable(enable)
	if self:GetEnable() != enable then
		if enable then
			self:MovePanel(self:GetArmPosition(), self:GetArmAngle())
		else
			self:MovePanel(Vector(), Angle())
		end
		
		self:SetEnable(enable)
	end
end

function ENT:GetAngleBy3Lendth(length1, length2, length3)
	if length3 > (length1 + length2) then return 180 end
	if length3 < math.abs(length1 - length2) then return 0 end
	return math.deg(math.acos((length1 * length1 + length2 * length2 - length3 * length3) / (2 * length1 * length2)))
end

if CLIENT then
	function ENT:TransformModel()
		local panel = self:GetNWEntity("TA:PhysPannel")
		if not IsValid(panel) then return end
		local rootBone = self:LookupBone("arm64x64_export_03Z")
		local dof1Bone = self:LookupBone("arm64x64_export_03X")
		local dof2Bone = self:LookupBone("arm64x64_export_06")
		local dofMidBone = self:LookupBone("arm64x64_export_05")
		local piston1Bone = self:LookupBone("arm64x64_export_08")
		local piston2Bone = self:LookupBone("arm64x64_export_09")
		local plateBone = self:LookupBone("arm64x64_export_010")
		local root = self:GetBonePosition(rootBone)
		
		local lroot = self:WorldToLocal(root)
		local lpos, lang = self:WorldToLocal(panel:LocalToWorld(Vector(-25	, 0, -13))), self:WorldToLocalAngles(panel:GetAngles())
		local d1 = lroot:Distance(lpos)
		local angle = (Vector(lpos.x, 0, lpos.z) - Vector(lroot.x, 0, lroot.z)):Angle()
		
		panel:SetNoDraw(true)
		
		if angle.yaw == 180 then
			angle = Angle(-angle.pitch + 180, 0, 0)
		end
		local dof2 = self.DofLength2Min
		if (d1 - self.DofLength1) > self.DofLength2Min then
			dof2 = math.min((d1 - self.DofLength1) + 0.01, self.DofLength2Max)
		end
		local ang1 = self:GetAngleBy3Lendth(self.DofLength1, dof2, d1)
		local ang2 = self:GetAngleBy3Lendth(d1, self.DofLength1, dof2)
		local pistonLength = (dof2 - self.DofLength2Min)
		
		self:ManipulateBonePosition(piston1Bone, Vector(pistonLength / 2, 0, 0))
		self:ManipulateBonePosition(piston2Bone, Vector(pistonLength / 2, 0, 0))
		local a1 = angle.pitch + ang2
		local a2 = 90 - (180 - ang1)
		local a3 = -a2 - a1 + lang.pitch
		self:ManipulateBoneAngles(dof1Bone, Angle(0, 0, -44 + a1))
		self:ManipulateBoneAngles(dof2Bone, Angle(0, 8 + a2, 0))
		self:ManipulateBoneAngles(dofMidBone, Angle(0, -90, 0))
		self:ManipulateBoneAngles(plateBone, Angle(0, 0, -54 + a3))
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

function ENT:CleatePlate()
	local ent = ents.Create("prop_physics")
	if not IsValid(ent) then return end
	ent:SetModel("models/aperture/arm_panel_plate.mdl")
	ent:SetPos(self:LocalToWorld(Vector(0, 0, 0)))
	ent:SetAngles(self:LocalToWorldAngles(Angle(0, 0, 0)))
	ent:SetMoveType(MOVETYPE_NONE)
	ent:SetCollisionGroup(COLLISION_GROUP_INTERACTIVE_DEBRIS)
	ent:Spawn()
	self:DeleteOnRemove(ent)
	ent:DeleteOnRemove(self)
	self:SetNWEntity("TA:PhysPannel", ent)
	self:GetPhysicsObject():EnableMotion(false)
end

function ENT:Initialize()

	self.BaseClass.Initialize(self)
	
	if SERVER then
		self:SetModel("models/aperture/arm_panel_interior.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetSkin(0)
		if self:GetStartEnabled() then self:Enable(true) end

		self:CleatePlate()
		self.LocalArmPosSmooth = Vector()
		self.LocalArmAngSmooth = Angle()
		
		if not WireAddon then return end
		self.Inputs = Wire_CreateInputs(self, {"Enable", "Arm Position [VECTOR]", "Arm Angle [ANGLE]"})
	end

	if CLIENT then
		
	end
end

function ENT:MovePanel(pos, ang)
	pos.y = 0
	if pos == self:GetArmPos() and ang == self:GetArmAng() then return end
	self:SetArmPos(pos)
	self:SetArmAng(ang)

	if not timer.Exists("TA:Timer_ArmPanel"..self:EntIndex()) then
		if pos == Vector() and ang == Angle() then
			self:EmitSound("TA:ArmPanelClose")
		else
			self:EmitSound("TA:ArmPanelOpen")
		end
	end
	
	timer.Create("TA:Timer_ArmPanel"..self:EntIndex(), 1, 1, function() end)
end

function ENT:Think()
	self:NextThink(CurTime())
	if CLIENT then
		self:TransformModel()
	end
	
	if SERVER then
		local panel = self:GetNWEntity("TA:PhysPannel")
		if not IsValid(panel) then return end
		
		local lDestArmPos = self:GetArmPos()
		local lDestArmAng = self:GetArmAng()
		
		-- smooth pos
		local dir = (lDestArmPos - self.LocalArmPosSmooth)
		local length = math.min(self.ArmPanelSpeed, dir:Length())
		dir:Normalize()
		self.LocalArmPosSmooth = self.LocalArmPosSmooth + dir * length
		local armPos = self:LocalToWorld(self.LocalArmPosSmooth)
		-- smooth ang
		local angleVel = self.LocalArmAngSmooth
		angleVel.p = math.ApproachAngle(angleVel.p, lDestArmAng.p, FrameTime() * 60 * self.ArmPanelSpeed)
		angleVel.y = math.ApproachAngle(angleVel.y, lDestArmAng.y, FrameTime() * 60 * self.ArmPanelSpeed)
		angleVel.r = math.ApproachAngle(angleVel.r, lDestArmAng.r, FrameTime() * 60 * self.ArmPanelSpeed)
		local armAng = self:LocalToWorldAngles(Angle(angleVel.p, angleVel.y, angleVel.r))
		local angOff = panel:WorldToLocalAngles(armAng)
		local physObj = panel:GetPhysicsObject()
		if not IsValid(physObj) then return end
		physObj:SetVelocity((armPos - panel:GetPos()) * 10)
		physObj:AddAngleVelocity(Vector(angOff.r, angOff.p, angOff.y) * 100 - physObj:GetAngleVelocity())
	end
	
	return true
end

-- no more client side
if CLIENT then return end

function ENT:TriggerInput(iname, value)
	if not WireAddon then return end
	if iname == "Enable" then self:ToggleEnable(tobool(value)) end
	if iname == "Arm Position" then self:MovePanel(Vector(value[1], value[2], value[3]), self:GetArmAng()) end
	if iname == "Arm Angle" then self:MovePanel(self:GetArmPos(), Angle(value[1], value[2], value[3])) end
end

numpad.Register("PortalArmPanel_Enable", function(pl, ent, keydown)
	if not IsValid(ent) then return false end
	ent:EnableEX(keydown)
	return true
end)