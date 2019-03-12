--[[

	APERTURE API PAINT
	
]]
AddCSLuaFile( )

LIB_PAINT = {}

local CHUNK_RADIUS = 512
local CHUNK_THINKNESS = 5
local TEXTURE_SIZE = 64

local TEXTURE_FLAGS_CLAMP_S = 0x0004
local TEXTURE_FLAGS_CLAMP_T = 0x0008
local TEXTURE_FLAGS_NORMAL_MAP = 0x0080
local TEXTURE_FLAGS_ANISOTROPIC_SAMPLING = 0x0010
local TEXTURE_FLAGS_NO_LEVEL_OF_DETAIL = 0x0200

local PAINTCHUNKS = { }
local CANPAINT = { }
local PAINTFLOW = { }

LIB_PAINT.PAINT_INFO_SIZE = 16
LIB_PAINT.PAINT_INFO = { }

-- Set angle to zero if angle close to zero
local function AngleToZeroz(angle)
	if math.abs(angle.p) < 0.0001 then angle.p = 0 end
	if math.abs(angle.y) < 0.0001 then angle.y = 0 end
	if math.abs(angle.r) < 0.0001 then angle.r = 0 end
end

local function ConvertToGrid(pos, gridSize)
	local gridPos = Vector(
		math.Round(pos.x / gridSize) * gridSize, 
		math.Round(pos.y / gridSize) * gridSize, 
		math.Round(pos.z / gridSize) * gridSize)
		
	return gridPos
end

local function NormalFlipZeros(normal)
	local lower = 0.000001
	if math.abs(normal.x) < lower then normal.x = 0 end
	if math.abs(normal.y) < lower then normal.y = 0 end
	if math.abs(normal.z) < lower then normal.z = 0 end
end

-- Converting coordinate to grid ignoring z on normal
local function ConvertToGridOnSurface(pos, angle, radius, zRound)

	local WTL = WorldToLocal(pos, Angle( ), Vector( ), angle)

	if zRound == 0 then
		WTL = Vector(math.Round(WTL.x / radius) * radius, math.Round(WTL.y / radius) * radius, WTL.z)
	else
		WTL = Vector(math.Round(WTL.x / radius) * radius, math.Round(WTL.y / radius) * radius, math.Round(WTL.z / zRound) * zRound)
	end
	pos = LocalToWorld(WTL, Angle( ), Vector( ), angle)
	
	return pos
end

-- checking for gel info
function LIB_PAINT:GetCellPaintInfo(pos)
	if not LIB_PAINT.PAINT_INFO[pos.x] or not LIB_PAINT.PAINT_INFO[pos.x][pos.y] or not LIB_PAINT.PAINT_INFO[pos.x][pos.y][pos.z] then return nil end
	return LIB_PAINT.PAINT_INFO[pos.x][pos.y][pos.z]
end

function LIB_PAINT:GetPaintInfo(start, direction)
	local trace = util.TraceLine({
		start = start,
		endpos = start + direction,
		collisiongroup = COLLISION_GROUP_DEBRIS,
		filter = function(ent) if ent:GetClass() == "env_portal_wall" then return true end end
	})
	local normal = trace.HitNormal
	NormalFlipZeros(normal)
	local gridPos = ConvertToGrid(trace.HitPos, LIB_PAINT.PAINT_INFO_SIZE)
	local paintInfo = LIB_PAINT:GetCellPaintInfo(gridPos)
	
	if paintInfo and normal == paintInfo.normal then
		return paintInfo, trace.HitPos
	else
		return nil, trace.HitPos
	end
end

local function ConvertToUVPos(pos, paintPos, normalAngle)
	local localPos = WorldToLocal(pos, Angle(), paintPos, normalAngle)
	local chunkTextRatio = (CHUNK_RADIUS / TEXTURE_SIZE)
	localPos.x = localPos.x + CHUNK_RADIUS / 2
	localPos.y = localPos.y + CHUNK_RADIUS / 2
	localPos = localPos / chunkTextRatio

	return localPos
end

