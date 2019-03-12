--[[

	WALL PROJECTOR SOUNDS
	
]]

AddCSLuaFile()

local monsterBoxChitter =
{
	channel	= CHAN_VOICE,
	name	= "TA:MonsterBoxChitter",
	level	= 65,
	sound	= { "npc/box_monster/box_monster_chitter_01.wav"
		, "npc/box_monster/box_monster_chitter_02.wav"
		, "npc/box_monster/box_monster_chitter_03.wav"
		, "npc/box_monster/box_monster_chitter_04.wav"
		, "npc/box_monster/box_monster_chitter_05.wav"
		, "npc/box_monster/box_monster_chitter_06.wav"
		, "npc/box_monster/box_monster_chitter_07.wav"
		, "npc/box_monster/box_monster_chitter_08.wav"
		, "npc/box_monster/box_monster_chitter_09.wav"
		, "npc/box_monster/box_monster_chitter_10.wav"
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(monsterBoxChitter)

local monsterBoxKick =
{
	channel	= CHAN_BODY,
	name	= "TA:MonsterBoxKick",
	level	= 65,
	sound	= { "npc/box_monster/box_monster_leg_kick_01.wav"
		, "npc/box_monster/box_monster_leg_kick_02.wav"
		, "npc/box_monster/box_monster_leg_kick_03.wav"
		, "npc/box_monster/box_monster_leg_kick_04.wav"
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(monsterBoxKick)

local monsterBoxFootsteps =
{
	channel	= CHAN_BODY,
	name	= "TA:MonsterBoxFootsteps",
	level	= 65,
	sound	= { "npc/box_monster/box_monster_fs_01.wav"
		, "npc/box_monster/box_monster_fs_02.wav"
		, "npc/box_monster/box_monster_fs_03.wav"
		, "npc/box_monster/box_monster_fs_04.wav"
		, "npc/box_monster/box_monster_fs_05.wav"
		, "npc/box_monster/box_monster_fs_06.wav"
	},
	volume	= 1.0,
	pitch	= 100,
}
sound.Add(monsterBoxFootsteps)
