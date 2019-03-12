AddCSLuaFile()

if not LIB_APERTURE then return end

--============= Adhesion Gel ==============
if not PORTAL_PAINT_STICKY then
	PORTAL_PAINT_STICKY = PORTAL_PAINT_COUNT + 1
end

local PAINT_INFO = {}

PAINT_INFO.COLOR 	= Color(125, 25, 220)
PAINT_INFO.NAME		= "Adhesion" 

if SERVER then

function PlayerChangeOrient(ply, orientation, paintHitPos)
	-- Handling changing orientation
	local currentOrient = ply:GetNWVector("TA:Orientation")
	if orientation == currentOrient then return end

	local playerHeight = ply:GetModelRadius()
	local plyOrientCenter = ply:GetPos() + currentOrient * playerHeight / 2
	local orientPlayerHeight = orientation * playerHeight
	local orientPlayerHeightCrouch = orientation * playerHeight / 2
	local plyAngle = ply:EyeAngles()
	if not paintHitPos then _, _, paintHitPos = LIB_APERTURE:GetPaintInfo(plyOrientCenter, -orientPlayerHeight * 1.5) end
	
	-- changing camera orientation
	ply:SetViewOffset(Vector())
	ply:SetViewOffsetDucked(Vector())
	ply:SetCurrentViewOffset(orientPlayerHeight)
	ply:SetNWVector("TA:Orientation", orientation)
	
	-- creating avatar if orientation is not default
	local avatar = ply:GetNWEntity("TA:Avatar")
	if orientation == ORIENTATION_DEFAULT then
		if IsValid(avatar) then avatar:Remove() end
	elseif not IsValid(avatar) then
		local avatar = ents.Create("aperture_player_avatar")
		if not IsValid(avatar) then return end
		avatar:SetPlayer(ply)
		avatar:SetPos(ply:GetPos())
		avatar:SetAngles(orientation:Angle() + Angle(90, 0, 0))
		avatar:Spawn()
	end

	-- Moving player to the floor
	if not paintHitPos then return end
	ply:SetNWVector("TA:OrientationWalk", paintHitPos)
	ply:SetPos(paintHitPos)
	ply:SetVelocity(-ply:GetVelocity())

	-- cooldown for ability to change
	timer.Create("TA:Player_Changed"..ply:EntIndex(), 1, 1, function() end)
end

function PlayerUnStuck(ply)
	local orientation = ply:GetNWVector("TA:Orientation")
	local offset = Vector()
	local nearestPoint = ply:NearestPoint(ply:GetPos() - orientation * ply:GetModelRadius() * 2) 
	local nearestOffset = (ply:GetPos() - nearestPoint)
	local obbmax = ply:OBBMaxs()
	local obbmin = ply:OBBMaxs()
	local pos = ply:GetPos() + Vector(0, 0, nearestOffset.z)

	local traceHullRight = util.TraceHull({
		start = pos - Vector(0, obbmax.y, 0),
		endpos = pos + Vector(0, obbmax.y, 0),
		mins = Vector(obbmin.x, -1, obbmin.z),
		maxs = Vector(obbmax.x, 1, obbmax.z),
		filter = ply,
	})
	
	local traceHullLeft = util.TraceHull({
		start = pos + Vector(0, obbmax.y, 0),
		endpos = pos - Vector(0, obbmax.y, 0),
		mins = Vector(obbmin.x, -1, obbmin.z),
		maxs = Vector(obbmax.x, 1, obbmax.z),
		filter = ply,
	})
	
	local traceHullForward = util.TraceHull({
		start = pos - Vector(obbmax.x, 0, 0),
		endpos = pos + Vector(obbmax.x, 0, 0),
		mins = Vector(-1, obbmin.y, obbmin.z),
		maxs = Vector(1, obbmax.y, obbmax.z),
		filter = ply,
	})
	
	local traceHullBack = util.TraceHull({
		start = pos + Vector(obbmax.x, 0, 0),
		endpos = pos - Vector(obbmax.x, 0, 0),
		mins = Vector(-1, obbmin.y, obbmin.z),
		maxs = Vector(1, obbmax.y, obbmax.z),
		filter = ply,
	})
	
	-- Offsetting
	offset = offset + Vector(0, 0, nearestOffset.z)

	if traceHullForward.Hit and not traceHullForward.StartSolid then
		offset = offset - Vector(traceHullForward.Fraction * obbmax.x * 4, 0, 0)
	end
	if traceHullBack.Hit and not traceHullBack.StartSolid then
		offset = offset + Vector(traceHullBack.Fraction * obbmax.x * 4, 0, 0)
	end
	-- if traceHullForward.StartSolid and traceHullBack.StartSolid then
		-- offset = offset + Vector(nearestOffset.x, 0, 0)
	-- end

	if traceHullRight.Hit and not traceHullRight.StartSolid then
		offset = offset - Vector(0, traceHullRight.Fraction * obbmax.y * 4, 0)
	end
	if traceHullLeft.Hit and not traceHullLeft.StartSolid then
		offset = offset + Vector(0, traceHullLeft.Fraction * obbmax.y * 4, 0)
	end
	-- if traceHullRight.StartSolid and traceHullLeft.StartSolid then
		-- offset = offset + Vector(0, nearestOffset.y, 0)
	-- end
	
	ply:SetPos(ply:GetPos() + offset)
	
	-- print(traceHullForward.Fraction, traceHullRight.Fraction, traceHullLeft.Fraction, traceHullBack.Fraction, traceHullUp.Fraction)
	-- print(traceHullForward.StartSolid, traceHullRight.StartSolid, traceHullLeft.StartSolid, traceHullBack.StartSolid, traceHullUp.StartSolid)
	-- print(traceHullForward.Hit, traceHullRight.Hit, traceHullLeft.Hit, traceHullBack.Hit, traceHullUp.Hit)
