AddCSLuaFile( )

ENT.Type = "anim"
ENT.Spawnable = false
ENT.AutomaticFrameAdvance = true

local Sequences = {
	[""] = { stand = "idle_all_01", //idle_all_01
		walk = "walk_all",
		run = "run_all_01",
		crouch = "cidle_all",
		crouch_walk = "cwalk_all" },
	["pistol"] = { stand = "idle_pistol",
		walk = "walk_pistol",
		run = "run_pistol",
		crouch = "cidle_pistol",
		crouch_walk = "cwalk_pistol" },
	["melee"] = { stand = "idle_melee",
		walk = "walk_melee",
		run = "run_melee",
		crouch = "cidle_melee",
		crouch_walk = "cwalk_melee" },
	["revolver"] = { stand = "idle_revolver",
		walk = "walk_revolver",
		run = "run_revolver",
		crouch = "cidle_revolver",
		crouch_walk = "cwalk_revolver" },
	["smg"] = { stand = "idle_smg1",
		walk = "walk_smg1",
		run = "run_smg1",
		crouch = "cidle_smg1",
		crouch_walk = "cwalk_smg1" },
	["ar2"] = { stand = "idle_ar2",
		walk = "walk_ar2",
		run = "run_ar2",
		crouch = "cidle_ar2",
		crouch_walk = "cwalk_ar2" },
	["shotgun"] = { stand = "idle_shotgun",
		walk = "walk_shotgun",
		run = "run_shotgun",
		crouch = "cidle_shotgun",
		crouch_walk = "cwalk_shotgun" },
	["crossbow"] = { stand = "idle_crossbow",
		walk = "walk_crossbow",
		run = "run_crossbow",
		crouch = "cidle_crossbow",
		crouch_walk = "cwalk_crossbow" },
	["grenade"] = { stand = "idle_grenade",
		walk = "walk_grenade",
		run = "run_grenade",
		crouch = "cidle_grenade",
		crouch_walk = "cwalk_grenade" },
	["rpg"] = { stand = "idle_rpg",
		walk = "walk_rpg",
		run = "run_rpg",
		crouch = "cidle_rpg",
		crouch_walk = "cwalk_rpg" },
	["physgun"] = { stand = "idle_physgun",
		walk = "walk_physgun",
		run = "run_physgun",
		crouch = "cidle_physgun",
		crouch_walk = "cwalk_physgun" },
	["camera"] = { stand = "idle_camera",
		walk = "walk_camera",
		run = "run_camera",
		crouch = "cidle_camera",
		crouch_walk = "cwalk_camera" },
	["fist"] = { stand = "idle_fist",
		walk = "walk_fist",
		run = "run_fist",
		crouch = "cidle_fist",
		crouch_walk = "cwalk_fist" },
	["magic"] = { stand = "idle_magic",
		walk = "walk_magic",
		run = "run_magic",
		crouch = "cidle_magic",
		crouch_walk = "cwalk_magic" },
	["dual"] = { stand = "idle_dual",
		walk = "walk_dual",
		run = "run_dual",
		crouch = "cidle_dual",
		crouch_walk = "cwalk_dual" },
	["slam"] = { stand = "idle_slam",
		walk = "walk_slam",
		run = "run_slam",
		crouch = "cidle_slam",
		crouch_walk = "cwalk_slam" },
}

function ENT:GetPlayer()
	return self:GetNWEntity("Player")
end

function ENT:Initialize()
	if SERVER then
		self:SetMoveType(MOVETYPE_NONE)
		self:SetSolid(SOLID_NONE)
		
		local weapon = ents.Create("prop_physics")
		weapon:SetModel("models/weapons/w_physics.mdl")
		weapon:PhysicsInitStatic(SOLID_VPHYSICS)
		-- weapon:Spawn()
		weapon:SetNotSolid(true)
		self:DeleteOnRemove(weapon)
		self:SetNWEntity("FakeWeapon", weapon)
	end
	
	if CLIENT then
		self:SetNoDraw(true)
	end
