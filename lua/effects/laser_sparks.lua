function EFFECT:Init( data )

	self.Start = data:GetOrigin()
	self.Direction = data:GetNormal()

	self.Emitter = ParticleEmitter( self.Start )
	
	local vec = VectorRand() + self.Direction
	
	local p = self.Emitter:Add( "sprites/gmdm_pickups/light", self.Start )

	p:SetDieTime( math.Rand( 0.25, 0.5 ) )
	p:SetStartAlpha( math.random( 100, 200 ) )
	p:SetEndAlpha( 0 )
	p:SetStartSize( math.Rand( 15, 30 ) )
	p:SetEndSize( 0 )
	p:SetRoll( 0 )
	p:SetRollDelta( 0 )
	p:SetColor( 255, 255, 255 )
	p:SetCollide( true )
	p:SetVelocityScale( true )
	p:SetBounce( 0.5 )

	
	self.Emitter:Finish()
	
end

function EFFECT:Think()

	return
	
end

function EFFECT:Render()

end
