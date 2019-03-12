function EFFECT:Init( data )

	self.Start = data:GetOrigin()
	self.Direction = data:GetNormal()
	self.Color = data:GetColor()
	self.Radius = math.max( 0.6, data:GetRadius() / 150 )
	
	local color = LIB_APERTURE:PaintTypeToColor( self.Color )
	
	self.Emitter = ParticleEmitter( self.Start )
	
	for i=1,2 do
		local vec = VectorRand()
		vec = Vector(vec.x, vec.y, vec.z + 3)
		vec:Rotate(self.Direction:Angle() + Angle(90, 0, 0))
		local p = self.Emitter:Add("particle/splat/paint_splat"..math.random(1, 4), self.Start + vec)

		p:SetDieTime( math.Rand( 0.3, 0.4 ) )
		p:SetStartAlpha( math.random( 200, 255 ) )
		p:SetEndAlpha( 0 )
		p:SetStartSize( math.Rand( 20, 40 ) * self.Radius )
		p:SetEndSize( math.Rand( 80, 120 ) * self.Radius )
		p:SetRoll( math.Rand( 0, 360 ) )
		p:SetRollDelta( 0 )
		p:SetVelocity( vec * 50 * self.Radius + self.Direction * math.Rand(50, 100))
		p:SetGravity( Vector( 0, 0, -500 ) )
		p:SetColor( color.r, color.g, color.b )
		p:SetCollide( true )
		
	end
	
	for i=1,4 do
	
		local vec = VectorRand()
		vec = Vector( vec.x, vec.y, vec.z + 1 )
		vec:Rotate( self.Direction:Angle() + Angle( 90, 0, 0 ) )
		
		local p = self.Emitter:Add("particle/paintblobs/paint_blob"..math.random(1, 2), self.Start + vec )
		local size = math.random( 10, 20 ) * self.Radius
		
		p:SetDieTime( math.Rand( 0.8, 1 ) )
		p:SetStartAlpha( 200 )
		p:SetEndAlpha( 200 )
		p:SetStartSize( size )
		p:SetEndSize( 0 )
		p:SetRoll( math.Rand( 0, 360 ) )
		p:SetRollDelta( math.Rand( -3, 3 ) )
		p:SetVelocity( vec * 120 * self.Radius + self.Direction * math.Rand( 200, 250 ) )
		p:SetGravity( Vector( 0, 0, -800 ) )
		p:SetColor( color.r, color.g, color.b )
		p:SetCollide( true )
		
	end
	
	self.Emitter:Finish()
	
end

function EFFECT:Think()

	return
	
end

function EFFECT:Render()

end
