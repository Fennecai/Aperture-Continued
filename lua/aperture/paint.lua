AddCSLuaFile()

-- ================================ PAINT STUFF ============================
LIB_APERTURE.PAINT_QUALITY	= 1
LIB_APERTURE.PAINT_TYPES 	= {}

PORTAL_PAINT_NONE 			= 0
PORTAL_PAINT_COUNT			= 0

ORIENTATION_DEFAULT 				= Vector(0, 0, 1)

LIB_APERTURE.GEL_BOX_SIZE 			= 64
LIB_APERTURE.GEL_MAXSIZE 			= 150
LIB_APERTURE.GEL_MINSIZE 			= 40
LIB_APERTURE.GEL_MAX_LAUNCH_SPEED 	= 1000

LIB_APERTURE.GELLED_ENTITIES 		= { }
LIB_APERTURE.CONNECTED_PAINTS 		= { }

local PLAYER_PAINT_CAMERA 			= { }

function LIB_APERTURE:IsPlayerOnGround( ply )
	local orientation = ply:GetNWVector("TA:Orientation")
	return orientation and orientation != Vector(0, 0, 1) or ply:IsOnGround()
end

function LIB_APERTURE:InvertNormal(normal)
	if normal.x != 0 then normal.x = normal.x * -1 end
	if normal.y != 0 then normal.y = normal.y * -1 end
	if normal.z != 0 then normal.z = normal.z * -1 end
end

function LIB_APERTURE:GetPaintInfo(startpos, dir, ignoreGelledProps, excludeNormalDifferents, sufraceNormalToCompare)
	if not LIB_PAINT then return end
	local paintInfo, point = LIB_PAINT:GetPaintInfo(startpos, dir)
	local trace = util.TraceLine({
		start = startpos,
		endpos = point,
		ignoreworld = true,
		filter = function(ent)
			if ent:GetClass() == "prop_portal" then return true end
		end
	})
	if IsValid(trace.Entity) and trace.Entity:GetClass() == "prop_portal" then return end 
	if not paintInfo then return nil end
	
	return paintInfo.paintType, paintInfo.normal, point
end

-- Assigning new paint type
function LIB_APERTURE:CreateNewPaintType(index, info)
	if not LIB_APERTURE.PAINT_TYPES[index] then PORTAL_PAINT_COUNT = PORTAL_PAINT_COUNT + 1 end
	LIB_APERTURE.PAINT_TYPES[index] = info
end

-- Loading paint types
local paint_types = file.Find("aperture/paint_types/*.lua", "LUA")
for _, plugin in ipairs(paint_types) do
	include("aperture/paint_types/" .. plugin)
end

function LIB_APERTURE:PaintTypeToColor(paintType)
	return LIB_APERTURE.PAINT_TYPES[paintType].COLOR
end

function LIB_APERTURE:PaintTypeToName(index)
	return LIB_APERTURE.PAINT_TYPES[index].NAME
end

function LIB_APERTURE:PaintTypeToInfo(index)
	return LIB_APERTURE.PAINT_TYPES[index]
end

if CLIENT then
	for k,v in pairs(LIB_APERTURE.PAINT_TYPES) do
		local color = v.COLOR
		local bumpMat = CreateMaterial("aperture_paintgun_paint_"..k, "VertexLitGeneric", {
			["$basetexture"] = "aperture/paint/prop_paint",
			["$bumpmap"] = "aperture/paint/blob_surface_normal",
			["$ssbump"] = "1",
			["$alphatestreference"] = "0.06",
			["$envmapmask"] = "aperture/paint/blob_surface_normal",
			["$envmapsaturation"] = "[.02 .02 .02]",
			["$phong"] = "1",
			["$phongexponent"] = "16",
			["$phongboost"] = "1",
			["$phongfresnelranges"] = "[0.5 0.5 0.5]",
			["$phongalbedotint"] = "1",
			["$color2"] = "{"..color.r.." "..color.g.." "..color.b.."}",
			["Proxies"] = {
				["TextureScroll"] = {
					["textureScrollVar"] = "$basetexturetransform",
					["textureScrollRate"] = "0.04",
					["texturescrollangle"] = "-100"
				}
			}
		})
	end
end
	
if SERVER then

end -- SERVER

-- Painting players screen
function LIB_APERTURE:PaintPlayerScreen(ply, paintType, radius)
	if CLIENT then return end
	net.Start("TA:NW_PaintCamera")
		net.WriteInt(paintType, 8)
		net.WriteFloat(radius)
	net.Send(ply)
