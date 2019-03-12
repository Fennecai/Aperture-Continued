AddCSLuaFile()

local rocketLaunch =
{
	channel	= CHAN_WEAPON,
	name	= "TA:RTurretLaunch",
	level	= 90,
	sound	= "npc/rocket_turret/rocket_fire1.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(rocketLaunch)

local rocketLock =
{
	channel	= CHAN_WEAPON,
	name	= "TA:RTurretLock",
	level	= 75,
	sound	= "npc/rocket_turret/rocket_locked_beep1.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(rocketLock)

local rocketFly =
{
	channel	= CHAN_WEAPON,
	name	= "TA:RocketMissileFly",
	level	= 75,
	sound	= "npc/rocket_turret/rocket_fly_loop1.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(rocketFly)