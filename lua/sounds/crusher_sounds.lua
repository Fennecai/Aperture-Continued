--[[

	CRUSHER SOUNDS
	
]]

AddCSLuaFile()

local crusherSmash =
{
	channel	= CHAN_WEAPON,
	name	= "TA:CrusherSmash",
	level	= 90,
	sound	= {
		"crusher/crusher_impact_01.wav",
		"crusher/crusher_impact_02.wav",
		"crusher/crusher_impact_03.wav",
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(crusherSmash)

local crusherOpen =
{
	channel	= CHAN_WEAPON,
	name	= "TA:CrusherOpen",
	level	= 75,
	sound	= {
		"crusher/crusher_open_01.wav",
		"crusher/crusher_open_02.wav",
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(crusherOpen)

local crusherSeparate =
{
	channel	= CHAN_WEAPON,
	name	= "TA:CrusherSeparate",
	level	= 75,
	sound	= {
		"crusher/crusher_separate_01.wav",
		"crusher/crusher_separate_02.wav",
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(crusherSeparate)