end

net.Receive("TA:NW_PaintCamera", function()
	local paintType = net.ReadInt(8)
	local radius = net.ReadFloat()
	local ply = LocalPlayer()
	if not PLAYER_PAINT_CAMERA[ply] then PLAYER_PAINT_CAMERA[ply] = {} end
	
	for i = 1, 2 do
		local pos = Vector(ScrW(), ScrH()) * Vector(math.Rand(0, 1), math.Rand(0, 1))
		
		-- removing paint from screen if it too much
		if #PLAYER_PAINT_CAMERA[ply] > 10 then
			table.remove(PLAYER_PAINT_CAMERA[ply], 1)
		else
			table.insert(PLAYER_PAINT_CAMERA[ply], {
				time = 0,
				paintType = paintType,
				pos = pos,
				radius = radius
			})
		end
	end
end)

-- Drawing painted screen
hook.Add("HUDPaint", "TA:PaintHUDPaint", function()
	local ply = LocalPlayer()
	if not PLAYER_PAINT_CAMERA[ply] then return end
	local paintCamInfos = PLAYER_PAINT_CAMERA[ply]
	
	for k,v in pairs(paintCamInfos) do
		local pos = v.pos
		local paintType = v.paintType
		local clr = LIB_APERTURE:PaintTypeToColor(paintType)
		local rad = math.min(50, v.radius) * 30
		local time = math.max(0, math.min(1, v.time))
		local color = Color(clr.r, clr.g, clr.b, math.min(150, math.max(0, 200 - time * 200)))
		local paintInfo = LIB_APERTURE:PaintTypeToInfo(paintType)
		surface.SetDrawColor(color)
		if paintInfo.SCREEN_PAINT_MATERIAL then
			surface.SetMaterial(paintInfo.SCREEN_PAINT_MATERIAL)
		else
			surface.SetMaterial(Material("aperture/paint/screen_paint"))
		end
		surface.DrawTexturedRect(
			pos.x - rad / 2,
			pos.y - rad / 2,
			rad,
			rad * (1 + time / 10)
		)
		
		v.pos.y = pos.y + math.max(0, time * 2 - 0.25)
		v.time = time + 0.2 * FrameTime()
		if time >= 1 then PLAYER_PAINT_CAMERA[ply][k] = nil end
	end
end)

-- no more client side
if CLIENT then return end

function LIB_APERTURE:PaintEntity(ent, paintType)
	local paint_model = ent:GetNWEntity("TA:PaintedModel")
	local paintInfo = LIB_APERTURE.PAINT_TYPES[paintType]
	
	if IsValid(paint_model) then
		local oldPaintType = ent:GetNWInt("TA:PaintType")
		local oldPaintInfo = LIB_APERTURE.PAINT_TYPES[oldPaintType]
		
		if oldPaintType != paintType and (oldPaintType and oldPaintType != PORTAL_PAINT_NONE) and (paintType and paintType != PORTAL_PAINT_NONE) then
			if paintInfo.OnEntityChangedTo then paintInfo:OnEntityChangedTo(ent, paintType) end
			if oldPaintInfo.OnEntityChangedFrom then oldPaintInfo:OnEntityChangedFrom(ent, oldPaintType) end
		end

		ent:SetNWInt("TA:PaintType", paintType)
		paint_model:SetColor(LIB_APERTURE:PaintTypeToColor(paintType))
		return
	end
	
	if paintInfo.OnEntityPainted then paintInfo:OnEntityPainted(ent) end
	
	paint_model = ents.Create("prop_physics")
	if not IsValid(paint_model) then return end
	paint_model:SetModel(ent:GetModel())
	paint_model:SetPos(ent:GetPos())
	paint_model:SetAngles(ent:GetAngles())
	paint_model:SetParent(ent)
	paint_model:PhysicsInit(SOLID_NONE)
	paint_model:SetMoveType(MOVETYPE_NONE)
	paint_model:Spawn()
	paint_model:SetNotSolid(true)
	paint_model:SetRenderMode(RENDERMODE_TRANSALPHA)
	paint_model:SetColor(LIB_APERTURE:PaintTypeToColor(paintType))
	paint_model.GASL_Ignore = true
	
	local mats = paint_model:GetMaterials()
	for mInx,mat in pairs(mats) do
		paint_model:SetSubMaterial(mInx - 1, "aperture/paint/prop_paint")
	end
	
	ent:SetNWInt("TA:PaintType", paintType)
	ent:SetNWEntity("TA:PaintedModel", paint_model)
	
	LIB_APERTURE.GELLED_ENTITIES[ent] = v
