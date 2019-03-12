--[[

	Radio SOUNDS
	
]]

AddCSLuaFile()

local radioLoop =
{
	channel	= CHAN_VOICE,
	name	= "TA:RadioLoop",
	level	= 60,
	sound	= "music/looping_radio_mix.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(radioLoop)

local radioStrangeNoice =
{
	channel	= CHAN_VOICE,
	name	= "TA:RadioStrangeNoice",
	level	= 60,
	sound	= "music/radio_strange_channel.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(radioStrangeNoice)
