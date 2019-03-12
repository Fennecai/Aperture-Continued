--[[

	PORTAL BUTTON SOUNDS
	
]]

AddCSLuaFile()

local buttonClick =
{
	channel	= CHAN_WEAPON,
	name	= "TA:ButtonClick",
	level	= 70,
	sound	= "buttons/button_press.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(buttonClick)

local buttonUp =
{
	channel	= CHAN_WEAPON,
	name	= "TA:ButtonUp",
	level	= 70,
	sound	= "buttons/button_release.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(buttonUp)

local oldButtonClick =
{
	channel	= CHAN_WEAPON,
	name	= "TA:OldButtonClick",
	level	= 70,
	sound	= "buttons/old_button_press.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(oldButtonClick)

local oldButtonUp =
{
	channel	= CHAN_WEAPON,
	name	= "TA:OldButtonUp",
	level	= 70,
	sound	= "buttons/old_button_release.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(oldButtonUp)