end

function LIB_APERTURE:ClearPaintedEntity(ent)
	local paint_model =	ent:GetNWEntity("TA:PaintedModel")

	if not IsValid( paint_model ) then return end
	
	local paintType = ent:GetNWInt("TA:PaintType")
	local paintInfo = LIB_APERTURE.PAINT_TYPES[paintType]
	if paintInfo.OnEntityCleared then paintInfo:OnEntityCleared(ent) end
	
	LIB_APERTURE.GELLED_ENTITIES[ent] = nil
	paint_model:Remove()
	ent:SetNWInt("TA:PaintType", 0)
end

function LIB_APERTURE:MakePaintBlob(paintType, pos, velocity, radius)
	local color = LIB_APERTURE:PaintTypeToColor(paintType)
	local ent = ents.Create("ent_paint_blob")
	
	if not IsValid(ent) then return end
	ent:SetPos(pos)
	ent:SetMoveType(MOVETYPE_NONE)
	ent:Spawn()
	ent:SetColor(color)
	if paintType == PORTAL_PAINT_WATER then ent:SetMaterial("models/aperture/water_blob") end
	ent:GetPhysicsObject():SetVelocity(velocity)

	ent:SetPaintType(paintType)
	ent:SetPaintRadius(radius)
	
	return ent
end

