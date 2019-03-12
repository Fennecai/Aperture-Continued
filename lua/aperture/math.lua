AddCSLuaFile()

LIB_MATH_TA = {}
LIB_MATH_TA.EPSILON = 0.00001
LIB_MATH_TA.HUGE = 100000

-- Converting coordinate to grid ignoring z on normal
function LIB_MATH_TA:SnapToGridOnSurface(pos, angle, radius, zRound)
	local localpos = WorldToLocal(pos, Angle(), Vector(), angle)
	local lx = math.Round(localpos.x / radius) * radius
	local ly = math.Round(localpos.y / radius) * radius
	local lz = (not zRound or zRound == 0) and localpos.z or math.Round(localpos.z / zRound) * zRound
	localpos = Vector(lx, ly, lz)
	
	return LocalToWorld(localpos, Angle(), Vector(), angle)
end

-- Fixing Mins and Maxs
function LIB_MATH_TA:FixMinMax(min, max)
	local smin = Vector(min)
	local smax = Vector(max)
	
	if min.x > max.x then min.x = smax.x  max.x = smin.x end
	if min.y > max.y then min.y = smax.y  max.y = smin.y end
	if min.z > max.z then min.z = smax.z  max.z = smin.z end
end

-- Converting vector to a grid
function LIB_MATH_TA:ConvertToGrid(pos, size)
	local gridPos = Vector(
		math.Round(pos.x / size) * size, 
		math.Round(pos.y / size) * size, 
		math.Round(pos.z / size) * size)
		
	return gridPos
end

-- if angles angle less then EPSILON equal that angle to zero
function LIB_MATH_TA:AnglesToZeroz(angle)
	if math.abs(angle.p) < LIB_MATH_TA.EPSILON then angle.p = 0 end
	if math.abs(angle.y) < LIB_MATH_TA.EPSILON then angle.y = 0 end
	if math.abs(angle.r) < LIB_MATH_TA.EPSILON then angle.r = 0 end
end

-- if normal coordinate less then EPSILON equal that coordinate to zero
function LIB_MATH_TA:NormalFlipZeros(normal)
	if math.abs(normal.x) < LIB_MATH_TA.EPSILON then normal.x = 0 end
	if math.abs(normal.y) < LIB_MATH_TA.EPSILON then normal.y = 0 end
	if math.abs(normal.z) < LIB_MATH_TA.EPSILON then normal.z = 0 end
end

-- return degreese between two vectors
function LIB_MATH_TA:DegreeseBetween(vector1, vector2)
	LIB_MATH_TA:NormalFlipZeros(vector1)
	LIB_MATH_TA:NormalFlipZeros(vector2)
	
	if vector1 == vector2 then return 0 end
	local dot = vector1:Dot(vector2)
	return math.deg(math.acos(dot))
end