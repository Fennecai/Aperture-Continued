AddCSLuaFile()

if not LIB_APERTURE then return end

--============= Propulsion Gel ==============

PORTAL_PAINT_SPEED = PORTAL_PAINT_COUNT + 1

local PAINT_INFO = {}

PAINT_INFO.COLOR 	= Color(255, 100, 0)
PAINT_INFO.NAME		= "Propulsion" 

if SERVER then

-- When player step in paint
function PAINT_INFO:OnEnter(ply, normal)
	ply:EmitSound("TA:PaintSpeedEnter")
	
	ply:SetNWInt("TA:PlayerWalkSpeed", ply:GetWalkSpeed())
	ply:SetNWInt("TA:PlayerRunSpeed", ply:GetRunSpeed())
end

-- When player step out paint
function PAINT_INFO:OnExit(ply, normal)
	ply:EmitSound("TA:PaintSpeedExit")
	
	ply:SetWalkSpeed(ply:GetNWInt("TA:PlayerWalkSpeed"))
	ply:SetRunSpeed(ply:GetNWInt("TA:PlayerRunSpeed"))
end

-- When player step from other type to this
function PAINT_INFO:OnChangeTo(ply, oldType, normal)
	PAINT_INFO:OnEnter(ply)
end

-- When player step from this type to other
function PAINT_INFO:OnChangeFrom(ply, newType, normal)
	PAINT_INFO:OnExit(ply)
end

-- Handling paint
function PAINT_INFO:Think(ply, normal)
	local speed = math.max(400, math.min(1000, ply:GetVelocity():Length() * 101 * FrameTime()))
	ply:SetWalkSpeed(speed)
	ply:SetRunSpeed(speed)
end

-- When entity become painted
function PAINT_INFO:OnEntityPainted(ent)
	-- Making entity slippery
	local physObj = ent:GetPhysicsObject()
	if not IsValid(physObj) then return end

	ent:SetNWString("TA:EntPhysMaterial", physObj:GetMaterial())
	physObj:SetMaterial("gmod_ice")
end

-- When entity become clear
function PAINT_INFO:OnEntityCleared(ent)
	-- Making entity normal
	local matType = ent:GetNWString("TA:EntPhysMaterial")
	local physObj = ent:GetPhysicsObject()
	if not IsValid(physObj) then return end
	physObj:SetMaterial(matType)
end

-- When entity changed paint type to this
function PAINT_INFO:OnEntityChangedTo(ent, oldType)
	PAINT_INFO:OnEntityPainted(ent)
end

-- When entity changed paint type from this
function PAINT_INFO:OnEntityChangedFrom(ent, newType)
	PAINT_INFO:OnEntityCleared(ent)
end

-- Handling painted entity
function PAINT_INFO:EntityThink(ent)
end

end -- SERVER

LIB_APERTURE:CreateNewPaintType(PORTAL_PAINT_SPEED, PAINT_INFO)
