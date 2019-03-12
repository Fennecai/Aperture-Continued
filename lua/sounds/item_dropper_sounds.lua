--[[

	LASER SOUNDS SOUNDS
	
]]

AddCSLuaFile()

local itemDropperOpen =
{
	channel	= CHAN_BODY,
	name	= "TA:ItemDropperOpen",
	level	= 65,
	sound	= { "item_dropper/dropper_open_01.wav"
		, "item_dropper/dropper_open_01.wav"
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(itemDropperOpen)

local itemDropperClose =
{
	channel	= CHAN_BODY,
	name	= "TA:ItemDropperClose",
	level	= 65,
	sound	= "item_dropper/dropper_close_01.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(itemDropperClose)

local oldItemDropperOpen =
{
	channel	= CHAN_BODY,
	name	= "TA:OldItemDropperOpen",
	level	= 70,
	sound	= { "item_dropper/underground_dropper_open_01.wav"
		, "item_dropper/underground_dropper_open_02.wav"
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(oldItemDropperOpen)

local oldItemDropperClose =
{
	channel	= CHAN_BODY,
	name	= "TA:OldItemDropperClose",
	level	= 70,
	sound	= "item_dropper/underground_dropper_close.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(oldItemDropperClose)
