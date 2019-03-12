AddCSLuaFile()

LIB_APERTURE.ACHIEVEMENTS = { }
LIB_APERTURE.ACHIEVEMENTS.ACHIEVEMENTS_INFO = { }
LIB_APERTURE.ACHIEVEMENTS.NOTIFICATIONS = { }

TA_DAchivmentPanels = TA_DAchivmentPanels and TA_DAchivmentPanels or {}

function LIB_APERTURE.ACHIEVEMENTS:AddAchievement(key, name, desc)
	local img = "aperture/achievement/"..key
	LIB_APERTURE.ACHIEVEMENTS.ACHIEVEMENTS_INFO[key] = {
		img = img,
		name = name,
		desc = desc,
		achieved = false,
	}
end

-- Achievements
LIB_APERTURE.ACHIEVEMENTS:AddAchievement("turret_song", "The Turret Song")
LIB_APERTURE.ACHIEVEMENTS:AddAchievement("fried_potato", "Fried Potato")
LIB_APERTURE.ACHIEVEMENTS:AddAchievement("cake", "Cake is not a lie")
LIB_APERTURE.ACHIEVEMENTS:AddAchievement("radio", "Strange channel")
LIB_APERTURE.ACHIEVEMENTS:AddAchievement("fall_survive", "How am I still alive?!")
LIB_APERTURE.ACHIEVEMENTS:AddAchievement("im_different", "Im Different", "It need a gift")
LIB_APERTURE.ACHIEVEMENTS:AddAchievement("im_not_defective", "Im not Defective!", "It need something")
LIB_APERTURE.ACHIEVEMENTS:AddAchievement("chromium", "Made out of chromium")
LIB_APERTURE.ACHIEVEMENTS:AddAchievement("love_kill", "Love can kill")
LIB_APERTURE.ACHIEVEMENTS:AddAchievement("inventor", "Yea! I am Inventor")
LIB_APERTURE.ACHIEVEMENTS:AddAchievement("not_for_you", "This is not for You!")
LIB_APERTURE.ACHIEVEMENTS:AddAchievement("laser_show", "Laser show", "Make a laser show")
LIB_APERTURE.ACHIEVEMENTS:AddAchievement("firefighter", "Firefight", "Help!")
LIB_APERTURE.ACHIEVEMENTS:AddAchievement("buttonmaniac", "Buttonmaniac", "Click, Click")
LIB_APERTURE.ACHIEVEMENTS:AddAchievement("good_idea", "Ooh, I have an idea")

local function UpdateAchievementMenu()
	for k,v in pairs(TA_DAchivmentPanels) do
		if LIB_APERTURE.ACHIEVEMENTS.ACHIEVEMENTS_INFO[k] and LIB_APERTURE.ACHIEVEMENTS.ACHIEVEMENTS_INFO[k].achieved then
			v.item:SetBackgroundColor(Color(255, 255, 255))
			v.bg_image:SetImage("aperture/achievement/ach_background_achived")
			v.image:SetImageColor(Color(50, 50, 50, 255))
		end
	end
end

if CLIENT then
	-- Loading achievement info
	if file.Exists("aperture_achievements.dat", "DATA") then
		local achDat = file.Open("aperture_achievements.dat", "r", "DATA")
		if achDat then
			local str = achDat:Read(achDat:Size())
			achDat:Close()
			if str then
				local achKeys = string.Explode(" ", str)
				for k,v in pairs(achKeys) do
					if LIB_APERTURE.ACHIEVEMENTS.ACHIEVEMENTS_INFO[v] then
						LIB_APERTURE.ACHIEVEMENTS.ACHIEVEMENTS_INFO[v].achieved = true
					end
				end
			end
			
			UpdateAchievementMenu()
		end
	else
		file.Write("aperture_achievements.dat", "") 
	end
end

local function BuildAchievementMenu(panel)
	for k,info in pairs(LIB_APERTURE.ACHIEVEMENTS.ACHIEVEMENTS_INFO) do
		local item = vgui.Create("DPanel", panel)
		item:Dock(TOP)
		item:SetPaintBackground(true)
		item:SetSize(0, 60)
		if info.achieved then
			item:SetBackgroundColor(Color(255, 255, 255))
		else
			item:SetBackgroundColor(Color(200, 200, 200))
		end
		panel:AddItem(item)
		
		-- achievement background image
		local bg_image = vgui.Create("DImage", item)
		bg_image:SetPos(5, 5)
		bg_image:SetSize(50, 50)
		if info.achieved then
			bg_image:SetImage("aperture/achievement/ach_background_achived")
		else
			bg_image:SetImage("aperture/achievement/ach_background")
		end
		-- achievement image
		local image = vgui.Create("DImage", item)
		image:SetPos(5, 5)
		image:SetSize(50, 50)
		image:SetImage(info.img)
		if info.achieved then
			image:SetImageColor(Color(50, 50, 50, 255))
		else
			image:SetImageColor(Color(150, 150, 150, 255))
		end
		local name = Label(info.name, item)
		name:SetPos(60, 5)
		name:SetSize(300, 20)
		name:SetDark(true)
		name:SetAutoStretchVertical(true)
		name:SetFont("DermaDefaultBold")

		if info.desc then
			local description = Label(info.desc, item)
			description:SetPos(60, 30)
			description:SetSize(300, 20)
			description:SetDark(true)
			description:SetAutoStretchVertical(true)
			description:SetFont("DermaDefaultBold")
		end
		item:SizeToContents()

		TA_DAchivmentPanels[k] = {item = item, image = image, bg_image = bg_image}
	end