local function CheckForPossiblePlacement(uvX, uvY, chunkPos, paintPos, offset, normal)
	local pos = paintPos + offset
	
	local trace = util.TraceLine({
		start = pos + normal,
		endpos = pos - normal,
		collisiongroup = COLLISION_GROUP_DEBRIS,
		filter = function(ent) if IsValid(ent) and ent:GetClass() == "env_portal_wall" then return true end end
	})
	
	if trace.Hit and trace.Fraction > 0 then
		CANPAINT[chunkPos.x.."_"..chunkPos.y.."_"..chunkPos.z][uvX.."_"..uvY] = 1
		return 1
	else
		CANPAINT[chunkPos.x.."_"..chunkPos.y.."_"..chunkPos.z][uvX.."_"..uvY] = 0
		return 0
	end
end
-- Painting on texture
local function PaintTexture(texture, UVpos, chunkPos, paintPos, normal, paintDat, clear)

	local w, h 				= ScrW(), ScrH()
	local color 			= paintDat.color
	local normalAngle 		= normal:Angle() + Angle(90, 0, 0)
	AngleToZeroz(normalAngle)
	local chunkTextRatio 	= CHUNK_RADIUS / TEXTURE_SIZE
	local radiusDivided 	= paintDat.radius / chunkTextRatio
	local canpaint 			= CANPAINT[chunkPos.x.."_"..chunkPos.y.."_"..chunkPos.z]
	local rendertarget_old 	= render.GetRenderTarget()
	
	render.SetRenderTarget(texture)
		render.ClearDepth()
		
		render.SetViewPort(0, 0, CHUNK_RADIUS, CHUNK_RADIUS)
		cam.Start2D()
			surface.SetDrawColor(color.r, color.g, color.b, color.a)
			if not canpaint then
				CANPAINT[chunkPos.x.."_"..chunkPos.y.."_"..chunkPos.z] = { }
				canpaint = { }
			end
			local offsetX = Vector(1, 0 ,0)
			local offsetY = Vector(0, 1, 0)
			offsetX:Rotate(normalAngle)
			offsetY:Rotate(normalAngle)
			
			for x = -radiusDivided, radiusDivided do
			for y = -radiusDivided, radiusDivided do
				if Vector(x, y):Distance(Vector(0, 0)) < radiusDivided * math.Rand(paintDat.hardness, 1) then
					local uvX, uvY = math.Round(UVpos.y + x), math.Round(UVpos.x + y)
					if uvX >= 0 and uvY >= 0 and uvX <= TEXTURE_SIZE and uvY <= TEXTURE_SIZE then
						local canpaintChunk = canpaint[uvX.."_"..uvY]
						
						local uvToworld = UVpos * chunkTextRatio
						local wX,wY = x * chunkTextRatio, y * chunkTextRatio
						uvToworld.x = uvToworld.x - CHUNK_RADIUS / 2
						uvToworld.y = uvToworld.y - CHUNK_RADIUS / 2
						local offset = offsetX * (uvToworld.x + wY) + offsetY * (uvToworld.y + wX)
						
						-- Creating client paint info
						local point = paintPos + offset
						local cellPos = ConvertToGrid(point, LIB_PAINT.PAINT_INFO_SIZE)
						local paintInfo = LIB_PAINT:GetCellPaintInfo(cellPos)
						if not paintInfo or paintInfo.paintType != paintDat.paintType then
							if not clear then
								if not LIB_PAINT.PAINT_INFO[cellPos.x] then LIB_PAINT.PAINT_INFO[cellPos.x] = {} end
								if not LIB_PAINT.PAINT_INFO[cellPos.x][cellPos.y] then LIB_PAINT.PAINT_INFO[cellPos.x][cellPos.y] = {} end
							end
							
							if clear then
								if LIB_PAINT.PAINT_INFO[cellPos.x] and LIB_PAINT.PAINT_INFO[cellPos.x][cellPos.y] then
									LIB_PAINT.PAINT_INFO[cellPos.x][cellPos.y][cellPos.z] = nil
								end
							else
								LIB_PAINT.PAINT_INFO[cellPos.x][cellPos.y][cellPos.z] = {paintType = paintDat.paintType, normal = normal}
							end
						end
						
						if not canpaintChunk then
							canpaintChunk = CheckForPossiblePlacement(uvX, uvY, chunkPos, paintPos, offset, normal)
						end
						
						-- Drawing or clearing texture
						if canpaintChunk == 1 then
							local uvX, uvY = UVpos.y + x, UVpos.x + y
							if clear then
								render.SetScissorRect(uvX, uvY, uvX + 1, uvY + 1, true)
								render.Clear(0, 0, 0, 0)
								render.SetScissorRect(0, 0, 0, 0, false)
							else
								surface.DrawRect(uvX, uvY, 1, 1)
							end
						end
					end
				end
			end
			end
		cam.End2D()
		render.SetViewPort(0, 0, w, h)
	render.SetRenderTarget(rendertarget_old)
