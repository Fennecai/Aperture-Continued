DEFINE_BASECLASS("base_brush")

ENT.Spawnable		= false
ENT.AdminOnly		= false

if CLIENT then return end

function ENT:Initialize()
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)
	
	self:SetNoDraw(true)
	self:SetNotSolid(true)
	
	self.DoNotDuplicate = true
	self.Parent = self:GetParent()
	
	if not IsValid(self.Parent) then
		self:Remove()
	end
end

function ENT:SetBounds(minpos, maxpos)
	self:PhysicsInit(SOLID_NONE)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_BBOX)

	self:SetCollisionBounds(minpos, maxpos)
	self:SetNotSolid(true)
	
	self.minpos = minpos
	self.maxpos = maxpos
end

function ENT:StartTouch(ent)
	self:GetParent():HandleEntity(ent)
end

function ENT:Touch( ent )
	self:StartTouch( ent )
end