AddCSLuaFile()

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.Editable				= true
ENT.PrintName				= "Aperture base class"
ENT.AutomaticFrameAdvance 	= true
ENT.Purpose 				= "Base for aperture SEnts"
ENT.RenderGroup				= RENDERGROUP_BOTH
ENT.Spawnable 				= false
ENT.AdminOnly 				= false

ENT.IsAperture 				= true

if WireAddon and ENT.IsConnectable then
	DEFINE_BASECLASS("base_wire_entity")
	ENT.WireDebugName = "Aperture Base"
else
	DEFINE_BASECLASS("base_gmodentity")
end

-- function ENT:Initialize()

	-- if CLIENT then
	
		-- return
	-- end
-- end

function ENT:Draw()
	self:DrawModel()
end

function ENT:PlaySequence(seq, rate)
	local sequence = self:LookupSequence(seq)
	self:ResetSequence(sequence)
	self:SetPlaybackRate(rate)
	self:SetSequence(sequence)
	self:ResetSequence(sequence)
	return self:SequenceDuration(sequence)
end

-- sounds
function ENT:MakeSoundEntity(soundName, pos, parent, index)
	self:RemoveSoundEntity(soundName, pos, index)
	if not index then index = 1 end
	local ent = ents.Create("env_soundscape")
	if not IsValid(ent) then return end
	ent:SetPos(pos)
	ent:Spawn()
	if parent then ent:SetParent(parent) end
	ent:SetNoDraw(true)
	ent:EmitSound(soundName)
	
	if not self.TA_SoundEntities then self.TA_SoundEntities = {} end
	self.TA_SoundEntities[soundName..tostring(index)] = ent
end

function ENT:MoveSoundEntity(soundName, pos, index)
	if not self.TA_SoundEntities then return end
	if not index then index = 1 end
	if not self.TA_SoundEntities[soundName..tostring(index)] then return end
	local ent = self.TA_SoundEntities[soundName..tostring(index)]
	if not IsValid(ent) then return end
	ent:SetPos(pos)
end

function ENT:RemoveSoundEntity(soundName, index)
	if not self.TA_SoundEntities then return end
	if not index then index = 1 end
	if not self.TA_SoundEntities[soundName..tostring(index)] then return end
	
	local ent = self.TA_SoundEntities[soundName..tostring(index)]
	if not IsValid(ent) then return end
	ent:StopSound(soundName)
	ent:Remove()
end