end

function ENT:Draw()
	local ply = self:GetNWEntity("Player")

	local color = self:GetNWVector("PlayerColor")
	self.GetPlayerColor = function() return color end
	self:DrawModel()
end

if SERVER then

function ENT:SetPlayer(ply)
	local color = ply:GetColor()
	ply:SetNWEntity("TA:Avatar", self)
	self:SetNWEntity("Player", ply)
	-- ply:SetNoDraw(true)
	
	if IsValid(ply) and ply:IsPlayer() then
		local model = ply:GetModel()
		local color = ply:GetPlayerColor()
		util.PrecacheModel(model)
		self:SetModel(model)
		self:SetSkin(ply:GetSkin())
		table.Merge(self:GetTable(), ply:GetTable())
		
		self.GetPlayerColor = function() return color end
		self:SetNWVector("PlayerColor", color)
		
		for i = 0, ply:GetNumBodyGroups() - 1 do self:SetBodygroup(i, ply:GetBodygroup(i)) end
	end
end

end

if CLIENT then

local pi2 = math.pi * 2

function ENT:WalkAnim(angRot, speed, amp)
	local rThigh = self:LookupBone("ValveBiped.Bip01_R_Thigh")
	local lThigh = self:LookupBone("ValveBiped.Bip01_L_Thigh")
	local rCalf = self:LookupBone("ValveBiped.Bip01_R_Calf")
	local lCalf = self:LookupBone("ValveBiped.Bip01_L_Calf")
	
	if not self.walkCycle then self.walkCycle = 0 end
	local walkCycle = self.walkCycle
	self.walkCycle = walkCycle + speed * FrameTime()
	if walkCycle > pi2 then walkCycle = (walkCycle - pi2)
		self.walkCycle = walkCycle
	elseif walkCycle < -pi2 then walkCycle = (walkCycle + pi2)
		self.walkCycle = walkCycle
	end
	
	local angle = math.cos(walkCycle) * 45
	local angle2 = math.sin(walkCycle) * 60
	local pelvisUp = math.sin(walkCycle * 2) * 2
	
	self:ManipulateBoneAngles(rThigh, Angle(angRot.y * (angle + 10), angRot.x * (angle + 10), 0) * amp)
	self:ManipulateBoneAngles(lThigh, Angle(angRot.y * (-angle + 10), angRot.x * (-angle + 10), 0) * amp)
	self:ManipulateBoneAngles(rCalf, Angle(0, angle2 + 30, 0) * amp)
	self:ManipulateBoneAngles(lCalf, Angle(0, -angle2 + 30, 0) * amp)
	self:ManipulateBonePosition(0, Vector(0, 0, pelvisUp) * amp)

end

