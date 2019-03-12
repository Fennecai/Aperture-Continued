--[[

	Potato OS SOUNDS
	
]]

AddCSLuaFile()

local potatoOSChat =
{
	channel	= CHAN_VOICE,
	name	= "TA:PotatoOSChat",
	level	= 60,
	sound	= { "npc/potatoos/potatos_chat01.wav"
	, "npc/potatoos/potatos_chat02.wav"
	, "npc/potatoos/potatos_chat03.wav"
	, "npc/potatoos/potatos_chat04.wav"
	, "npc/potatoos/potatos_chat05.wav"
	, "npc/potatoos/potatos_chat06.wav" },
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(potatoOSChat)

local potatoOSSeeBird =
{
	channel	= CHAN_VOICE,
	name	= "TA:PotatoOSSeeBird",
	level	= 60,
	sound	= "npc/potatoos/potatos_see_bird01.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(potatoOSSeeBird)

local potatoOSSing =
{
	channel	= CHAN_VOICE,
	name	= "TA:PotatoOSSing",
	level	= 60,
	sound	= "npc/potatoos/potatos_sing.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(potatoOSSing)

local potatoOSBurn =
{
	channel	= CHAN_VOICE,
	name	= "TA:PotatoOSBurn",
	level	= 60,
	sound	= "npc/potatoos/potatos_burn.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(potatoOSBurn)