end

local function CreatePaintTexture()
	local id = table.Count(PAINTCHUNKS)
	
	local texture = GetRenderTargetEx("temp_paint_texture_"..id,
		TEXTURE_SIZE, TEXTURE_SIZE,
		RT_SIZE_NO_CHANGE,
		MATERIAL_RT_DEPTH_SEPARATE,
		bit.bor(TEXTURE_FLAGS_CLAMP_S, TEXTURE_FLAGS_CLAMP_T),
		CREATERENDERTARGETFLAGS_HDR,
		IMAGE_FORMAT_RGBA8888
	)
	
	local material = CreateMaterial("temp_paint_material_"..id, "VertexLitGeneric", {
		["$vertexcolor"] = 1,
		["$vertexalpha"] = 1,
		["$envmaptint"] = "[.5 .5 .5]",
		["$envmap"] = "env_cubemap",
		["$bumpmap"] = "paint_bubbles_normal",
		["$detailscale"] = 1,
		["$basetexture"] = texture:GetName()
	})
	
	-- clearing background
	local rendertarget_old = render.GetRenderTarget()
	render.SetRenderTarget(texture)
	render.Clear(0, 0, 0, 0)
	render.SetRenderTarget(rendertarget_old)
	
	return texture, material
end

-- Painting chunk and contiguous chunks
local function PaintChunk(pos, chunkPos, paintPos, normal, paintDat, clear)

	local normalAngle = normal:Angle() + Angle(90, 0, 0)
	AngleToZeroz(normalAngle)
	if chunkPos == nil then chunkPos = ConvertToGridOnSurface(pos, normalAngle, CHUNK_RADIUS, CHUNK_THINKNESS) end
	if paintPos == nil then paintPos = ConvertToGridOnSurface(pos, normalAngle, CHUNK_RADIUS, 0) end
	
	if not PAINTCHUNKS[chunkPos.x.."_"..chunkPos.y.."_"..chunkPos.z] then
		if clear then return end
		
		-- creating new paint texture
		local texture, material = CreatePaintTexture()
		
		local UVpos = ConvertToUVPos(pos, paintPos, normalAngle)
		PaintTexture(texture, UVpos, chunkPos, paintPos, normal, paintDat, clear)
		
		util.PrecacheModel("models/aperture/paint_plane.mdl")
		local c_Model = ClientsideModel("models/aperture/paint_plane.mdl")
		c_Model:SetPos(paintPos + normal)
		c_Model:SetAngles(normalAngle)
		c_Model:Spawn()
		c_Model:SetNoDraw(true)
		c_Model:SetMaterial("!"..material:GetName(), false)
		
		PAINTCHUNKS[chunkPos.x.."_"..chunkPos.y.."_"..chunkPos.z] = {
			texture = texture,
			mat = material,
			pos = paintPos,
			normal = normal,
			ent = c_Model,
		}
		
		local scale = Vector(CHUNK_RADIUS / 2, CHUNK_RADIUS / 2, 1)
		local mat = Matrix()
		mat:Scale(scale)
		c_Model:EnableMatrix("RenderMultiply", mat)
		c_Model:SetRenderBounds(-Vector(CHUNK_RADIUS, CHUNK_RADIUS, 1), Vector(CHUNK_RADIUS, CHUNK_RADIUS, 1)) 

	else
		local Chunk = PAINTCHUNKS[chunkPos.x.."_"..chunkPos.y.."_"..chunkPos.z]
		local UVpos = ConvertToUVPos(pos, paintPos, normalAngle)
		
		PaintTexture(Chunk.texture, UVpos, chunkPos, paintPos, normal, paintDat, clear)
	end
