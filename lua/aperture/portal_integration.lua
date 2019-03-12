AddCSLuaFile()

if not LIB_APERTURE then print("Error: Aperture lib does not exit!!!") return end

LIB_APERTURE.MAX_PASSAGES = 256
local PORTAL_RADIUS = 50

-- ================================ PORTAL INTEGRATION ============================

-- Fixed Find in cone
function LIB_APERTURE:FindInCone(startpos, dir, height, degrese)
	local tbl = {}
	local rad = math.rad(degrese)
	dir:Normalize()
	local endpos = startpos + dir * height
	local h1 = height / math.cos(math.rad(degrese))
	local radius = math.sqrt(h1 * h1 - height * height)
	local min = startpos - Vector(1, 1, 1) * radius
	local max = endpos + Vector(1, 1, 1) * radius
	LIB_MATH_TA:FixMinMax(min, max)
	
	local entities = ents.FindInBox(min, max)
	for k,v in ipairs(entities) do
		local center = IsValid(v:GetPhysicsObject()) and v:LocalToWorld(v:GetPhysicsObject():GetMassCenter()) or v:GetPos()
		local dir2v = center - startpos
		dir2v:Normalize()
		local ang = math.deg(math.acos(dir:Dot(dir2v)))
		
		if ang > 0 and ang < degrese then
			table.insert(tbl, v)
		end
	end
	return tbl
end

-- Rotating vector relative to portals
function LIB_APERTURE:GetPortalRotateVector(vec, portal, flip)
	if not IsValid(portal) then return end
	if not portal:IsLinked() then return end
	local portalOther = portal:GetOther()
	if not IsValid(portalOther) then return end
	local vec = vec and vec or Vector()
	local ang = Angle()
	vec = WorldToLocal(vec, Angle(), Vector(), portal:GetAngles())
	local pang = flip and portalOther:LocalToWorldAngles(Angle(0, 180, 0)) or portalOther:GetAngles()
	return LocalToWorld(vec, Angle(), Vector(), pang)
end

-- Transforming pos, ang from enter portal relative to exit portal
function LIB_APERTURE:GetPortalTransform(pos, ang, portal, flip)
	if not IsValid(portal) then return end
	if not portal:IsLinked() then return end
	local portalOther = portal:GetOther()
	if not IsValid(portalOther) then return end
	local pos = pos and pos or Vector()
	local ang = ang and ang or Angle()
	local pang = flip and portalOther:LocalToWorldAngles(Angle(0, 180, 0)) or portalOther:GetAngles()
	pos, ang = WorldToLocal(pos, ang, portal:GetPos(), portal:GetAngles())
	return LocalToWorld(pos, ang, portalOther:GetPos(), pang)
end

-- Mathing Entity and Table of models or entities
local function MathEntityAndTable(ent, entTable)
	if not istable(entTable) then return false end
	for k,v in pairs(entTable) do
		if isentity(v) then
			if ent == v then return true end
		end
		if ent:GetModel() == v then return true end
	end
	return false
end

