--[[

	CATAPULT SOUNDS
	
]]

AddCSLuaFile()

local turretDifferent =
{
	channel	= CHAN_VOICE,
	name	= "TA:TurretDifferent",
	level	= 60,
	sound	= {"npc/turret/turretstuckintube01.wav"
	, "npc/turret/turretstuckintube02.wav"
	, "npc/turret/turretstuckintube03.wav"
	, "npc/turret/turretstuckintube04.wav"
	, "npc/turret/turretstuckintube05.wav"
	, "npc/turret/turretstuckintube06.wav"},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretDifferent)

local turretThruth =
{
	channel	= CHAN_VOICE,
	name	= "TA:TurretThruth",
	level	= 60,
	sound	= {"npc/turret/different_turret01.wav"
	, "npc/turret/different_turret02.wav"
	, "npc/turret/different_turret03.wav"
	, "npc/turret/different_turret04.wav"
	, "npc/turret/different_turret05.wav"
	, "npc/turret/different_turret06.wav"},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretThruth)

local turretSong =
{
	channel	= CHAN_VOICE,
	name	= "TA:TurretSong",
	level	= 75,
	sound	= "music/turrets_song.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretSong)
