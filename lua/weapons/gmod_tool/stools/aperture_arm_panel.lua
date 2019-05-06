TOOL.Tab = "Aperture"
TOOL.Category = "Puzzle elements"
TOOL.Name = "#tool.aperture_arm_panel.name"

TOOL.ClientConVar["keyenable"] = "45"
TOOL.ClientConVar["startenabled"] = "0"
TOOL.ClientConVar["toggle"] = "0"
TOOL.ClientConVar["localx"] = "0"
TOOL.ClientConVar["localz"] = "0"
TOOL.ClientConVar["lpitch"] = "0"
TOOL.ClientConVar["countx"] = "1"
TOOL.ClientConVar["county"] = "1"

local ARM_PANEL_GRID = 64
local ARM_PANEL_MODEL = "models/aperture/arm_panel_interior.mdl"

local DofLength1 = 38
local DofLength2Min = 47
local DofLength2Max = 90
local AnimTime = 2

if CLIENT then
	language.Add("tool.aperture_arm_panel.name", "Panel Arm")
	language.Add(
		"tool.aperture_arm_panel.desc",
		"Fully configurable. Infinitely variable. Aperture brand panels will assist your test subjects every step of the way."
	)
	language.Add("tool.aperture_arm_panel.0", "Left click to place")
	language.Add("tool.aperture_arm_panel.enable", "Enable")
	language.Add("tool.aperture_arm_panel.startenabled", "Enabled")
	language.Add("tool.aperture_arm_panel.startenabled.help", "Arm Panel will be deployed when placed")
	language.Add("tool.aperture_arm_panel.localx", "Forward Offset")
	language.Add("tool.aperture_arm_panel.localz", "Up Offset")
	language.Add("tool.aperture_arm_panel.countx", "Copies to the back")
	language.Add("tool.aperture_arm_panel.county", "Copies to the right")
	language.Add("tool.aperture_arm_panel.lpitch", "Rotate Pitch")
	language.Add("tool.aperture_arm_panel.toggle", "Toggle")
end

local function IsArmPanelsNearby(pos)
	local entities = ents.FindInSphere(pos, 60)
	for k, v in pairs(entities) do
		if v:GetClass() == "ent_arm_panel" then
			return v
		end
	end
end

local function GetSpawnPos(pos, ang, ply, normal)
	local armPanel = IsArmPanelsNearby(pos)
	if not IsValid(armPanel) then
		local angle = ang
		if math.abs(normal.z) == 1 then
			_,
				angle = WorldToLocal(Vector(), (pos - ply:GetPos()):Angle(), Vector(), ang)
			angle = Angle(0, angle.y + 180, 0)
			_,
				angle = LocalToWorld(Vector(), angle, Vector(), ang)
		end
		ang:Set(angle)
		return
	end
	local armPos = armPanel:GetPos()
	local armAng = armPanel:GetAngles()
	local gridArmPos = LIB_MATH_TA:SnapToGridOnSurface(armPos, armAng, ARM_PANEL_GRID)
	local posOffset = armPanel:WorldToLocal(gridArmPos)
	local gridPos = LIB_MATH_TA:SnapToGridOnSurface(pos, armAng, ARM_PANEL_GRID)
	gridPos = LocalToWorld(-posOffset, Angle(), gridPos, armAng)
	pos:Set(gridPos)
	ang:Set(armAng)

	if armPos == gridPos then
		return 1
	end
	return 0
end

local function MakeArmPanel(ply, pos, ang, localx, localz, lpitch, key_enable, startenabled, toggle, data)
	local ent = ents.Create("ent_arm_panel")
	if not IsValid(ent) then
		return
	end

	duplicator.DoGeneric(ent, data)

	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:SetMoveType(MOVETYPE_NONE)
	ent:SetPlayer(ply)
	ent:SetArmPosition(Vector(localx, 0, localz))
	ent:SetArmAngle(Angle(lpitch, 0, 0))
	ent:SetStartEnabled(tobool(startenabled))
	ent:SetToggle(tobool(toggle))
	ent:Spawn()

	-- initializing numpad inputs
	ent.NumDown = numpad.OnDown(ply, key_enable, "PortalArmPanel_Enable", ent, true)
	ent.NumUp = numpad.OnUp(ply, key_enable, "PortalArmPanel_Enable", ent, false)

	-- saving data
	local ttable = {
		key_enable = key_enable,
		ply = ply,
		startenabled = startenabled,
		localx = localx,
		localz = localz,
		lpitch = lpitch,
		toggle = toggle,
		data = data
	}

	table.Merge(ent:GetTable(), ttable)

	if IsValid(ply) then
		ply:AddCleanup("Arm Panel", ent)
	end

	return ent
