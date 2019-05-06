local BRIDGE_WIDTH = 36
local PORTAL_HEIGHT_HALF = 60
local PORTAL_WIDTH = 32

function EFFECT:Init(data)
	local startpos = data:GetOrigin()
	local radius = data:GetRadius()
	local angle = data:GetAngles()
	local entity = data:GetEntity()
	local localpos = IsValid(entity) and entity:WorldToLocal(startpos) or Vector()
	local borderSize =
		IsValid(entity) and math.cos((math.abs(localpos.z) / PORTAL_HEIGHT_HALF) * math.pi / 2) * BRIDGE_WIDTH or BRIDGE_WIDTH

	self.Emitter = ParticleEmitter(startpos)
	local offset = Vector(0, 1, 0)
	offset:Rotate(angle)

	for i = -1, 1, 0.1 do
		local pos = startpos + offset * BRIDGE_WIDTH * i
		if
			not IsValid(entity) or
				(i * BRIDGE_WIDTH <= (-borderSize + localpos.y) or i * BRIDGE_WIDTH >= (borderSize + localpos.y))
		 then
			local rad = radius * math.Rand(0.25, 0.5)
			local p = self.Emitter:Add("effects/energyball", pos)
			p:SetDieTime(0.5)
			p:SetStartAlpha(255)
			p:SetEndAlpha(0)
			p:SetStartSize(rad)
			p:SetEndSize(rad)
			p:SetVelocity(Vector())
			p:SetGravity(Vector())
			p:SetColor(200, 250, 255)
			p:SetCollide(false)
		end
	end

	self.Emitter:Finish()
end

function EFFECT:Think()
	return
end

function EFFECT:Render()
end
