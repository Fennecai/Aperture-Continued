function EFFECT:Init(data)
	local ent = data:GetEntity()
	local radius = data:GetRadius()
	local magnitude = data:GetMagnitude()
	local reversed = tobool(data:GetColor())
	local color = reversed and LIB_APERTURE.FUNNEL_REVERSE_COLOR or LIB_APERTURE.FUNNEL_COLOR
	local dir = reversed and -1 or 1
	
	if not self.Emitter then
		self.Emitter = ParticleEmitter(ent:GetPos())
	end
	
	for i = 0,1,0.1 do 
		for k = 1,3 do 
			local cossinValues = CurTime() * magnitude * dir + ((math.pi * 2) / 3) * k
			local multWidth = i * radius
			local localVec = Vector(math.cos(cossinValues) * multWidth, math.sin(cossinValues) * multWidth, 30)
			local particlePos = ent:LocalToWorld(localVec) + VectorRand() * 5
			
			local p = self.Emitter:Add("sprites/light_glow02_add", particlePos)
			p:SetDieTime(math.random( 1, 2 ) * ((0 - i) / 2 + 1))
			p:SetStartAlpha( math.random( 0, 50 ) ) 
			p:SetEndAlpha(255)
			p:SetStartSize(math.random(10, 20))
			p:SetEndSize(0)
			p:SetVelocity(ent:GetUp() * LIB_APERTURE.FUNNEL_MOVE_SPEED * dir + VectorRand() * 5)
			p:SetGravity( VectorRand() * 5)
			p:SetColor(color.r, color.g, color.b)
			p:SetCollide(true)
		end
	end
	
	self.Emitter:Finish()
	
	-- for repeats = 1, 2 do
		-- local randDist = math.min( totalDistance - TA_FunnelWidth, math.max( TA_FunnelWidth, math.random( 0, totalDistance ) ) )
		-- local randVecNormalized = VectorRand()
		-- randVecNormalized:Normalize()
		
		-- local particlePos = self:LocalToWorld( Vector( 0, 0, randDist ) + randVecNormalized * TA_FunnelWidth )
		
		-- local p = self.TA_ParticleEffect:Add( "sprites/light_glow02_add", particlePos )
		-- p:SetDieTime( math.random( 3, 5 ) )
		-- p:SetStartAlpha( math.random( 200, 255 ) )
		-- p:SetEndAlpha( 0 )
		-- p:SetStartSize( math.random( 5, 10 ) )
		-- p:SetEndSize( 0 )
		-- p:SetVelocity( self:GetUp() * APERTURESCIENCE.FUNNEL_MOVE_SPEED * 4 * dir )
		
		-- p:SetColor( color.r, color.g, color.b )
		-- p:SetCollide( true )
	-- end
end

function EFFECT:Think()
	return
end

function EFFECT:Render()
	
end