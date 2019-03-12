AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_ent")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Pneumatic Diversity Vent"
ENT.IsAperture 		= true
ENT.IsConnectable 	= true

local SUCK_RADIUS 	= 150

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end

function ENT:SetupDataTables()
	self:NetworkVar("Bool", 0, "Enable")
	self:NetworkVar("Bool", 1, "Toggle")
	self:NetworkVar("Bool", 2, "StartEnabled")
	self:NetworkVar("Bool", 3, "IgnoreAlive")
end

function ENT:Enable(enable)
	if self:GetEnable() != enable then
		if enable then
			self:EmitSound("TA:TubeSuck")
		else
			self:StopSound("TA:TubeSuck")
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

local function FilterValid(pipe, ent, routeInx)
	if not pipe.DivventFilter then return true end
	if not pipe.DivventFilter[routeInx] then return true end
	local filters = pipe.DivventFilter[routeInx]
	
	for k,v in pairs(filters) do
		local filterType = v.filterType
		local text = v.text
		local min, max = v.min, v.max
		
		if filterType == 1 then
			if ent:GetModel() == string.lower(text) then return true end
		elseif filterType == 2 then
			if ent:GetClass() == text then return true end
		elseif filterType == 3 then
			local physObj = ent:GetPhysicsObject()
			if IsValid(physObj) then
				local mass = physObj:GetMass()
				if mass >= min and mass < max then return true end
			end
		elseif filterType == 4 then
			local radius = ent:GetModelRadius()
			if radius >= min and radius < max then return true end
		elseif filterType == 5 then
			if ent:IsPlayer() or ent:IsNPC() then return true end
		elseif filterType == 6 then
			if not ent:IsPlayer() and not ent:IsNPC() then return true end
		end
	end
end

