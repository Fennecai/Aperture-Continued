--[[

	APERTURE API MAIN
	
]]
AddCSLuaFile( )

LIB_APERTURE = {}

-- Loading sounds
local paint_types = file.Find("sounds/*.lua", "LUA")
for _,plugin in ipairs(paint_types) do
	include("sounds/" .. plugin)
end

-- Loading entities data
local entities_data = file.Find("aperture/entities_data/*.lua", "LUA")
for _,plugin in ipairs(entities_data) do
	include("aperture/entities_data/"..plugin)
end

-- Loading math lib
include("aperture/math.lua")

-- Loading portal integration lib
include("aperture/portal_integration.lua")

-- Loading achievement lib
include("aperture/achievement.lua")

-- Loading paint lib
include("aperture/paint_lib.lua")
include("aperture/paint.lua")

-- Loading floor buttons lib
include("aperture/buttons.lua")

-- Funnel
LIB_APERTURE.FUNNEL_COLOR 			= Color(0, 150, 255)
LIB_APERTURE.FUNNEL_REVERSE_COLOR 	= Color(255, 150, 0)
LIB_APERTURE.FUNNEL_MOVE_SPEED 		= 173

-- Fizzler
LIB_APERTURE.DISSOLVE_SPEED 	= 150
LIB_APERTURE.DISSOLVE_ENTITIES 	= { }

-- Diversity Vent
LIB_APERTURE.DIVVENT_ENTITIES = { }

LIB_APERTURE.FALL_BOOTS_LEG_SIZE = 10

function LIB_APERTURE:GetAIDisabled()
	local conVar = GetConVar("ai_disabled")
	if not conVar then return false end
	return tobool(conVar:GetInt())
end

function LIB_APERTURE:GetAIIgnorePlayers()
	local conVar = GetConVar("ai_ignoreplayers")
	if not conVar then return false end
	return tobool(conVar:GetInt())
end

function LIB_APERTURE:JumperBootsResizeLegs(ply, size)
	local ent = ply:GetNWEntity("TA:ItemJumperBootsEntity")
	local prCalf = ply:LookupBone("ValveBiped.Bip01_R_Calf")
	local plCalf = ply:LookupBone("ValveBiped.Bip01_L_Calf")
	local prFoot = ply:LookupBone("ValveBiped.Bip01_R_Foot")
	local plFoot = ply:LookupBone("ValveBiped.Bip01_L_Foot")
	local prToe0 = ply:LookupBone("ValveBiped.Bip01_R_Toe0")
	local plToe0 = ply:LookupBone("ValveBiped.Bip01_L_Toe0")
	ply:ManipulateBoneScale(prCalf, Vector(1, 1, 1) / size)
	ply:ManipulateBoneScale(plCalf, Vector(1, 1, 1) / size)
	ply:ManipulateBoneScale(prFoot, Vector(1, 1, 1) / size)
	ply:ManipulateBoneScale(plFoot, Vector(1, 1, 1) / size)
	ply:ManipulateBoneScale(prToe0, Vector(1, 1, 1) / size)
	ply:ManipulateBoneScale(plToe0, Vector(1, 1, 1) / size)

	if not IsValid(ent) then return end
	local rCalf = ent:LookupBone("ValveBiped.Bip01_R_Calf")
	local lCalf = ent:LookupBone("ValveBiped.Bip01_L_Calf")
	local rFoot = ent:LookupBone("ValveBiped.Bip01_R_Foot")
	local lFoot = ent:LookupBone("ValveBiped.Bip01_L_Foot")
	local rToe0 = ent:LookupBone("ValveBiped.Bip01_R_Toe0")
	local lToe0 = ent:LookupBone("ValveBiped.Bip01_L_Toe0")
	ent:ManipulateBoneScale(rCalf, Vector(1, 1, 1) * size)
	ent:ManipulateBoneScale(lCalf, Vector(1, 1, 1) * size)
	ent:ManipulateBoneScale(rFoot, Vector(1, 1, 1) * size)
	ent:ManipulateBoneScale(lFoot, Vector(1, 1, 1) * size)
	ent:ManipulateBoneScale(rToe0, Vector(1, 1, 1) * size)
	ent:ManipulateBoneScale(lToe0, Vector(1, 1, 1) * size)
end

