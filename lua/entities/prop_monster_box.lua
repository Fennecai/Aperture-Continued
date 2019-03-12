AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_ent")

ENT.Editable		= true
ENT.PrintName		= "Frankenturret"
ENT.Category		= "Aperture Science"
ENT.Spawnable 		= true
ENT.AutomaticFrameAdvance = true

ENT.IsConnectable 	= false

function ENT:SpawnFunction(ply, trace, className)
	if not trace.Hit then return end
	
	local ent = ents.Create(className)
	ent:SetPos(trace.HitPos + trace.HitNormal * 30)
	ent:SetAngles(Angle(0, ply:EyeAngles().y, 0))
	ent:Spawn()
	
	return ent
end

function ENT:Draw()
	self:DrawModel()
end

-- no more client side
if CLIENT then return end

function ENT:Initialize()
	self:SetModel("models/aperture/monster_cube.mdl")
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self.Cubemode = false
	
	for k, v in pairs(self:GetBodyGroups()) do
		if math.random(0, 1) == 1 then self:SetBodygroup(v.id, 1) end
	end
end

function ENT:Think()

	self:NextThink(CurTime() + 0.1)
	local traceBottom = util.QuickTrace(self:GetPos() + self:GetForward() * 20, -self:GetUp() * 50, self)
	
	-- random chitter sounds
	if not timer.Exists("TA:Monsterbox_Chitter"..self:EntIndex()) then 
		timer.Create("TA:Monsterbox_Chitter"..self:EntIndex(), math.Rand(1, 3), 1, function() end)
		self:EmitSound("TA:MonsterBoxChitter")
	end
	
	local traceDown = util.QuickTrace(self:GetPos(), -Vector(0, 0, 50), self)
	-- When player is holding release cube mode toggle
	if self:IsPlayerHolding() then self.Cubemode = false end
	-- When player is holding or it stand on the button transform into a cube mode
	if self:IsPlayerHolding() or self.Cubemode 
		or (IsValid(traceDown.Entity) and (traceDown.Entity:GetClass() == "sent_portalbutton_box"
		or traceDown.Entity:GetClass() == "sent_portalbutton_normal"
		or traceDown.Entity:GetClass() == "sent_portalbutton_old"
		or traceDown.Entity:GetClass() == "portalbutton_phys")) then
		
		if not timer.Exists( "TA:Monsterbox_Hermit"..self:EntIndex()) then 
			timer.Create("TA:Monsterbox_Hermit"..self:EntIndex(), self:PlaySequence("hermit_idle", 1.0 ), 1, function() end)
		end
		
		return true
		
	end

	if not traceDown.Hit then
		-- When box in the air
		if not timer.Exists("TA:Monsterbox_Intheair"..self:EntIndex()) then 
			timer.Create( "TA:Monsterbox_Intheair"..self:EntIndex(), self:PlaySequence("intheair", 1.0 ), 1, function() end )
		end

		return true		
	end

	-- When box is fallower
	if not traceBottom.Hit then
		if not timer.Exists("TA:Monsterbox_Fallover"..self:EntIndex()) then 
			timer.Create( "TA:Monsterbox_Fallover"..self:EntIndex(), self:PlaySequence("fallover_idle", 1.0), 1, function() end)
		end
		if timer.Exists("TA:Monsterbox_Trapped"..self:EntIndex()) then timer.Remove("TA:Monsterbox_Trapped"..self:EntIndex()) end
		return true
	else
		-- When box is trapped
		local traceForward = util.QuickTrace(self:GetPos(), self:GetForward() * 60, self)
		if traceForward.Hit then
			if not timer.Exists("TA:Monsterbox_Trapped"..self:EntIndex()) then 
				timer.Create( "TA:Monsterbox_Trapped"..self:EntIndex(), self:PlaySequence("trapped", 1.0), 0, function() end)
			end
			return true
			
		elseif timer.Exists("TA:Monsterbox_Trapped"..self:EntIndex()) then timer.Remove("TA:Monsterbox_Trapped"..self:EntIndex()) end
	end
	
	-- Default box jump-walk
	if not timer.Exists("TA:Monsterbox_Straight"..self:EntIndex()) then 
		local animType = math.random(1, 3)
		timer.Create("TA:Monsterbox_Straight"..self:EntIndex(), self:PlaySequence("straight0"..animType, 1.0), 1, function() end)

		if animType == 1 then
			timer.Simple(0.25, function() if IsValid(self) then self:Jump(100, 100) end end)
			timer.Simple(1.5, function() if IsValid(self) then self:Jump(100, 100) end end )
		elseif animType == 2 then
			timer.Simple(0, function() if IsValid(self) then self:Jump(100, 100) end end)
			timer.Simple(0.5, function() if IsValid(self) then self:Jump(80, 100) end end)
			timer.Simple(1.2, function() if IsValid(self) then self:Jump(80, 85) end end)
		elseif animType == 3 then
			timer.Simple(0.25, function() if IsValid(self) then self:Jump(150, 100) end end)
		end
	end

	return true
end

function ENT:Jump(force, forceUp)
	if not IsValid(self) then return true end 
	local traceBottom = util.QuickTrace(self:GetPos() + self:GetForward() * 20, -self:GetUp() * 50, self)
	if not traceBottom.Hit then return true end
	-- skip if it trapped or player is holding it
	if timer.Exists("TA:Monsterbox_Trapped"..self:EntIndex()) or self:IsPlayerHolding() then return end
	
	self:GetPhysicsObject():SetVelocity(self:GetForward() * force + Vector(0, 0, forceUp))
	self:EmitSound("TA:MonsterBoxKick")
	
	timer.Simple(0.25, function() if IsValid(self) then self:EmitSound("TA:MonsterBoxFootsteps") end end)
end

function ENT:OnRemove()
	timer.Remove("TA:Monsterbox_Trapped"..self:EntIndex())

end