end

local function PaintSurface(pos, surfacePos, normal, paintDat, clear)
	local normalAngle = normal:Angle() + Angle(90, 0, 0)
	AngleToZeroz(normalAngle)
	local chunkPos = ConvertToGridOnSurface(surfacePos, normalAngle, CHUNK_RADIUS, CHUNK_THINKNESS)
	local paintPos = ConvertToGridOnSurface(surfacePos, normalAngle, CHUNK_RADIUS, 0)
	PaintChunk(pos, chunkPos, paintPos, normal, paintDat, clear)
	for i=0,3 do
		local offset = Vector()
		if i == 0 then offset = Vector(1, 1, 0) end
		if i == 1 then offset = Vector(-1, 1, 0) end
		if i == 2 then offset = Vector(1, -1, 0) end
		if i == 3 then offset = Vector(-1, -1, 0) end
		offset = offset * paintDat.radius
		offset:Rotate(normalAngle)
		
		if chunkPos != ConvertToGridOnSurface(surfacePos + offset, normalAngle, CHUNK_RADIUS, CHUNK_THINKNESS) then
			local chnkPos = ConvertToGridOnSurface(surfacePos + offset, normalAngle, CHUNK_RADIUS, CHUNK_THINKNESS)
			local pntPos = ConvertToGridOnSurface(surfacePos + offset, normalAngle, CHUNK_RADIUS, 0)
			PaintChunk(pos, chnkPos, pntPos, normal, paintDat, clear)
		end
	end
end

local function BroadCastPaint(pos, surfacePos, normal, paintDat, clear)
	net.Start("PaintL:Network")
		net.WriteVector(pos)
		net.WriteVector(surfacePos)
		net.WriteFloat(normal.x)
		net.WriteFloat(normal.y)
		net.WriteFloat(normal.z)
		net.WriteTable(paintDat)
		net.WriteBool(clear)
	net.Broadcast()
end

net.Receive("PaintL:Network", function()
	local pos = net.ReadVector()
	local surfacePos = net.ReadVector()
	local normalX = net.ReadFloat()
	local normalY = net.ReadFloat()
	local normalZ = net.ReadFloat()
	local normal = Vector(normalX, normalY, normalZ)
	local paintDat = net.ReadTable()
	local clear = net.ReadBool()
	
	PaintSurface(pos, surfacePos, normal, paintDat, clear)
end )