function LIB_APERTURE:DissolveEnt(ent)
	if ent.IsDissolving then return end
	local phys = ent:GetPhysicsObject()
	ent:SetSolid(SOLID_NONE)
	ent.IsDissolving = true
	
	if phys:GetVelocity():Length() < 10 then
		phys:SetVelocity(Vector(0, 0, 10) + VectorRand() * 2)
		phys:AddAngleVelocity(VectorRand() * 100)
	else
		phys:SetVelocity(phys:GetVelocity() / 4)
	end
	phys:EnableGravity(false)
	ent:EmitSound("TA:FizzlerDissolve")
	-- Calling fizzle event
	if ent.OnFizzle then ent:OnFizzle() end
	table.insert(LIB_APERTURE.DISSOLVE_ENTITIES, ent)
end

function LIB_APERTURE:IsValidEntity(ent)
	if not IsValid(ent) then return false end
	return true
end

function LIB_APERTURE:IsValidPhysicsEntity(ent)
	if not IsValid(ent) then return false end
	if not IsValid(ent:GetPhysicsObject()) then return false end
	return true
end

function LIB_APERTURE:IsValidAliveEntity(ent)
	if not IsValid(ent) then return false end
	if not (ent:IsPlayer() and ent:Alive() or ent:IsNPC()) then return end
	return true
end

function LIB_APERTURE:IsValidHealthEntity(ent)
	if not IsValid(ent) then return false end
	if not ent:Health() then return end
	return true
end

hook.Add( "Initialize", "TA:Initialize", function()
	if SERVER then
		util.AddNetworkString("TA:NW_PaintCamera")
		util.AddNetworkString("TA:DivventFilterNetwork")
		util.AddNetworkString("TA:NW_AchievedAchievement")
	end
	
	if CLIENT then
	end
end)

local function HandleEntitiesInDivvent(ent, flow, inx, info)
	if not IsValid(ent) 
		or not IsValid(info.vent) 
		or ent:GetMoveType() == MOVETYPE_NOCLIP then
		LIB_APERTURE.DIVVENT_ENTITIES[ent] = nil
		return
	end

	local flowpoint = flow[inx]
	
	if flowpoint != Vector() then
		local physObj = ent:GetPhysicsObject()
		local centerPos = ent:LocalToWorld(physObj:GetMassCenter())
		-- remove entity from table if it too far from the point
		if centerPos:Distance(flowpoint) > 300 then
			LIB_APERTURE.DIVVENT_ENTITIES[ent] = nil
			return
		end
		
		local mass = physObj:GetMass()
		local dirN = (flowpoint - centerPos):GetNormalized()
		if ent:IsPlayer() or ent:IsNPC() then
			local velvec = dirN * 400 - ent:GetVelocity() / 2
			ent:SetVelocity(velvec)
		else
			local velvec = dirN * 100 - physObj:GetVelocity() / 10
			physObj:AddVelocity(velvec)
		end
		
		if flowpoint:Distance(centerPos) < 30 then
			info.index = inx + 1
			if (inx + 1) > #flow then
				LIB_APERTURE.DIVVENT_ENTITIES[ent] = nil
			end
		end
	end
end

local function HandleDissolvedEntities(ent, index)
	-- skip if entity doesn't exist
	if not IsValid(ent) then
		LIB_APERTURE.DISSOLVE_ENTITIES[index] = nil
		return
	end
	
	if not ent.TA_Dissovle then ent.TA_Dissovle = 0 end
	ent.TA_Dissovle = ent.TA_Dissovle + 1
	
	-- Turning entity into black and then fadeout alpha
	local colorBlack = (math.max(0, LIB_APERTURE.DISSOLVE_SPEED - ent.TA_Dissovle * 1.75) / LIB_APERTURE.DISSOLVE_SPEED) * 255
	local alpha = math.max(0, ent.TA_Dissovle - LIB_APERTURE.DISSOLVE_SPEED / 1.1) / (LIB_APERTURE.DISSOLVE_SPEED - LIB_APERTURE.DISSOLVE_SPEED / 1.1)
	alpha = 255 - alpha * 255
	ent:SetColor(Color(colorBlack, colorBlack, colorBlack, alpha))
	if alpha < 255 then ent:SetRenderMode(RENDERMODE_TRANSALPHA) end

	local effectdata = EffectData()
	effectdata:SetEntity(ent)
	util.Effect("fizzler_dissolve", effectdata)
	
	if ent.TA_Dissovle >= LIB_APERTURE.DISSOLVE_SPEED then
		LIB_APERTURE.DISSOLVE_ENTITIES[index] = nil
		ent:Remove()
	end
