--[[

	TURRETS SOUNDS
	
]]

AddCSLuaFile()

local turretShoot =
{
	channel	= CHAN_WEAPON,
	name	= "TA:TurretShoot",
	level	= 60,
	sound	= { "npc/turret_floor/turret_fire_4x_01.wav"
	, "npc/turret/turret_floor.wav" 
	, "npc/turret/turret_floor.wav" },
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretShoot)

local turretDie =
{
	channel	= CHAN_WEAPON,
	name	= "TA:TurretDie",
	level	= 60,
	sound	= "npc/turret_floor/die.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretDie)

local turretActivateVO =
{
	channel	= CHAN_VOICE,
	name	= "TA:TurretActivateVO",
	level	= 70,
	sound	= { "npc/turret_floor/turret_active_1.wav"
	, "npc/turret_floor/turret_active_2.wav"
	, "npc/turret_floor/turret_active_3.wav"
	, "npc/turret_floor/turret_active_4.wav"
	, "npc/turret_floor/turret_active_5.wav"
	, "npc/turret_floor/turret_active_6.wav"
	, "npc/turret_floor/turret_active_7.wav"
	, "npc/turret_floor/turret_active_8.wav" },
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretActivateVO)

local turretActivate =
{
	channel	= CHAN_WEAPON,
	name	= "TA:TurretActivate",
	level	= 60,
	sound	= "npc/turret_floor/active.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretActivate)

local turretPing =
{
	channel	= CHAN_WEAPON,
	name	= "TA:TurretPing",
	level	= 60,
	sound	= "npc/turret_floor/ping.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretPing)

local turretDeploy =
{
	channel	= CHAN_WEAPON,
	name	= "TA:TurretDeploy",
	level	= 70,
	sound	= "npc/turret_floor/deploy.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretDeploy)

local turretFizzleVO =
{
	channel	= CHAN_VOICE,
	name	= "TA:TurretFizzleVO",
	level	= 70,
	sound	= "npc/turret_floor/turret_fizzler_1.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretFizzleVO)

local turretDeployVO =
{
	channel	= CHAN_VOICE,
	name	= "TA:TurretDeployVO",
	level	= 70,
	sound	= { "npc/turret_floor/turret_deploy_1.wav"
	, "npc/turret_floor/turret_deploy_2.wav"
	, "npc/turret_floor/turret_deploy_3.wav"
	, "npc/turret_floor/turret_deploy_4.wav"
	, "npc/turret_floor/turret_deploy_5.wav"
	, "npc/turret_floor/turret_deploy_6.wav" },
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretDeployVO)

local turretDisabledVO =
{
	channel	= CHAN_VOICE,
	name	= "TA:TurretDisabledVO",
	level	= 70,
	sound	= { "npc/turret_floor/turret_disabled_1.wav"
	, "npc/turret_floor/turret_disabled_2.wav"
	, "npc/turret_floor/turret_disabled_3.wav"
	, "npc/turret_floor/turret_disabled_4.wav"
	, "npc/turret_floor/turret_disabled_5.wav"
	, "npc/turret_floor/turret_disabled_6.wav" },
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretDisabledVO)

local turretSearchVO =
{
	channel	= CHAN_VOICE,
	name	= "TA:TurretSearchVO",
	level	= 75,
	sound	= { "npc/turret_floor/turret_search_1.wav"
	, "npc/turret_floor/turret_search_2.wav"
	, "npc/turret_floor/turret_search_3.wav"
	, "npc/turret_floor/turret_search_4.wav" },
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretSearchVO)

local turretAutoSearchVO =
{
	channel	= CHAN_VOICE,
	name	= "TA:TurretAutoSearchVO",
	level	= 75,
	sound	= { "npc/turret_floor/turret_autosearch_1.wav"
		, "npc/turret_floor/turret_autosearch_2.wav" 
		, "npc/turret_floor/turret_autosearch_3.wav"
		, "npc/turret_floor/turret_autosearch_4.wav"
		, "npc/turret_floor/turret_autosearch_5.wav"
		, "npc/turret_floor/turret_autosearch_6.wav" },
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretAutoSearchVO)

local turretRetract =
{
	channel	= CHAN_WEAPON,
	name	= "TA:TurretRetract",
	level	= 60,
	sound	= "npc/turret_floor/retract.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretRetract)

local turretRetractVO =
{
	channel	= CHAN_VOICE,
	name	= "TA:TurretRetractVO",
	level	= 70,
	sound	= { "npc/turret_floor/turret_retire_1.wav"
	, "npc/turret_floor/turret_retire_2.wav"
	, "npc/turret_floor/turret_retire_3.wav"
	, "npc/turret_floor/turret_retire_4.wav"
	, "npc/turret_floor/turret_retire_5.wav"
	, "npc/turret_floor/turret_retire_6.wav" },
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretRetractVO)

local turretPickupVO =
{
	channel	= CHAN_VOICE,
	name	= "TA:TurretPickupVO",
	level	= 70,
	sound	= { "npc/turret_floor/turret_pickup_1.wav"
	, "npc/turret_floor/turret_pickup_2.wav" 
	, "npc/turret_floor/turret_pickup_3.wav" 
	, "npc/turret_floor/turret_pickup_4.wav" 
	, "npc/turret_floor/turret_pickup_5.wav" 
	, "npc/turret_floor/turret_pickup_6.wav" 
	, "npc/turret_floor/turret_pickup_7.wav" 
	, "npc/turret_floor/turret_pickup_8.wav" 
	, "npc/turret_floor/turret_pickup_9.wav" 
	, "npc/turret_floor/turret_pickup_10.wav" },
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretPickupVO)

local turretLaunch =
{
	channel	= CHAN_VOICE,
	name	= "TA:TurretLaunch",
	level	= 70,
	sound	= { "npc/turret_floor/turretlaunched01.wav"
	, "npc/turret_floor/turretlaunched02.wav" 
	, "npc/turret_floor/turretlaunched03.wav" 
	, "npc/turret_floor/turretlaunched04.wav" 
	, "npc/turret_floor/turretlaunched05.wav" 
	, "npc/turret_floor/turretlaunched06.wav" },
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretLaunch)

local turretBurn =
{
	channel	= CHAN_VOICE,
	name	= "TA:TurretBurn",
	level	= 60,
	sound	= { "npc/turret/turretshotbylaser01.wav"
	, "npc/turret/turretshotbylaser02.wav"
	, "npc/turret/turretshotbylaser03.wav"
	, "npc/turret/turretshotbylaser04.wav"
	, "npc/turret/turretshotbylaser05.wav"
	, "npc/turret/turretshotbylaser06.wav" },
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(turretBurn)
