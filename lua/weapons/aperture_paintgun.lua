AddCSLuaFile( )

if ( SERVER ) then
	SWEP.Weight                     = 4
	SWEP.AutoSwitchTo               = false
	SWEP.AutoSwitchFrom             = false
end

if ( CLIENT ) then
	//SWEP.WepSelectIcon 		= surface.GetTextureID("weapons/portalgun_inventory")
	SWEP.PrintName          = "Paint Gun"
	SWEP.Author             = "CrishNate"
	SWEP.Purpose            = "Shoot Different Gels"
	SWEP.ViewModelFOV       = 45
	SWEP.Instructions       = "Left/Right Mouse shoot gel, Reload change gel types"
	SWEP.Slot = 0
	SWEP.Slotpos = 0
	SWEP.CSMuzzleFlashes    = false

end

SWEP.HoldType			= "crossbow"
SWEP.EnableIdle			= false	
SWEP.BobScale 			= 0
SWEP.SwayScale 			= 0

SWEP.DrawAmmo 			= false
SWEP.DrawCrosshair 		= true
SWEP.Category 			= "Aperture Science"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= true

SWEP.ViewModel 			= "models/weapons/v_aperture_paintgun.mdl" 
SWEP.WorldModel 		= "models/weapons/w_aperture_paintgun.mdl"

SWEP.ViewModelFlip 		= false

SWEP.Delay              = .5

SWEP.Primary.ClipSize		= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic		= true
SWEP.Primary.Ammo				= "none"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo				= "none"

SWEP.RunBob = 0.5
SWEP.RunSway = 2.0

SWEP.PaintGunHoldEntity	= NULL
SWEP.NextAllowedPickup	= 0
SWEP.PickupSound		= nil
SWEP.IsShooting			= false
SWEP.HUDAnimation		= 0
SWEP.HUDSmoothCursor	= 0

local BobTime = 0
local BobTimeLast = CurTime()

local SwayAng = nil
local SwayOldAng = Angle()
local SwayDelta = Angle()

function SWEP:CreateFakeViewModel()
	-- Creating fake viewmodel
	if IsValid(self.PaintGunViewModel) then
		self.PaintGunViewModel:SetNoDraw(false)
		return
	end
	local vm = ClientsideModel(self.ViewModel, RENDERGROUP_OPAQUE)
	vm:SetPos(EyePos() - LocalPlayer():GetForward() * (self.ViewModelFOV / 5))
	vm:SetAngles(EyeAngles())
	vm:SetNoDraw(true)
	vm.AutomaticFrameAdvance = true
	self.PaintGunViewModel = vm
	
	function vm.PreDraw(vm)
		vm:SetColor(Color(255, 255, 255))
		local oldorigin = EyePos() -- -EyeAngles():Forward()*10
		local pos, ang = self:CalcViewModelView(vm, oldorigin, EyeAngles(), vm:GetPos(), vm:GetAngles())
		return pos, ang
	end
end

function SWEP:MakePaintBlob(paintType)
	if timer.Exists("TA:Player_ShootingPaint"..self.Owner:EntIndex()) then return end
	timer.Create("TA:Player_ShootingPaint"..self.Owner:EntIndex(), 0.01, 1, function() end)
	
	if not paintType then return end

	local ownerEyeAngles = self.Owner:EyeAngles()
	local ownerSpeed = self.Owner:GetVelocity()
	local offset = Vector(25, -30, -30)
	offset:Rotate(ownerEyeAngles)
	local ownerShootPos = self.Owner:GetShootPos() + offset
	local forward = ownerEyeAngles:Forward()
	local traceForce = util.QuickTrace(ownerShootPos, forward * 1000, self.Owner)
	local force = traceForce.HitPos:Distance(ownerShootPos)
	
	-- Randomize makes random size between maxsize and minsize by selected procent
	local randSize = math.Rand(LIB_APERTURE.GEL_MINSIZE, (LIB_APERTURE.GEL_MAXSIZE + LIB_APERTURE.GEL_MINSIZE) / 2)
	local paint = LIB_APERTURE:MakePaintBlob(paintType, ownerShootPos, forward * math.max(100, math.min(200, force - 100)) * 8 + VectorRand() * 100 + ownerSpeed, randSize)
	paint.IsFromPaintGun = true
	
	if not IsValid(paint) then return end
	if IsValid(self.Owner) and self.Owner:IsPlayer() then paint:SetOwner(self.Owner) end
