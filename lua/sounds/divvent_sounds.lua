AddCSLuaFile()

local tubesuck =
{
	channel	= CHAN_WEAPON,
	name	= "TA:TubeSuck",
	level	= 75,
	sound	= {"diversity_vent/tube_suction_lp_01.wav"
	, "diversity_vent/tube_suction_lp_02.wav"},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(tubesuck)