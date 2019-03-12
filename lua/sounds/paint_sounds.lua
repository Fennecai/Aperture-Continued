--[[

	CATAPULT SOUNDS
	
]]

AddCSLuaFile()

local paintSplat =
{
	channel	= CHAN_WEAPON,
	name	= "TA:PaintSplat",
	level	= 75,
	sound	= { "paint/paint_blob_splat_01.wav"
		, "paint/paint_blob_splat_02.wav"
		, "paint/paint_blob_splat_03.wav"
		, "paint/paint_blob_splat_04.wav"
		, "paint/paint_blob_splat_05.wav"
		, "paint/paint_blob_splat_06.wav"
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(paintSplat)

local paintSplatBig =
{
	channel	= CHAN_WEAPON,
	name	= "TA:PaintSplatBig",
	level	= 75,
	sound	= "paint/phys_paint_bomb_01.wav",
	volume	= 1.0,
	pitch	= { 80, 120 },
}
sound.Add(paintSplatBig)

local bounceProp =
{
	channel	= CHAN_WEAPON,
	name	= "TA:BounceProp",
	level	= 75,
	sound	= { "paint/phys_bouncy_cube_lg_01.wav"
		, "paint/phys_bouncy_cube_lg_02.wav"
		, "paint/phys_bouncy_cube_lg_03.wav"
		, "paint/phys_bouncy_cube_lg_04.wav"
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(bounceProp)

local playerBounce =
{
	channel	= CHAN_WEAPON,
	name	= "TA:PlayerBounce",
	level	= 75,
	sound	= { "paint/player_bounce_jump_paint_01.wav"
		, "paint/player_bounce_jump_paint_02.wav"
		, "paint/player_bounce_jump_paint_03.wav"
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(playerBounce)

local paintFootsteps =
{
	channel	= CHAN_WEAPON,
	name	= "TA:PaintFootsteps",
	level	= 60,
	sound	= { "player/footsteps/fs_fm_paint_01.wav"
		, "player/footsteps/fs_fm_paint_02.wav"
		, "player/footsteps/fs_fm_paint_03.wav"
		, "player/footsteps/fs_fm_paint_04.wav"
		, "player/footsteps/fs_fm_paint_05.wav"
		, "player/footsteps/fs_fm_paint_06.wav"
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(paintFootsteps)

local paintBounceEnter =
{
	channel	= CHAN_AUTO,
	name	= "TA:PaintBounceEnter",
	level	= 75,
	sound	= { "player/paint/player_enter_jump_paint_01.wav"
		, "player/paint/player_enter_jump_paint_02.wav"
		, "player/paint/player_enter_jump_paint_03.wav"
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(paintBounceEnter)

local paintBounceExit =
{
	channel	= CHAN_AUTO,
	name	= "TA:PaintBounceExit",
	level	= 75,
	sound	= { "player/paint/player_exit_jump_paint_01.wav"
		, "player/paint/player_exit_jump_paint_02.wav"
		, "player/paint/player_exit_jump_paint_03.wav"
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(paintBounceExit)

local paintSpeedEnter =
{
	channel	= CHAN_AUTO,
	name	= "TA:PaintSpeedEnter",
	level	= 75,
	sound	= { "player/paint/player_enter_speed_paint_01.wav"
		, "player/paint/player_enter_speed_paint_02.wav"
		, "player/paint/player_enter_speed_paint_03.wav"
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(paintSpeedEnter)

local paintSpeedExit =
{
	channel	= CHAN_AUTO,
	name	= "TA:PaintSpeedExit",
	level	= 75,
	sound	= { "player/paint/player_exit_speed_paint_01.wav"
		, "player/paint/player_exit_speed_paint_02.wav"
		, "player/paint/player_exit_speed_paint_03.wav"
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(paintSpeedExit)

local paintStickEnter =
{
	channel	= CHAN_AUTO,
	name	= "TA:PaintStickEnter",
	level	= 75,
	sound	= { "player/paint/player_enter_stick_paint_01.wav"
		, "player/paint/player_enter_stick_paint_02.wav"
		, "player/paint/player_enter_stick_paint_03.wav"
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(paintStickEnter)

local paintStickExit =
{
	channel	= CHAN_AUTO,
	name	= "TA:PaintStickExit",
	level	= 75,
	sound	= { "player/paint/player_exit_stick_paint_01.wav"
		, "player/paint/player_exit_stick_paint_02.wav"
		, "player/paint/player_exit_stick_paint_03.wav"
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(paintStickExit)

local paintFlow =
{
	channel	= CHAN_AUTO,
	name	= "TA:PaintFlow",
	level	= 70,
	sound	= "paint/paint_nozzle_waterfall_lp.wav",
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(paintFlow)