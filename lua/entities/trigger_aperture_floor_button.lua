DEFINE_BASECLASS("base_brush")

ENT.Spawnable		= false
ENT.AdminOnly		= false

ENT.IsPortalButtonTrigger = true
ENT.IsPortalButtonEnt = true
ENT.DoNotDuplicate = true

local IsValid = IsValid
local Vector = Vector
local Angle = Angle
local pairs = pairs
local CurTime = CurTime
local tobool = tobool
local istable = istable

local NULL = NULL
local TRANSMIT_PVS = TRANSMIT_PVS

local math = math
local ents = ents
local util = util

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit( SOLID_NONE )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_BBOX )
	
	self:SetNoDraw( true )
	self:SetNotSolid( true )
	
	self.DoNotDuplicate = true
	self.Parent = self:GetParent()
	
	if !IsValid( self.Parent ) then
		self:Remove()
	end
	
	self.InTrigger = {}
	self.CheckTrace = {}
	self.CheckTraceParams = {}

	self.CheckTraceParams.output = self.CheckTrace
	self.CheckTraceParams.filter = function( ent )
		if ( !IsValid( self ) ) then return false end
		if ( !IsValid( ent ) ) then return false end

		local Parent = self.Parent
		if ( !IsValid( Parent ) ) then return false end

		if ( ent == self ) then return false end
		if self.InTrigger[ent] then return false end
		if Parent:Filter( ent ) then return false end
		if ( ent == Parent ) then return true end
		if ( ent:IsWorld() ) then return true end
		
		return true
	end
end

function ENT:OnReloaded()
	self:Remove()
end

function ENT:OnRemove()
	self:Reset()

	if IsValid( self.Parent ) then
		self.Parent:Remove()
	end
end

local function Box(min, max)
	local tab = {
		Vector(min.x, min.y, min.z),
		Vector(min.x, min.y, max.z),
		Vector(min.x, max.y, min.z),
		Vector(min.x, max.y, max.z),

		Vector(max.x, min.y, min.z),
		Vector(max.x, min.y, max.z),
		Vector(max.x, max.y, min.z),
		Vector(max.x, max.y, max.z)
	}

	return tab
end

function ENT:Reset()
	for k,v in pairs(self.InTrigger or {}) do
		if !IsValid(k) then
			continue
		end

		self:EndTouch( k )
	end

	self.InTrigger = {}
end

function ENT:SetBounds( minpos, maxpos )
	self:PhysicsInit( SOLID_NONE )
	self:SetMoveType( MOVETYPE_NONE )
	self:SetSolid( SOLID_BBOX )

	self:SetCollisionBounds( minpos, maxpos )
	self:SetNotSolid( true )
	
	self.minpos = minpos
	self.maxpos = maxpos
end

function ENT:DoCheckTrace( endpos )
	self.CheckTraceParams.start = self:GetPos()
	self.CheckTraceParams.endpos = endpos
	
	util.TraceLine( self.CheckTraceParams )	
	return self.CheckTrace.Hit
end

function ENT:CleanUpList()
	for k,v in pairs(self.InTrigger or {}) do
		if IsValid(k) then
			continue
		end

		self.InTrigger[k] = nil
	end
end

function ENT:Filter( ent )
	if ( !IsValid( ent ) ) then return false end
	if ( !IsValid( self ) ) then return false end

	local Parent = self.Parent
	if ( !IsValid( Parent ) ) then return false end
	if ( !ent:IsPlayer() ) then return false end

	return true
end

function ENT:StartTouch( ent )
	if !IsValid(self.Parent) then return end
	if !self.Parent.Active then return end

	--local ang = self:GetAngles()
	--local tab = Box(self.minpos, self.maxpos)
	--for k,v in pairs(tab) do
	--	debugoverlay.Cross( self:LocalToWorld( v ), 3, 0.2, color_white, false )
	--end

	if self.InTrigger[ent] then return end
	if !self:Filter( ent ) then return end

	local tr = self:GetTouchTrace()
	if self:DoCheckTrace( tr.HitPos ) then return end

	--debugoverlay.Cross( self.CheckTrace.HitPos, 3, 0.2, Color(255,255,0), false )
	--debugoverlay.Cross( self.CheckTrace.StartPos, 3, 0.2, Color(255,255,0), false )

	self:CleanUpList()

	local set = false
	for k,v in pairs(self.InTrigger or {}) do
		self.Parent:TurnON( k )
		set = true
		break
	end
	self.InTrigger[ent] = true

	if set then return end
	self.Parent:TurnON( ent )
end

function ENT:EndTouch( ent )
	if !IsValid(self.Parent) then return end
	if !self.Parent.Active then return end

	if !self.InTrigger[ent] then return end
	if !self:Filter( ent ) then return end

	self.InTrigger[ent] = nil
	self:CleanUpList()

	for k,v in pairs(self.InTrigger or {}) do
		self.Parent:TurnON( k )
		return
	end
end

function ENT:Touch( ent )
	self:StartTouch( ent )
end