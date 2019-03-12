AddCSLuaFile()
DEFINE_BASECLASS("base_aperture_ent")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED
local PortalButtons = PortalButtons

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

ENT.PrintName		= "Wired Button"
ENT.Editable		= istable(PortalButtons)
ENT.Spawnable		= false
ENT.AdminOnly		= false
ENT.Category		= "Portal"
ENT.RenderGroup		= RENDERGROUP_BOTH

ENT.IsPortalButton = true
ENT.IsPortalButtonEnt = true
ENT.IsConnectable = true

if ( WireAddon ) then
	ENT.WireDebugName = "Wired Portal Button"
end

function ENT:Changed( key )
	if ( !self.old ) then return false end
	if ( !key ) then return false end

	local old, new = self.old[key], self[key]
	if ( new ~= old ) then
		self.old[key] = new
		return true
	end
	return false
end

function ENT:NetworkKeyValue( key, value )
	if ( !key ) then return end

	local GET, SET = self["Get"..key], self["Set"..key]
	if ( !GET ) then error("self.Get"..key.."() missing!", 2) return end
	if ( !SET ) then error("self.Set"..key.."() missing!", 2) return end

	if ( value ~= nil ) then
		if ( self:Changed( key ) ) then
			SET( self, value )
		end
	end

	return GET( self )
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Active", {KeyName = "Active", Edit = {type = "Boolean", order = 1}})
	self:NetworkVar("Int", 1, "Key")
end

function ENT:SetAnim( Animation, Frame, Rate )
	if ( !self.Animated ) then
		-- This must be run once on entities that will be animated
		self.Animated = true
		self.AutomaticFrameAdvance = true
	end

	self:ResetSequence( Animation or 0 )
	self:SetCycle( Frame or 0 )
	self:SetPlaybackRate( Rate or 1 )
end

function ENT:SetAnimEX( ent, Animation, Frame, Rate )
	if ( !self.Animated ) then
		-- This must be run once on entities that will be animated
		self.Animated = true
		self.AutomaticFrameAdvance = true
	end

	self:ResetSequence( Animation or 0 )
	self:SetCycle( Frame or 0 )
	self:SetPlaybackRate( Rate or 1 )
end

if CLIENT then
	function ENT:Think()
		if ( !WireAddon ) then return end

		if ( CurTime() >= ( self.NextRBUpdate or 0 ) ) then
			self.NextRBUpdate = CurTime() + math.random( 30, 100 ) / 10
			Wire_UpdateRenderBounds( self )
		end
	end
	
	function ENT:DrawTranslucent()
		self:DrawModel()

		if ( !WireAddon ) then return end
		Wire_Render( self )
	end

	return
end

local function SpawnCPPI(class, ply)
	local ent = ents.Create( class )
	if !IsValid( ent ) then return end

	ent.Owner = ply
	if ent.CPPISetOwner then
		if IsValid( ply ) then
			ent:CPPISetOwner( ply )
		end
	end

	return ent
end

function ENT:Initialize()
	self:SetAnim(0)
	self:SetSkin(0)

	self.old = {}
	self.Active = true
	self:NetworkKeyValue("Active", self.Active)

	if ( WireAddon ) then
		self.Inputs = WireLib.CreateSpecialInputs( self,
			{"Activicate"},
			{"NORMAL", "NORMAL"}
		)
		self.Outputs = WireLib.CreateSpecialOutputs( self,
			{"Pressed",	"Active",	"Current Entity"},
			{"NORMAL",	"NORMAL",	"ENTITY"}
		)
	end
	
	self.Pressed = false
	self.CurrentEntity = NULL
	
	self:TurnOFF()
	self:UpdateOutputs()

	self:UpdateSettings()
end

