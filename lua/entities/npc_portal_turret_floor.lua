AddCSLuaFile( )
DEFINE_BASECLASS("base_aperture_turret")

local WireAddon = WireAddon or WIRE_CLIENT_INSTALLED

ENT.PrintName 		= "Portal Turret Floor"

ENT.TurretEyePos 				= Vector(11.7, 0, 36.8)
ENT.TurretSoundFound 			= "TA:TurretDeployVO"
ENT.TurretSoundSearch 			= "TA:TurretSearchVO"
ENT.TurretSoundAutoSearch 		= "TA:TurretAutoSearchVO"
ENT.TurretRetract				= "TA:TurretRetractVO"
ENT.TurretSoundFizzle 			= "TA:TurretFizzleVO"
ENT.TurretSoundPickup 			= "TA:TurretPickupVO"
ENT.TurretDisabled				= "TA:TurretDisabledVO"
ENT.TurretPersonal				= ENT

local TURRET_STATE_IDLE 		= 1

if WireAddon then
	ENT.WireDebugName = ENT.PrintName
end

function ENT:Initialize()

	self.BaseClass.Initialize(self)
	
	if SERVER then
		self:SetModel("models/npcs/turret/turret.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		
		if self:GetStartEnabled() then self:Enable(true) end

		if not WireAddon then return end
		self.Inputs = Wire_CreateInputs(self, {"Enable"})
	end

	if CLIENT then
		
	end
end

-- no more client side
if CLIENT then return end

function ENT:MakeDifferent()
	local effectdata = EffectData()
	effectdata:SetEntity(self)
	util.Effect("portal_heart_effect", effectdata)
	
	self:EmitSound("TA:TurretDifferent")
	self.TurretDifferent = true
	self:SetNWBool("TA:TurretDifferent", true)
	self.CantShoot = true
end


function ENT:Think()
	self:NextThink(CurTime() + 1)
	self.BaseClass.Think(self)
	
	local constTbl = constraint.FindConstraints(self, "Weld")
	if constTbl then
		for k,v in pairs(constTbl) do
			if v.Ent1 == self then
				if v.Ent2:GetModel() == "models/portal_custom/metal_ball_custom.mdl" then
					if IsValid(self.Owner) then LIB_APERTURE.ACHIEVEMENTS:AchievAchievement(self.Owner, "inventor") end
				end
			elseif v.Ent2 == self then
				if v.Ent1:GetModel() == "models/portal_custom/metal_ball_custom.mdl" then
					if IsValid(self.Owner) then LIB_APERTURE.ACHIEVEMENTS:AchievAchievement(self.Owner, "inventor") end
				end
			end
		end
	end
	
	if IsValid(self.TurretPersonal) then return end
	if not self.TurretDifferent then
		-- Finding arount turret any entitie with cake in model name, and if it found change turret state to different
		local entities = ents.FindInSphere(self:GetPos(), 100)
		for k,v in pairs(entities) do
			local model = v:GetModel() and v:GetModel():lower() or ""
			if string.find(model, "cake") then
				local ply = v.Player
				if v.OnDieFunctions and v.OnDieFunctions.GetCountUpdate and v.OnDieFunctions.GetCountUpdate.Args and v.OnDieFunctions.GetCountUpdate.Args[1] then
					ply = v.OnDieFunctions.GetCountUpdate.Args[1]
				end
				if IsValid(ply) then LIB_APERTURE.ACHIEVEMENTS:AchievAchievement(ply, "im_different") end
				self:MakeDifferent()
				v:SetPos(Vector())
				v:Remove()
				break
			end
		end
	end
	
	if self.TurretSong then
		-- Stop sining if any turret have different state
		if self.TurretBundle then
			for k,v in pairs(self.TurretBundle) do
				if not IsValid(v) then self:StopSing() break end
				if v:GetTurretState() != TURRET_STATE_IDLE then
					self:StopSing()
					break
				end
			end
		end
		
		return true
	end
	if not self:GetEnable() then return true end
	if not self.TurretDifferent then return true end
	-- random turret speach
	if not timer.Exists("TA:Turret_Speach") then
		timer.Create("TA:Turret_Speach", 10.0, 1, function() end)
		self:EmitSound("TA:Turret_Speach")
	end
	
	if not self.TurretSong and self:GetTurretState() == TURRET_STATE_IDLE then
		local entities = ents.FindInSphere(self:GetPos(), 200)
		local turrets = {self}
		for k,v in pairs(entities) do
			if v != self and v:GetClass() == "npc_portal_turret_floor" and v.TurretDifferent and v:GetTurretState() == TURRET_STATE_IDLE and not v.TurretSong then
				table.insert(turrets, v)
			end
		end
		
		if table.Count(turrets) == 4 then
			for k,v in pairs(turrets) do
				timer.Simple(4, function() if not IsValid(v) then return end v:SingInit(k) end)
				v.TurretSong = true
				v.TurretBundle = turrets
			end
		end
	end
	
	return true
end

function ENT:StopSing()
	if not self.TurretSong then return end
	if not self.TurretBundle then return end
	for k,v in pairs(self.TurretBundle) do
		if IsValid(v) then
			v:StopSound("TA:TurretSong")
			v.TurretSong = false
			v.TurretBundle = nil
			v:PlaySequence("idle", 1.0)
		end
	end
end

function ENT:SingInit(turretInx)
	if not IsValid(self) then return end
	
	if turretInx == 1 then self:PlaySequence("3penny_hi", 1.0)
	elseif turretInx == 2 then self:PlaySequence("3penny_lo", 1.0)
	elseif turretInx == 3 then self:PlaySequence("3penny_mid", 1.0)
	elseif turretInx == 4 then self:PlaySequence("3penny_perc", 1.0) end

	if turretInx == 1 then
		if IsValid(self.Owner) then
			LIB_APERTURE.ACHIEVEMENTS:AchievAchievement(self.Owner, "turret_song")
		end
		
		self:EmitSound("TA:TurretSong")
	end
end

function ENT:OnRemove()
	if CLIENT then return end
	self:StopSing()
end