end

-- When player step in paint
function PAINT_INFO:OnEnter(ply, normal, enterPos)
	local orientation = ply:GetNWVector("TA:Orientation")
	if LIB_MATH_TA:DegreeseBetween(normal, orientation) > 1 then PlayerChangeOrient(ply, normal, enterPos) end
	ply:EmitSound("TA:PaintStickEnter")
end

-- When player step out paint
function PAINT_INFO:OnExit(ply)
	local playerHeight = 72
	local orientation = ply:GetNWVector("TA:Orientation")
	if orienation != ORIENTATION_DEFAULT then
		PlayerUnStuck(ply)
	end
	
	PlayerChangeOrient(ply, ORIENTATION_DEFAULT)
	ply:SetViewOffset(ORIENTATION_DEFAULT * playerHeight)
	ply:SetViewOffsetDucked(ORIENTATION_DEFAULT * playerHeight / 2)
	ply:SetCurrentViewOffset(ORIENTATION_DEFAULT * playerHeight)

	ply:EmitSound("TA:PaintStickExit")
end

-- When player step from other type to this
function PAINT_INFO:OnChangeTo(ply, oldType, normal)
	PlayerChangeOrient(ply, normal)
end

-- When player step from this type to other
function PAINT_INFO:OnChangeFrom(ply, newType, normal)
	local playerHeight = 72
	local orientation = ply:GetNWVector("TA:Orientation")
	if orientation != ORIENTATION_DEFAULT then
		PlayerUnStuck(ply)
		PlayerChangeOrient(ply, ORIENTATION_DEFAULT)
	end
	PlayerChangeOrient(ply, ORIENTATION_DEFAULT)
	ply:SetViewOffset(ORIENTATION_DEFAULT * playerHeight)
	ply:SetViewOffsetDucked(ORIENTATION_DEFAULT * playerHeight / 2)
	ply:SetCurrentViewOffset(ORIENTATION_DEFAULT * playerHeight)
end

-- Handling orienation changes
function PAINT_INFO:OnChangingOrientation(ply, oldOrientation, newOrientation)
	PlayerChangeOrient(ply, newOrientation)
end