end

--[[---------------------------------------------------------
   Name: CalcViewModelView
   Desc: Overwrites the default GMod v_model system.
---------------------------------------------------------]]

function SWEP:CalcViewModelView(ViewModel, oldPos, oldAng, pos, ang)
	local pPlayer = self.Owner

	local CT = CurTime()
	local FT = FrameTime()

	local RunSpeed = pPlayer:GetRunSpeed()
	local Speed = math.Clamp(pPlayer:GetVelocity():Length2D(), 0, RunSpeed)

	local BobCycleMultiplier = Speed / pPlayer:GetRunSpeed()

	BobCycleMultiplier = (BobCycleMultiplier > 1 and math.min(1 + ((BobCycleMultiplier - 1) * 0.2), 5) or BobCycleMultiplier)
	BobTime = BobTime + (CT - BobTimeLast) * (Speed > 0 and (Speed / pPlayer:GetWalkSpeed()) or 0)
	BobTimeLast = CT
	local BobCycleX = math.sin(BobTime * 0.5 % 1 * math.pi * 2) * BobCycleMultiplier
	local BobCycleY = math.sin(BobTime % 1 * math.pi * 2) * BobCycleMultiplier

	oldPos = oldPos + oldAng:Right() * (BobCycleX * 1.5)
	oldPos = oldPos
	oldPos = oldPos + oldAng:Up() * BobCycleY/2

	SwayAng = oldAng - SwayOldAng
	if math.abs(oldAng.y - SwayOldAng.y) > 180 then
		SwayAng.y = (360 - math.abs(oldAng.y - SwayOldAng.y)) * math.abs(oldAng.y - SwayOldAng.y) / (SwayOldAng.y - oldAng.y)
	else
		SwayAng.y = oldAng.y - SwayOldAng.y
	end
	SwayOldAng.p = oldAng.p
	SwayOldAng.y = oldAng.y
	SwayAng.p = math.Clamp(SwayAng.p, -3, 3)
	SwayAng.y = math.Clamp(SwayAng.y, -3, 3)
	SwayDelta = LerpAngle(math.Clamp(FT * 5, 0, 1), SwayDelta, SwayAng)
	
	return oldPos + oldAng:Up() * SwayDelta.p + oldAng:Right() * SwayDelta.y + oldAng:Up() * oldAng.p / 90 * 2, oldAng
end

local gravityLight, gravityBeam = Material("sprites/light_glow02_add"), Material("particle/bendibeam")
local gravitySprites = {
	{bone = "ValveBiped.Bip001", pos = Vector(-17, -44.5, 26), size = {x = 10, y = 10}},
	{bone = "ValveBiped.Bip001", pos = Vector(-12, -44.5, 20.5), size = {x = 10, y = 10}},
	{bone = "ValveBiped.Bip001", pos = Vector(0.10, 1.25, 1.05), size = {x = 10, y = 10}}
}

