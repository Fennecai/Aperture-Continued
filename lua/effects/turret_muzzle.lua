function EFFECT:Init(data)
	self.ePos = data:GetOrigin()
	self.eNormal = data:GetNormal()
	self.Emitter = ParticleEmitter( self.ePos )
	for i = 1,3 do
		for mult = 1,3 do
			local vel = Vector( 0, math.sin( 2 * math.pi / 3 * i ), math.cos( 2 * math.pi / 3 * i ) ) * 60
			vel:Rotate( self.eNormal:Angle() )
			
			local p = self.Emitter:Add( "effects/combinemuzzle1", self.ePos )
			p:SetDieTime( math.Rand( 0.2, 0.2 ) )
			p:SetStartAlpha( 255 )
			p:SetEndAlpha( 255 )
			p:SetStartSize( 15 )
			p:SetEndSize( 0 )
			p:SetRoll( math.Rand( 0, 360 ) )
			p:SetVelocity( vel / mult )
			p:SetColor( 255, 255, 255 )
			p:SetCollide( true )
		end
	end

	local p = self.Emitter:Add( "effects/strider_muzzle", self.ePos )
	p:SetDieTime( math.Rand( 0.2, 0.3 ) )
	p:SetStartAlpha( 255 )
	p:SetEndAlpha( 255 )
	p:SetStartSize( math.Rand( 30, 40 ) )
	p:SetEndSize( 0 )
	p:SetRoll( 0 )
	p:SetRollDelta( 0 )
	p:SetColor( 200, 200 + math.Rand( 0, 55 ), 255 )
	p:SetCollide( true )
	
	self.Emitter:Finish()
end

function EFFECT:Think()
	return
end

function EFFECT:Render()
end