end

if SERVER then
	duplicator.RegisterEntityClass(
		"ent_arm_panel",
		MakeArmPanel,
		"pos",
		"ang",
		"localx",
		"localz",
		"lpitch",
		"key_enable",
		"startenabled",
		"toggle",
		"data"
	)
end

function TOOL:LeftClick(trace)
	-- Ignore if place target is Alive
	--if ( trace.Entity and ( trace.Entity:IsPlayer() or trace.Entity:IsNPC() or APERTURESCIENCE:GASLStuff( trace.Entity ) ) ) then return false end

	if CLIENT then
		return true
	end

	-- if not APERTURESCIENCE.ALLOWING.paint and not self:GetOwner():IsSuperAdmin() then self:GetOwner():PrintMessageHUD_PRINTTALK, "This tool is disabled" return end

	local ply = self:GetOwner()
	local localx = self:GetClientNumber("localx")
	local localz = self:GetClientNumber("localz")
	local lpitch = self:GetClientNumber("lpitch")
	local countx = self:GetClientNumber("countx")
	local county = self:GetClientNumber("county")
	local key_enable = self:GetClientNumber("keyenable")
	local startenabled = self:GetClientNumber("startenabled")
	local toggle = self:GetClientNumber("toggle")
	local pos = trace.HitPos + trace.HitNormal * 75
	local ang = trace.HitNormal:Angle() + Angle(90, 0, 0)
	local result = GetSpawnPos(pos, ang, ply, trace.HitNormal)
	if result == 1 then
		return true
	end
	local armPanelTable = {}

	for x = 0, countx - 1 do
		for y = 0, county - 1 do
			local offset = Vector(x, y, 0) * ARM_PANEL_GRID
			offset:Rotate(ang)
			local pos = pos + offset
			local ent = MakeArmPanel(ply, pos, ang, localx, localz, lpitch, key_enable, startenabled, toggle)
			table.insert(armPanelTable, ent)
		end
	end

	undo.Create("Arm Panel")
	for k, v in pairs(armPanelTable) do
		undo.AddEntity(v)
	end
	undo.SetPlayer(ply)
	undo.Finish()

	return true, ent
end

if CLIENT then
	function TOOL:MakeGhostEntityInx(inx, subinx)
		if not self.TA_GhostEntityArray then
			self.TA_GhostEntityArray = {}
		end
		local subinx = subinx and subinx or 0
		local inxName = inx .. "_" .. subinx
		local ent = self.TA_GhostEntityArray[inxName]
		if IsValid(ent) then
			return
		end
		local ent = ClientsideModel(ARM_PANEL_MODEL)
		if not IsValid(ent) then
			return
		end
		ent:SetRenderMode(RENDERMODE_TRANSALPHA)

		self.TA_GhostEntityArray[inxName] = ent
	end

	function TOOL:RemoveGhostEntitityInx(inx, subinx)
		if not self.TA_GhostEntityArray then
			return
		end
		local subinx = subinx and subinx or 0
		local inxName = inx .. "_" .. subinx
		local ent = self.TA_GhostEntityArray[inxName]
		if not IsValid(ent) then
			return
		end
		ent:Remove()
	end

	function TOOL:GetGhostEntityInx(inx, subinx)
		if not self.TA_GhostEntityArray then
			return
		end
		local subinx = subinx and subinx or 0
		local inxName = inx .. "_" .. subinx

		return self.TA_GhostEntityArray[inxName]
	end

	function TOOL:RemoveGhostEntityRange(minInx, maxInx, subinx)
		for i = minInx, maxInx do
			self:RemoveGhostEntitityInx(i, subinx)
		end
	end

	function TOOL:ClearGhostEntities()
		if not self.TA_GhostEntityArray then
			return
		end
		for k, v in pairs(self.TA_GhostEntityArray) do
			v:Remove()
			self.TA_GhostEntityArray[k] = nil
		end
	end