-- Handling paint
function PAINT_INFO:Think(ply, normal, orientationMove)

	local playerHeight = ply:OBBMaxs().z
	local playerHeightFull = ply:GetModelRadius()
	local plyWidth = ply:OBBMaxs().x
	local orientation = ply:GetNWVector("TA:Orientation")
	local orientPlayerHeight = ply:KeyDown(IN_DUCK) and orientation * playerHeightFull / 2 or orientation * playerHeightFull
	local orienationWalk = ply:GetNWVector("TA:OrientationWalk")
	local orientationAng = orientation:Angle() + Angle(90, 0, 0)
	
	ply:SetViewOffset(Vector(0, 0, orientPlayerHeight.z))
	ply:SetViewOffsetDucked(Vector(0, 0, orientPlayerHeight.z))
	ply:SetCurrentViewOffset(orientPlayerHeight)

	-- if player stand on sticky paint
	if orienationWalk != Vector() and orientation != ORIENTATION_DEFAULT then
		
		local playerCenter = ply:GetPos() + orientation * playerHeightFull / 2
		local boxSize = Vector(1, 1, 1)
		local traceForward = util.TraceHull({
			start = playerCenter,
			endpos = playerCenter + orientationAng:Forward() * plyWidth,
			mins = -boxSize,
			maxs = boxSize,
			filter = ply,
		})
		local traceBack = util.TraceHull({
			start = playerCenter,
			endpos = playerCenter - orientationAng:Forward() * plyWidth,
			mins = -boxSize,
			maxs = boxSize,
			filter = ply,
		})
		local traceRight = util.TraceHull({
			start = playerCenter,
			endpos = playerCenter + orientationAng:Right() * plyWidth,
			mins = -boxSize,
			maxs = boxSize,
			filter = ply,
		})
		local traceLeft = util.TraceHull({
			start = playerCenter,
			endpos = playerCenter - orientationAng:Right() * plyWidth,
			mins = -boxSize,
			maxs = boxSize,
			filter = ply,
		})
		
		boxSize = Vector(plyWidth, plyWidth, 1)
		local traceForwardFloor = util.QuickTrace(ply:GetPos() + orientation * 5, Vector(0, 0, plyWidth / 4), ply)
		local traceForwardFloorDown = util.QuickTrace(traceForwardFloor.HitPos, -orientation * 6, ply)
		local traceForwardFloorBack = util.TraceHull({
			start = traceForwardFloorDown.HitPos,
			endpos = traceForwardFloorDown.HitPos - Vector(0, 0, plyWidth / 4),
			mins = -boxSize,
			maxs = boxSize,
			filter = ply,
			collisiongroup = COLLISION_GROUP_DEBRIS,
		})
		
		-- footsteps
		if not timer.Exists("TA:PlayerFootsteps"..ply:EntIndex()) and orientationMove:Length() > 0 then
			sound.Play("TA:PaintFootsteps", ply:GetPos() + orientation * playerHeight)
			local time = ply:KeyDown(IN_SPEED) and 0.25 or 0.35
			timer.Create("TA:PlayerFootsteps"..ply:EntIndex(), time, 1, function() end)
		end
		
		if not traceForwardFloor.Hit and not traceForwardFloorDown.Hit
			and traceForwardFloorBack.Hit and traceForwardFloorBack.Fraction > 0 and LIB_MATH_TA:DegreeseBetween(ORIENTATION_DEFAULT, traceForwardFloorBack.HitNormal) < 25
			and LIB_MATH_TA:DegreeseBetween(ORIENTATION_DEFAULT, orientation) > 45 then
			
			-- Step on conner
			ply:SetPos(traceForwardFloorBack.HitPos)
			ply:SetVelocity(Vector(0, 0, 100))
			orientation = ORIENTATION_DEFAULT
			paintNormal = orientation
			PlayerUnStuck(ply)
			PlayerChangeOrient(ply, ORIENTATION_DEFAULT)
		else
			-- Normalization orientation
			if ply:KeyPressed(IN_JUMP) then
				
				-- Jump out paint
				PlayerUnStuck(ply)
				PlayerChangeOrient(ply, ORIENTATION_DEFAULT)
				ply:SetVelocity(orientation * ply:GetJumpPower())
			else
				-- Pseudo collision
				if traceForward.Hit then orientationMove = orientationMove - orientationAng:Forward() * (1 - traceForward.Fraction) * plyWidth end
				if traceBack.Hit then orientationMove = orientationMove + orientationAng:Forward() * (1 - traceBack.Fraction) * plyWidth end
				if traceRight.Hit then orientationMove = orientationMove - orientationAng:Right() * (1 - traceRight.Fraction) * plyWidth end
				if traceLeft.Hit then orientationMove = orientationMove + orientationAng:Right() * (1 - traceLeft.Fraction) * plyWidth end
				local walk = orienationWalk + orientationMove / 1.2
				
				ply:SetNWVector("TA:OrientationWalk", walk)
				ply:SetPos(walk)
				ply:SetVelocity(-ply:GetVelocity())
			end
		end
	end
