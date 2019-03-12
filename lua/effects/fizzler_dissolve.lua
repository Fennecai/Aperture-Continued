function EFFECT:Init( data )

	self.eEntity = data:GetEntity()
	if ( !self.eEntity:IsValid() ) then return end
	
	self.Emitter = ParticleEmitter( self.eEntity:GetPos() )
	
	local min, max = self.eEntity:GetModelBounds()
	local randVec = Vector( math.Rand( min.x, max.x ), math.Rand( min.y, max.y ), math.Rand( min.z, max.z ) )

	for count = 1, 2 do
		local p = self.Emitter:Add( "sprites/gmdm_pickups/light", self.eEntity:LocalToWorld( VectorRand() * randVec + self.eEntity:OBBCenter() ) )
		p:SetDieTime( math.Rand( 0.75, 1 ) )
		p:SetStartAlpha( 255 )
		p:SetEndAlpha( 255 )
		p:SetStartSize( math.Rand( 5, 10 ) )
		p:SetEndSize( 0 )
		p:SetRoll( 0 )
		p:SetRollDelta( 0 )
		local vel = VectorRand()
		p:SetVelocity( vel * 100 )
		p:SetGravity( -vel * 100 + VectorRand() * 100 )
		p:SetColor( 255, 255, 255 )
		p:SetCollide( true )
	end

	local p = self.Emitter:Add( "particle/smokesprites_000" .. math.random( 1, 9 ), self.eEntity:LocalToWorld( VectorRand() * randVec + self.eEntity:OBBCenter() ) )
	p:SetDieTime( math.Rand( 2, 2.5 ) )
	p:SetStartAlpha( 255 )
	p:SetEndAlpha( 0 )
	local size = math.Rand( 3, 5 )
	p:SetStartSize( size )
	p:SetEndSize( size )
	p:SetRoll( math.Rand( 0, 360 ) )
	local vel = VectorRand()
	p:SetVelocity( VectorRand() * 20 )
	p:SetGravity( physenv.GetGravity() / 2 )
	p:SetColor( 0, 0, 0 )
	p:SetCollide( true )
	
	p = self.Emitter:Add( "sprites/gmdm_pickups/light", self.eEntity:LocalToWorld( self.eEntity:OBBCenter() ) )
	p:SetDieTime( math.Rand( 0.1, 0.2 ) )
	p:SetStartAlpha( 255 )
	p:SetEndAlpha( 255 )
	p:SetStartSize( math.Rand( 0.9, 1.1 ) * self.eEntity:GetModelRadius() * 3.5 )
	p:SetEndSize( 0 )
	p:SetRoll( 0 )
	p:SetRollDelta( 0 )
	local vel = VectorRand()
	p:SetColor( 200, 200 + math.Rand( 0, 55 ), 255 )
	p:SetCollide( true )
	
	self.Emitter:Finish()
	
end

function EFFECT:Think()

	return
	
end

function EFFECT:Render()

end
