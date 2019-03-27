include("shared.lua")

local reticle = CreateClientConVar("portal_crosshair","1",true,false)

function SWEP:GetTracerOrigin()
	local viewm = ply:GetViewModel()
	local obj = viewm:LookupAttachment( "muzzle" )
	return vm:GetAttachment( obj )
end


local leftpos1 = {x=-2,y=-4}
local rightpos1 = {x=10,y=20}
local sizeLarge1 = {w=46,h=64}
local sizeSmall1 = {w=30,h=64}
local cBlu1 = Color(66,163,255,125)
local cOrg1 = Color(252,148,61,125)
local cBlu1Time = Color(66,163,255,125)
local cOrg1Time = Color(252,148,61,125)
surface.CreateFont( "xhair", 
                    {
                    font    = "HL2Cross",
                    size    = 54,
                    weight  = 400,
                    antialias = true,
                    shadow = false
})

function SWEP:DrawHUD()

	if not reticle:GetBool() then return end

	local w = ScrW()
	local h = ScrH()
	local cX = (w / 2)-29
	local cY = (h / 2)-38
	local trd = {}
		trd.start = LocalPlayer():GetShootPos()
		trd.endpos = trd.start + LocalPlayer():GetAimVector() * 10000
		trd.mask = MASK_SOLID_BRUSHONLY
	local trc = util.TraceLine(trd)
	
	local cRit1 = (self:GetNetworkedBool("OnlyBlue") and cBlu1 or cOrg1)
	local cRit1Time = (self:GetNetworkedBool("OnlyBlue") and cBlu1Time or cOrg1Time)
	--TODO: Add option for material exclusivity
	local validMat = trc.MatType ~= MAT_METAL and trc.MatType ~= MAT_DEFAULT and trc.MatType ~= MAT_GLASS
	local validBlu = true
	local validRed = true
	local hEnt = LocalPlayer():GetEyeTrace().Entity
	if hEnt ~= nil and hEnt:IsValid() and hEnt:GetClass() == "prop_portal" then
		if hEnt:GetNWInt("Potal:PortalType",TYPE_BLUE) == TYPE_BLUE then
			validRed = false
		else
			validBlu = false
		end
	end
	
	if GetConVarNumber("portal_crosshair") >=2 then
	cX = cX + 29
	cY = cY + 37
	local bBrack = (validMat and validBlu) and "[" or "{"
	local rBrack = (validMat and validRed) and "]" or "}"
	draw.SimpleText(bBrack,"xhair",cX-16,cY,cBlu1,2,1)
	draw.SimpleText(rBrack,"xhair",cX+18,cY,cRit1,0,1)
	local lastPort = self:GetNetworkedInt("LastPortal",0)
	bBrack = (lastPort == TYPE_BLUE) and "[" or "{"
	rBrack = (lastPort == TYPE_ORANGE) and "]" or "}"
	draw.SimpleText(bBrack,"xhair",cX-27,cY,cBlu1Time,2,1)
	draw.SimpleText(rBrack,"xhair",cX+29,cY,cRit1Time,0,1)

	else
	
	local drawmaterial
	if (validMat and validBlu) then
		surface.SetMaterial( Material("vgui/portalgun/leftFull.png"))
	else
		surface.SetMaterial( Material("vgui/portalgun/leftEmpty.png"))
	end

	surface.SetDrawColor(cBlu1)
	surface.DrawTexturedRect(cX+leftpos1.x, cY+leftpos1.y, sizeLarge1.w, sizeLarge1.h)
	
	if (validMat and validRed) then
		surface.SetMaterial( Material("vgui/portalgun/rightFull.png"))
	else
		surface.SetMaterial( Material("vgui/portalgun/rightEmpty.png"))
		
	end
	
	surface.SetDrawColor(cOrg1)
	surface.DrawTexturedRect(cX+rightpos1.x, cY+rightpos1.y, sizeLarge1.w, sizeLarge1.h)
		
	local lastPort = self:GetNetworkedInt("LastPortal",0)
	surface.SetMaterial( Material("vgui/portalgun/lastFired.png"))
	if lastPort == TYPE_BLUE then
		surface.SetDrawColor(cBlu1Time)
		surface.DrawTexturedRect(cX+leftpos1.x-20, cY+leftpos1.y-(sizeSmall1.h/2)+45, sizeSmall1.w, sizeSmall1.h)
	elseif lastPort == TYPE_ORANGE then
		surface.SetDrawColor(cOrg1Time)
		surface.DrawTexturedRect(cX+rightpos1.x+38, cY+rightpos1.y-(sizeSmall1.h/2)+21, sizeSmall1.w, sizeSmall1.h)
	end
	
