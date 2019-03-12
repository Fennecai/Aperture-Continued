AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_ent")

ENT.Editable		= true
ENT.PrintName		= "Long Fall Boots"
ENT.Category		= "Aperture Science"
ENT.Spawnable 		= true
ENT.AutomaticFrameAdvance = true

function ENT:SpawnFunction(ply, trace, className)
	if not trace.Hit then return end
	
	local ent = ents.Create(className)
	ent:SetPos(trace.HitPos + trace.HitNormal * 30)
	ent:SetAngles(Angle(0, ply:EyeAngles().y + 180, 0))
	ent:Spawn()
	
	return ent
end

function ENT:Draw()
	self:DrawModel()
end

-- no more client side
if CLIENT then return end

function ENT:Initialize()
	self:SetModel("models/aperture/jumper_boots_box.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:GetPhysicsObject():Wake()
end

function ENT:Think()
	self:NextThink(CurTime() + 0.1)
	
	return true
end

function ENT:Use(activator, caller)
	if IsValid(caller) and caller:IsPlayer() and not caller:GetNWBool("TA:ItemJumperBoots") then
		self:SetPlayer(caller)
	end
end

local function CreateBoots(ply)
	if not IsValid(ply) then return end
	local ent = ents.Create("prop_physics")
	if not IsValid(ent) then return end
	ent:SetModel("models/aperture/jumper_boots.mdl")
	ent:SetPos(ply:GetPos())
	ent:PhysicsInitStatic(SOLID_VPHYSICS)
	ent:Spawn()
	ent:SetNotSolid(true)
	ent:SetParent(ply)
	ent:AddEffects(EF_BONEMERGE)
	ent.GetPlayerColor = function() return ply:GetPlayerColor() end
	ply:SetNWEntity("TA:ItemJumperBootsEntity", ent)
	LIB_APERTURE:JumperBootsResizeLegs(ply, 10)
end

function ENT:SetPlayer(ply)
	ply:SetNWBool("TA:ItemJumperBoots", true)
	self:Remove()
	CreateBoots(ply)
end