end

local function GetAngleBy3Lendth(length1, length2, length3)
	if length3 > (length1 + length2) then
		return 180
	end
	if length3 < math.abs(length1 - length2) then
		return 0
	end
	return math.deg(math.acos((length1 * length1 + length2 * length2 - length3 * length3) / (2 * length1 * length2)))
end

function TOOL:TransformGhostArmPanel(ent)
	if not IsValid(ent) then
		return
	end
	local mult = math.min(1, (CurTime() - math.floor(CurTime() / AnimTime) * AnimTime) / (AnimTime - 0.5))
	local multF = math.min(1, (CurTime() - math.floor(CurTime() / AnimTime) * AnimTime) / AnimTime)
	local localx = self:GetClientNumber("localx") * mult
	local localz = self:GetClientNumber("localz") * mult
	local lpitch = self:GetClientNumber("lpitch") * mult
	local lang = Angle(lpitch, 0, 0)
	local offset = Vector(-25, 0, -13)
	offset:Rotate(lang)
	local lpos = Vector(localx, 0, localz) + offset
	-- bones
	local rootBone = ent:LookupBone("arm64x64_export_03Z")
	local dof1Bone = ent:LookupBone("arm64x64_export_03X")
	local dof2Bone = ent:LookupBone("arm64x64_export_06")
	local dofMidBone = ent:LookupBone("arm64x64_export_05")
	local piston1Bone = ent:LookupBone("arm64x64_export_08")
	local piston2Bone = ent:LookupBone("arm64x64_export_09")
	local plateBone = ent:LookupBone("arm64x64_export_010")
	local root = ent:GetBonePosition(rootBone)
	-- local transform
	local lroot = ent:WorldToLocal(root)
	local d1 = lroot:Distance(lpos)
	local dof2 = DofLength2Min
	if (d1 - DofLength1) > DofLength2Min then
		dof2 = math.min((d1 - DofLength1) + 0.01, DofLength2Max)
	end
	local angle = (Vector(lpos.x, 0, lpos.z) - Vector(lroot.x, 0, lroot.z)):Angle()

	local ang1 = GetAngleBy3Lendth(DofLength1, dof2, d1)
	local ang2 = GetAngleBy3Lendth(d1, DofLength1, dof2)
	local pistonLength = (dof2 - DofLength2Min)

	if angle.yaw == 180 then
		angle = Angle(-angle.pitch + 180, 0, 0)
	end
	local a1 = angle.pitch + ang2
	local a2 = 90 - (180 - ang1)
	local a3 = -a2 - a1 + lang.pitch

	ent:ManipulateBonePosition(piston1Bone, Vector(pistonLength / 2, 0, 0))
	ent:ManipulateBonePosition(piston2Bone, Vector(pistonLength / 2, 0, 0))
	-- bone transform
	ent:ManipulateBoneAngles(dof1Bone, Angle(0, 0, -44 + a1))
	ent:ManipulateBoneAngles(dof2Bone, Angle(0, 8 + a2, 0))
	ent:ManipulateBoneAngles(dofMidBone, Angle(0, -90, 0))
	ent:ManipulateBoneAngles(plateBone, Angle(0, 0, -54 + a3))
	-- fade effect
	ent:SetColor(Color(255, 255, 255, math.sin(multF * math.pi) * 50))
end

