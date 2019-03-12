AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_ent")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Thermal Discouragement Beam Emitter"
ENT.IsAperture 		= true
ENT.IsConnectable 	= true

ENT.LASER_BBOX 		= 1
ENT.MAX_REFLECTIONS = 256

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end
	
function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "DropAtStart")
	self:NetworkVar("Bool", 1, "Respawn")
	self:NetworkVar("Int", 2, "DropType")
end

function ENT:ModelToInfo()
	local modelToInfo = {
		["models/aperture/item_dropper.mdl"] = {open = "item_dropper_open", close = "item_dropper_close", opensound = "TA:ItemDropperOpen", closesound = "TA:ItemDropperClose", blockerZ = 45},
		["models/aperture/underground_boxdropper.mdl"] = {open = "open", close = "close", opensound = "TA:OldItemDropperOpen", closesound = "TA:OldItemDropperClose", blockerZ = 10},
	}
	return modelToInfo[self:GetModel()]
end

function ENT:DropTypeToInfo()
	local dropTypeToinfo = {
		[1] = {model = "models/portal_custom/metal_box_custom.mdl", class = "prop_physics"},
		[2] = {model = "models/portal_custom/underground_weighted_cube.mdl", class = "prop_physics"},
		[3] = {model = "models/portal_custom/metal_box_custom.mdl", class = "prop_physics", skin = 1},
		[4] = {model = "models/portal_custom/metal_ball_custom.mdl", class = "prop_physics"},
		[5] = {model = "models/aperture/reflection_cube.mdl", class = "prop_physics"},
		[6] = {class = "prop_monster_box"},
		[7] = {class = "ent_portal_bomb"}
	}
	return dropTypeToinfo[self:GetDropType()]
end

function ENT:Initialize()

	self.BaseClass.Initialize(self)
	
	if SERVER then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_VPHYSICS)
		self:GetPhysicsObject():EnableMotion(false)
		self:DrawShadow(false)
		self.CanDrop = true
		
		-- phys iris
		local modelInfo = self:ModelToInfo()
		local ent = ents.Create("prop_physics")
		ent:SetModel("models/props_phx/construct/metal_angle360.mdl")
		ent:SetPos(self:LocalToWorld(Vector(0, 0, -modelInfo.blockerZ)))
		ent:SetAngles(self:GetAngles())
		ent:SetNoDraw(true)
		ent:Spawn()
		ent:GetPhysicsObject():EnableMotion(false)
		self:DeleteOnRemove(ent)
		self.DropperBlockEntity = ent
		
		if self:GetDropAtStart() then
			timer.Simple(1, function() if IsValid(self) then self:Drop() end end)
		end
		
		if not WireAddon then return end
		self.Inputs = Wire_CreateInputs(self, {"Drop"})
	end
	
	if CLIENT then
		
	end
end

function ENT:Draw()
	self:DrawModel()
end

-- No more client side
if CLIENT then return end

function ENT:Think()
	self:NextThink(CurTime() + 0.1)
	-- skip if item dropper allready drops item
	if timer.Exists("TA:ItemDroper_Redrop"..self:EntIndex()) then return true end
	-- if item inside dropper was missing spawing another one
	if not IsValid(self.ItemInDropper) then
		local item = self:CreateItem()
		if not IsValid(self.LastDroppedItem) then self.LastDroppedItem = item end
	end
	-- if item is missing spawn another and if this function enabled
	if not IsValid(self.LastDroppedItem) and self:GetRespawn() then self:Drop() end
	
	return true
end

function ENT:CreateItem()
	local info = self:DropTypeToInfo()
	
	local item = ents.Create(info.class)
	if not IsValid(item) then return end
	if info.model then item:SetModel(info.model) end
	item:SetPos(self:LocalToWorld(Vector(0, 0, 80)))
	item:SetAngles(AngleRand())
	item:Spawn()
	if IsValid(item:GetPhysicsObject()) then item:GetPhysicsObject():Wake() end
	
	if info.skin then item:SetSkin( info.skin ) end
	if info.class == "prop_monster_box" then item.Cubemode = true end
	if info.class == "ent_portal_bomb" then item.BombDisabled = true end
	self.ItemInDropper = item
	self.ItemDropper_Fall = 0
	
	return item
end

function ENT:Drop()
	-- skip if item dropper allready drops item
	if not self.CanDrop then return end
	self.CanDrop = false
	local modelInfo = self:ModelToInfo()
	
	-- dissolve old entitie
	if IsValid(self.LastDroppedItem) and self.LastDroppedItem != self.ItemInDropper then 
		LIB_APERTURE:DissolveEnt(self.LastDroppedItem)
	end

	self:PlaySequence(modelInfo.open, 1.0)
	self:SetSkin(1)
	self:EmitSound(modelInfo.opensound)
	
	-- Droping item
	timer.Simple(0.2, function()
		local blocker = self.DropperBlockEntity
		if not IsValid(blocker) then return end
		if not IsValid(self.ItemInDropper) then return end
		blocker:GetPhysicsObject():EnableCollisions(false)
		
		local lastSpawnedItem = self.ItemInDropper
		if not IsValid(lastSpawnedItem) then return end
		local lastSpawnedItemPhys = lastSpawnedItem:GetPhysicsObject()
		if not IsValid(lastSpawnedItemPhys) then return end
		
		if lastSpawnedItem:GetClass() == "ent_portal_bomb" then lastSpawnedItem.BombDisabled = false end
		self.ItemInDropper = nil
		self.LastDroppedItem = lastSpawnedItem
	end)

	-- Close iris
	timer.Simple(1.5, function()
		if not IsValid(self) then return end
		local modelInfo = self:ModelToInfo()
		self:PlaySequence(modelInfo.close, 1.0)
		self:SetSkin(0)
		self:EmitSound(modelInfo.closesound)	
	end)

	-- Spawn new item
	timer.Create("TA:ItemDroper_Redrop"..self:EntIndex(), 2.5, 1, function()
		if not IsValid(self) then return end
		self:CreateItem()
		self.ItemDropper_Fall = 0
		local blocker = self.DropperBlockEntity
		blocker:GetPhysicsObject():EnableCollisions(true)
	end)

	timer.Create("TA:ItemDroper_CanDrop"..self:EntIndex(), 3.5, 1, function()
		if IsValid(self) then self.CanDrop = true end
	end)
end

function ENT:TriggerInput(iname, value)
	if not WireAddon then return end

	if iname == "Drop" then self:Drop() end
end

numpad.Register("PortalItemDropper_Drop", function(pl, ent, keydown)
	if not IsValid(ent) then return false end
	if keydown then ent:Drop() end
	return true
end)

function ENT:OnRemove()
	if IsValid(self.LastDroppedItem) then self.LastDroppedItem:Remove() end
	if IsValid(self.ItemInDropper) then self.ItemInDropper:Remove() end
end