end

-- Handling painted entity
function PAINT_INFO:EntityThink(ent)
end

end -- SERVER

if CLIENT then

local function ChangeCamerOrientation(ply, angleFrom, angleTo, plyCamera)
	ply.TA_Current_Ang = angleFrom
	ply.TA_New_Ang = angleTo
	ply.TA_RotateIt = 0
	ply.TA_MaxDegreese = degreese
	local _, angOffset = WorldToLocal(Vector(), plyCamera, Vector(), angleFrom)
	angOffset = Angle(angOffset.p, angOffset.y, 0)
	ply.TA_Camera_Ang_Offset = angOffset
end

-- STICKY gel camera orientation
hook.Add("Think", "TA:StickCamerOrient", function()
	local ply = LocalPlayer()
	local eyeAngles = ply:EyeAngles()
	if not ply:GetNWVector("TA:PrevOrientation") then ply:SetNWVector("TA:PrevOrientation", Vector()) end
	if not ply:GetNWAngle("TA:PrevOrientationAng" ) then ply:SetNWAngle("TA:PrevOrientationAng", Vector(0, 0, 1):Angle()) end
	if not ply:GetNWAngle("TA:PlayerAng" ) then ply:SetNWAngle("TA:PlayerAng", eyeAngles) end
	if not ply:GetNWAngle("TA:PlayerEyeAngle" ) then ply:SetNWAngle("TA:PlayerEyeAngle", eyeAngles) end

	local newEyeAngle = Angle()
	local orientation = ply:GetNWVector("TA:Orientation")
	local prevOrientation = ply:GetNWVector("TA:PrevOrientation")
	local playerEyeAngle = ply:GetNWAngle("TA:PlayerEyeAngle")
	local prevOrientationAng = ply:GetNWAngle("TA:PrevOrientationAng")
	local orientationAng = orientation:Angle() + Angle(90, 0, 0)

	-- rotating camera by roll if player orientation is default
	if orientation == ORIENTATION_DEFAULT then
		if math.abs(playerEyeAngle.r) > 0.1 then
			playerEyeAngle.r = math.ApproachAngle(playerEyeAngle.r, 0, FrameTime() * math.min(playerEyeAngle.r * 10, 160))
		elseif playerEyeAngle.r != 0 then
			playerEyeAngle.r = 0
		end
	end
	
	-- checking for changing orientation
	if orientation != prevOrientation then
		local _, angleFrom = WorldToLocal(Vector(), (-orientation):Angle(), Vector(), prevOrientationAng)
		angleFrom = Angle(0, angleFrom.yaw, 0)
		_, angleFrom = LocalToWorld(Vector(), angleFrom, Vector(), prevOrientationAng)
		
		local _, angleTo = WorldToLocal(Vector(), prevOrientation:Angle(), Vector(), orientationAng)
		angleTo = Angle(0, angleTo.yaw, 0)
		_, angleTo = LocalToWorld(Vector(), angleTo, Vector(), orientationAng)
		
		ChangeCamerOrientation(ply, angleFrom, angleTo, eyeAngles)
	end
	
	ply:SetNWVector("TA:PrevOrientation", orientation)
	
	if newEyeAngle != eyeAngles then
		local playerAng = ply:GetNWAngle("TA:PlayerAng")

		-- fixing player's roll if orientation is default
		if playerAng != eyeAngles then
			local angOffset = eyeAngles - playerAng
			
			playerEyeAngle.p = math.max(-88, math.min(88, playerEyeAngle.p))
			if playerEyeAngle.y > 360 then playerEyeAngle.y = playerEyeAngle.y - 360 end
			if playerEyeAngle.y < -360 then playerEyeAngle.y = playerEyeAngle.y + 360 end
			
			ply:SetNWAngle("TA:PlayerEyeAngle", playerEyeAngle + angOffset)
			playerAng = eyeAngles
			ply:SetNWAngle("TA:PlayerAng", playerAng)
		end
		
		-- player camera changing orientation
		if ply.TA_Current_Ang and ply.TA_New_Ang and ply.TA_Camera_Ang_Offset then
			local currentAng = ply.TA_Current_Ang
			local newAng = ply.TA_New_Ang
			local cameraAngOffset = ply.TA_Camera_Ang_Offset
			local maxDegreese = ply.TA_MaxDegreese
			
			local _, offsetAngle = WorldToLocal(Vector(), newAng, Vector(), currentAng)
			offsetAngle = offsetAngle * FrameTime() * 10
			_, offsetAngle = LocalToWorld(Vector(), offsetAngle, Vector(), currentAng)
			currentAng = offsetAngle
			ply.TA_Current_Ang = currentAng
			
			local _, camAng = LocalToWorld(Vector(), cameraAngOffset, Vector(), currentAng)
			
			ply:SetEyeAngles(camAng)
			
			local result = LIB_MATH_TA:DegreeseBetween(currentAng:Forward(), newAng:Forward())
			if result < 1 then
				ply.TA_Current_Ang = nil
				local _, camOffAng = LocalToWorld(Vector(), Angle(0, 0, 0), Vector(), newAng)
				ply:SetNWAngle("TA:PrevOrientationAng", camOffAng)
				ply:SetNWAngle("TA:PlayerEyeAngle", cameraAngOffset)
			end
		else
			_, newEyeAngle = LocalToWorld(Vector(), playerEyeAngle, Vector(), prevOrientationAng)
			
			local plyAng = -ply:GetAngles()
			local _, orientAngToPly = WorldToLocal(Vector(), plyAng, Vector(), prevOrientationAng)

			-- changing cam orientation when player is have different orientation or roll is inccorect
			if orientation != ORIENTATION_DEFAULT or orientation == ORIENTATION_DEFAULT and math.abs(ply:EyeAngles().r) > 0.1 then
				ply:SetEyeAngles(newEyeAngle)
				ply:SetNWAngle("TA:PlayerAng", newEyeAngle)
			end
		end
	end
end )