function ENT:CreateTrigger()
	if IsValid( self.PlayerTrigger ) and self.PlayerTrigger.Parent == self then
		self.PlayerTrigger.OnRemove = function(ent)
			ent:Reset()
		end
	
		self.PlayerTrigger:Remove()
		self.PlayerTrigger = nil
	end

	local ent = SpawnCPPI( "trigger_aperture_floor_button", self.Owner )
	if !IsValid( ent ) then return end

	local pos = self:GetPos()
	local ang = self:GetAngles()
	
	ent:SetPos( pos + ang:Up() * self.PressTriggerHeight )
	ent:SetAngles( ang )
	ent:SetParent( self )
	ent:Spawn()
	ent:Activate()
	self.PlayerTrigger = ent
	
	return ent
end

function ENT:CreatePhys( model )
	if IsValid( self.ButtonPhysEnt ) and self.ButtonPhysEnt.Parent == self then
		self.ButtonPhysEnt.Parent = nil
		self.ButtonPhysEnt:Remove()
		self.ButtonPhysEnt = nil
	end

	local ent = SpawnCPPI( "phys_aperture_floor_button", self.Owner )
	if !IsValid( ent ) then return end

	local pos = self:GetPos()
	local ang = self:GetAngles()
	ent:SetModel( model )
	ent:SetPos( pos )
	ent:SetAngles( ang )
	ent:Spawn()
	ent:Activate()

	local con = ent:WeldToEnt( self )

	self.ButtonPhysEnt = ent
	return ent, con
end

function ENT:UpdateSettings()
	if !self.CanUpdateSettings then return end

	self:SetAnim(0)
	self:SetSkin(0)

	self:OnUpdateSettings()

	local self_phys = self:GetPhysicsObject()
	local button_phys = nil

	if IsValid( self.ButtonPhysEnt ) then
		button_phys = self.ButtonPhysEnt:GetPhysicsObject()
	end

	if IsValid( self_phys ) and IsValid( button_phys ) then
		button_phys:EnableMotion( self_phys:IsMotionEnabled() )
	end

	self.PressTriggerHeight = self.PressTriggerHeight or 10
	self.PressTriggerSize = self.PressTriggerSize or 15

	if self.UsePlayerTrigger then
		self:CreateTrigger()
		if !IsValid( self.PlayerTrigger ) then
			self:Remove()
			return
		end
		self.PlayerTrigger:SetBounds( Vector(-self.PressTriggerSize, -self.PressTriggerSize, 0), Vector(self.PressTriggerSize, self.PressTriggerSize, 4) )
	else
		self.PlayerTrigger = nil
	end

	self.PressTraceCount = self.PressTraceCount or 2
	if self.PressTraceCount and (self.PressTraceCount > 0) then
		self.PressTrace = {}
		self.PressTraceParams = {}

		self.PressTraceParams.output = self.PressTrace
		self.PressTraceParams.ignoreworld = true
		self.PressTraceParams.filter = function( ent )
			if ( !IsValid( self ) ) then return false end
			if ( !IsValid( ent ) ) then return false end

			if ( ent:IsWorld() ) then return false end
			if ( ent:IsPlayer() ) then return false end
			if ( ent == self ) then return false end
			if ( ent.IsPortalButtonPhys ) then return false end
			if ( ent.IsPortalButtonTrigger ) then return false end

			return self:Filter( ent )
		end
		
		self:CalcTracePoses()
	else
		self.PressTrace = nil
		self.PressTraceParams = nil
		self.TracePoses = nil
	end

	self:TurnOFF()
	self:UpdateOutputs()
	
	self:CheckPressed()
	self:EnableButtonPhys(!self.Pressed)
end

function ENT:OnUpdateSettings()
	return
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

function ENT:UpdateOutputs()
	if ( !WireAddon ) then return end
	print(self:GetKey())
	if self.Pressed then
		numpad.Activate(self:GetPlayer(), self:GetKey(), true)
	else
		numpad.Deactivate(self:GetPlayer(), self:GetKey(), false)
	end

	WireLib.TriggerOutput( self, "Pressed", self.Pressed and 1 or 0 )
	WireLib.TriggerOutput( self, "Active", self.Active and 1 or 0 )
	WireLib.TriggerOutput( self, "Current Entity", self.CurrentEntity or NULL )
end

function ENT:Filter( ent )
	return false
end

