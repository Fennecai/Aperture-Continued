AddCSLuaFile()

if not LIB_APERTURE then return end

--============= Repulsion Gel ==============
if not PORTAL_PAINT_BOUNCE then
	PORTAL_PAINT_BOUNCE = PORTAL_PAINT_COUNT + 1
end
local PAINT_INFO = {}

PAINT_INFO.COLOR 	= Color(50, 135, 355)
PAINT_INFO.NAME		= "Repulsion" 

if SERVER then

local function Bounce(ply, normal)
	ply:SetVelocity(normal * 400)
	ply:EmitSound("TA:PlayerBounce")
end

-- When player step in paint
function PAINT_INFO:OnEnter(ply, normal)
	if LIB_MATH_TA:DegreeseBetween(normal, ORIENTATION_DEFAULT) > 35 then return end
	
	ply:EmitSound("TA:PaintBounceEnter")
end

-- When player step out paint
function PAINT_INFO:OnExit(ply, normal)
	if LIB_MATH_TA:DegreeseBetween(normal, ORIENTATION_DEFAULT) > 35 then return end
	
	ply:EmitSound("TA:PaintBounceExit")
end

-- When player step from other type to this
function PAINT_INFO:OnChangeTo(ply, oldType, normal)
	if oldType == PORTAL_PAINT_STICKY then Bounce(ply, normal) return end
	if LIB_MATH_TA:DegreeseBetween(normal, ORIENTATION_DEFAULT) > 35 then return end
	if oldType == PORTAL_PAINT_SPEED and ply:GetVelocity():Length() > 1000 then Bounce(ply, normal) end
end

-- When player step from this type to other
function PAINT_INFO:OnChangeFrom(ply, newType, normal)
end

-- Handling player landing
function PAINT_INFO:OnLanding(ply, normal, speed)
	local plyVelocity = ply:GetVelocity()
	
	-- skip if player stand on the ground
	-- doesn't skip if player ran on repulsion paint when he was on propulsion paint
	if not ply:KeyDown(IN_DUCK) then
		local worldVelToLocalPaint = WorldToLocal(plyVelocity, Angle(), Vector(), normal:Angle() + Angle(90, 0, 0))
		worldVelToLocalPaint = Vector(0, 0, math.max(math.abs(worldVelToLocalPaint.z), 400))
		local velocity = LocalToWorld(worldVelToLocalPaint, Angle(), Vector(), normal:Angle() + Angle(90, 0, 0))
		velocity.z = math.max(200, velocity.z / 2)
		
		ply:SetVelocity(velocity + Vector(0, 0, velocity.z))
		ply:EmitSound("TA:PlayerBounce")
	end
end

function PAINT_INFO:OnLand(ply, normal)
	local plyVelocity = ply:GetVelocity()
	
	-- skip if player stand on the ground
	-- doesn't skip if player ran on repulsion paint when he was on propulsion paint
	if not ply:KeyDown(IN_DUCK) then
		local worldVelToLocalPaint = WorldToLocal(plyVelocity, Angle(), Vector(), normal:Angle() + Angle(90, 0, 0))
		worldVelToLocalPaint.z = math.max(math.abs(worldVelToLocalPaint.z), 400)
		local velocity = LocalToWorld(worldVelToLocalPaint, Angle(), Vector(), normal:Angle() + Angle(90, 0, 0))
		velocity.z = math.max(300, velocity.z / 2)
		
		ply:SetVelocity(velocity / 1.2 - ply:GetVelocity())
		ply:EmitSound("TA:PlayerBounce")
	end
end

-- Handling fall damage
function PAINT_INFO:OnGetFallDamage(ply, speed)
	-- Fall damage reduction to zero
	return 0
end

-- Handling key presses
function PAINT_INFO:OnButtonPressed(ply, normal, key)
	if LIB_MATH_TA:DegreeseBetween(normal, ORIENTATION_DEFAULT) > 35 then return end
	
	if key == IN_JUMP then Bounce(ply, normal) end
end

-- Handling entity paint
function PAINT_INFO:OnEntityPainted(ent)
	if not IsValid(ent) then return end
	if not IsValid(ent:GetPhysicsObject()) then return end
	
	local inx = ent:AddCallback("PhysicsCollide", function(ent, colData, collider)
		if not IsValid(ent) then return end
		if not IsValid(colData.PhysObject) then return end
		if colData.DeltaTime < 0.1 then return end
		local physObj = colData.PhysObject
		local vel = colData.OurOldVelocity
		local normal = -colData.HitNormal
		
		local worldVelToLocalPaint = WorldToLocal(vel, Angle(), Vector(), normal:Angle() + Angle(90, 0, 0))
		worldVelToLocalPaint.z = math.max(math.abs(worldVelToLocalPaint.z), 400)
		local velocity = LocalToWorld(worldVelToLocalPaint, Angle(), Vector(), normal:Angle() + Angle(90, 0, 0))
		
		-- adding random to prop bounce
		local velLength = velocity:Length()
		velocity:Normalize()
		velocity = velocity * 3 + VectorRand()
		velocity:Normalize()
		velocity = velocity * velLength
		
		physObj:SetVelocity(velocity)
		ent:EmitSound("TA:BounceProp")
	end)
	ent.TA_BPhysCollideCallbackInxed = inx
end

-- Handling entity clear
function PAINT_INFO:OnEntityCleared(ent)
	if ent.TA_BPhysCollideCallbackInxed then
		ent:RemoveCallback("PhysicsCollide", ent.TA_BPhysCollideCallbackInxed)
	end
end

function PAINT_INFO:OnEntityChangedTo(ent, paintType)
	PAINT_INFO:OnEntityPainted(ent)
end

function PAINT_INFO:OnEntityChangedFrom(ent, paintType)
	PAINT_INFO:OnEntityCleared(ent)
end

-- Handling painted entity
function PAINT_INFO:EntityThink(ent)
end

end -- SERVER

LIB_APERTURE:CreateNewPaintType(PORTAL_PAINT_BOUNCE, PAINT_INFO)