function LIB_APERTURE:GetAllPortalPassagesAng(pos, angle, maxLength, ignore, ignoreEntities, ignoreAlive)
	local exitportal
	local prevPos = pos
	local prevAng = angle
	local passagesInfo = {}
	local passages = 0
	local trace = {}
	repeat
		local hitPortal = true
		local direction = prevAng:Forward()
		trace = util.TraceLine({
			start = prevPos,
			endpos = prevPos + direction * LIB_MATH_TA.HUGE,
			filter = function(ent)
				if ent != ignore and not MathEntityAndTable(ent, ignore)
					and not ignoreEntities 
					and ent:GetClass() != "prop_portal"
					and (not ignoreAlive or (ent:IsPlayer() or ent:IsNPC())) then return true end
			end
		})
		table.insert(passagesInfo, {
			startpos = prevPos,
			endpos = trace.HitPos,
			angles = prevAng,
			exitportal = exitportal,
		})
		
		-- Portal loop if trace hit portal
		for k,v in pairs(ents.FindByClass("prop_portal")) do
			if v != exitPortal then
				local pos = v:WorldToLocal(trace.HitPos)
				
				if pos.x > -30 and pos.x < 10
					and pos.y > -30 and pos.y < 30
					and pos.z > -45 and pos.z < 45 then
					if IsValid(v:GetNWEntity("Potal:Other")) then
						local otherPortal = v:GetNWEntity("Potal:Other")
						
						localPos = v:WorldToLocal(trace.HitPos)
						localAng = v:WorldToLocalAngles(prevAng)
						localPos = Vector(0, -localPos.y, localPos.z)
						localAng = localAng + Angle(0, 180, 0)
						
						prevPos = otherPortal:LocalToWorld(localPos)
						prevAng = otherPortal:LocalToWorldAngles(localAng)
						hitPortal = false
						passagesInfo[#passagesInfo].enterportal = v
						exitportal = otherPortal
						break
					end
				end
			end
		end
		
		passages = passages + 1
		if passages >= LIB_APERTURE.MAX_PASSAGES then break end
	until hitPortal
	
	return passagesInfo, trace
end

function LIB_APERTURE:GetAllPortalPassages(pos, dir, maxLength, ignore, ignoreEntities)
	local angle = dir:Angle()
	return LIB_APERTURE:GetAllPortalPassagesAng(pos, angle, maxLength, ignore, ignoreEntities)
end

--[[
	Here's some function that is used for turrets
	
	Return closest alive entity in specific cone, even if it seen throw portal
	This function is recursive!
]]
local function RFindClosestAliveInSphereIncludingPortalPassages(entities, startpos, length, degrese, portal, distance)
	local distance = distance and distance or 0
	local dist = -1
	local ent
	local point = Vector()
	
	for k,v in pairs(entities) do
		local pos = v:GetPos()
		
		if IsValid(portal) then
			local p = WorldToLocal(pos, Angle(), portal:GetPos(), portal:GetAngles())
			if p.x < 0 then continue end
		end
		
		local d = pos:Distance(startpos)
		-- if found portal then do recursive find
		if v:GetClass() == "prop_portal" and v != portal and v:IsLinked() then
			local dir1 = (pos - startpos)
			local portalOther = v:GetOther()
			dir1:Normalize()
			local startp = LIB_APERTURE:GetPortalTransform(startpos, nil, v, true)
			dir1 = LIB_APERTURE:GetPortalRotateVector(dir1, v, true)
			
			local h1 = math.sqrt(PORTAL_RADIUS * PORTAL_RADIUS + d * d)
			local deg = math.deg(math.acos(d / h1))
			-- Entity(1):SetPos(startp + dir1 * length / 2)
			if not degrese or deg < degrese then degrese = deg end
			
			local entits = LIB_APERTURE:FindInCone(startp, dir1, length, degrese)
			local e, p, d = RFindClosestAliveInSphereIncludingPortalPassages(entits, startp, length, degrese, portalOther, d)
			
			if IsValid(e) and (dist == -1 or dist > d) then
				-- fliping portal angle
				local vang = v:LocalToWorldAngles(Angle(0, 180, 0))
				point = LocalToWorld(p, Angle(), v:GetPos(), vang)
				dist = d
				ent = e
			end
		end
		
		if ((v:IsPlayer() and v:Alive() and not LIB_APERTURE:GetAIIgnorePlayers()) or v:IsNPC() and v:Health() > 0) and (dist == -1 or dist > d) then
			-- local center = IsValid(v:GetBone) and v:LocalToWorld(v:GetPhysicsObject():GetMassCenter()) or v:GetPos()
			local center = v:LocalToWorld(v:OBBCenter())
			point = IsValid(portal) and portal:WorldToLocal(center) or center
			dist = d
			ent = v
		end
	end
	
	return ent, point, dist + distance
end

--[[
	Return closest alive entity in specific radius, even if it seen throw portal
]]
function LIB_APERTURE:FindClosestAliveInSphereIncludingPortalPassages(startpos, radius)
	local entities = ents.FindInSphere(startpos, radius)
	return RFindClosestAliveInSphereIncludingPortalPassages(entities, startpos, radius)
end

--[[
	Return closest alive entity in specific cone, even if it seen throw portal
]]
function LIB_APERTURE:FindClosestAliveInConeIncludingPortalPassages(startpos, dir, length, degrese)
	local entities = LIB_APERTURE:FindInCone(startpos, dir, length, degrese)
	return RFindClosestAliveInSphereIncludingPortalPassages(entities, startpos, length, degrese)
end

--[[------------------------------------------------------------------------
	Overriding Portal Gun
	yea it's baaaad
	
	:D
---------------------------------------------------------------------------]]

function OverridedShootPortal(self, type)

	local ballSpeed = GetConVar("portal_projectile_speed")
	local weapon = self.Weapon
	local owner = self.Owner
   
	weapon:SetNextPrimaryFire( CurTime() + self.Delay )
	weapon:SetNextSecondaryFire( CurTime() + self.Delay )

	local OrangePortalEnt = owner:GetNWEntity( "Portal:Orange", nil )
	local BluePortalEnt = owner:GetNWEntity( "Portal:Blue", nil )
   
	local EntToUse = type == TYPE_BLUE and BluePortalEnt or OrangePortalEnt
	local OtherEnt = type == TYPE_BLUE and OrangePortalEnt or BluePortalEnt
   
	local tr = {}
	tr.start = owner:GetShootPos()
	tr.endpos = owner:GetShootPos() + ( owner:GetAimVector() * 2048 * 1000 )
   
	tr.filter = { owner, EntToUse, EntToUse.Sides }
   
	for k,v in pairs(ents.FindByClass( "prop_physics*" )) do
			table.insert( tr.filter, v )
	end
   
	for k,v in pairs( ents.FindByClass( "npc_turret_floor" ) ) do
			table.insert( tr.filter, v )
	end
   
	tr.mask = MASK_SHOT
   
	local trace = util.TraceLine( tr )
   
	if IsFirstTimePredicted() and owner:IsValid() then --Predict that motha' fucka'
			
		if SERVER then
			--shoot a ball.
			local ball = self:ShootBall(type,tr.start,tr.endpos,trace.Normal)
			
			if ( trace.Hit and (trace.HitWorld or trace.Entity and trace.Entity:GetClass() == "env_portal_wall" and trace.Entity:GetSkin() == 0) ) then
		
				local validpos, validnormang = self:IsPosionValid( trace.HitPos, trace.HitNormal, 2, true )
				local cellPos = LIB_MATH_TA:ConvertToGrid(trace.HitPos, LIB_PAINT.PAINT_INFO_SIZE)
				local cellInfo = LIB_PAINT:GetCellPaintInfo(cellPos)
				print(cellInfo)
				
				if !trace.HitNoDraw and !trace.HitSky and ( trace.MatType != MAT_METAL and trace.MatType != MAT_GLASS or ( trace.MatType == MAT_CONCRETE or trace.MatType == MAT_DIRT ) ) and validpos and validnormang 
					or cellInfo and cellInfo.paintType == PORTAL_PAINT_PORTAL or trace.Entity:GetClass() == "env_portal_wall" then
					  --Wait until our ball lands, if it's enabled.
					  hitDelay = ((trace.Fraction * 2048 * 1000)-100)/ballSpeed:GetInt()
					  
					  self:SetNextPrimaryFire(math.max(CurTime()+hitDelay+.2, CurTime() + self.Delay))
					  self:SetNextSecondaryFire(math.max(CurTime()+hitDelay+.2, CurTime() + self.Delay))
					  
					  timer.Simple( hitDelay - .05, function()
							if ball and ball:IsValid() then 
								ball:Remove()
								
								local OrangePortalEnt = owner:GetNWEntity( "Portal:Orange", nil )
								local BluePortalEnt = owner:GetNWEntity( "Portal:Blue", nil )
								
								local EntToUse = type == TYPE_BLUE and BluePortalEnt or OrangePortalEnt
								local OtherEnt = type == TYPE_BLUE and OrangePortalEnt or BluePortalEnt
								if !IsValid( EntToUse ) then
							   
										local Portal = ents.Create( "prop_portal" )
										Portal:SetPos( validpos )
										Portal:SetAngles( validnormang )
										Portal:Spawn()
										Portal:Activate()
										Portal:SetMoveType( MOVETYPE_NONE )
										Portal:SetActivatedState(true)
										Portal:SetType( type )
										Portal:SuccessEffect()
									   
										if type == TYPE_BLUE then
									   
												owner:SetNWEntity( "Portal:Blue", Portal )
												Portal:SetNetworkedBool("blue",true,true)
											   
										else
									   
												owner:SetNWEntity( "Portal:Orange", Portal )
												Portal:SetNetworkedBool("blue",false,true)
											   
										end
									   
										EntToUse = Portal
									   
										if IsValid( OtherEnt ) then
									   
												EntToUse:LinkPortals( OtherEnt )
											   
										end
									   
								else
							   
										EntToUse:MoveToNewPos( validpos, validnormang )
										EntToUse:SuccessEffect()
									   
								end
							end
						end )
				else
			   
						local ang = trace.HitNormal:Angle()
			   
						ang:RotateAroundAxis( ang:Right(), -90 )
						ang:RotateAroundAxis( ang:Forward(), 0 )
						ang:RotateAroundAxis( ang:Up(), 90 )
						local ent = ents.Create( "info_particle_system" )
						ent:SetPos( trace.HitPos + trace.HitNormal * 0.1 )
						ent:SetAngles( ang )
						--TODO: Different fail effects.
						if GetConVarNumber("portal_beta_borders") >= 1 then
						ent:SetKeyValue( "effect_name", "portal_" .. type .. "_badsurface_")
						else
						ent:SetKeyValue( "effect_name", "portal_" .. type .. "_badsurface")
						end
						ent:SetKeyValue( "start_active", "1")
						ent:Spawn()
						ent:Activate()
						timer.Simple( 5, function()
							if IsValid( ent ) then
								ent:Remove()
							end 
						end )
						
						ent:EmitSound(Sound("weapons/portalgun/portal_invalid_surface3.wav"))
						
					   
				end
			   
				   
			end
		   
		end
	end
   
end

local function OverridePortalGun(weapon)
	weapon.ShootPortal = OverridedShootPortal
end

hook.Add("Think", "TA:PortalGunOverride", function()
	if SERVER then
		for k,v in pairs(player.GetAll()) do
			if IsValid(v:GetActiveWeapon()) and v:GetActiveWeapon():GetClass() == "weapon_portalgun" and TYPE_BLUE and TYPE_ORANGE then
				OverridePortalGun(v:GetActiveWeapon())
			end
		end
	end
	
	if CLIENT then
		-- Removing this bother hook to prevent player view correction on the gel
		hook.Remove("Think", "Reset Camera Roll")
	end
end)