function ENT:OnChangePressEnt(ent_new, ent_old)
	MsgN(self, " OnChangePressEnt: Override me")
end

function ENT:OnTurnOn()
	MsgN(self, " OnTurnOn: Override me")
end

function ENT:OnTurnOFF()
	MsgN(self, " OnTurnOFF: Override me")
end

function ENT:EnableButtonPhys( bool )
	if !IsValid( self.ButtonPhysEnt ) then return end
	self.ButtonPhysEnt:EnableButtonPhys( bool )
end

function ENT:OnFreeze()
	if !IsValid( self.ButtonPhysEnt ) then return end
	self:EnableButtonPhys( false )

	timer.Simple( 0.01, function()
		if !IsValid( self ) then return end
		if !IsValid( self.ButtonPhysEnt ) then return end

		local self_phys = self:GetPhysicsObject()
		local button_phys = self.ButtonPhysEnt:GetPhysicsObject()
		if !IsValid( self_phys ) then return end
		if !IsValid( button_phys ) then return end

		self.ButtonPhysEnt:SetPos(self:GetPos())
		self.ButtonPhysEnt:SetAngles(self:GetAngles())
		self:EnableButtonPhys( true )
		button_phys:EnableMotion( self_phys:IsMotionEnabled() )
	end)
end

function ENT:OnUnfreeze()
	self:OnFreeze()
end

function ENT:TurnON( ent )
	if (!self.Active) then
		self:TurnOFF()
		return
	end

	if ( !IsValid(ent) ) then
		self:TurnOFF()
		return
	end

	if ( self.Pressed and self.CurrentEntity == ent ) then
		return
	end
	

	self:OnChangePressEnt(ent, self.CurrentEntity)

	local OldPressed = self.Pressed
	self.Pressed = true
	self.CurrentEntity = ent

	self:UpdateOutputs()

	if ( OldPressed ) then return end
	
	self:OnTurnOn()
end

function ENT:TurnOFF()
	if (!self.Pressed and !IsValid(self.CurrentEntity)) then return end

	if IsValid(self.CurrentEntity) then
		self:OnChangePressEnt(NULL, self.CurrentEntity)
	end

	local OldPressed = self.Pressed
	self.Pressed = false
	self.CurrentEntity = NULL

	self:UpdateOutputs()

	if ( !OldPressed ) then return end
	self:OnTurnOFF()
end

local PI = math.pi

function ENT:CalcTracePoses()
	local dist = PI / self.PressTraceCount
	
	self.TracePoses = {}
	for i=1, self.PressTraceCount do
		local rad = (dist * (i-1)) % PI
		local tan = 0
		local x = 0
		local y = 0

		if (rad < PI / 4) then
			x = 1
			y = math.tan( rad )
		elseif (rad >= PI / 4) and (rad < PI / 2) then
			x = 1 / math.tan( rad )
			y = 1
		elseif (rad >= PI / 2) and (rad < PI * 3 / 4) then
			x = 1 / math.tan( rad )
			y = 1
		elseif (rad >= PI * 3 / 4) then
			x = 1
			y = math.tan( rad )
		end
		
		x = math.Round(x, 6)
		y = math.Round(y, 6)
		
		self.TracePoses[i] = {
			{x,y}, {-x,-y}
		}
	end
end


function ENT:CheckPressed()
	if !self.Active then
		self:TurnOFF()
		return
	end

	if IsValid( self.PlayerTrigger ) then
		for k,v in pairs(self.PlayerTrigger.InTrigger or {}) do
			self:TurnON( k )
			return
		end
	end

	if self.TracePoses then
		local Pos = self:GetPos()
		local Ang = self:GetAngles()

		local Up = Ang:Up()
		local Forward = Ang:Forward()
		local Right = Ang:Right()
		local TraceCenter = Pos + Up * self.PressTriggerHeight 
		
		for k,v in pairs(self.TracePoses) do
			local Start = v[1]
			local End = v[2]
			
			local StartX = Start[1]
			local StartY = Start[2]
			local EndX = End[1]
			local EndY = End[2]
			
			local StartVector = TraceCenter + (Forward * StartX + Right * StartY) * self.PressTriggerSize
			local EndVector = TraceCenter + (Forward * EndX + Right * EndY) * self.PressTriggerSize
			
			--debugoverlay.Line( StartVector, EndVector, 0.1, color_white, false ) 

			self.PressTraceParams.start = StartVector
			self.PressTraceParams.endpos = EndVector

			util.TraceLine( self.PressTraceParams )

			local HitEnt = self.PressTrace.Entity
			if IsValid(HitEnt) then
				self:TurnON(HitEnt)
				return
			end
		end
	end

	self:TurnOFF()
