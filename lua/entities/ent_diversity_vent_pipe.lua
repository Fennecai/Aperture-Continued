AddCSLuaFile( )

if not LIB_APERTURE then error("Error: Aperture lib does not exit!!!") end

DEFINE_BASECLASS("base_anim")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Pneumatic Direvsity Vent Pipe"
ENT.IsAperture 		= true

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end

local EXIT_MODEL = "models/aperture/vacum_flange_a.mdl"

function ENT:GetModelConnectionData()
	return LIB_APERTURE:GetModelConnectionData(self)
end

function ENT:GetModelFlowData()
	return LIB_APERTURE:GetModelFlowData(self)
end

function ENT:Initialize()
	if SERVER then
		self:PhysicsInitStatic(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		
		self.ExitEntities = { }
	end
	
	if CLIENT then
		
	end
end

-- no more client side
if CLIENT then return end

function ENT:RemoveConnection(inx)
	local connectedEnt = self:GetNWEntity("TA:ConnectedPipe:"..inx)
	local connectedPipeInx = self:GetNWInt("TA:ConnectedPipeInx:"..inx)
	connectedEnt:SetNWEntity("TA:ConnectedPipe:"..connectedPipeInx, nil)
end

function ENT:UpdatePipe(updateConnected, removeConnection)
	local coords = self:GetModelConnectionData()
	for k,v in pairs(coords) do
		local connectedEnt = self:GetNWEntity("TA:ConnectedPipe:"..k)
		local lastExitEnt = self.ExitEntities[k]
		
		if IsValid(connectedEnt) then
			if removeConnection then self:RemoveConnection(k) end
			if updateConnected then connectedEnt:UpdatePipe() end
			
			if IsValid(lastExitEnt) then
				lastExitEnt:Remove()
			end
		elseif not IsValid(lastExitEnt) then
			local ent = ents.Create("prop_physics")
			ent:SetModel(EXIT_MODEL)
			ent:SetPos(self:LocalToWorld(v.pos))
			ent:SetAngles(self:LocalToWorldAngles(v.ang))
			ent:SetAngles(ent:LocalToWorldAngles(Angle(0, 0, 90)))
			ent:Spawn()
			ent:SetNotSolid(true)
			ent:PhysicsInitStatic(SOLID_VPHYSICS)
			self:DeleteOnRemove(ent)
			
			self.ExitEntities[k] = ent
		end
	end
end

-- function ENT:Think()
	-- self:NextThink(CurTime() + 1)
	-- -- local anyConnection = false
	-- -- local flowinfo = self:ModelToFlowPos()
	-- -- if not flowinfo then return end
	
	-- -- for i=0,#flowinfo do
		-- -- if IsValid(self:GetNWEntity("TA:ConnectedPipe:"..i)) then anyConnection = true end
	-- -- end

	-- -- if IsValid(self:GetNWEntity("TA:Vent")) and anyConnection then
		-- -- self:SetColor(Color(255, 255, 255))
	-- -- else
		-- -- self:SetColor(Color(255, 0, 0))
	-- -- end
	
	-- return true
-- end

function ENT:OnRemove()
	if not IsValid(self) then return end
	self:UpdatePipe(true, true)
end
