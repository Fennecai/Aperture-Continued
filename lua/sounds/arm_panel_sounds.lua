--[[

	ARM PANEL SOUNDS
	
]]

AddCSLuaFile()

local armPanelOpen =
{
	channel	= CHAN_WEAPON,
	name	= "TA:ArmPanelOpen",
	level	= 60,
	sound	= "arm_panel/arm_panel_open.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(armPanelOpen)

local armPanelClose =
{
	channel	= CHAN_WEAPON,
	name	= "TA:ArmPanelClose",
	level	= 60,
	sound	= "arm_panel/arm_panel_close.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(armPanelClose)