end

function ENT:Think()
	self.Active = self:NetworkKeyValue("Active", self.Active) and !(!PortalButtons)
	self.ActiveChange = self.Active

	if ( self:Changed( "ActiveChange" ) ) then
		if !self.Active then
			self:TurnOFF()
			
			if IsValid( self.PlayerTrigger ) then
				self.PlayerTrigger:Reset()
			end
		end

		self:UpdateOutputs()
	end
	
	local Time = CurTime()
	if Time >= ( self.NextCheck or 0 ) then
		self.NextCheck = Time + 0.2
		self:CheckPressed()
	end

	self:NextThink( Time + 0.01 )
	return true
end

function ENT:OnRemove()
	self:TurnOFF()

	if IsValid( self.PlayerTrigger ) then
		self.PlayerTrigger:Remove()
	end

	if IsValid( self.ButtonPhysEnt ) then
		self.ButtonPhysEnt:Remove()
	end

	if ( WireAddon ) then
		WireLib.Remove(self)
	end
end

function ENT:OnRestore()
	if ( WireAddon ) then
		WireLib.Restored( self )
	end
end

function ENT:BuildDupeInfo()
	if ( WireAddon ) then
		return WireLib.BuildDupeInfo( self )
	end
end

function ENT:ApplyDupeInfo( ply, ent, info, GetEntByID )
	if ( WireAddon ) then
		WireLib.ApplyDupeInfo( ply, ent, info, GetEntByID )
	end
end

function ENT:PreEntityCopy()
	if ( WireAddon ) then
		-- build the DupeInfo table and save it as an entity mod
		local DupeInfo = self:BuildDupeInfo()
		if DupeInfo then
			duplicator.StoreEntityModifier(self, "WireDupeInfo", DupeInfo)
		end
	end
end

local function EntityLookup(CreatedEntities)
	return function(id, default)
		if id == nil then return default end
		if id == 0 then return game.GetWorld() end
		local ent = CreatedEntities[id] or (isnumber(id) and ents.GetByIndex(id))
		if IsValid(ent) then return ent else return default end
	end
end

function ENT:PostEntityPaste(Player,Ent,CreatedEntities)
	if Ent.EntityMods and Ent.EntityMods.WireDupeInfo then
		Ent:ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, EntityLookup(CreatedEntities))
	end
end

function ENT:PostEntityPaste( Player, Ent, CreatedEntities ) // apply the DupeInfo
	if ( !IsValid( Ent ) ) then return end

	Ent:SetAnim(0)
	Ent:SetSkin(0)

	Ent.Owner = Player
	Ent.CanUpdateSettings = true
	Ent:UpdateSettings()

	if ( WireAddon ) then
		-- We manually apply the entity mod here rather than using a
		-- duplicator.RegisterEntityModifier because we need access to the
		-- CreatedEntities table.
		if Ent.EntityMods and Ent.EntityMods.WireDupeInfo then
			Ent:ApplyDupeInfo(Player, Ent, Ent.EntityMods.WireDupeInfo, EntityLookup(CreatedEntities))
		end
	end
end

function ENT:OnEntityCopyTableFinish( data )
	PortalButtons.FilterDuplicatorTable( data )
end

if ( WireAddon ) then
	function ENT:TriggerInput( name, value )
		local wired = ( istable(self.Inputs) and IsValid( self.Inputs[name].Src ) )

		if ( name == "Activicate" ) then
			self.Active = tobool(value)
			self:Think()
		end
	end
end
