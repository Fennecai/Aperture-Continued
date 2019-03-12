--[[

	FIZZLER SOUNDS
	
]]

AddCSLuaFile()

local plyLand =
{
	channel	= CHAN_WEAPON,
	name	= "TA:PlayerLand",
	level	= 70,
	sound	= { "player/longfall_land_01.wav",
		"player/longfall_land_02.wav",
		"player/longfall_land_03.wav",
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(plyLand)