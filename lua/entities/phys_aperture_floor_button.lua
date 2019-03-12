AddCSLuaFile()
DEFINE_BASECLASS("base_anim")

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
local timer = timer

ENT.Spawnable			= false
ENT.AdminOnly			= false
ENT.RenderGroup 		= RENDERGROUP_OPAQUE

ENT.IsPortalButtonPhys = true
ENT.IsPortalButtonEnt = true
ENT.DoNotDuplicate = true

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetNoDraw(true)

	self.PhysTrace = {}
	self.PhysTraceParams = {}
	self.PhysTraceParams.ignoreworld = true
	self.PhysTraceParams.filter = function(ent)
		if ( !IsValid( self ) ) then return false end
		if ( !IsValid( ent ) ) then return false end

		if ( ent:IsWorld() ) then return false end
		if ( !ent:IsPlayer() ) then return false end
		if ( ent == self.Parent ) then return false end
		if ( ent.IsPortalButtonPhys ) then return false end
		if ( ent.IsPortalButtonTrigger ) then return false end

		return true
	end
	self.PhysTraceParams.output = self.PhysTrace
	
	self:EnableButtonPhys( true )
end

function ENT:WeldToEnt( ent )
	if !IsValid( ent ) then
		return
	end
	self.Parent = ent

	local con = constraint.Find( ent, self, "Weld", 0, 0 )
	if IsValid(con) then
		con:DeleteOnRemove(self)
		con.DoNotDuplicate = true
		self.Constraint = con
		return con
	end

	con = constraint.Weld( ent, self, 0, 0, 0, true, false )
	if !IsValid( con ) then
		return
	end

	con:DeleteOnRemove(self)
	con.DoNotDuplicate = true
	self.Constraint = con

	return con
end

function ENT:OnTakeDamage( dmg )
	self:TakePhysicsDamage( dmg )
end

function ENT:OnReloaded()
	self:Remove()
end

function ENT:UpdateTransmitState()
	return TRANSMIT_PVS
end

function ENT:EnableButtonPhys( bool )
	if !IsValid( self.Parent ) then return end
	if !self.PhysTraceParams then return end

	local phys = self:GetPhysicsObject()
	if !IsValid( phys ) then return end

	local timername = tostring( self ) .. "_PhysOFF"
	timer.Remove( timername ) 

	if !bool then
		self:SetNotSolid( true )
		phys:EnableCollisions( false ) 
		phys:Wake()
		
		return
	end
	self:EnableButtonPhys( false )

	timer.Create( timername, 0.25, 0, function()
		if !IsValid( self ) then
			timer.Remove( timername ) 
			return
		end

		if !IsValid( self.Parent ) then
			timer.Remove( timername ) 
			return
		end

		if self.Parent.Pressed then
			timer.Remove( timername )
			self:EnableButtonPhys( false )
			return
		end

		local phys = self:GetPhysicsObject()
		if !IsValid( phys ) then
			timer.Remove( timername )
			return
		end

		local parent_phys = self.Parent:GetPhysicsObject()
		if !IsValid( parent_phys ) then
			timer.Remove( timername )
			return
		end

		if !parent_phys:IsCollisionEnabled() then
			timer.Remove( timername )
			return
		end

		self.PhysTraceParams.start = self:GetPos()
		self.PhysTraceParams.endpos = self.PhysTraceParams.start + self:GetUp() * 16
		
		util.TraceEntity( self.PhysTraceParams, self )
		if IsValid( self.PhysTrace.Entity ) then return end
		
		self:SetNotSolid( false )
		phys:EnableCollisions( true ) 
		phys:Wake()
		timer.Remove( timername )
	end)
end

function ENT:OnFreeze()
	if !IsValid( self.Parent ) then return end
	self:EnableButtonPhys( false )

	timer.Simple( 0.01, function()
		if !IsValid( self ) then return end
		if !IsValid( self.Parent ) then return end

		local self_phys = self:GetPhysicsObject()
		local parent_phys = self.Parent:GetPhysicsObject()
		if !IsValid( self_phys ) then return end
		if !IsValid( parent_phys ) then return end

		self:SetPos(self.Parent:GetPos())
		self:SetAngles(self.Parent:GetAngles())
		self:EnableButtonPhys( true )
		parent_phys:EnableMotion( self_phys:IsMotionEnabled() )
	end)
end

function ENT:OnUnfreeze()
	self:OnFreeze()
end

function ENT:Think()

end

function ENT:OnRemove()
	if IsValid( self.Parent ) then
		self.Parent:Remove()
		self.Parent = nil
	end

	if IsValid( self.Constraint ) then
		self.Constraint:Remove()
		self.Constraint = nil
	end
end