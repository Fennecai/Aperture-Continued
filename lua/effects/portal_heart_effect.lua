function EFFECT:Init( data )

	local ent = data:GetEntity()
	local emitter = ParticleEmitter(Vector())
	
	for i = 1,10 do
		local min, max = ent:GetModelBounds()
		local randVec = Vector(math.Rand(min.x, max.x), math.Rand(min.y, max.y), math.Rand(min.z, max.z))
		local pos = ent:LocalToWorld(randVec)
		local p = emitter:Add("aperture/particle/heart", pos)

		p:SetDieTime(math.Rand(1, 2))
		p:SetStartAlpha(math.random(255, 255))
		p:SetEndAlpha(0)
		p:SetStartSize(5)
		p:SetEndSize(5)
		p:SetVelocity(VectorRand() * 30)
		p:SetGravity(Vector(0, 0, 50))
		-- p:SetColor(color.r, color.g, color.b )
		p:SetCollide(true)
	end
	
	emitter:Finish()
	
end

function EFFECT:Think()

	return
	
end

function EFFECT:Render()

end
