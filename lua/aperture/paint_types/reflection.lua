AddCSLuaFile()

if not LIB_APERTURE then return end

--============= Repulsion Gel ==============

PORTAL_PAINT_REFLECTION = PORTAL_PAINT_COUNT + 1

local PAINT_INFO = {}

PAINT_INFO.COLOR 	= Color(255, 255, 255)
PAINT_INFO.NAME		= "Reflection" 

if SERVER then

-- When player step in paint
function PAINT_INFO:OnEnter(ply, normal)
	ply:EmitSound("GASL.GelBounceEnter")
end

-- When player step out paint
function PAINT_INFO:OnExit(ply)
	ply:EmitSound("GASL.GelBounceExit")
end

-- When player step from other type to this
function PAINT_INFO:OnChangeTo(ply, oldType, normal)
end

-- When player step from this type to other
function PAINT_INFO:OnChangeFrom(ply, newType, normal)
end

-- When player jump
function PAINT_INFO:OnJump(ply, normal)
end

-- Handling paint
function PAINT_INFO:Think(ply, normal)

end

-- Handling painted entity
function PAINT_INFO:EntityThink(ent)
end

end -- SERVER

LIB_APERTURE:CreateNewPaintType(PORTAL_PAINT_REFLECTION, PAINT_INFO)
