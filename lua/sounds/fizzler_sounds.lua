--[[

	FIZZLER SOUNDS
	
]]

AddCSLuaFile()

local fizzlerDissolve =
{
	channel	= CHAN_WEAPON,
	name	= "TA:FizzlerDissolve",
	level	= 70,
	sound	= "fizzler/material_emancipation_01.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(fizzlerDissolve)

local fizzlerEnable =
{
	channel	= CHAN_WEAPON,
	name	= "TA:FizzlerEnable",
	level	= 70,
	sound	= "fizzler/fizzler_start_01.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(fizzlerEnable)

local fizzlerDisable =
{
	channel	= CHAN_WEAPON,
	name	= "TA:FizzlerDisable",
	level	= 70,
	sound	= "fizzler/fizzler_shutdown_01.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(fizzlerDisable)