local function CalcPipeFlow(info, inx, ent, pointIgnore, ignore, checkEntFilter, onePath)
	local pointInfo = info[inx]
	local pointIgnore = pointIgnore and pointIgnore or {[inx] = true}
	local returnDat = {}
	local dirtbl = {}
	local splits = 0
	
	for k,v in pairs(pointInfo.connected) do
		if not pointIgnore[v] and (not IsValid(checkEntFilter) or FilterValid(ent, checkEntFilter, v)) then
			splits = splits + 1
			table.insert(dirtbl, v)
		end
	end
	
	if onePath then
		local stop = false
		
		while true do
			if #dirtbl == 0 then return returnDat end
			local rand = math.random(1, #dirtbl)
			local dirinx = dirtbl[rand]
			local outinx = info[dirinx].outinx
			local pos = info[dirinx].pos
			pointIgnore[dirinx] = true
			
			if outinx then
				local exitPipe = ent:GetNWEntity("TA:ConnectedPipe:"..outinx)
				local exitPipeInx = ent:GetNWInt("TA:ConnectedPipeInx:"..outinx)
				table.insert(returnDat, ent:LocalToWorld(pointInfo.pos))
				
				if IsValid(exitPipe) then
					if exitPipe:GetClass() != "ent_diversity_vent" then
						local path = CalculateFlows(exitPipe, exitPipeInx, ignore, _, checkEntFilter, onePath)
						if path then
							table.Add(returnDat, path)
							return returnDat
						else table.remove(dirtbl, rand) end
					end
				else
					local wpos = ent:LocalToWorld(pos)
					table.insert(returnDat, wpos)
					return returnDat
				end
			else
				table.remove(dirtbl, rand)
				table.insert(returnDat, ent:LocalToWorld(pointInfo.pos))
				table.Add(returnDat, CalcPipeFlow(info, dirinx, ent, pointIgnore, ignore, checkEntFilter, onePath))
			end
		end
	else
		for k,v in pairs(dirtbl) do
			local outinx = info[v].outinx
			local pos = info[v].pos
			pointIgnore[v] = true
			
			if outinx then
				local exitPipe = ent:GetNWEntity("TA:ConnectedPipe:"..outinx)
				local exitPipeInx = ent:GetNWInt("TA:ConnectedPipeInx:"..outinx)
				table.insert(returnDat, ent:LocalToWorld(pointInfo.pos))
				
				if IsValid(exitPipe) then
					if exitPipe:GetClass() != "ent_diversity_vent" then
						local path = CalculateFlows(exitPipe, exitPipeInx, ignore, _, checkEntFilter)
						if splits > 1 then table.Add(returnDat, {path}) else table.Add(returnDat, path) end
					end
				else
					local wpos = ent:LocalToWorld(pos)
					if splits > 1 then table.insert(returnDat, {wpos}) else table.insert(returnDat, wpos) end
				end
			else
				table.insert(returnDat, ent:LocalToWorld(pointInfo.pos))
				table.Add(returnDat, CalcPipeFlow(info, v, ent, pointIgnore, ignore, checkEntFilter))
			end
		end
	end
	
	-- if #returnDat == 0 then
		-- table.insert(returnDat, ent:LocalToWorld(pointInfo.pos))
	-- end

	return returnDat
end

function CalculateFlows(ent, index, ignore, startent, checkEntFilter, onePath)
	if IsValid(startent) and not IsValid(startent:GetNWEntity("TA:ConnectedPipe:1")) then return end
	
	local ent = ent and ent or startent:GetNWEntity("TA:ConnectedPipe:1")
	local index = index and index or startent:GetNWInt("TA:ConnectedPipeInx:1")
	local ignore = ignore and ignore or {}
	if IsValid(startent) then ignore[startent:EntIndex().."|"..1] = true end
	if ignore[ent:EntIndex().."|"..index] then return {} end
	ignore[ent:EntIndex().."|"..index] = true
	
	local info = ent:GetModelFlowData()
	return CalcPipeFlow(info, index, ent, nil, ignore, checkEntFilter, onePath)
end

function CalculateFlow(flowstbl)
	local flow = {}
	for k,v in pairs(flowstbl) do
		if istable(v) then
			local randtbl = {}
			for i=k,#flowstbl do
				if istable(flowstbl[i]) then table.insert(randtbl, i) end
			end
			local rand = randtbl[math.random(1, #randtbl)]
			table.Add(flow, CalculateFlow(flowstbl[rand]))
			break
		else
			table.insert(flow, v) 
		end
	end
	return flow
end

function ENT:Initialize()

	self.BaseClass.Initialize(self)
	
	if SERVER then
		self:SetModel("models/aperture/vacum_flange_a.mdl")
		self:PhysicsInitStatic(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetCollisionGroup(COLLISION_GROUP_WORLD)
		
		if self:GetStartEnabled() then self:Enable(true) end
		
		if not WireAddon then return end
		self.Inputs = Wire_CreateInputs(self, {"Enable"})
	end

	if CLIENT then
		
	end
end

function ENT:HandleEntities(ent, portalable, fromportal)
	if portalable and ent:GetClass() == "prop_portal" then
		local portalOther = ent:GetNWEntity("Potal:Other")
			if IsValid(portalOther) then
			local entities = ents.FindInSphere(portalOther:GetPos(), SUCK_RADIUS)
			
			local effectdata = EffectData()
			effectdata:SetOrigin(portalOther:GetPos())
			effectdata:SetNormal(portalOther:GetForward())
			util.Effect("tube_suck_effect", effectdata)
			
			for k,v in pairs(entities) do
				self:HandleEntities(v, false, portalOther)
			end
		end
	end

	if ent.IsAperture then return end
	if not IsValid(ent:GetPhysicsObject()) then return end
	if self:GetIgnoreAlive() and (ent:IsPlayer() or ent:IsNPC()) then return end
	if LIB_APERTURE.DIVVENT_ENTITIES[ent] then return end
	if not IsValid(self:GetNWEntity("TA:ConnectedPipe:1")) then return end
	if not ent:GetPhysicsObject():IsMotionEnabled() then return end
	-- if ent:GetCollisionGroup() != COLLISION_GROUP_NONE and ent:GetCollisionGroup() != COLLISION_GROUP_PLAYER then return end
	if ent:GetMoveType() == MOVETYPE_PUSH then return end
	
	local flow = {}
	-- if vent is from portal then suck at portal first
	if IsValid(fromportal) then
		table.insert(flow, fromportal:LocalToWorld(Vector(-(ent:GetModelScale() + 40), 0, 0)))
	else
		flow = CalculateFlows(nil, nil, nil, self, ent, true)
	end
	
	LIB_APERTURE.DIVVENT_ENTITIES[ent] = {flow = flow, vent = self, index = 1}
end


-- no more client side
if CLIENT then return end

function ENT:UpdatePipe(updateConnected)
end

function ENT:Think()
	self:NextThink(CurTime() + 0.1)
	-- skip if disabled
	if not self:GetEnable() then return end

	local effectdata = EffectData()
	effectdata:SetOrigin(self:GetPos())
	effectdata:SetNormal(self:GetRight())
	util.Effect("tube_suck_effect", effectdata)
	
	local entities = ents.FindInSphere(self:LocalToWorld(Vector(0, -SUCK_RADIUS, 0)), SUCK_RADIUS)
	for k,v in pairs(entities) do
		self:HandleEntities(v, true)
	end
	
	return true
end

numpad.Register("DiversityVent_Enable", function(pl, ent, keydown)
	if not IsValid(ent) then return false end
	ent:EnableEX(keydown)
	return true
end)

function ENT:OnRemove()
	self:StopSound("TA:TubeSuck")
end
