AddCSLuaFile()
PortalButtons = {}
local function ADD_PROP(name, nicename, model, skin)
	list.Set( "SpawnableEntities", name, {
		PrintName = nicename,
		ClassName = "prop_physics",
		Category = "Aperture Science",
		NormalOffset = 32,
		DropToFloor = true,
		
		KeyValues = {
			model = model,
			skin = skin or 0
		}
	}
)
end

ADD_PROP("portal_box1", "Cube (Normal)", "models/portal_custom/metal_box_custom.mdl", 0)
ADD_PROP("portal_box2", "Cube (Dirty)", "models/portal_custom/metal_box_custom.mdl", 3)
ADD_PROP("portal_box3", "Cube (Companion)", "models/portal_custom/metal_box_custom.mdl", 1)
ADD_PROP("portal_box4", "Cube (Old)", "models/portal_custom/underground_weighted_cube.mdl", 0)
ADD_PROP("portal_ball", "Ball", "models/portal_custom/metal_ball_custom.mdl", 0)
ADD_PROP("portal_box5", "Reflection Cube", "models/aperture/reflection_cube.mdl", 0)

-- Notes:
-- Ent:Fire( "Dissolve", Ent.Target, 0 )

sound.Add({
	name = "Portal.ButtonDepress",
	volume = 0.8,
	level = 75,
	channel = CHAN_STATIC,
	pitch = 100,
	sound = "portal_costum/buttons/portal_button_down_01.wav"
})

sound.Add({
	name = "Portal.ButtonRelease",
	volume = 0.8,
	level = 75,
	channel = CHAN_STATIC,
	pitch = 100,
	sound = "portal_costum/buttons/portal_button_up_01.wav"
})

sound.Add({
	name = "Portal.OGButtonDepress",
	volume = 0.8,
	level = 75,
	channel = CHAN_STATIC,
	pitch = 100,
	sound = {
		"portal_costum/buttons/og_button_down_01.wav",
		"portal_costum/buttons/og_button_down_02.wav",
		"portal_costum/buttons/og_button_down_03.wav",
	}
})

sound.Add({
	name = "Portal.OGButtonRelease",
	volume = 0.8,
	level = 75,
	channel = CHAN_STATIC,
	pitch = 100,
	sound = {
		"portal_costum/buttons/og_button_up_01.wav",
		"portal_costum/buttons/og_button_up_02.wav",
		"portal_costum/buttons/og_button_up_03.wav",
	}
})

local AcceptedObjects = {
	Cupes = {
		["models/props/metal_box_fx_fizzler.mdl"] = {
			on = {[0] = 2},
			off = {[2] = 0},
		},
		["models/portal_custom/metal_box_custom.mdl"] = {
			on = {[0] = 2, [1] = 4, [3] = 5},
			off = {[2] = 0, [4] = 1, [5] = 3},
		},
		["models/props/reflection_cube.mdl"] = {},
		["models/props/metal_box.mdl"] = {},
		["models/props_underground/underground_weighted_cube.mdl"] = {},
		["models/portal_custom/underground_weighted_cube.mdl"] = {},
	},

	Spheres = {
		["models/props_gameplay/mp_ball.mdl"] = {
			on = {[0] = 1},
			off = {[1] = 0},
		},

		["models/portal_custom/metal_ball_custom.mdl"] = {
			on = {[0] = 1},
			off = {[1] = 0},
		},
		
		["models/props/sphere.mdl"] = {
			on = {[0] = 9, [1] = 9, [2] = 9, [3] = 9, [4] = 9},
			off = {[5] = 0, [6] = 0, [7] = 0, [8] = 0, [9] = 0},
		},
		
		["models/props_bts/glados_ball_reference.mdl"] = {},
	},
}

AcceptedObjects.All = {}

for type,v in pairs(AcceptedObjects) do
	for k,v in pairs(AcceptedObjects[type]) do
		AcceptedObjects.All[k] = v
	end
end

function PortalButtons.GetAcceptedObjects()
	return AcceptedObjects
end

local Whitelist = {
	["boolean"] = true,
	["number"] = true,
	["string"] = true,
	["Vector"] = true,
	["Angle"] = true,
}

local function FilterDuplicatorTable(data)
	for k,v in pairs(data) do
		if istable(v) then
			FilterDuplicatorTable(v)
			continue
		end
	
		if !Whitelist[type(v)] or !Whitelist[type(k)] then
			data[k] = nil
		end
	end
end

function PortalButtons.FilterDuplicatorTable( data )
	local EntityMods = data.EntityMods

	data.Inputs = nil
	data.Outputs = nil
	data.EntityMods = nil
	data.NextCheck = nil

	FilterDuplicatorTable( data )

	data.EntityMods = EntityMods
end

local function PortalButtonPhys_PhysgunPickup( ply, ent )
	if !IsValid(ent) then return end

	if !ent.IsPortalButtonEnt then return end
	if !ent.OnUnfreeze then return end
	if ent:OnUnfreeze() == false then return false end
end
hook.Add( "PhysgunPickup", "PortalButtonPhys_PhysgunPickup", PortalButtonPhys_PhysgunPickup )

local function PortalButtonPhys_OnPhysgunFreeze( weapon, physobj, ent, ply )
	if !IsValid(ent) then return end

	if !ent.IsPortalButtonEnt then return end
	if !ent.OnFreeze then return end
	if ent:OnFreeze() == false then return false end
end
hook.Add( "OnPhysgunFreeze", "PortalButtonPhys_OnPhysgunFreeze", PortalButtonPhys_OnPhysgunFreeze )


local function PortalButtonPhys_CanDrive( ply, ent )
	if !IsValid(ent) then return end
	if !ent.IsPortalButtonEnt then return end
	if ent.IsPortalButton then return end
	
	return false
end
hook.Add( "CanDrive", "PortalButtonPhys_CanDrive", PortalButtonPhys_CanDrive )

local function PortalButtonPhys_PlayerPickup( ply, ent )
	if !IsValid(ent) then return end
	if !ent.IsPortalButtonEnt then return end
	if ent.IsPortalButton then return end
	
	return false
end
hook.Add( "PlayerPickup", "PortalButtonPhys_PlayerPickup", PortalButtonPhys_PlayerPickup )

local function PortalButtonPhys_CanTool( ply, tr, tool )
	local ent = tr.Entity

	if !IsValid(ent) then return end
	if !ent.IsPortalButtonEnt then return end
	if ent.IsPortalButton then return end

	if IsValid(ent.Parent) then
		tr.Entity = ent.Parent
	else
		tr.Entity = ent
	end
end
hook.Add( "CanTool", "PortalButtonPhys_CanTool", PortalButtonPhys_CanTool )