local function ResolveWorldPaint(ply)

	-- assigning variables
	if ply:GetNWVector("TA:Orientation") == Vector() then ply:SetNWVector("TA:Orientation", ORIENTATION_DEFAULT) end
	if not ply:GetNWVector("TA:OrientationWalk") then ply:SetNWVector("TA:OrientationWalk", Vector(0, 0, 0)) end
	if not ply.TA_Player_PrevOrient then ply.TA_Player_PrevOrient = Angle() end
	if not ply.TA_LastTimeOnPaint then ply.TA_LastTimeOnPaint = 0 end
	
	local orientation 	= ply:GetNWVector("TA:Orientation")
	local eyeAngle 		= ply:EyeAngles()
	local dir 			= Vector()
	local playerWidth 	= ply:OBBMaxs().x
	local playerHeight 	= ply:GetModelRadius()
	
	-- Checking if player stands or hitting paint
	if LIB_APERTURE:IsPlayerOnGround(ply) or orientation != ORIENTATION_DEFAULT then 
		dir = -orientation * (playerHeight + 50)
	else
		local velocity = ply:GetVelocity()
		dir = (Vector(0, 0, -0.5) + velocity:GetNormalized()) * velocity:Length()
		if dir:Length() > playerHeight then dir = dir:GetNormalized() * playerHeight end
	end
	local paintType, paintNormal, paintHitPos = LIB_APERTURE:GetPaintInfo(ply:GetPos() + orientation * playerHeight / 2, dir)

	-- Getting player moving speed
	local speed = ply:GetWalkSpeed()
	if ply:KeyDown(IN_WALK) then speed = ply:GetWalkSpeed() / 2 end
	if ply:KeyDown(IN_SPEED) then speed = ply:GetRunSpeed() end
	speed = speed * FrameTime() * 50
	
	-- Getting player moving direction
	local moveDirection = Vector(0, 0, 0)
	if ply:KeyDown(IN_FORWARD) then moveDirection.x = 1 end
	if ply:KeyDown(IN_BACK) then moveDirection.x = -1 end
	if ply:KeyDown(IN_MOVELEFT) then moveDirection.y = 1 end
	if ply:KeyDown(IN_MOVERIGHT) then moveDirection.y = -1 end
	moveDirection:Normalize()
	
	-- Converting player moving direction in world orientation in to current orientation
	local plyOrientCenter = ply:GetPos() + orientation * playerHeight / 2
	local orientationAng = orientation:Angle() + Angle(90, 0, 0)
	local _, localangle = WorldToLocal(Vector(), eyeAngle, Vector(), orientationAng)
	localangle = Angle(0, localangle.yaw, 0)
	local _, worldangle = LocalToWorld(Vector(), localangle, Vector(), orientationAng)
	moveDirection:Rotate(worldangle)
	
	local orientationMove = moveDirection * speed / 50
	
	-- Checking for paint infront of player current position
	-- if doesn't found then tring to do this againg but with conner on floor
	local paintTypeFront, paintNormalFront, paintHitPosFront = LIB_APERTURE:GetPaintInfo(plyOrientCenter, moveDirection * playerWidth * 2)
	if not paintTypeFront then
		local traceForwardFloor = util.QuickTrace(ply:GetPos() + orientation * 5, moveDirection * playerWidth * 2, ply)
		local traceForwardFloorDown = util.QuickTrace(traceForwardFloor.HitPos, -orientation * 25, ply)
		
		paintTypeFront, paintNormalFront, paintHitPosFront = LIB_APERTURE:GetPaintInfo(traceForwardFloorDown.HitPos, -moveDirection * playerWidth * 2)
	end

	if paintTypeFront then
		paintType 		= paintTypeFront
		paintNormal 	= paintNormalFront
		paintHitPos 	= paintHitPosFront
	end
	
	local paintInfo = LIB_APERTURE.PAINT_TYPES[paintType]
	
	-- Handling player exiting paint
	local lastPaintType = ply.TA_LastPaintType
	local lastTimeOnPaint = ply.TA_LastTimeOnPaint
	
	if not paintType and lastPaintType and (lastTimeOnPaint and CurTime() > lastTimeOnPaint + 0.1) then
		local prevPaintInfo = LIB_APERTURE.PAINT_TYPES[ply.TA_LastPaintType]

		if prevPaintInfo.OnExit then prevPaintInfo:OnExit(ply, ply.TA_LastPaintNormal) end
		
		ply.TA_LastTimeOnPaint = nil
		ply.TA_LastPaintType = nil
		
		return
	end

	-- Skip if paint doesn't found
	if not paintType then return end
	LIB_MATH_TA:NormalFlipZeros(paintNormal)
	ply.TA_LastPaintNormal = paintNormal
	
	-- Handling player entering paint
	if LIB_APERTURE:IsPlayerOnGround(ply) or paintTypeFront then
		local lastPaintType = ply.TA_LastPaintType
		local lastTimeOnPaint = ply.TA_LastTimeOnPaint
		
		if lastPaintType != paintType and paintType and lastPaintType then
			local prevPaintInfo = LIB_APERTURE.PAINT_TYPES[lastPaintType]
			if prevPaintInfo.OnChangeFrom then prevPaintInfo:OnChangeFrom(ply, paintType, paintNormal) end
			if paintInfo.OnChangeTo then paintInfo:OnChangeTo(ply, lastPaintType, paintNormal) end
			ply.TA_LastPaintType = paintType
		end
		
		if (not lastPaintType or lastPaintType == PORTAL_PAINT_NONE) and (not lastTimeOnPaint or lastTimeOnPaint == 0) then
			if paintInfo.OnEnter then paintInfo:OnEnter(ply, paintNormal, paintHitPos) end
			ply.TA_LastPaintType = paintType
			ply.TA_LastTimeOnPaint = CurTime()
			
			return
		end
		
		ply.TA_LastTimeOnPaint = CurTime()
	end
	
	if LIB_APERTURE:IsPlayerOnGround(ply) then
		-- Paint Think
		if ply.TA_LastPaintType and ply.TA_LastTimeOnPaint then
			if paintInfo.Think then paintInfo:Think(ply, paintNormal, orientationMove) end
		end
		
		-- Handling orientation changing
		if orientation != paintNormal then
			if paintInfo.OnChangingOrientation then paintInfo:OnChangingOrientation(ply, orientation, paintNormal) end
		end
	else
		local mins, maxs = ply:GetPhysicsObject():GetAABB()
		
		local hitWall = util.TraceHull({
			start = ply:GetPos(),
			endpos = ply:GetPos() + ply:GetVelocity() / 100,
			filter = ent,
			mins = mins,
			maxs = maxs,
			mask = MASK_SHOT_HULL
		})
		
		if hitWall.Hit then
			local paintType, paintNormal, paintHitPos = LIB_APERTURE:GetPaintInfo(ply:GetPos() + Vector(0, 0, playerHeight), ply:GetVelocity():GetNormalized() * playerHeight)

			if paintType then
				local paintInfo = LIB_APERTURE.PAINT_TYPES[paintType]
				if paintInfo.OnLand then paintInfo:OnLand(ply, paintNormal) end
			end
		end
	end
end