function ENT:Animate(angle, ply)

	if not self.walkspeed then self.walkspeed = 0 end
	local spine = self:LookupBone("ValveBiped.Bip01_Spine")
	local spine1 = self:LookupBone("ValveBiped.Bip01_Spine1")
	local spine2 = self:LookupBone("ValveBiped.Bip01_Spine2")
	local lforearm = self:LookupBone("ValveBiped.Bip01_R_Forearm")
	
	local holdtype = ""
	if IsValid(ply:GetActiveWeapon()) then
		local weapon = ply:GetActiveWeapon()
		holdtype = ply:GetActiveWeapon():GetHoldType()
		if weapon:GetClass() == "weapon_portalgun" then holdtype = "crossbow" end
	end
	
	local sequences = Sequences[holdtype]
	if not sequences then return end
	local name = sequences.stand
	if ply:KeyDown(IN_FORWARD)
		or ply:KeyDown(IN_MOVELEFT)
		or ply:KeyDown(IN_MOVERIGHT)
		or ply:KeyDown(IN_BACK) then
			name = sequences.run
		end
	if ply:KeyDown(IN_DUCK) then name = sequences.crouch end

	local sequence = self:LookupSequence(name)
	if not self.LastSequence or self.LastSequence != sequence then
		self:ResetSequence(sequence)
		self:SetPlaybackRate(1)
		self:SetSequence(sequence)
		self.LastSequence = sequence
	end
	
	self:ManipulateBoneAngles(spine, Angle(0, math.min(10, angle.pitch / 4), 0)) 
	self:ManipulateBoneAngles(spine1, Angle(0, angle.pitch / 10, 0)) 
	self:ManipulateBoneAngles(spine2, Angle(0, angle.pitch / 10, 0)) 
	self:ManipulateBoneAngles(lforearm, Angle(0, angle.pitch / 10, 0)) 
	local dir = Vector()
	local speed = 1
	if ply:KeyDown(IN_FORWARD) then dir = dir + Vector(1, 0, 0) end
	if ply:KeyDown(IN_BACK) then dir = dir - Vector(1, 0, 0) end
	if ply:KeyDown(IN_MOVELEFT) then dir = dir + Vector(0, -1, 0) end
	if ply:KeyDown(IN_MOVERIGHT) then dir = dir + Vector(0, 1, 0) end
	if ply:KeyDown(IN_SPEED) then speed = 2 end
	dir:Normalize()
	
	if dir != Vector() then
		if self.walkspeed < 1 then self.walkspeed = self.walkspeed + 5 * FrameTime() end
	elseif self.walkspeed > 0 then self.walkspeed = self.walkspeed - 5 * FrameTime() else self.walkspeed = 0 end
	self:WalkAnim(dir, speed * 9, self.walkspeed / 2)
end

end

function ENT:Think()
	self:NextThink(CurTime())
	
	local ply = self:GetPlayer()
	local weaponEnt = self:GetNWEntity("FakeWeapon")

	if not IsValid(ply) then return true end
	if CLIENT then
		local orientation = ply:GetNWVector("TA:Orientation")
		local eyeAngle = ply:EyeAngles()
		local orientAng = orientation:Angle() + Angle(90, 0, 0)
		local _, localangle = WorldToLocal(Vector(), eyeAngle, Vector(), orientAng)
		local _, worldangle = LocalToWorld(Vector(), Angle(0, localangle.yaw, 0), Vector(), orientAng)

		self:SetPos(ply:GetPos())
		self:SetAngles(worldangle)
		ply:SetNoDraw(true)
		
		if IsValid(ply) and (LocalPlayer() != ply or LocalPlayer():GetViewEntity() != ply) then
			self:SetNoDraw(false)
			weaponEnt:SetNoDraw(false)
		else
			self:SetNoDraw(true)
			weaponEnt:SetNoDraw(true)
		end
		if not IsValid(ply:GetActiveWeapon()) then weaponEnt:SetNoDraw(true) end

		self:Animate(localangle, ply)
		-- Moving fake weapon
		if not IsValid(weaponEnt) then return true end
		local rightHand = self:LookupBone("ValveBiped.Bip01_R_Hand")
		local pos, ang = self:GetBonePosition(rightHand)
		local wrightHand = weaponEnt:LookupBone("ValveBiped.Bip01_R_Hand")
		local wpos, wang = weaponEnt:GetBonePosition(wrightHand)
		local lpos, lang = WorldToLocal(weaponEnt:GetPos(), weaponEnt:GetAngles(), wpos, wang)
		pos, ang = LocalToWorld(lpos, lang, pos, ang)
		weaponEnt:SetPos(pos)
		weaponEnt:SetAngles(ang)
		
		return true -- client side ends here
	end
	
	local weapon = ply:GetActiveWeapon()
	if not IsValid(weapon) then return true end
	if not IsValid(weaponEnt) then return true end
	weaponEnt:SetSkin(weapon:GetSkin())
	weaponEnt:SetModel(weapon:GetModel())
	return true
end

function ENT:OnRemove()
	local ply = self:GetPlayer()
	if not IsValid(ply) then return end
	ply:SetNoDraw(false)
end

if CLIENT then return end