end
end

local VElements = {
	["BodyLight"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Base", rel = "", pos = Vector(0.25, -5.45, 10.5), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight1"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Base", rel = "", pos = Vector(0.25, -5.45, 10.5), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight2"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Base", rel = "", pos = Vector(0.25, -5.45, 10.5), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight3"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Base", rel = "", pos = Vector(0.25, -5.45, 10.5), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight4"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Base", rel = "", pos = Vector(0.25, -5.45, 10.5), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight4"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Base", rel = "", pos = Vector(0.25, -5.45, 10.5), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight5"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Base", rel = "", pos = Vector(0.25, -5.45, 10.5), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(-0.101, -2.401, -6.737), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BeamPoint1"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(-0.101, -2.401, -5.699), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BeamPoint2"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(-0.101, -2.401, -5.448), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BeamPoint3"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(0.083, -2.56, -6.889), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BeamPoint4"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(0.083, -2.56, -6.488), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BeamPoint5"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(0.083, -2.56, -5.922), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BeamPoint6"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(0.083, -2.56, -5.436), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BeamPoint7"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(0.083, -2.56, -4.869), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BeamPoint8"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(0.083, -2.56, -4.303), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BeamPoint9"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(0.083, -2.56, -3.737), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BeamPoint10"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(0.083, -2.56, -3.166), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["InsideEffects"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(0, -2.201, 0), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false}
}

local WElements = {
	["BodyLight"] = { type = "Sprite", sprite = "sprites/portalgun_light2", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(6.344, 0.324, -6.737), size = { x = 0.03, y = 0.03 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight1"] = { type = "Sprite", sprite = "sprites/portalgun_effects", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(12.541, 0.324, -5.699), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight2"] = { type = "Sprite", sprite = "sprites/portalgun_effects", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(11.659, 0.324, -5.448), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight3"] = { type = "Sprite", sprite = "sprites/portalgun_effects", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(12.071, 0.324, -5.531), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight4"] = { type = "Sprite", sprite = "sprites/portalgun_effects", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(13.104, 0.324, -5.85), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight5"] = { type = "Sprite", sprite = "sprites/portalgun_effects", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(14.149, 0.324, -6.17), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight6"] = { type = "Sprite", sprite = "sprites/portalgun_effects", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(15.269, 0.324, -6.41), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight7"] = { type = "Sprite", sprite = "sprites/portalgun_effects", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(14.675, 0.324, -6.281), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight8"] = { type = "Sprite", sprite = "sprites/portalgun_effects", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(11.178, 0.324, -5.219), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight9"] = { type = "Sprite", sprite = "sprites/portalgun_effects", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(10.593, 0.324, -5.052), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight10"] = { type = "Sprite", sprite = "sprites/portalgun_effects", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(13.758, 0.324, -6.013), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false}
}

if GetConVarNumber("portal_beta_borders") >= 1 then
VElements = {
	["BodyLight"] = { type = "Sprite", sprite = "sprites/betalight", bone = "ValveBiped.Base", rel = "", pos = Vector(0.25, -5.45, 10.5), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight1"] = { type = "Sprite", sprite = "sprites/betalight", bone = "ValveBiped.Base", rel = "", pos = Vector(0.25, -5.45, 10.5), size = { x = 0.018, y = 0.018 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BeamPoint1"] = { type = "Sprite", sprite = "sprites/portalgun_effects", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(-0.101, -2.401, -3.1), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BeamPoint2"] = { type = "Sprite", sprite = "sprites/portalgun_effects", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(-0.01, -2.391, -3.401), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BeamPoint3"] = { type = "Sprite", sprite = "sprites/portalgun_effects", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(-0.03, -2.381, -3.701), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BeamPoint4"] = { type = "Sprite", sprite = "sprites/portalgun_effects", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(-0.04, -2.36, -4), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BeamPoint5"] = { type = "Sprite", sprite = "sprites/portalgun_effects", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(-0.051, -2.35, -4.301), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["InsideEffects"] = { type = "Sprite", sprite = "sprites/portalgun_effects", bone = "ValveBiped.Front_Cover", rel = "", pos = Vector(0, -2.201, 0), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false}
}

WElements = {
	["BodyLight"] = { type = "Sprite", sprite = "sprites/portalgun_light", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(6.344, 0.324, -6.737), size = { x = 0.03, y = 0.03 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight1"] = { type = "Sprite", sprite = "sprites/portalgun_light", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(12.541, 0.324, -5.699), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight2"] = { type = "Sprite", sprite = "sprites/portalgun_light", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(11.659, 0.324, -5.448), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight3"] = { type = "Sprite", sprite = "sprites/portalgun_light", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(12.071, 0.324, -5.531), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight4"] = { type = "Sprite", sprite = "sprites/portalgun_light", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(13.104, 0.324, -5.85), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight5"] = { type = "Sprite", sprite = "sprites/portalgun_light", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(14.149, 0.324, -6.17), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight6"] = { type = "Sprite", sprite = "sprites/portalgun_light", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(15.269, 0.324, -6.41), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight7"] = { type = "Sprite", sprite = "sprites/portalgun_light", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(14.675, 0.324, -6.281), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight8"] = { type = "Sprite", sprite = "sprites/portalgun_light", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(11.178, 0.324, -5.219), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight9"] = { type = "Sprite", sprite = "sprites/portalgun_light", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(10.593, 0.324, -5.052), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false},
	["BodyLight10"] = { type = "Sprite", sprite = "sprites/portalgun_light", bone = "ValveBiped.Bip01_R_Hand", rel = "", pos = Vector(13.758, 0.324, -6.013), size = { x = 0.04, y = 0.04 }, color = Color(255, 255, 255, 255), nocull = false, additive = true, vertexalpha = true, vertexcolor = true, ignorez = false}
}

end

local ViewModelBoneMods = {
	["bicep_L"] = { scale = Vector(0.0001, 0.0001, 0.0001), pos = Vector(-30, 0, 0), angle = Angle(0, 0, 0) }
}


local BobTime = 0
local BobTimeLast = CurTime()

local SwayAng = nil
local SwayOldAng = Angle()
local SwayDelta = Angle()

SWEP.DrawWeaponInfoBox	= false					-- Should draw the weapon info box
SWEP.BounceWeaponIcon   = false					-- Should the weapon icon bounce?

SWEP.WepSelectFont		= "HL2MPTypeDeath"
SWEP.WepSelectLetter	= "C"

--[[-------------------------------------------------------
	Checks the objects before any action is taken
	This is to make sure that the entities haven't been removed
---------------------------------------------------------]]
function SWEP:DrawWeaponSelection( x, y, wide, tall, alpha )

	-- Set us up the texture
	surface.SetDrawColor( color_transparent )
	surface.SetTextColor( 255, 220, 0, alpha )
	surface.SetFont( self.WepSelectFont )
	local w, h = surface.GetTextSize( self.WepSelectLetter )

	-- Draw that mother
	surface.SetTextPos( x + ( wide / 2 ) - ( w / 2 ),
						y + ( tall / 2 ) - ( h / 2 ) )
	surface.DrawText( self.WepSelectLetter )

end

function SWEP:Initialize()

	self.Weapon:SetNetworkedInt("LastPortal",0,true)
	self:SetWeaponHoldType( self.HoldType )


	-- Create a new table for every weapon instance
	self.VElements = table.FullCopy( VElements )
	self.WElements = table.FullCopy( WElements )
	self.ViewModelBoneMods = table.FullCopy( ViewModelBoneMods )
	
	-- init view model bone build function
	if IsValid(self.Owner) then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
			
			-- Init viewmodel visibility
			if (self.ShowViewModel == nil or self.ShowViewModel) then
				vm:SetColor(Color(255,255,255,255))
			else
				-- we set the alpha to 1 instead of 0 because else ViewModelDrawn stops being called
				vm:SetColor(Color(255,255,255,1))
				-- ^ stopped working in GMod 13 because you have to do Entity:SetRenderMode(1) for translucency to kick in
				-- however for some reason the view model resets to render mode 0 every frame so we just apply a debug material to prevent it from drawing
				vm:SetMaterial("Debug/hsv")			
			end
		end
	end
	

end

net.Receive( 'PORTALGUN_PICKUP_PROP', function()
	local self = net.ReadEntity()
	local ent = net.ReadEntity()
	
	if not IsValid( ent ) then
		--Drop it.
		if self.PickupSound then
		self.PickupSound:Stop()
			self.PickupSound = nil
			EmitSound( Sound( 'player/object_use_stop_01.wav' ), self:GetPos(), 1, CHAN_AUTO, 0.4, 100, 0, 100 )
		end
		if self.ViewModelOverride then
			self.ViewModelOverride:Remove()
		end
	else
		--Pick it up.
		if not self.PickupSound and CLIENT then
			self.PickupSound = CreateSound( self, 'player/object_use_lp_01.wav' )
			self.PickupSound:Play()
			self.PickupSound:ChangeVolume( 0.5, 0 )
		end
		
		-- self.ViewModelOverride = true
		
		self.ViewModelOverride = ClientsideModel(self.ViewModel,RENDERGROUP_OPAQUE)
		self.ViewModelOverride:SetPos(EyePos()-LocalPlayer():GetForward()*(self.ViewModelFOV/5))
		self.ViewModelOverride:SetAngles(EyeAngles())
		self.ViewModelOverride.AutomaticFrameAdvance = true
		self.ViewModelOverride.startCarry = false
		-- self.ViewModelOverride:SetParent(self.Owner)
		function self.ViewModelOverride.PreDraw(vm)
			vm:SetColor(Color(255,255,255))
			local oldorigin = EyePos() -- -EyeAngles():Forward()*10
			local pos, ang = self:CalcViewModelView(vm,oldorigin,EyeAngles(),vm:GetPos(),vm:GetAngles())
			return pos, ang
		end
		
	end
	
	self.HoldenProp = ent
end )

local GravityLight,GravityBeam = Material("sprites/light_glow02_add"),Material("particle/bendibeam")
local GravitySprites = {
	{bone = "ValveBiped.Arm1_C", pos = Vector(-1.25 ,-0.10, 1.06), size = { x = 0.02, y = 0.02 }},
	{bone = "ValveBiped.Arm2_C", pos = Vector(0.10, 1.25, 1.00), size = { x = 0.02, y = 0.02 }},
	{bone = "ValveBiped.Arm3_C", pos = Vector(0.10, 1.25, 1.05), size = { x = 0.02, y = 0.02 }}
}

function SWEP:DrawPickupEffects(ent)
	
	--Draw the lights
	local lightOrigins = {}
	for k,v in pairs(GravitySprites) do
		local bone = ent:LookupBone(v.bone)

		if ( not bone) then return end
		
		local pos, ang = Vector(0,0,0), Angle(0,0,0)
		local m = ent:GetBoneMatrix(bone)
		if (m) then
			pos, ang = m:GetTranslation(), m:GetAngles()
		end
		
		if (IsValid(self.Owner) and self.Owner:IsPlayer() and 
			ent == self.Owner:GetViewModel() and self.ViewModelFlip) then
			ang.r = -ang.r -- Fixes mirrored models
		end
			
		if (not pos) then return end
		
		local col = Color(255, 255, 255, math.Rand(96,128))
		local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
		local _sin = math.abs( math.sin( CurTime() * ( 0.1 ) * math.Rand(1,3))); --math.sinwave( 25, 3, true )
		
		render.SetMaterial(GravityLight)
		render.DrawSprite(drawpos, v.size.x*128+_sin, v.size.y*128+_sin, col)
		
		lightOrigins[k] = drawpos
			
	end
	
	
	--Draw the beams and center sprite.
	local bone = ent:GetBoneMatrix(ent:LookupBone("ValveBiped.Front_Cover")) 
	local endpos,ang = bone:GetTranslation(),bone:GetAngles()
	local _sin = math.abs( math.sin( 1+CurTime( ) * 3 ) ) * 1
	endpos = endpos + ang:Up()*6 + ang:Right()*-1.8
	
	render.DrawSprite(endpos, 5+_sin, 5+_sin, col)
	
	render.SetMaterial(GravityBeam)
	if math.random(0,1) == 0 then
		render.DrawBeam(lightOrigins[1], endpos, (_sin + 0.5) * 3, CurTime(), CurTime() + 0.5, Color(255, 255, 255, 100))
		render.DrawBeam(lightOrigins[2], endpos, (_sin + 0.5) * 3, CurTime(), CurTime() + 0.5, Color(255, 255, 255, 100))
		render.DrawBeam(lightOrigins[3], endpos, (_sin + 0.5) * 3, CurTime(), CurTime() + 0.5, Color(255, 255, 255, 100))
	else
		render.DrawBeam(lightOrigins[1], endpos, (_sin + 0.5) * 3, CurTime(), CurTime() + 0.5, Color(255, 255, 255, 100))
		render.DrawBeam(lightOrigins[2], endpos, (_sin + 0.5) * 3, CurTime(), CurTime() + 0.5, Color(255, 255, 255, 100))
		render.DrawBeam(lightOrigins[3], endpos, (_sin + 0.5) * 3, CurTime(), CurTime() + 0.5, Color(255, 255, 255, 100))
	end
	
end

function SWEP:DoPickupAnimations(vm)
	-- local toIdle = vm:LookupSequence("carrying_to_idle")
	local toCarry, toCarryLength = vm:LookupSequence("idle_to_carrying")
	local carry, carryLength = vm:LookupSequence("idle_carrying")
	if not vm.StartCarry then
		vm.StartCarry = CurTime() + (toCarryLength/10)
		vm:SetSequence(toCarry)
	elseif CurTime() > vm.StartCarry then
		vm:SetSequence(carry)
	end
end

hook.Add("HUDPaint", "View model pickup override", function(vm)
	local weapon = LocalPlayer():GetActiveWeapon()
	if CLIENT and IsValid(weapon.ViewModelOverride) then
		cam.Start3D(EyePos(),EyeAngles(),weapon.ViewModelFOV+5)
			local pos,ang = weapon.ViewModelOverride:PreDraw()
			render.SetColorModulation(1,1,1,255)
			render.Model({pos=pos,angle=ang,model=weapon.ViewModel},weapon.ViewModelOverride)
			weapon:ViewModelDrawn(weapon.ViewModelOverride)
			weapon:DoPickupAnimations(weapon.ViewModelOverride)
			weapon:DrawPickupEffects(weapon.ViewModelOverride)
		cam.End3D()
	end
end)

local VGravityLight = Material("sprites/glow04_noz")

local VGravitySprites = {
	{bone = "ValveBiped.Arm1_A", pos = Vector(0, 0, 0), size = { x = 0, y = 0 }},
	{bone = "ValveBiped.Arm2_A", pos = Vector(0, 0, 0), size = { x = 0, y = 0 }},
	{bone = "ValveBiped.Arm3_A", pos = Vector(0, 0, 0), size = { x = 0, y = 0 }},
	{bone = "ValveBiped.Arm1_B", pos = Vector(0, 0, 0), size = { x = 0, y = 0 }},
	{bone = "ValveBiped.Arm2_B", pos = Vector(0, 0, 0), size = { x = 0, y = 0 }},
	{bone = "ValveBiped.Arm3_B", pos = Vector(0, 0, 0), size = { x = 0, y = 0 }},	
}


function SWEP:ViewModelDrawn(vm)

	--Draw the lights
	local lightOrigins = {}
	for k,v in pairs(VGravitySprites) do
		local bone = vm:LookupBone(v.bone)

		if ( not bone) then return end
		
		local pos, ang = Vector(0,0,0), Angle(0,0,0)
		local m = vm:GetBoneMatrix(bone)
		if (m) then
			pos, ang = m:GetTranslation(), m:GetAngles()
		end
		
		if (IsValid(self.Owner) and self.Owner:IsPlayer() and 
			vm == self.Owner:GetViewModel() and self.ViewModelFlip) then
			ang.r = -ang.r -- Fixes mirrored models
		end
			
		if (not pos) then return end
		
		local col = Color(255, 128, 0, math.Rand(10,24))
		local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
		local _sin = math.abs( math.sin( CurTime() * ( 0.1 ) * math.Rand(0.0075,0.05 )))

		render.SetMaterial(VGravityLight)
		render.DrawSprite(drawpos, v.size.x*128+_sin, v.size.y*128+_sin, col)
		end
	


	for k, name in pairs( self.VElements ) do
		
		local v = name
		if (not v) then break end
		if not (v.hide) then return end
		
		local sprite = Material(v.sprite)
		
		if (v.bone) then return end
		
		local pos, ang = self:GetBoneOrientation( self.VElements, v, vm )
		
		if (pos) then return end
		
		if (v.type == "Sprite" and sprite) then
			local last =  self:GetNetworkedInt("LastPortal",0)
			local col = Color(0,0,0)
			if last == TYPE_BLUE and GetConVarNumber("portal_beta_borders") >= 1 then
			col = Color(0, 116, 254)
			elseif last == TYPE_BLUE then
			col = Color(0, 116, 254)
			elseif last == TYPE_ORANGE and GetConVarNumber("portal_beta_borders") >= 1 then
			col = Color(254, 154, 0  )
			elseif last == TYPE_ORANGE then
			col = Color(254, 154, 0  )
			end
			local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			local _sin = math.abs( math.sin( CurTime( ) * 1 ) ) * .3; --math.sinwave( 25, 3, true )
			col.a = math.sin(CurTime()*math.pi)*((128-96)/2)+112
			render.SetMaterial(sprite)
			render.DrawSprite(drawpos, v.size.x*128.0, v.size.y*128.0, col)
			end
			
		end
		
	end

SWEP.wRenderOrder = nil
function SWEP:DrawWorldModel()
	
	if (self.ShowWorldModel == nil or self.ShowWorldModel) then
		self:DrawModel()
	end
	
	if ( not self.WElements) then return end
	
	if ( not self.wRenderOrder) then

		self.wRenderOrder = {}

		for k, v in pairs( self.WElements ) do
			if (v.type == "Model") then
				table.insert(self.wRenderOrder, 1, k)
			elseif (v.type == "Sprite" or v.type == "Quad") then
				table.insert(self.wRenderOrder, k)
			end
		end

	end
	
	if (IsValid(self.Owner)) then
		bone_ent = self.Owner
	else
		-- when the weapon is dropped
		bone_ent = self
	end
	
	for k, name in pairs( self.wRenderOrder ) do
	
		local v = self.WElements[name]
		if ( not v) then self.wRenderOrder = nil break end
		if (not v.hide) then return end
		
		local pos, ang
		
		if (v.bone) then
			pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent )
		else
			pos, ang = self:GetBoneOrientation( self.WElements, v, bone_ent, "ValveBiped.Bip01_R_Hand" )
		end
		
		if (pos) then return end
		
		local model = v.modelEnt
		local sprite = Material(v.sprite)
		
		if (v.type == "Model" and IsValid(model)) then

			model:SetPos(pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z )
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)

			model:SetAngles(ang)
			--model:SetModelScale(v.size)
			local matrix = Matrix()
			matrix:Scale(v.size)
			model:EnableMatrix( "RenderMultiply", matrix )
			
			if (v.material == "") then
				model:SetMaterial("")
			elseif (model:GetMaterial() ~= v.material) then
				model:SetMaterial( v.material )
			end
			
			if (v.skin and v.skin ~= model:GetSkin()) then
				model:SetSkin(v.skin)
			end
			
			if (v.bodygroup) then
				for k, v in pairs( v.bodygroup ) do
					if (model:GetBodygroup(k) ~= v) then
						model:SetBodygroup(k, v)
					end
				end
			end
			
			if (v.surpresslightning) then
				render.SuppressEngineLighting(true)
			end
			
			render.SetColorModulation(v.color.r/255, v.color.g/255, v.color.b/255)
			render.SetBlend(v.color.a/255)
			model:DrawModel()
			render.SetBlend(1)
			render.SetColorModulation(1, 1, 1)
			
			if (v.surpresslightning) then
				render.SuppressEngineLighting(false)
			end
			
		elseif (v.type == "Sprite" and sprite) then
			
			local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			local last =  self:GetNetworkedInt("LastPortal",0)
			local col = Color(0,0,0)
			if last == TYPE_BLUE and GetConVarNumber("portal_beta_borders") >= 1 then
			col = Color(0, 116, 254)
			elseif last == TYPE_BLUE then
			col = Color(0, 116, 254)
			elseif last == TYPE_ORANGE and GetConVarNumber("portal_beta_borders") >= 1 then
			col = Color(254, 154, 0  )
			elseif last == TYPE_ORANGE then
			col = Color(254, 154, 0  )
			end
			render.SetMaterial(sprite)
			for i=0, 1, .2 do --visible in daylight.
			render.DrawSprite(drawpos, v.size.x*128, v.size.y*128, col)
			end
			
		elseif (v.type == "Quad" and v.draw_func) then
			
			local drawpos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
			ang:RotateAroundAxis(ang:Up(), v.angle.y)
			ang:RotateAroundAxis(ang:Right(), v.angle.p)
			ang:RotateAroundAxis(ang:Forward(), v.angle.r)
			
			cam.Start3D2D(drawpos, ang, v.size)
				v.draw_func( self )
			cam.End3D2D()
		end
			
	end
		
end

function SWEP:GetBoneOrientation( basetab, tab, ent, bone_override )
	
	local bone, pos, ang
	if (tab.rel and tab.rel ~= "") then
		
		local v = basetab[tab.rel]
		
		if ( not v) then return end
		
		-- Technically, if there exists an element with the same name as a bone
		-- you can get in an infinite loop. Let's just hope nobody's that stupid.
		pos, ang = self:GetBoneOrientation( basetab, v, ent )
		
		if ( not pos) then return end
		
		pos = pos + ang:Forward() * v.pos.x + ang:Right() * v.pos.y + ang:Up() * v.pos.z
		ang:RotateAroundAxis(ang:Up(), v.angle.y)
		ang:RotateAroundAxis(ang:Right(), v.angle.p)
		ang:RotateAroundAxis(ang:Forward(), v.angle.r)
			
	else
	
		bone = ent:LookupBone(bone_override or tab.bone)

		if ( not bone) then return end
		
		pos, ang = Vector(0,0,0), Angle(0,0,0)
		local m = ent:GetBoneMatrix(bone)
		if (m) then
			pos, ang = m:GetTranslation(), m:GetAngles()
		end
		
		if (IsValid(self.Owner) and self.Owner:IsPlayer() and 
			ent == self.Owner:GetViewModel() and self.ViewModelFlip) then
			ang.r = -ang.r -- Fixes mirrored models
		end
	
	end
	
	return pos, ang
end
local allbones
local hasGarryFixedBoneScalingYet = false


 
function SWEP:ResetBonePositions(vm)
	
	if ( not vm:GetBoneCount()) then return end
	for i=0, vm:GetBoneCount() do
		vm:ManipulateBoneScale( i, Vector(1, 1, 1) )
		vm:ManipulateBoneAngles( i, Angle(0, 0, 0) )
		vm:ManipulateBonePosition( i, Vector(0, 0, 0) )
	end
	
end
function table.FullCopy( tab )

	if ( not tab) then return nil end
	
	local res = {}
	for k, v in pairs( tab ) do
		if (type(v) == "table") then
			res[k] = table.FullCopy(v) -- recursion ho!
		elseif (type(v) == "Vector") then
			res[k] = Vector(v.x, v.y, v.z)
		elseif (type(v) == "Angle") then
			res[k] = Angle(v.p, v.y, v.r)
		else
			res[k] = v
		end
	end
	
	return res
	
end


function SWEP:Holster()
	
	if IsValid(self.Owner) then
		local vm = self.Owner:GetViewModel()
		if IsValid(vm) then
			self:ResetBonePositions(vm)
			if self.PickupSound then
				self.PickupSound:Stop()
				self.PickupSound = nil
			end
		end
	end
	
	return true
end

function SWEP:OnRemove()
	self:Holster()
end

--[[-------------------------------------------------------
   Name: CalcViewModelView
   Desc: Overwrites the default GMod v_model system.
---------------------------------------------------------]]


local sin, abs, pi, clamp, min = math.sin, math.abs, math.pi, math.Clamp, math.min
function SWEP:CalcViewModelView(ViewModel, oldPos, oldAng, pos, ang)

	local pPlayer = self.Owner

	local CT = CurTime()
	local FT = FrameTime()

	local RunSpeed = pPlayer:GetRunSpeed()
	local Speed = clamp(pPlayer:GetVelocity():Length2D(), 0, RunSpeed)

	local BobCycleMultiplier = Speed / pPlayer:GetRunSpeed()

	BobCycleMultiplier = (BobCycleMultiplier > 1 and min(1 + ((BobCycleMultiplier - 1) * 0.2), 5) or BobCycleMultiplier)
	BobTime = BobTime + (CT - BobTimeLast) * (Speed > 0 and (Speed / pPlayer:GetWalkSpeed()) or 0)
	BobTimeLast = CT
	local BobCycleX = sin(BobTime * 0.5 % 1 * pi * 2) * BobCycleMultiplier
	local BobCycleY = sin(BobTime % 1 * pi * 2) * BobCycleMultiplier

	oldPos = oldPos + oldAng:Right() * (BobCycleX * 1)
	oldPos = oldPos
	oldPos = oldPos + oldAng:Up() * BobCycleY/9

	SwayAng = oldAng - SwayOldAng
	if abs(oldAng.y - SwayOldAng.y) > 999 then
		SwayAng.y = (360 - abs(oldAng.y - SwayOldAng.y)) * abs(oldAng.y - SwayOldAng.y) / (SwayOldAng.y - oldAng.y)
	else
		SwayAng.y = oldAng.y - SwayOldAng.y
	end
	SwayOldAng.p = oldAng.p
	SwayOldAng.y = oldAng.y
	SwayAng.p = math.Clamp(SwayAng.p, -3, 3)
	SwayAng.y = math.Clamp(SwayAng.y, -3, 3)
	SwayDelta = LerpAngle(clamp(FT * 5, 0, 1), SwayDelta, SwayAng)
	
	return oldPos + oldAng:Up() * SwayDelta.p + oldAng:Right() * SwayDelta.y + oldAng:Up() * oldAng.p / 90 * 0, oldAng
end