end

hook.Add("Think", "TA:Think", function()	
	-- Handling dissolved entities
	for k,v in pairs(LIB_APERTURE.DISSOLVE_ENTITIES) do
		HandleDissolvedEntities(v, k)
	end
	
	for k,v in pairs(LIB_APERTURE.DIVVENT_ENTITIES) do
		HandleEntitiesInDivvent(k, v.flow, v.index, v)
	end
end )


hook.Add("PostDrawTranslucentRenderables", "TA:RenderObjects", function()
	-- Making render fullbright
	for k,v in pairs(ents.FindByClass("ent_tractor_beam")) do v:Drawing() end
	for k,v in pairs(ents.FindByClass("ent_portal_floor_turret")) do v:Drawing() end
	for k,v in pairs(ents.FindByClass("ent_portal_laser_emitter")) do v:Drawing() end
	for k,v in pairs(ents.FindByClass("ent_wall_projector")) do v:Drawing() end
	for k,v in pairs(ents.FindByClass("ent_portal_fizzler")) do v:Drawing() end
	for k,v in pairs(ents.FindByClass("ent_laser_field")) do v:Drawing() end
	for k,v in pairs(ents.FindByClass("npc_portal_turret_floor")) do v:Drawing() end
	for k,v in pairs(ents.FindByClass("npc_portal_rocket_turret")) do v:Drawing() end
end)

hook.Add("PhysgunPickup", "TA:DisablePhysgunPickup", function(ply, ent)
	if ent.TA_Untouchable then return false end
end)

hook.Add("GetFallDamage", "TA:GetFallDamage", function(ply, speed)
	if ply:GetNWBool("TA:ItemJumperBoots") then
		ply:EmitSound("TA:PlayerLand")
		
		if speed >= 3500 then LIB_APERTURE.ACHIEVEMENTS:AchievAchievement(ply, "fall_survive") end
		return 0
	end
	return
end)

local function ResetingFallboots(ply)
	if ply:GetNWBool("TA:ItemJumperBoots") then
		ply:SetNWBool("TA:ItemJumperBoots", false)
		LIB_APERTURE:JumperBootsResizeLegs(ply, 1)
		local boots = ply:GetNWEntity("TA:ItemJumperBootsEntity")
		if IsValid(boots) then
			boots:Remove()
		end
	end
end

hook.Add("DoPlayerDeath", "TA:DoPlayerDeath", function(ply, attacker, dmg)
	ResetingFallboots(ply)
end)

local function Clear()
	LIB_APERTURE.DISSOLVE_ENTITIES = {}
	for k,v in pairs(player.GetAll()) do
		ResetingFallboots(v)
	end
end

hook.Add("PostCleanupMap", "TA:PostCleanupMap", Clear)

local function AllowPickup(ply, ent)
	if ent:IsPlayerHolding() and IsValid(ent) and ent:GetNWInt("TA:PaintType") and ent:GetNWInt("TA:PaintType") == PORTAL_PAINT_STICKY then
		local constrain = constraint.Find(ent, Entity(0), "Weld", 0, 0)
		if constrain then constrain:Remove() end
	end
end

hook.Add("AllowPlayerPickup", "TA:AllowPlayerPickup", AllowPickup)
hook.Add("GravGunOnPickedUp", "TA:AllowPlayerPickupGrav", AllowPickup)

local function EntityTakeDamage(target, dmg)
	local attacker = dmg:GetAttacker()
	local damage = dmg:GetDamage()
	
	if attacker:GetClass() == "portal_rocket_turret_missile" 
		and IsValid(attacker.OriginalTarget) and attacker.OriginalTarget:IsPlayer() and attacker != target
		and (target:IsPlayer() and target:Alive() or target:IsNPC()) 
		and damage > target:Health()
		and attacker.OriginalTarget:GetPos():Distance(target:GetPos()) > 300 then
			print(attacker.OriginalTarget)
			LIB_APERTURE.ACHIEVEMENTS:AchievAchievement(attacker.OriginalTarget, "not_for_you")
	end
	if attacker:GetModel() == "models/portal_custom/metal_box_custom.mdl" and attacker:GetSkin() == 1 
		and target:IsPlayer() and damage > target:Health() then
		LIB_APERTURE.ACHIEVEMENTS:AchievAchievement(target, "love_kill")
	end
end

hook.Add("EntityTakeDamage", "TA:EntityTakeDamage", EntityTakeDamage)