function SWEP:DrawPickupEffects(ent)
	--Draw the lights
	local lightOrigins = {}
	for k,v in pairs(gravitySprites) do
		local bone = ent:LookupBone(v.bone)

		if not bone then return end
		
		local pos, ang = Vector(0, 0, 0), Angle(0, 0, 0)
		local m = ent:GetBoneMatrix(bone)
		if (m) then
			pos, ang = m:GetTranslation(), m:GetAngles()
		end
		
		if (IsValid(self.Owner) and self.Owner:IsPlayer() and 
			ent == self.Owner:GetViewModel() and self.ViewModelFlip) then
			ang.r = -ang.r // Fixes mirrored models
		end
		
		if not pos then continue end
		
		local col = Color(255, 255, 255, math.Rand(96, 128))
		local offset = Vector(v.pos)
		offset:Rotate(ang)
		local drawpos = pos + offset
		local _sin = math.abs(math.sin(CurTime() * 0.1 * math.Rand(1, 3))) //math.sinwave( 25, 3, true )
		
		render.SetMaterial(gravityLight)
		render.DrawSprite(drawpos, v.size.x + _sin, v.size.y + _sin, col)
		
		lightOrigins[k] = drawpos
	end
	
	local bone = ent:GetBoneMatrix(ent:LookupBone("ValveBiped.Bip001")) 
	local endpos, ang = bone:GetTranslation(),bone:GetAngles()
	local offset = Vector(-18, -44, 22)
	offset:Rotate(ang)
	local _sin = math.abs(math.sin(1 + CurTime() * 3))
	local _sin2 = math.abs(math.sin(1 + CurTime() * 2))
	endpos = endpos + offset
	
	render.DrawSprite(endpos, 5 + _sin, 5 + _sin, col)
	
	render.SetMaterial(gravityBeam)
	render.DrawBeam(lightOrigins[1], endpos, (_sin + 0.5) * 4, CurTime(), CurTime() + 0.5, Color(255, 255, 255, 100))
	render.DrawBeam(lightOrigins[2], endpos, (_sin2 + 0.5) * 4, CurTime(), CurTime() + 0.5, Color(255, 255, 255, 100))
	render.DrawBeam(lightOrigins[3], endpos, (_sin + 0.5) * 4, CurTime(), CurTime() + 0.5, Color(255, 255, 255, 100))
	
end

function SWEP:Initialize()
	if CLIENT then
		self:CreateFakeViewModel()
		self.CursorEnabled = false
		return
	end

	util.AddNetworkString("TA_NW_PaintGun_SwitchPaint")
	util.AddNetworkString("TA_NW_PaintGun_Holster")
	util.AddNetworkString("TA:NW_PaintGun_Pickup")
	
	self:SetNWInt("TA:firstPaintType", PORTAL_PAINT_BOUNCE)
	self:SetNWInt("TA:secondPaintType", PORTAL_PAINT_SPEED)
	
	self:SetHoldType(self.HoldType)
	self:SetWeaponHoldType(self.HoldType)
end

function SWEP:ViewModelDrawn(viewModel) 
	self.Owner:SetNWEntity("TA:ViewModel", viewModel)
	local vm = self.PaintGunViewModel
	local firstPaintType = self:GetNWInt("TA:firstPaintType")
	local secondPaintType = self:GetNWInt("TA:secondPaintType")
	if IsValid(viewModel) then viewModel:SetNoDraw(true) end

	if IsValid(vm) then
		vm:SetSubMaterial(3, "!aperture_paintgun_paint_"..firstPaintType)
		vm:SetSubMaterial(2, "!aperture_paintgun_paint_"..secondPaintType)
	end
	
end

function SWEP:Holster(wep)
	if not IsFirstTimePredicted() then return end
	if SERVER then
		net.Start("TA_NW_PaintGun_Holster")
			net.WriteEntity(self.Owner)
		net.Send(self.Owner)
		self.Owner:StopSound("player/object_use_lp_01.wav")
	end

	if CLIENT then
		local viewModel = self.Owner:GetNWEntity("TA:ViewModel")
		local vm = self.PaintGunViewModel
		if IsValid(viewModel) then viewModel:SetNoDraw(false) end
		if IsValid(vm) then vm:Remove() end
	end
	
	return true
end

