AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_ent")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Hight Energy Pellet Catcher"
ENT.IsAperture 		= true
ENT.IsConnectable 	= true

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end

if SERVER then
	function ENT:CreateTrigger()
		local ent = ents.Create("trigger_aperture_fizzler")
		if not IsValid(ent) then ent:Remove() end
		ent:SetPos(self:LocalToWorld(Vector(20, 0, 0)))
		ent:SetParent(self)
		ent:SetBounds(Vector(1, 1, 1) * -20, Vector(1, 1, 1) * 20)
		ent:Spawn()
		self.CatcherTrigger = ent
	end
end

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Key")
	self:NetworkVar("Bool", 1, "Active")
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:Initialize()
	self.BaseClass.Initialize(self)

	if SERVER then
		self:SetModel("models/aperture/combine_ball_catcher.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetActive(false)
		self:GetPhysicsObject():EnableMotion(false)
		
		self:CreateTrigger()
		
		if not WireAddon then return end
		self.Outputs = WireLib.CreateSpecialOutputs(self, {"Activated"}, {"NORMAL"})
	end

	if CLIENT then

	end
end

if CLIENT then return end

function ENT:Think()
	self:NextThink(CurTime() + 0.1)
	
	return true
end

function ENT:HandleEntity(ent)
	if self:GetActive() then return end
	if ent:GetClass() == "prop_combine_ball" then
		self:ConsumeBall(ent)
	end
end

function ENT:ConsumeBall(ent)
	if WireAddon then Wire_TriggerOutput(self, "Activated", 1) end
	numpad.Activate(self:GetPlayer(), self:GetKey(), true)
	sound.Play("TA:BallCatch", self:LocalToWorld(Vector(30, 0, 0)))
	self:SetActive(true)
	self:PlaySequence("close", 1.0)
	ent:Remove()
end

function ENT:Setup()
	if not WireAddon then return end
	Wire_TriggerOutput(self, "Activated", 0)
end

function ENT:OnRemove()
	if not IsValid(self) then return end
	numpad.Deactivate(self:GetPlayer(), self:GetKey(), false)
end