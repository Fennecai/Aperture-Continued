function EFFECT:Init( data )

	self.Start = data:GetOrigin()
	self.Direction = data:GetNormal()

	self.Emitter = ParticleEmitter(self.Start)
	
	for it=0,5 do
		local vec = VectorRand() + self.Direction * 3
		local pos = self.Start + vec * 50
		local rand = math.Rand(30, 60)
		local p = self.Emitter:Add("particles/smokey", pos)
		
		p:SetDieTime(math.Rand(0.75, 1))
		p:SetStartAlpha(0)
		p:SetEndAlpha(10)
		p:SetStartSize(rand)
		p:SetEndSize(rand / 2)
		p:SetRoll(math.Rand(0, 1) * 360)
		p:SetRollDelta(math.Rand(-1, 1) * 1)
		p:SetColor(255, 255, 255)
		p:SetBounce( 0.5 )
		p:SetVelocity(Vector())
		p:SetGravity(-vec * 100)
	end
	
	self.Emitter:Finish()
	
end

function EFFECT:Think()

	return
	
end

function EFFECT:Render()

end
