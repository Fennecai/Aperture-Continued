function EFFECT:Init(data)
	local startpos = data:GetOrigin()
	local radius = data:GetRadius()
	local dir = data:GetNormal()
	
	self.Emitter = ParticleEmitter(startpos)	
	local p = self.Emitter:Add("particle/laser_beam_glow", startpos)
	p:SetDieTime(0.25)
	p:SetStartAlpha(255)
	p:SetEndAlpha(255)
	p:SetStartSize(radius)
	p:SetEndSize(0)
	p:SetVelocity(dir * 100)
	p:SetGravity(dir * 1000)
	p:SetColor(255, 255, 255)
	p:SetCollide(false)
	
	self.Emitter:Finish()
end

function EFFECT:Think()
	return
end

function EFFECT:Render()
	
end