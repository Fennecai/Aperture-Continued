AddCSLuaFile()

local ballCatch =
{
	channel	= CHAN_WEAPON,
	name	= "TA:BallCatch",
	level	= 90,
	sound	= {
		"energy_pellet/energy_pellet_catch_0.wav",
		"energy_pellet/energy_pellet_catch_1.wav",
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(ballCatch)

local ballLaunch =
{
	channel	= CHAN_WEAPON,
	name	= "TA:BallLaunch",
	level	= 75,
	sound	= {
		"energy_pellet/energy_pellet_launch_0.wav",
		"energy_pellet/energy_pellet_launch_1.wav",
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(ballLaunch)