local function ResolvePaintedEntities(ent)

	-- skip and remove if entity is not exist
	if not IsValid(ent) then
		LIB_APERTURE.GELLED_ENTITIES[k] = nil
		return
	end

	-- skip if props is freezed or it is holding by the player
	if IsValid(ent:GetPhysicsObject()) and not ent:GetPhysicsObject():IsMotionEnabled() or ent:IsPlayerHolding() then return end
	
	local vPhys = ent:GetPhysicsObject()
	local dir = vPhys:GetVelocity() / 10
	
	local trace = util.TraceEntity({
		start = ent:GetPos()
		, endpos = ent:GetPos() + dir
		, filter = ent 
	}, ent)

	-- if ent.GASL_GelledType == PORTAL_PAINT_BOUNCE then
		-- if trace.Hit then
			-- ent:EmitSound("GASL.GelBounceProp")
			-- -- makes negative z for local hitnormal
			-- local WTL = WorldToLocal(vPhys:GetVelocity(), Angle(), Vector(), trace.HitNormal:Angle() + Angle(90, 0, 0))
			-- WTL.z = math.max( -WTL.z, 400 )
			-- WTL = WTL + VectorRand() * 100
			-- local LTW = LocalToWorld(WTL, Angle(), Vector(), trace.HitNormal:Angle() + Angle(90, 0, 0))
			
			-- vPhys:SetVelocity(LTW)
			-- ent:GetPhysicsObject():AddAngleVelocity(VectorRand() * 400)
		-- end
	-- end
	
	-- if ent.GASL_GelledType == PORTAL_PAINT_STICKY then
		-- if trace.Hit and (not IsValid(trace.Entity) or IsValid(trace.Entity) and not IsValid(constraint.Find(ent, trace.Entity, "Weld", 0, 0))) then
			-- timer.Simple(dir:Length() / 1000, function()
				-- if IsValid(ent) and IsValid(ent:GetPhysicsObject()) then
					-- if trace.HitWorld then
						-- ent:GetPhysicsObject():EnableMotion( false )
					-- elseif IsValid(trace.Entity) then
						-- constraint.Weld(ent, trace.Entity, 0, trace.PhysicsBone, 5000, collision == 0, false)
					-- end
				-- end
			-- end )
		-- end
	-- end
end

hook.Add("Think", "TA:HandlingPaint", function()	
	-- Handling Player
	for i,ply in pairs(player.GetAll()) do
		ResolveWorldPaint(ply)
	end
	
	-- Handling paintled entities
	for k,v in pairs(LIB_APERTURE.GELLED_ENTITIES) do
		ResolvePaintedEntities(v)
	end
end)

hook.Add("PlayerFootstep", "TA:Paint_Footsteps", function(ply, pos, foot, lsound, volume)
	if not ply.TA_LastPaintType then return ply, pos, foot, lsound, volume end
	local orientation 	= ply:GetNWVector("TA:Orientation")
	local playerHeight 	= ply:GetModelRadius()
	
	sound.Play("TA:PaintFootsteps", ply:GetPos() + orientation * playerHeight)
	return true
end)

hook.Add("KeyPress", "TA:Paint_ButtonPressed", function(ply, key)
	if not ply.TA_LastPaintType then return end
	local paintInfo = LIB_APERTURE.PAINT_TYPES[ply.TA_LastPaintType]
	
	if paintInfo.OnButtonPressed then paintInfo:OnButtonPressed(ply, ply.TA_LastPaintNormal, key) end
end)

hook.Add("OnPlayerHitGround", "TA:Paint_OnPlayerHitGround", function(ply, inwater, onFloater, speed)
	local paintType, paintNormal, paintHitPos = LIB_APERTURE:GetPaintInfo(ply:GetPos(), ply:GetVelocity())
	if not paintType then return ply, inwater, onFloater, 0 end
	
	local paintInfo = LIB_APERTURE.PAINT_TYPES[paintType]
	if paintInfo.OnLanding then paintInfo:OnLanding(ply, paintNormal, speed) end
	return ply, inwater, onFloater, 0
end)

hook.Add("GetFallDamage", "TA:Paint_GetFallDamage", function(ply, speed)
	local paintType, paintNormal, paintHitPos = LIB_APERTURE:GetPaintInfo(ply:GetPos(), ply:GetVelocity())
	if not paintType then return end
	
	local paintInfo = LIB_APERTURE.PAINT_TYPES[paintType]
	if paintInfo.OnGetFallDamage then return paintInfo:OnGetFallDamage(ply, speed) end
end)