function SWEP:PrimaryAttack()
	if CLIENT then return end
	
	local firstPaintType = self:GetNWInt("TA:firstPaintType")
	self:MakePaintBlob(firstPaintType)
	self:DropEntity()
end

function SWEP:SecondaryAttack()
	if CLIENT then return end

	local secondPaintType = self:GetNWInt("TA:secondPaintType")
	self:MakePaintBlob(secondPaintType)
	self:DropEntity()
end

function SWEP:Reload()
	return
end

local function ConvectTo360( angle )
	if angle < 0 then return 360 + angle end
	return angle
end

function SWEP:DrawHUD()
	
	local animation = self.HUDAnimation
	local firstPaintType = self:GetNWInt("TA:firstPaintType")
	local secondPaintType = self:GetNWInt("TA:secondPaintType")
	
	local cursorX, cursorY = input.GetCursorPos()
	local curpos = Vector(cursorX - ScrW() / 2, cursorY - ScrH() / 2)
	local angle = math.atan2(curpos.x, curpos.y) * 180 / math.pi
	local offsetY = 200
	local imgSize = 64 * animation
	local pointerSize = 80 * animation
	local paintCount = PORTAL_PAINT_COUNT
	local separating = 50
	local selectCircleAddictionSize = 5
	local roundDegTo = 360 / paintCount
	
	local roundAngle = math.Round((angle - 90) / roundDegTo) * roundDegTo
	local selectionDeg = math.Round(ConvectTo360(-angle + 90) / roundDegTo) * roundDegTo
	if selectionDeg == 360 then selectionDeg = 0 end
	
	if LocalPlayer():KeyDown(IN_RELOAD) then
		if animation < 1 then self.HUDAnimation = math.min(1, animation + FrameTime() * 2) end
		
		if not self.CursorEnabled then
			self.CursorEnabled = true
			gui.EnableScreenClicker(true)
		end
	else
		if animation > 0 then self.HUDAnimation = math.max(0, animation - FrameTime() * 2) end
		
		if self.CursorEnabled then
			self.CursorEnabled = false
			gui.EnableScreenClicker(false)
		end
	end
	
	if animation != 0 then
		for i = 1,paintCount  do
			local deg = roundDegTo * (i - 1)
			local radian = deg * math.pi / 180
			local rotAnim = math.pi * (1 - animation)
			
			local wheelRad = imgSize * (1 + paintCount * (paintCount / 50))
			local cos = math.cos(radian + rotAnim)
			local sin = math.sin(radian + rotAnim)

			local XPos = ScrW() / 2 + (cos * wheelRad - imgSize / 2) * animation
			local YPos = ScrH() / 2 + (sin * wheelRad - imgSize / 2) * animation
			
			if selectionDeg == deg and LocalPlayer():KeyDown(IN_RELOAD) then
				if firstPaintType != i and secondPaintType != i then
					if input.IsMouseDown(MOUSE_LEFT) then
						net.Start("TA_NW_PaintGun_SwitchPaint")
							net.WriteString("first")
							net.WriteInt(i, 8)
						net.SendToServer()
					elseif input.IsMouseDown(MOUSE_RIGHT) then
						net.Start("TA_NW_PaintGun_SwitchPaint")
							net.WriteString("second")
							net.WriteInt(i, 8)
						net.SendToServer()
					end
				end
			end
			
			local addingSize = 0
			local DrawColor = Color(150, 150, 150)
			local DrawHalo = false
			
			if i == firstPaintType then
				DrawColor = Color(0, 200, 255)
				DrawHalo = true
			elseif i == secondPaintType then 
				DrawColor = Color(255, 200, 0)
				DrawHalo = true
			elseif selectionDeg == deg and animation == 1 then 
				DrawColor = Color(255, 255, 255)
				DrawHalo = true 
			end
		
			surface.SetDrawColor( DrawColor )

			if animation == 1 then
				if selectionDeg == deg then addingSize = 20 end
				
				local PaintName = LIB_APERTURE:PaintTypeToName(i) 
				surface.SetFont("Default")
				surface.SetTextColor(DrawColor)

				local textW, textH = surface.GetTextSize(PaintName)
				local textRadius = (textW + textH) / 2
				local textOffsetX = cos * (imgSize + textRadius / 2) + imgSize / 2 - textW / 2
				local textoffsetY = sin * (imgSize + textRadius / 2) + imgSize / 2 - textH / 2
				surface.SetTextPos(XPos + textOffsetX, YPos + textoffsetY)
				surface.DrawText(PaintName)
			end

			if DrawHalo then
				surface.SetMaterial(Material("vgui/paint_type_select_circle"))
				surface.DrawTexturedRect( 
					XPos - selectCircleAddictionSize - addingSize / 2
					, YPos - selectCircleAddictionSize - addingSize / 2
					, imgSize + selectCircleAddictionSize * 2 + addingSize
					, imgSize + selectCircleAddictionSize * 2 + addingSize
				)
			end

			surface.SetDrawColor(Color(255, 255, 255))
			surface.SetMaterial(Material( "vgui/paint_type_back"))
			surface.DrawTexturedRect(XPos - addingSize / 2, YPos - addingSize / 2, imgSize + addingSize, imgSize + addingSize)
			
			surface.SetDrawColor(LIB_APERTURE:PaintTypeToColor(i))
			surface.SetMaterial(Material("vgui/paint_icon"))
			surface.DrawTexturedRect(XPos - addingSize / 2, YPos - addingSize / 2, imgSize + addingSize, imgSize + addingSize)
		end
		
		self.HUDSmoothCursor =  math.ApproachAngle(self.HUDSmoothCursor, selectionDeg, FrameTime() * 500)
		
		surface.SetDrawColor(Color(255, 255, 255))
		surface.SetMaterial(Material("vgui/hud/paint_type_select_arrow"))
		surface.DrawTexturedRectRotated(ScrW() / 2, ScrH() / 2, pointerSize, pointerSize, -self.HUDSmoothCursor - 90)
	end
	
	-- Drawing viewmodel
	local weapon = LocalPlayer():GetActiveWeapon()
	if IsValid(weapon.PaintGunViewModel) and self.Owner:GetViewEntity() == self.Owner then
		cam.Start3D(EyePos(), EyeAngles(), weapon.ViewModelFOV + 10)
			local pos, ang = weapon.PaintGunViewModel:PreDraw()
			render.SetColorModulation(1, 1, 1, 255)
				render.Model({
				pos = pos, 
				angle = ang, 
				model = weapon.ViewModel
			}, weapon.PaintGunViewModel)
			
			-- weapon:DoPickupAnimations(weapon.PaintGunViewModel)
			if self.IsPickupEntity then weapon:DrawPickupEffects(weapon.PaintGunViewModel) end
		cam.End3D()
	end
	weapon:ViewModelDrawn(weapon.PaintGunViewModel)