function TOOL:UpdateGhostArmPanelInx(offsetx, offsety, inx, ply)
	local ent = self:GetGhostEntityInx(inx)
	if not IsValid(ent) then
		return
	end
	local animArmPanel = self:GetGhostEntityInx(inx, 1)
	-- if not IsValid(animArmPanel) then return end
	local trace = ply:GetEyeTrace()
	if not trace.Hit or trace.Entity and (trace.Entity:IsPlayer() or trace.Entity:IsNPC() or trace.Entity.IsAperture) then
		ent:SetNoDraw(true)
		return
	end
	local curPos = ent:GetPos()
	local pos = trace.HitPos + trace.HitNormal * 75
	local ang = trace.HitNormal:Angle() + Angle(90, 0, 0)
	local result = GetSpawnPos(pos, ang, ply, trace.HitNormal)
	if result == 1 then
		ent:SetNoDraw(true)
		return
	end
	local offset = Vector(offsetx, offsety, 0) * ARM_PANEL_GRID
	offset:Rotate(ang)
	pos = pos + offset
	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:SetNoDraw(false)
	ent:SetColor(Color(255, 255, 255, 100))

	if IsValid(animArmPanel) then
		animArmPanel:SetPos(pos)
		animArmPanel:SetAngles(ang)
		animArmPanel:SetNoDraw(false)
		self:TransformGhostArmPanel(animArmPanel)
	end
end

function TOOL:UpdateGhostArmPanels(ply)
	local countx = self:GetClientNumber("countx")
	local county = self:GetClientNumber("county")
	local amount = countx * county
	local inx = 0
	for x = 0, countx - 1 do
		for y = 0, county - 1 do
			self:UpdateGhostArmPanelInx(x, y, inx, self:GetOwner())
			inx = inx + 1
		end
	end
end

function TOOL:Think()
	if SERVER then
		return true
	end
	if self.HolserTime and CurTime() < (self.HolserTime + 0.1) then
		return
	end
	local countx = self:GetClientNumber("countx")
	local county = self:GetClientNumber("county")
	local amount = countx * county
	local lastAmount = self.LastPanelAmount

	if lastAmount ~= amount then
		local inx = 0
		for i1 = 1, countx do
			for i2 = 1, county do
				self:MakeGhostEntityInx(inx)
				self:MakeGhostEntityInx(inx, 1)
				inx = inx + 1
			end
		end

		if lastAmount and lastAmount > amount then
			self:RemoveGhostEntityRange(amount, lastAmount)
			self:RemoveGhostEntityRange(amount, lastAmount, 1)
		end
		self.LastPanelAmount = amount
	end

	self:UpdateGhostArmPanels(ply)

	-- if CLIENT then
	-- self:CreateAnimatedArmPanel()
	-- if IsValid(self.TA_AnimatedArmPanel) then
	-- self:UpdateGhostArmPanelInx(self.TA_AnimatedArmPanel)
	-- end
	-- end
end

function TOOL:RightClick(trace)
end

function TOOL:Holster()
	if SERVER then
		return true
	end
	self.HolserTime = CurTime()
	self:ClearGhostEntities()
	self.LastPanelAmount = 0
	return true
end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", {Description = "#tool.aperture_arm_panel.desc"})
	CPanel:NumSlider("#tool.aperture_arm_panel.localx", "aperture_arm_panel_localx", -80, 80)
	CPanel:NumSlider("#tool.aperture_arm_panel.localz", "aperture_arm_panel_localz", -130, 90)
	CPanel:NumSlider("#tool.aperture_arm_panel.lpitch", "aperture_arm_panel_lpitch", -90, 90)
	CPanel:NumSlider("#tool.aperture_arm_panel.county", "aperture_arm_panel_county", 1, 10, 0)
	CPanel:NumSlider("#tool.aperture_arm_panel.countx", "aperture_arm_panel_countx", 1, 10, 0)
	CPanel:AddControl(
		"CheckBox",
		{Label = "#tool.aperture_arm_panel.startenabled", Command = "aperture_arm_panel_startenabled", Help = true}
	)
	CPanel:AddControl("Numpad", {Label = "#tool.aperture_arm_panel.enable", Command = "aperture_arm_panel_keyenable"})
	CPanel:AddControl("CheckBox", {Label = "#tool.aperture_arm_panel.toggle", Command = "aperture_arm_panel_toggle"})
end