end -- CLIENT

-- Handling entity paint
function PAINT_INFO:OnEntityPainted(ent)
	if not IsValid(ent) then return end
	if not IsValid(ent:GetPhysicsObject()) then return end
	
	local inx = ent:AddCallback("PhysicsCollide", function(ent, colData, collider)
		if not IsValid(ent) then return end
		if ent:IsPlayerHolding() then return end
		if not IsValid(colData.PhysObject) then return end
		local physObj = colData.PhysObject
		local collider = colData.HitObject:GetEntity()
		-- if collided with other entity
		if colData.DeltaTime < 0.25 then return end
		
		if IsValid(collider) then
			if not IsValid(constraint.Find(ent, collider, "Weld", 0, 0)) then
				-- bypass
				timer.Simple(0, function() constraint.Weld(ent, collider, 0, 0, 3000, 1, false) end)
				ent:EmitSound("TA:PaintStickEnter")
			end
		else
			-- bypass
			timer.Simple(0, function() constraint.Weld(ent, Entity(0), 0, 0, 10000, 1, false) end)
			ent:EmitSound("TA:PaintStickEnter")
		end
	end)
	
	ent.TA_SPhysCollideCallbackInxed = inx
end

-- Handling entity clear
function PAINT_INFO:OnEntityCleared(ent)
	if ent.TA_SPhysCollideCallbackInxed then
		ent:RemoveCallback("PhysicsCollide", ent.TA_SPhysCollideCallbackInxed)
	end
end

function PAINT_INFO:OnEntityChangedTo(ent, paintType)
	PAINT_INFO:OnEntityPainted(ent)
end

function PAINT_INFO:OnEntityChangedFrom(ent, paintType)
	PAINT_INFO:OnEntityCleared(ent)
end

LIB_APERTURE:CreateNewPaintType(PORTAL_PAINT_STICKY, PAINT_INFO)