local function PaintOnSurface(pos, surfacePos, normal, paintDat, clear)

	if CLIENT then return end
	BroadCastPaint(pos, surfacePos, normal, paintDat, clear)
	
	if paintDat.viscosity then
		local viscosity = paintDat.viscosity
		paintDat.viscosity = nil
		
		local normalXY = Vector(normal.x, normal.y, 0):GetNormalized()
		local angle = 1 - math.acos(normalXY:Dot(normal)) / (math.pi / 2)
		local direction = paintDat.direction and -paintDat.direction or normal:Angle():Up()
		local time = paintDat.direction and CurTime() + 0.25 or CurTime() + angle * 0.25
		
		if direction.z >= 0 then
			table.insert(PAINTFLOW, table.Count(PAINTFLOW) + 1, {
				viscosity = viscosity,
				direction = direction,
				time = time,
				pos = pos,
				surfacePos = surfacePos,
				normal = normal,
				paintDat = paintDat,
				clear = clear
			})
		end
	end
	
	local offsetX = Vector(1, 0 ,0)
	local offsetY = Vector(0, 1, 0)
	offsetX:Rotate(normal:Angle() + Angle(90, 0, 0))
	offsetY:Rotate(normal:Angle() + Angle(90, 0, 0))
	
	local radcell = paintDat.radius / LIB_PAINT.PAINT_INFO_SIZE
	for x=-radcell,radcell do
	for y=-radcell,radcell do
		if Vector(x, y):Distance(Vector(0, 0)) < radcell then
			local offset = (offsetX * x + offsetY * y) * LIB_PAINT.PAINT_INFO_SIZE
			local point = surfacePos + offset
			local cellPos = ConvertToGrid(point, LIB_PAINT.PAINT_INFO_SIZE)
			local paintInfo = LIB_PAINT:GetCellPaintInfo(cellPos)
			
			NormalFlipZeros(normal)
			local trace = util.TraceLine({
				start = point + normal, 
				endpos = point - normal,
				collisiongroup = COLLISION_GROUP_DEBRIS,
				filter = function(ent) if IsValid(ent) and ent:GetClass() == "env_portal_wall" then return true end end
			})
			
			if clear or trace.Hit and (not paintInfo or paintInfo.paintType != paintDat.paintType) then
				if not LIB_PAINT.PAINT_INFO[cellPos.x] then LIB_PAINT.PAINT_INFO[cellPos.x] = {} end
				if not LIB_PAINT.PAINT_INFO[cellPos.x][cellPos.y] then LIB_PAINT.PAINT_INFO[cellPos.x][cellPos.y] = {} end
				
				if clear then
					LIB_PAINT.PAINT_INFO[cellPos.x][cellPos.y][cellPos.z] = nil
				else
					LIB_PAINT.PAINT_INFO[cellPos.x][cellPos.y][cellPos.z] = {paintType = paintDat.paintType, normal = normal}
				end
			end
		end
	end
	end
end

function LIB_PAINT:PaintSplat(pos, paintDat, clear)

	local usedChunks = {}
	local deltaTheta = math.pi / 12;
	local deltaPhi = 2 * math.pi / 10;
	local theta = 0
	local phi = 0
	
	local radius = paintDat.radius
	
	for i=0,9 do
		theta = theta + deltaTheta
		for j=0,9 do
			phi = phi + deltaPhi
			x = math.sin(theta) * math.cos(phi)
			y = math.sin(theta) * math.sin(phi)
			z = math.cos(theta)
			
			local trace = util.TraceLine({
				start = pos, 
				endpos = pos + Vector(x, y, z) * radius,
				collisiongroup = COLLISION_GROUP_DEBRIS,
				filter = function(ent) if IsValid(ent) and ent:GetClass() == "env_portal_wall" then return true end end
			})
			
			if trace.HitWorld or IsValid(trace.Entity) and trace.Entity:GetClass() == "env_portal_wall" then
				local normalAngle = trace.HitNormal:Angle() + Angle(90, 0, 0)
				local chunkPos = ConvertToGridOnSurface(trace.HitPos, normalAngle, CHUNK_RADIUS, CHUNK_THINKNESS)
				
				if not usedChunks[chunkPos.x.."_"..chunkPos.y.."_"..chunkPos.z] then
					
					local LocalPos = WorldToLocal(pos, Angle(), trace.HitPos, normalAngle)
					local Fraction = LocalPos.z / radius
					paintDat.radius = radius * math.cos(Fraction * (math.pi / 2))
					PaintOnSurface(pos, trace.HitPos, trace.HitNormal, paintDat, clear)
					usedChunks[chunkPos.x.."_"..chunkPos.y.."_"..chunkPos.z] = true
				end
			end
		end
	end
end

