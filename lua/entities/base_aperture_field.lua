AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_ent")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Field Base"
ENT.IsAperture 		= true
ENT.IsConnectable 	= true

local FIELD_MODEL_SIZE = 120
local FIELD_TRIGGER_THICK = 2

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Enable")
	self:NetworkVar("Bool", 1, "Toggle")
	self:NetworkVar("Bool", 2, "StartEnabled")
	self:NetworkVar("Entity", 3, "SecondEmitter")
end

function ENT:Enable(enable)
	local secondEmitter = self:GetSecondEmitter()
	if not IsValid(secondEmitter) then return end
	local middlepos = (self:GetPos() + secondEmitter:GetPos()) / 2
	if self:GetEnable() != enable then
		if enable then
			self:EmitSound("TA:FizzlerEnable")
			sound.Play("TA:FizzlerEnable", middlepos, 85, 100, 1)
			self:PlaySequence("open", 1)
			secondEmitter:PlaySequence("open", 1)
		else
			sound.Play("TA:FizzlerDisable", middlepos, 85, 100, 1)
			self:PlaySequence("close", 1)
			secondEmitter:PlaySequence("close", 1)
		end
		
		self:SetEnable(enable)
	end
end

function ENT:EnableEX(enable)
	if self:GetToggle() then
		if enable then
			self:Enable(not self:GetEnable())
		end
		return true
	end
	
	if self:GetStartEnabled() then enable = !enable end
	self:Enable(enable)
end

if SERVER then
	function ENT:CreateSecondEmitter()
		local angles = self:GetAngles()
		local trace = util.QuickTrace(self:GetPos(), -self:GetRight() * LIB_MATH_TA.HUGE, function() end)
		if not trace.Hit then return end
		local ent = ents.Create("base_aperture_ent")
		if not IsValid(ent) then return end
		local _, ang = LocalToWorld(Vector(), Angle(0, 180, 0), Vector(), angles)
		ent:SetPos(trace.HitPos)
		ent:SetAngles(ang)
		ent:SetModel(self:GetModel())
		ent:Spawn()
		ent:PhysicsInitStatic(SOLID_VPHYSICS)
		self:PhysicsInitStatic(SOLID_VPHYSICS)
		self:SetSecondEmitter(ent)
		ent:DeleteOnRemove(self)
		self:DeleteOnRemove(ent)
	end

	function ENT:CreateTrigger()
		local ent = ents.Create("trigger_aperture_fizzler")
		if not IsValid(ent) then ent:Remove() end
		local secondEmitter = self:GetSecondEmitter()
		if not IsValid(secondEmitter) then return end
		local dist = self:GetPos():Distance(secondEmitter:GetPos())
		local vec1 = self:GetUp() * FIELD_MODEL_SIZE / 2 + self:GetForward() * FIELD_TRIGGER_THICK + self:GetRight() * dist
		local vec2 = self:GetUp() * -FIELD_MODEL_SIZE / 2 - self:GetForward() * FIELD_TRIGGER_THICK
		LIB_MATH_TA:FixMinMax(vec1, vec2)
		ent:SetPos(self:GetPos())
		ent:SetParent(self)
		ent:SetBounds(vec1, vec2)
		ent:Spawn()
		self.FieldTrigger = ent
	end

end

function ENT:Initialize()

	self.BaseClass.BaseClass.Initialize(self)
	
	if SERVER then
		self:CreateSecondEmitter()
		self:CreateTrigger()
	end
	
	if CLIENT then
		self.FieldsEntities = { }
	end
end

function ENT:Drawing()
	if not self:GetEnable() then return end
	
end

function ENT:Draw()
	self:DrawModel()
	
	if not self:GetEnable() then return end
end

if CLIENT then
	function ENT:ClearFields()
		if not IsValid(self) then return end
		for k,v in pairs(self.FieldsEntities) do
			v:Remove()
		end
		self.FieldsEntities = { }
	end
end

function ENT:Think()

	if CLIENT then

		-- clearing
		if not self:GetEnable() then 
			if self.FieldsEntities and #self.FieldsEntities > 0 then self:ClearFields() end
			return
		end
		
		local secondEmitter = self:GetSecondEmitter()
		if not IsValid(secondEmitter) then return end
		local dist = self:GetPos():Distance(secondEmitter:GetPos())
		if self.FieldStrech then
			if #self.FieldsEntities != 1 then
				self:ClearFields()
				local ent = ClientsideModel("models/aperture/effects/field_effect.mdl")
				ent:SetPos(self:LocalToWorld(Vector(0, dist / 2, 0)))
				ent:SetAngles(self:LocalToWorldAngles(Angle(0, 90, 0)))
				ent:SetColor(self.FieldColor)
				if self.FieldMaterial then ent:SetSubMaterial(0, self.FieldMaterial) end
				ent:SetNoDraw(true)
				
				-- streching model to full length
				local scale = Vector(dist / FIELD_MODEL_SIZE, 1, 1)
				local mat = Matrix()
				mat:Scale(scale)
				ent:EnableMatrix("RenderMultiply", mat)
				
				table.insert(self.FieldsEntities, ent)
			end
			
		else
			local requireToSpawn = math.ceil(dist / FIELD_MODEL_SIZE)
			
			-- clearing
			if requireToSpawn != #self.FieldsEntities then
				self:ClearFields()
				
				for i=0, self:GetPos():Distance(secondEmitter:GetPos()), FIELD_MODEL_SIZE do
					local ent = ClientsideModel("models/aperture/effects/field_effect.mdl")
					ent:SetPos(self:LocalToWorld(Vector(0, i + FIELD_MODEL_SIZE / 2, 0)))
					ent:SetAngles(self:LocalToWorldAngles(Angle(0, 90, 0)))
					ent:SetColor(self.FieldColor)
					
					if self.FieldMaterial then ent:SetSubMaterial(0, self.FieldMaterial) end
					
					table.insert(self.FieldsEntities, ent)
				end
			end
		end
	end
	
	if SERVER then
		if not self:GetEnable() then return end
	
		local secondEmitter = self:GetSecondEmitter()
		if not IsValid(secondEmitter) then return end
		local triggerEnt = self.FieldTrigger
		if not IsValid(triggerEnt) then return end
		local dist = self:GetPos():Distance(secondEmitter:GetPos())
		local vec1 = self:GetUp() * FIELD_MODEL_SIZE / 2 + self:GetForward() * FIELD_TRIGGER_THICK - self:GetRight() * dist
		local vec2 = self:GetUp() * -FIELD_MODEL_SIZE / 2 - self:GetForward() * FIELD_TRIGGER_THICK
		LIB_MATH_TA:FixMinMax(vec1, vec2)
		
		triggerEnt:SetBounds(vec1, vec2)
		triggerEnt:SetPos(self:GetPos())
	end
end

function ENT:Drawing()
	if not self:GetEnable() then return end
	if self.FieldStrech then
		self.FieldsEntities[1]:DrawModel()
	end
end

function ENT:OnRemove()
	self:StopSound("TA:WallEmiterEnabledNoises")

	if CLIENT then
		self:ClearFields()
	end
end

function ENT:PreEntityCopy()
	local entTable = self:GetTable()
	entTable.FieldTrigger = nil
	return true
end

if CLIENT then return end -- no more client side

function ENT:TriggerInput(iname, value)
	if not WireAddon then return end

	if iname == "Enable" then self:Enable(tobool(value)) end
end

numpad.Register("PortalField_Enable", function(pl, ent, keydown)
	if not IsValid(ent) then return false end
	ent:EnableEX(keydown)
	return true
end)
