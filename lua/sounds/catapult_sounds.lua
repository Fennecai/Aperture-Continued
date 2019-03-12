--[[

	CATAPULT SOUNDS
	
]]

AddCSLuaFile()

local catapultLaunch =
{
	channel	= CHAN_WEAPON,
	name	= "TA:CatapultLaunch",
	level	= 60,
	sound	= "catapult/catapult_launch.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(catapultLaunch)