end

hook.Add("PopulateToolMenu", "AddApertureAchiementMenu", function()
  spawnmenu.AddToolMenuOption("Aperture", "Achievements", "ApertureAchievements", "Achievements", "", "", BuildAchievementMenu, {})
end)

local function SaveAchievementProgress()
	local strDat = ""
	for k,info in pairs(LIB_APERTURE.ACHIEVEMENTS.ACHIEVEMENTS_INFO) do
		if info.achieved then strDat = strDat..k.." " end
	end
	file.Write("aperture_achievements.dat", strDat) 
	UpdateAchievementMenu()
end

function LIB_APERTURE.ACHIEVEMENTS:AchievAchievement(ply, achInx)
	if CLIENT then return end
	if not IsValid(ply) then return end
	
	net.Start("TA:NW_AchievedAchievement")
		net.WriteString(achInx)
	net.Send(ply)
end

local function CreateAchievementNotification(achInx)
	local achInfo = LIB_APERTURE.ACHIEVEMENTS.ACHIEVEMENTS_INFO[achInx]
	if not achInfo then return end
	local ply = LocalPlayer()
	table.insert(LIB_APERTURE.ACHIEVEMENTS.NOTIFICATIONS, {achInfo = achInfo, startCurtime = CurTime()})
	ply:EmitSound("garrysmod/save_load1.wav")
end

net.Receive("TA:NW_AchievedAchievement", function(len, pl)
	local achInx = net.ReadString()
	-- if achievement allready achived skipping it
	if LIB_APERTURE.ACHIEVEMENTS.ACHIEVEMENTS_INFO[achInx].achieved then return end
	CreateAchievementNotification(achInx)
	LIB_APERTURE.ACHIEVEMENTS.ACHIEVEMENTS_INFO[achInx].achieved = true
	SaveAchievementProgress()
end)

local AchivmentHeight = 100
local AchivmentWidth = 300
local ShadowX = 10
local ShadowY = 10
local ImgSize = 80
local ImgXOffset = 10
local TextXOffset = 10
local TextYOffset = 10
local AchievmentTime = 4

hook.Add("PostDrawHUD", "TA:AchievmentNotifications", function()	
	if not LIB_APERTURE.ACHIEVEMENTS.NOTIFICATIONS then return end
	
	local itter = 0
	for k,v in pairs(LIB_APERTURE.ACHIEVEMENTS.NOTIFICATIONS) do
		local time = (CurTime() - v.startCurtime)
		local mult = 0
		if time <= 1 then mult = time 
		elseif time <= (1 + AchievmentTime) then mult = 1
		else mult = 1 - (time - (1 + AchievmentTime)) end
		
		-- removing notification
		if time > (2 + AchievmentTime) then
			LIB_APERTURE.ACHIEVEMENTS.NOTIFICATIONS[k] = nil
		end
		
		local panelX = ScrW() - mult * AchivmentWidth
		local panelY = itter * (AchivmentHeight + 5)
		-- shadow
		surface.SetDrawColor(0, 0, 0, 100)
		surface.DrawRect(panelX - ShadowX, panelY + ShadowY, AchivmentWidth, AchivmentHeight ) 
		-- achievement background
		surface.SetDrawColor(200, 200, 200)
		surface.DrawRect(panelX, panelY, AchivmentWidth, AchivmentHeight)
		-- image background
		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(Material("aperture/achievement/ach_background_achived"))
		surface.DrawTexturedRect(panelX + ImgXOffset, panelY + AchivmentHeight / 2 - ImgSize / 2, ImgSize, ImgSize)
		-- image
		surface.SetDrawColor(50, 50, 50)
		surface.SetMaterial(Material(v.achInfo.img))
		surface.DrawTexturedRect(panelX + ImgXOffset, panelY + AchivmentHeight / 2 - ImgSize / 2, ImgSize, ImgSize)
		-- text
		surface.SetTextColor(25, 25, 25)
		local _, txtHeight = surface.GetTextSize("")
		surface.SetTextPos(panelX + ImgXOffset + ImgSize + TextXOffset, panelY + TextYOffset)
		surface.DrawText(v.achInfo.name)
		
		itter = itter + 1
	end
	-- local panelX = 0
	-- local panelY = 0
		-- -- -- image background
		-- -- surface.SetDrawColor(255, 255, 255)
		-- -- surface.SetMaterial(Material("aperture/achievement/ach_background_achived"))
		-- -- surface.DrawTexturedRect(panelX + ImgXOffset, panelY + AchivmentHeight / 2 - ImgSize / 2, ImgSize, ImgSize)
		-- -- image
		-- surface.SetDrawColor(50, 50, 50)
		-- surface.SetMaterial(Material("aperture/achievement/cake"))
		-- surface.DrawTexturedRect(panelX + ImgXOffset, panelY + AchivmentHeight / 2 - ImgSize / 2, ImgSize, ImgSize)
end)