hook.Add("Initialize", "PaintL:Initialize", function()

	if SERVER then
		util.AddNetworkString("PaintL:Network")
		
		-- no more server side
		return true
	end
	
	-- Creating temperary normalmap texture
	local genBumpmapSize = CHUNK_RADIUS * 8
	
	local genBumpTexture = GetRenderTargetEx("paint_bubbles_normal",
		genBumpmapSize, genBumpmapSize,
		RT_SIZE_FULL_FRAME_BUFFER,
		MATERIAL_RT_DEPTH_SEPARATE,
		bit.bor(TEXTURE_FLAGS_NORMAL_MAP, TEXTURE_FLAGS_ANISOTROPIC_SAMPLING, TEXTURE_FLAGS_NO_LEVEL_OF_DETAIL),
		CREATERENDERTARGETFLAGS_HDR,
		IMAGE_FORMAT_BGR888
	)
	
	local bumpMat = CreateMaterial("paintbubbles_normal", "UnlitGeneric", {
		["$basetexture"] = "aperture/paint/paint_bump"
	})
	
	-- Rendering of normalmap texture
	local w, h = ScrW(), ScrH()
	local rendertarget_old = render.GetRenderTarget()
	render.SetRenderTarget(genBumpTexture)
	render.Clear(0, 0, 0, 0)
	render.ClearDepth()
	render.ClearBuffersObeyStencil(255, 255, 255, 255, true) 
	
	render.SetViewPort(0, 0, genBumpmapSize, genBumpmapSize)
	cam.Start2D()
		local bumpmapSize = 512
		local textID = surface.GetTextureID("paint/gelmap");

		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetTexture( textID )
		
		for x=0,math.floor(genBumpmapSize / bumpmapSize) - 1 do
		for y=0,math.floor(genBumpmapSize / bumpmapSize) - 1 do
			surface.SetMaterial(bumpMat)
			surface.DrawTexturedRect( x * bumpmapSize, y * bumpmapSize, bumpmapSize, bumpmapSize )
		end
		end
	cam.End2D()
	render.SetViewPort(0, 0, w, h)

	render.SetRenderTarget(rendertarget_old)

end)

hook.Add("PreDrawOpaqueRenderables", "PaintL:Renderer", function()
	render.SetColorMaterial()
	render.SetColorModulation(1, 1, 1) 
	for k,v in pairs(PAINTCHUNKS) do
		v.ent:DrawModel()
		if LocalPlayer():FlashlightIsOn() then
			render.PushFlashlightMode(true)
			v.ent:DrawModel()
			render.PopFlashlightMode()
		end
	end
end)

hook.Add("PreCleanupMap", "PaintL:Cleanup", function()
	for k,v in pairs(PAINTCHUNKS) do v.ent:Remove() end
	
	-- clearing data
	PAINTCHUNKS = {}
	CANPAINT = {}
	PAINTFLOW = {}
	LIB_PAINT.PAINT_INFO = {}
end)

hook.Add("Think", "PaintL:Think", function()
	if CLIENT then return end
	if not timer.Exists("PaintL:FlowUpdate") then
		for k,v in pairs(PAINTFLOW) do
		
			if CurTime() > v.time then
				PAINTFLOW[k] = nil
			else
				local offset = v.direction * v.viscosity * 40
				local pos = v.pos - offset
				local surfacePos = v.surfacePos - offset
				PAINTFLOW[k].pos = pos
				PAINTFLOW[k].surfacePos = surfacePos
				PaintOnSurface(pos, surfacePos, v.normal, v.paintDat, v.clear)
			end
		end
		
		timer.Create("PaintL:FlowUpdate", 0.05, 1, function() end)
	end
end)

-- hook.Add("Think", "PaintTest", function()
	-- if CLIENT then return end
	-- for k,v in pairs(player.GetAll()) do
		-- if !timer.Exists("PlyPaint"..k) && (v:KeyDown(IN_RELOAD) || v:KeyDown(IN_USE)) then
			-- --if v:KeyDown(IN_RELOAD) then BroadCastPaint(v:GetEyeTrace().HitPos, 100, Color(50, 125, 255), v:GetEyeTrace().HitPos, v:GetEyeTrace().HitNormal) end
			-- --if v:KeyDown(IN_USE) then PaintSplat(v:GetEyeTrace().HitPos + v:GetEyeTrace().HitNormal * 0, 25, Color(255, 125, 0, 255)) end
			-- --timer.Create("PlyPaint"..k, 1, 1, function() end)
		-- end
		-- --local a, b = LIB_PAINT.GetPaintInfo(v:GetPos(), Vector(0, 0, -100))
		-- --PrintTable(a)
	-- end

-- end )