end

function SWEP:DropEntity()
	if SERVER then
		local ply = self.Owner
		net.Start("TA:NW_PaintGun_Pickup")
		net.WriteEntity(self)
		net.WriteEntity(NULL)
		net.Send(ply)
		
		if IsValid(self.PaintGunHoldEntity) then
			self.Owner:StopSound("player/object_use_lp_01.wav")
			self.Owner:EmitSound("player/object_use_stop_01.wav")
			self.PaintGunHoldEntity = NULL
		end
	end
	
	if CLIENT then
		if self.IsPickupEntity then self.IsPickupEntity = false end
	end
end

if SERVER then
	function SWEP:PickupEntity(ent)
		local ply = self.Owner
		if ply:GetGroundEntity() == ent then return false end
		
		--Take it from other players.
		if ent:IsPlayerHolding() and ent.Holder and ent.Holder:IsValid() then
			ent.Holder:GetActiveWeapon():OnDroppedProp()
		end
		
		--Rotate it first
		local angOffset = hook.Call("GetPreferredCarryAngles",GAMEMODE,ent) 
		if angOffset then
			ent:SetAngles(ply:EyeAngles() + angOffset)
		end

		if ent:IsPlayerHolding() then return end
		-- self.Owner:EmitSound("player/object_use_lp_01.wav")
		ply:PickupObject(ent)
		self.PaintGunHoldEntity = ent
		
		net.Start("TA:NW_PaintGun_Pickup")
			net.WriteEntity(self)
			net.WriteEntity(ent)
		net.Send(ply)
	end
	
	function SWEP:TryPickup()
		local ply = self.Owner
		local tr = util.TraceLine({ 
			start = ply:EyePos(),
			endpos = ply:EyePos() + ply:EyeAngles():Forward() * 150,
			filter = ply
		})
		
		if IsValid(tr.Entity) then
			if tr.Entity.isClone then tr.Entity = tr.Entity.daddyEnt end
			local entsize = (tr.Entity:OBBMaxs() - tr.Entity:OBBMins()):Length() / 2
			if entsize > 45 then return end
			if not IsValid(self.HoldenProp) and tr.Entity:GetMoveType() != 2 then
				if not self:PickupEntity(tr.Entity) then
					self:EmitSound("player/object_use_failure_01.wav")
				end
			end
		else
			self.Owner:EmitSound("player/object_use_failure_01.wav")
		end
	end
	
	net.Receive("TA_NW_PaintGun_SwitchPaint", function(len, ply)
		local mouse = net.ReadString()
		local paintType = net.ReadInt(8)
		
		if mouse == "first" then ply:GetActiveWeapon():SetNWInt("TA:firstPaintType", paintType) end
		if mouse == "second" then ply:GetActiveWeapon():SetNWInt("TA:secondPaintType", paintType) end
	end)
	
	function SWEP:Think()
		local ply = self.Owner
		if not IsValid(self.PaintGunHoldEntity) or not self.PaintGunHoldEntity:IsPlayerHolding() then self:DropEntity() end

		if ply:KeyPressed(IN_USE) then
			if IsValid(self.PaintGunHoldEntity) then self:DropEntity() end
		end
		
		if ply:KeyDown(IN_USE) then
			if not self.UsePressed then
				self:DropEntity()
				self:TryPickup()
				self.UsePressed = true
			end
		else
			self.UsePressed = false
		end
	end
	
	-- hook.Add("KeyPress", "PaintGunPickupEntity", function(ply, key)
		-- if key == IN_USE and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "aperture_paintgun" then
			-- ply:GetActiveWeapon():TryPickup()
		-- end
	-- end)

	hook.Add("AllowPlayerPickup", "TA:PaintGunDisablePickupbility", function(ply, ent)
		if IsValid(ent) and IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "aperture_paintgun" then return false end
	end)

end

net.Receive("TA:NW_PaintGun_Pickup", function(len, ply)
	local weapon = net.ReadEntity()
	local ent = net.ReadEntity()
	
	if not IsValid(weapon) then return end
	if IsValid(ent) then
		weapon.IsPickupEntity = true
	else
		weapon.IsPickupEntity = false
	end
end)

function SWEP:Deploy()
	if SERVER then return true end
	if not IsFirstTimePredicted() then return true end
	self:CreateFakeViewModel()
	return true
end

function SWEP:OnRemove()
	if SERVER then
		self.Owner:StopSound("player/object_use_lp_01.wav")
	end

	if CLIENT then
		local vm = self.PaintGunViewModel
		if IsValid(vm) then vm:Remove() end
		if self.CursorEnabled then
			self.CursorEnabled = false
			gui.EnableScreenClicker(false)
		end
		
		local viewModel = self.Owner:GetNWEntity("TA:ViewModel")
		if IsValid(viewModel) then viewModel:SetNoDraw(false) end
	end
	
	return true
end
