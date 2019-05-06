-- client includes
AddCSLuaFile("aperture/main.lua")
-- shared includes
include("aperture/main.lua")
--Map fixer includes
include("mapfixer/mapfixer_autorun.lua")
if SERVER then
	AddCSLuaFile()
--resource.AddWorkshop( "862644776" ) -- Workshop download
end
