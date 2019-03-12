AddCSLuaFile()

ENT.Type 					= "anim"
ENT.Base 					= "base_entity"
ENT.RenderGroup 			= RENDERGROUP_BOTH
ENT.AutomaticFrameAdvance 	= true
ENT.Purpose 				= "Prop that can be animated"
ENT.RenderGroup				= RENDERGROUP_BOTH
ENT.Spawnable 				= false
ENT.AdminOnly 				= false

function ENT:Initialize()
	if SERVER then
		self:SetRenderMode(RENDERMODE_TRANSALPHA)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
	end
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:PlaySequence(seq, rate)
	local sequence = self:LookupSequence(seq)
	self:ResetSequence(sequence)
	self:SetPlaybackRate(rate)
	self:SetSequence(sequence)
	return self:SequenceDuration(sequence)
end

function ENT:Think()
	self:NextThink(CurTime())
	return true
end
