AddCSLuaFile()

if not LIB_APERTURE then return end

--============= Conversion Gel ==============

PORTAL_PAINT_PORTAL = PORTAL_PAINT_COUNT + 1

local PAINT_INFO = {}

PAINT_INFO.COLOR 	= Color(200, 200, 200)
PAINT_INFO.NAME		= "Conversion" 

if SERVER then

end -- SERVER

LIB_APERTURE:CreateNewPaintType(PORTAL_PAINT_PORTAL, PAINT_INFO)
