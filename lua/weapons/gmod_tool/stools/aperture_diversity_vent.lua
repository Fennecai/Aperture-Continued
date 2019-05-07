TOOL.Tab = "Aperture"
TOOL.Category = "Puzzle elements"
TOOL.Name = "#tool.aperture_diversity_vent.name"

TOOL.ClientConVar["model"] = "models/aperture/vacum_flange_a.mdl"
TOOL.ClientConVar["ignorealive"] = "1"
TOOL.ClientConVar["keyenable"] = "45"
TOOL.ClientConVar["startenabled"] = "0"
TOOL.ClientConVar["toggle"] = "0"
TOOL.ClientConVar["count"] = "1"
TOOL.ClientConVar["debug"] = "0"

local HEIGHT_FROM_FLOOR = 200
local CONNTECTION_POINT_MATERIAL = Material("sprites/sent_ball")
local POINT_TYPE_CONNECTION = 0
local POINT_TYPE_FILTER = 1

if CLIENT then
	language.Add("tool.aperture_diversity_vent.name", "Diversity Vent")
	language.Add(
		"tool.aperture_diversity_vent.desc",
		"A Pneumatic Diversity Vent will suck up anything that gets too close in a non-discriminatory manner."
	)
	language.Add(
		"tool.aperture_diversity_vent.0",
		"Left click to place, E to show path, Right click to change attachement position and R to rotate"
	)
	language.Add("tool.aperture_diversity_vent.count", "Count")
	language.Add("tool.aperture_diversity_vent.ignorealive", "Ignore Alive")
	language.Add(
		"tool.aperture_diversity_vent.ignorealive.help",
		"Diversity vent will be slightly more discriminatory, and refuse to suck up any players or npcs."
	)
	language.Add("tool.aperture_diversity_vent.keyenable", "Enable")
	language.Add("tool.aperture_diversity_vent.startenabled", "Enabled")
	language.Add(
		"tool.aperture_diversity_vent.startenabled.help",
		"Pneumatic Diversity Vent will be activated when placed"
	)
	language.Add("tool.aperture_diversity_vent.toggle", "Toggle")
end

local function GetModelConnectionData(model)
	return LIB_APERTURECONTINUED:GetModelConnectionData(model)
end

-- if model is filterable then return local center pos
local function GetFilterableModelData(model)
	-- print(model)
	return LIB_APERTURECONTINUED:GetFilterableModelData(model)
end

local function GetClosestVentPoint(ply)
	local plyShootPos = ply:GetShootPos()
	local closestPoint = -1
	local ent,
		pointType,
		pos,
		ang,
		index
	local plyEyeDir = plyShootPos + ply:EyeAngles():Forward() * LIB_MATH_TA.HUGE
	local entities = ents.FindByClass("ent_diversity_vent_pipe")
	table.Add(entities, ents.FindByClass("ent_diversity_vent"))

	for k, v in pairs(entities) do
		local dist = util.DistanceToLine(plyShootPos, plyEyeDir, v:GetPos())
		local model = v:GetModel()
		if model == "models/props_bts/vactube_90deg_06.mdl" then
			Entity(1):SetPos(v:GetPos())
		end
		if dist < v:GetModelRadius() * 2 then
			local tbl = GetModelConnectionData(model)
			if tbl then
				for inx, coord in pairs(tbl) do
					local coordWorld = v:LocalToWorld(coord.pos)
					local distToPoint = plyShootPos:Distance(coordWorld)
					local distFromLineToPoint = util.DistanceToLine(plyShootPos, plyEyeDir, coordWorld)
					if
						distFromLineToPoint < 50 and (closestPoint == -1 or distToPoint < closestPoint) and
							not IsValid(v:GetNWEntity("TA:ConnectedPipe:" .. inx))
					 then
						ent = v
						pos = coord.pos
						ang = coord.ang
						index = inx
						pointType = POINT_TYPE_CONNECTION

						closestPoint = distToPoint
					end
				end
			end
		end

		if GetFilterableModelData(model) then
			local lcenter = GetFilterableModelData(model)
			local centerpos = v:LocalToWorld(lcenter)
			local distToPoint = plyShootPos:Distance(centerpos)
			local distFromLineToPoint = util.DistanceToLine(plyShootPos, plyEyeDir, centerpos)
			if distFromLineToPoint < 50 and (closestPoint == -1 or distToPoint < closestPoint) then
				closestPoint = distFromLineToPoint
				ent = v
				pointType = POINT_TYPE_FILTER
			end
		end
	end

	return ent, pointType, pos, ang, index
end

if SERVER then
	local function ConnectedPipes(pipe1, inx1, pipe2, inx2)
		pipe1:SetNWInt("TA:ConnectedPipeInx:" .. inx1, inx2)
		pipe1:SetNWEntity("TA:ConnectedPipe:" .. inx1, pipe2)
		pipe2:SetNWInt("TA:ConnectedPipeInx:" .. inx2, inx1)
		pipe2:SetNWEntity("TA:ConnectedPipe:" .. inx2, pipe1)

		if pipe1:GetClass() == "ent_diversity_vent" then
			pipe2:SetNWEntity("TA:Vent", pipe1)
		elseif IsValid(pipe1:GetNWEntity("TA:Vent")) then
			pipe2:SetNWEntity("TA:Vent", pipe1:GetNWEntity("TA:Vent"))
		elseif IsValid(pipe2:GetNWEntity("TA:Vent")) then
			pipe1:SetNWEntity("TA:Vent", pipe2:GetNWEntity("TA:Vent"))
		end
	end

	local function UpdateNearbyPipes(ent, entities)
		for k, v in pairs(entities) do
			if v:GetClass() == "ent_diversity_vent" or v:GetClass() == "ent_diversity_vent_pipe" then
				for inx, coord in pairs(GetModelConnectionData(ent:GetModel())) do
					for inx2, coord2 in pairs(GetModelConnectionData(v:GetModel())) do
						local wpos1 = ent:LocalToWorld(coord.pos)
						local wpos2 = v:LocalToWorld(coord2.pos)
						if wpos1:Distance(wpos2) < 0.1 then
							ConnectedPipes(v, inx2, ent, inx)
						end
					end
				end
			end
		end

		ent:UpdatePipe(true)
	end

	function MakePortalDiversityVent(ply, pos, ang, ignorealive, key_enable, startenabled, toggle, data)
		local findResult = ents.FindInSphere(pos, 1000)
		local ent = ents.Create("ent_diversity_vent")
		if not IsValid(ent) then
			return
		end

		duplicator.DoGeneric(ent, data)

		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:SetMoveType(MOVETYPE_NONE)
		ent.Owner = ply
		ent:SetIgnoreAlive(tobool(ignorealive))
		ent:SetStartEnabled(tobool(startenabled))
		ent:SetToggle(tobool(toggle))
		ent:Spawn()

		-- initializing numpad inputs
		ent.NumDown = numpad.OnDown(ply, key_enable, "DiversityVent_Enable", ent, true)
		ent.NumUp = numpad.OnUp(ply, key_enable, "DiversityVent_Enable", ent, false)

		-- saving data
		local ttable = {
			key_enable = key_enable,
			ply = ply,
			startenabled = startenabled,
			toggle = toggle
		}

		table.Merge(ent:GetTable(), ttable)

		if IsValid(ply) then
			ply:AddCleanup("#tool.aperture_diversity_vent.name", ent)
		end

		UpdateNearbyPipes(ent, findResult)

		return ent
	end

	function MakePortalDiversityVentPipe(ply, pos, ang, model, data)
		local findResult = ents.FindInSphere(pos, 1000)
		local ent = ents.Create("ent_diversity_vent_pipe")
		if not IsValid(ent) then
			return
		end

		duplicator.DoGeneric(ent, data)

		ent:SetModel(model)
		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:SetMoveType(MOVETYPE_NONE)
		ent.Owner = ply
		ent:Spawn()

		-- saving data
		local ttable = {
			key_enable = key_enable,
			model = model,
			ply = ply
		}

		table.Merge(ent:GetTable(), ttable)

		if IsValid(ply) then
			ply:AddCleanup("#tool.aperture_diversity_vent.name", ent)
		end

		UpdateNearbyPipes(ent, findResult)

		return ent
	end

	function MakePortalDiversityVentPipeArray(ply, pos, ang, model, dir, count)
		local entities = {}
		for i = 1, count do
			local findResult = ents.FindInSphere(pos, 1000)
			local ent = ents.Create("ent_diversity_vent_pipe")
			if not IsValid(ent) then
				return
			end

			ent:SetModel(model)
			ent:SetPos(pos)
			ent:SetAngles(ang)
			ent:SetMoveType(MOVETYPE_NONE)
			ent.Owner = ply
			ent:Spawn()
			pos = pos + dir * 128

			if IsValid(ply) then
				ply:AddCleanup("#tool.aperture_diversity_vent.name", ent)
			end

			table.insert(entities, ent)
			UpdateNearbyPipes(ent, findResult)
		end

		return entities
	end

	function CreatePipe(ply, pos, ang, model, dir, count)
		if
			count > 1 and
				(model == "models/aperture/vactube_128_straight.mdl" or model == "models/portal_custom/clear_tube_straight.mdl")
		 then
			return MakePortalDiversityVentPipeArray(ply, pos, ang, model, dir, count)
		else
			return MakePortalDiversityVentPipe(ply, pos, ang, model)
		end
	end

	duplicator.RegisterEntityClass(
		"ent_diversity_vent",
		MakePortalDiversityVent,
		"pos",
		"ang",
		"ignorealive",
		"key_enable",
		"startenabled",
		"toggle",
		"data"
	)
	duplicator.RegisterEntityClass("ent_diversity_vent_pipe", MakePortalDiversityVentPipe, "pos", "ang", "model", "data")
end

local function SendRemoveFilterDat(routeInx, inx)
	net.WriteBool(true)
	net.WriteInt(routeInx, 4)
	net.WriteInt(inx, 8)
end

local function SendFilterDat(routeInx, filterType, ent, text, min, max)
	net.Start("TA:DivventFilterNetwork")
	net.WriteBool(false)
	net.WriteInt(routeInx, 4)
	net.WriteInt(filterType, 4)
	net.WriteEntity(ent)
	if filterType == 1 or filterType == 2 then
		net.WriteString(text)
	end
	if filterType == 3 or filterType == 4 then
		net.WriteFloat(min)
		net.WriteFloat(max)
	end
	net.SendToServer()
end

net.Receive(
	"TA:DivventFilterNetwork",
	function()
		local remove = net.ReadBool()
		local routeInx = net.ReadInt(4)
		-- removing filter data from server entity
		if remove then
			local inx = net.ReadInt(8)
			table.remove(ent.DivventFilter[routeInx], inx)
			return
		end

		-- adding filter data to server entity
		local filterType = net.ReadInt(4)
		local ent = net.ReadEntity()
		local text
		local min,
			max

		if filterType == 1 or filterType == 2 then
			text = net.ReadString()
		end
		if filterType == 3 or filterType == 4 then
			min = net.ReadFloat()
			max = net.ReadFloat()
		end

		if not ent.DivventFilter then
			ent.DivventFilter = {}
		end
		if not ent.DivventFilter[routeInx] then
			ent.DivventFilter[routeInx] = {}
		end

		table.insert(ent.DivventFilter[routeInx], {filterType = filterType, text = text, min = min, max = max})
	end
)

local FilterTypes = {
	[1] = "Model",
	[2] = "Class",
	[3] = "Mass",
	[4] = "Scale",
	[5] = "Alive",
	[6] = "Non Alive"
}

local function RemoveFilter(routeInx, scroll, panel)
	local ply = LocalPlayer()
	if not ply:GetTool() then
		return
	end
	local ent = ply:GetTool().SelectedVent
	if not IsValid(ent) then
		return
	end
	if not ent.DivventFilter then
		return
	end
	if not ent.DivventFilter[routeInx] then
		return
	end

	for k, v in pairs(scroll:GetCanvas():GetChildren()) do
		if v == panel then
			table.remove(ent.DivventFilter[routeInx], k)
			panel:Remove()
			SendRemoveFilterDat(routeInx, k)
			return
		end
	end
end

local function AddFilterBlock(dScroll, text, model)
	local dPanel = dScroll:Add("DPanel")
	local routeInx = dScroll.RouteInx
	dPanel:Dock(TOP)
	dPanel:DockMargin(5, 5, 5, 0)
	dPanel:SetBackgroundColor(Color(200, 200, 200))

	if model then
		dPanel:SetSize(0, 100)

		local icon = vgui.Create("DModelPanel", dPanel)
		icon:SetSize(90, 90)
		icon:SetModel(model)
		local ent = icon:GetEntity()
		local pos = Vector(0, 1, 1):GetNormalized() * ent:GetModelRadius() * 2
		-- ent:OBBCenter()
		icon:SetCamPos(pos)
		icon:SetLookAt(Vector())
	else
		dPanel:SetSize(0, 30)

		local dLabelTxt = vgui.Create("DLabel", dPanel)
		dLabelTxt:SetPos(20, 5)
		dLabelTxt:SetSize(300, 20)
		dLabelTxt:SetText(text)
		dLabelTxt:SetDark(true)
	end

	local dButtonRemove = vgui.Create("DButton", dPanel)
	dButtonRemove:SetText("X")
	dButtonRemove:SetPos(305, 5)
	dButtonRemove:SetSize(20, 20)
	dButtonRemove.DoClick = function()
		RemoveFilter(routeInx, dScroll, dPanel)
	end
end

local function AddFilter(routeInx, dScroll, filterType, text, min, max, nocopy)
	if SERVER then
		return
	end
	dScroll.RouteInx = routeInx

	if filterType == 1 then
		local name = "Model: " .. text
		AddFilterBlock(dScroll, name, string.lower(text))
	elseif filterType == 2 then
		local name = "Class: " .. text
		AddFilterBlock(dScroll, name)
	elseif filterType == 3 then
		local name = ""
		if min == max then
			name = "Mass: " .. min
		else
			name = "Mass: from " .. min .. " to " .. max
		end
		AddFilterBlock(dScroll, name)
	elseif filterType == 4 then
		local name = ""
		if min == max then
			name = "Scale: " .. min
		else
			name = "Scale: from " .. min .. " to " .. max
		end
		AddFilterBlock(dScroll, name)
	elseif filterType == 5 then
		local name = "Alive Entities"
		AddFilterBlock(dScroll, name)
	elseif filterType == 6 then
		local name = "Non Alive Entities"
		AddFilterBlock(dScroll, name)
	end

	if nocopy then
		return
	end

	local ply = LocalPlayer()
	if not ply:GetTool() then
		return
	end
	local ent = ply:GetTool().SelectedVent
	if not IsValid(ent) then
		return
	end
	if not ent.DivventFilter then
		ent.DivventFilter = {}
	end
	if not ent.DivventFilter[routeInx] then
		ent.DivventFilter[routeInx] = {}
	end
	table.insert(ent.DivventFilter[routeInx], {filterType = filterType, text = text, min = min, max = max})
	SendFilterDat(routeInx, filterType, ent, text, min, max)
end

local function CreateFilterRange(addbutton, parent)
	local dPanel = vgui.Create("DPanel", parent)
	dPanel:SetPos(10, 120)
	dPanel:SetSize(230, 55)

	local dNumSliderMin = vgui.Create("DNumSlider", dPanel)
	dNumSliderMin:SetPos(5, 5)
	dNumSliderMin:SetSize(220, 20)
	dNumSliderMin:SetText("Min")
	dNumSliderMin:SetMin(0)
	dNumSliderMin:SetMax(50000)
	dNumSliderMin:SetDecimals(0)
	dNumSliderMin:SetDark(true)

	local dNumSliderMax = vgui.Create("DNumSlider", dPanel)
	dNumSliderMax:SetPos(5, 30)
	dNumSliderMax:SetSize(220, 20)
	dNumSliderMax:SetText("Max")
	dNumSliderMax:SetMin(0)
	dNumSliderMax:SetMax(50000)
	dNumSliderMax:SetDecimals(0)
	dNumSliderMax:SetDark(true)
	dNumSliderMax:SetValue(50000)

	dNumSliderMin.OnValueChanged = function(self)
		local value = self:GetValue()
		if value > dNumSliderMax:GetValue() then
			dNumSliderMax:SetValue(value)
		end
	end
	dNumSliderMax.OnValueChanged = function(self)
		local value = self:GetValue()
		if value < dNumSliderMin:GetValue() then
			dNumSliderMin:SetValue(value)
		end
	end

	addbutton.FilterMinSlider = dNumSliderMin
	addbutton.FilterMaxSlider = dNumSliderMax

	return dPanel
end

local function CreateFilterString(addbutton, parent)
	local dPanel = vgui.Create("DPanel", parent)
	dPanel:SetPos(10, 120)
	dPanel:SetSize(230, 40)

	local dTextEntry = vgui.Create("DTextEntry", dPanel)
	dTextEntry:SetPos(5, 5)
	dTextEntry:SetSize(220, 30)
	-- dTextEntry.OnEnter = function(self) end

	addbutton.FilterTextEntry = dTextEntry

	return dPanel
end

local function CreateFilterTypeSettings(filtertype, addbutton, parent)
	if filtertype == 1 or filtertype == 2 then
		return CreateFilterString(addbutton, parent)
	elseif filtertype == 3 or filtertype == 4 then
		return CreateFilterRange(addbutton, parent)
	end
end

local function CreateFilterSettings(model)
	if SERVER then
		return
	end

	local connectionDat = GetModelConnectionData(model)

	-- Main Window
	local dFrame = vgui.Create("DFrame")
	dFrame:SetSize(600, 400)
	local w,
		h = dFrame:GetSize()
	dFrame:SetPos(ScrW() / 2 - w / 2, ScrH() / 2 - h / 2)
	dFrame:SetTitle("Filter Settings")
	dFrame:MakePopup()

	-- Right Panel

	local dPanelR = vgui.Create("DPanel", dFrame)
	dPanelR:SetPos(250, 35)
	dPanelR:SetSize(340, 355)

	local dFilterList = vgui.Create("DScrollPanel", dPanelR)
	dFilterList:Dock(FILL)

	-- Left Panel

	-- Filter color panel
	local dFilterPanelL = vgui.Create("DPanel", dFrame)
	dFilterPanelL:SetPos(10, 35)
	dFilterPanelL:SetSize(40 + 35 * (#connectionDat - 1), 40)

	-- Filter type selector
	local dComboBox = vgui.Create("DComboBox", dFrame)
	dComboBox:SetPos(10, 80)
	dComboBox:SetSize(210, 30)
	dComboBox:SetValue("filter type")
	for k, v in pairs(FilterTypes) do
		dComboBox:AddChoice(v)
	end

	local dButton = vgui.Create("DButton", dFrame)
	dButton:SetText("Add")
	dButton:SetPos(10, 360)
	dButton:SetSize(230, 30)
	dButton:SetDisabled(true)
	dButton.RouteInx = 1
	dButton.DoClick = function(self)
		local filterType = self.FilterType
		local text = IsValid(self.FilterTextEntry) and self.FilterTextEntry:GetValue() or nil
		local min = IsValid(self.FilterMinSlider) and math.Round(self.FilterMinSlider:GetValue()) or nil
		local max = IsValid(self.FilterMaxSlider) and math.Round(self.FilterMaxSlider:GetValue()) or nil
		if not self.RouteInx or self.RouteInx == 0 then
			return
		end
		local routeInx = self.RouteInx

		AddFilter(routeInx, dFilterList, filterType, text, min, max)
	end

	dComboBox.OnSelect = function(panel, index, value)
		dButton:SetDisabled(false)
		dButton.FilterType = index

		if IsValid(panel.LastTypeSettingsPanel) then
			panel.LastTypeSettingsPanel:Remove()
		end
		panel.LastTypeSettingsPanel = CreateFilterTypeSettings(index, dButton, dFrame)
	end

	-- Creating Filter Routs Selector
	local dFilterRouteSelector = vgui.Create("DPanel", dFilterPanelL)
	dFilterRouteSelector:SetPos(3, 3)
	dFilterRouteSelector:SetSize(34, 34)
	dFilterRouteSelector:SetBackgroundColor(Color(0, 0, 0))

	-- Creating Filter Routs
	for i = 0, #connectionDat - 1 do
		local dFilterRoute = vgui.Create("DColorButton", dFilterPanelL)
		local color = LIB_APERTURECONTINUED:GetFilterColor(i + 1)
		dFilterRoute:SetPos(5 + 35 * i, 5)
		dFilterRoute:SetSize(30, 30)
		dFilterRoute:SetColor(color)
		dFilterRoute.RouteInx = (i + 1)
		dFilterRoute.DoClick = function(self)
			-- Move Selector
			local x,
				y = dFilterRoute:GetPos()
			dFilterList:Clear()
			dFilterRouteSelector:SetPos(x - 2, y - 2)

			-- Filling filter list
			local ply = LocalPlayer()
			if not ply:GetTool() then
				return
			end
			local ent = ply:GetTool().SelectedVent
			if not IsValid(ent) then
				return
			end
			if not ent.DivventFilter then
				ent.DivventFilter = {}
			end
			local routeInx = self.RouteInx
			if not ent.DivventFilter[routeInx] then
				ent.DivventFilter[routeInx] = {}
			end
			for k, v in pairs(ent.DivventFilter[routeInx]) do
				AddFilter(routeInx, dFilterList, v.filterType, v.text, v.min, v.max, true)
			end

			dButton.RouteInx = routeInx
		end
	end

	-- Filling filter list
	local ply = LocalPlayer()
	if not ply:GetTool() then
		return
	end
	local ent = ply:GetTool().SelectedVent
	if not IsValid(ent) then
		return
	end
	if not ent.DivventFilter then
		ent.DivventFilter = {}
	end
	local routeInx = 1
	if not ent.DivventFilter[routeInx] then
		ent.DivventFilter[routeInx] = {}
	end
	for k, v in pairs(ent.DivventFilter[routeInx]) do
		AddFilter(routeInx, dFilterList, v.filterType, v.text, v.min, v.max, true)
	end
end

function TOOL:LeftClick(trace)
	--if ( not APERTURESCIENCE.ALLOWING.diversity_vent and not self:GetOwner():IsSuperAdmin() ) then self:GetOwner():PrintMessage( HUD_PRINTTALK, "This tool is disabled" ) return end

	local ply = self:GetOwner()
	local vent,
		vpointType,
		vpos,
		vang,
		vindex = GetClosestVentPoint(ply)

	if vpointType == POINT_TYPE_FILTER then
		if CLIENT and self.LastClientLeftClick ~= CurTime() then
			self.SelectedVent = vent
			CreateFilterSettings(vent:GetModel())
			self.LastClientLeftClick = CurTime()
		end

		return true
	end

	if CLIENT then
		return true
	end

	local weapon = self:GetWeapon()
	local angOffset = weapon:GetNWInt("TA:DivventRotation")
	local index = weapon:GetNWInt("TA:DivventIndex")

	if IsValid(vent) and vpointType == POINT_TYPE_CONNECTION then
		if not IsValid(vent:GetNWEntity("TA:ConnectedPipe:" .. vindex)) then
			local count = self:GetClientNumber("count")
			local model = self:GetClientInfo("model")
			local pos = vent:LocalToWorld(vpos)
			local ang = vent:LocalToWorldAngles(vang)
			local coords = GetModelConnectionData(model)[index]
			local dir = -ang:Up()

			if angOffset > 0 then
				_,
					ang = LocalToWorld(Vector(), Angle(0, angOffset, 0), Vector(), ang)
			end
			if coords.ang and coords.ang ~= Angle() then
				_,
					ang = LocalToWorld(Vector(), coords.ang, Vector(), ang)
			end
			if coords.pos and coords.pos ~= Vector() then
				pos = LocalToWorld(-coords.pos, Angle(), pos, ang)
			end

			local ent = CreatePipe(ply, pos, ang, model, dir, count)

			if not IsValid(ent) and not istable(ent) then
				return
			end

			undo.Create("Pneumatic Diversity Pipe")
			if istable(ent) then
				for k, v in pairs(ent) do
					undo.AddEntity(v)
				end
			else
				undo.AddEntity(ent)
			end
			undo.SetPlayer(ply)
			undo.Finish()

			return true, ent
		end
	else
		-- if no pipe is selected then creating diversity vent
		local ignorealive = self:GetClientNumber("ignorealive")
		local key_enable = self:GetClientNumber("keyenable")
		local startenabled = self:GetClientNumber("startenabled")
		local toggle = self:GetClientNumber("toggle")

		local pos = trace.HitPos + trace.HitNormal * HEIGHT_FROM_FLOOR
		local ang = trace.HitNormal:Angle() + Angle(90, 0, 90)

		local ent = MakePortalDiversityVent(ply, pos, ang, ignorealive, key_enable, startenabled, toggle)
		if not IsValid(ent) then
			return
		end

		undo.Create("#tool.aperture_diversity_vent.name")
		undo.AddEntity(ent)
		undo.SetPlayer(ply)
		undo.Finish()

		return true, ent
	end

	return true
end

function TOOL:Reload()
	if SERVER then
		local weapon = self:GetWeapon()
		local rotation = weapon:GetNWInt("TA:DivventRotation")
		if (rotation + 90) >= 360 then
			weapon:SetNWInt("TA:DivventRotation", 0)
		else
			weapon:SetNWInt("TA:DivventRotation", rotation + 90)
		end
	end
end

function TOOL:RightClick(trace)
	if SERVER then
		local weapon = self:GetWeapon()
		local index = weapon:GetNWInt("TA:DivventIndex")
		local mdl = self:GetClientInfo("model")
		local coords = GetModelConnectionData(mdl)

		if (index + 1) > #coords then
			weapon:SetNWInt("TA:DivventIndex", 1)
		else
			weapon:SetNWInt("TA:DivventIndex", index + 1)
		end
	end
end

function TOOL:UpdateGhostDiversityVent(ent, ply)
	if not IsValid(ent) then
		return
	end

	local trace = ply:GetEyeTrace()
	local weapon = self:GetWeapon()
	local angOffset = weapon:GetNWInt("TA:DivventRotation")
	local index = weapon:GetNWInt("TA:DivventIndex")
	local vent,
		vpointType,
		vpos,
		vang,
		vindex = GetClosestVentPoint(ply)

	if vpointType == POINT_TYPE_FILTER then
		ent:SetNoDraw(true)
		return
	end
	ent:SetNoDraw(false)

	if IsValid(vent) then
		if not IsValid(vent:GetNWEntity("TA:ConnectedPipe:" .. vindex)) then
			local mdl = self:GetClientInfo("model")
			if not util.IsValidModel(mdl) then
				self:ReleaseGhostEntity()
				return
			end
			local pos = vent:LocalToWorld(vpos)
			local ang = vent:LocalToWorldAngles(vang)

			local coords = GetModelConnectionData(mdl)[index]

			if not coords then
				return
			end
			-- remaking ghost entity
			if self.GhostEntity:GetModel() ~= mdl then
				self:MakeGhostEntity(mdl, Vector(), Angle())
			end

			if angOffset > 0 then
				_,
					ang = LocalToWorld(Vector(), Angle(0, angOffset, 0), Vector(), ang)
			end
			if coords.ang then
				local _,
					angle = LocalToWorld(Vector(), coords.ang, Vector(), ang)
				ang = angle
			end
			if coords.pos and coords.pos ~= Vector() then
				pos = LocalToWorld(-coords.pos, Angle(), pos, ang)
			end

			ent:SetPos(pos)
			ent:SetAngles(ang)
		else
			ent:SetNoDraw(true)
		end

		return
	else
		-- if no pipe is selected then creating diversity vent
		local pos = trace.HitPos + trace.HitNormal * HEIGHT_FROM_FLOOR
		local ang = trace.HitNormal:Angle() + Angle(90, 0, 90)
		ent:SetModel("models/aperture/vacum_flange_a.mdl")
		ent:SetPos(pos)
		ent:SetAngles(ang)

		return
	end
end

function TOOL:Think()
	local weapon = self:GetWeapon()
	if not weapon:GetNWInt("TA:DivventRotation") then
		weapon:SetNWInt("TA:DivventRotation", 0)
	end
	if not weapon:GetNWInt("TA:DivventIndex") or weapon:GetNWInt("TA:DivventIndex") == 0 then
		weapon:SetNWInt("TA:DivventIndex", 1)
	end

	local mdl = self:GetClientInfo("model")
	local coords = GetModelConnectionData(mdl)

	if weapon:GetNWInt("TA:DivventIndex") > #coords then
		weapon:SetNWInt("TA:DivventIndex", 1)
	end

	if not util.IsValidModel(mdl) then
		self:ReleaseGhostEntity()
		return
	end

	if not IsValid(self.GhostEntity) then
		self:MakeGhostEntity(mdl, Vector(), Angle())
	end

	self:UpdateGhostDiversityVent(self.GhostEntity, self:GetOwner())
end

local function DrawPipesFlow(flowtbl, lastPos)
	local lastPos = lastPos and lastPos or Vector()
	for k, v in pairs(flowtbl) do
		if istable(v) then
			DrawPipesFlow(v, lastPos)
		else
			-- render.SetMaterial(CONNTECTION_POINT_MATERIAL)
			-- render.DrawSprite(v, 30, 30, Color(255, 255, 255))
			if lastPos ~= Vector() then
				render.SetMaterial(Material("vgui/hud/paint_type_select_arrow"))
				render.DrawBeam(v, lastPos, 40, 0, v:Distance(lastPos) / 40, Color(255, 255, 255))
			end
			lastPos = v
		end
	end
end

function TOOL:DrawHUD()
	local ply = LocalPlayer()
	local flows = self.FlowsData
	local entities = ents.FindByClass("ent_diversity_vent_pipe")
	table.Add(entities, ents.FindByClass("ent_diversity_vent"))

	local vent,
		vpointType,
		vpos,
		vang,
		vindex = GetClosestVentPoint(ply)
	if ply:KeyPressed(IN_USE) then
		self.FlowsData = {}
		for k, v in pairs(ents.FindByClass("ent_diversity_vent")) do
			local info = CalculateFlows(nil, nil, nil, v, nil, true)
			self.FlowsData[v] = info
		end
	-- tinfo = CalculateFlow(tinfo)
	end

	cam.Start3D()

	local debugmode = self:GetClientNumber("debug")

	if flows then
		for k, v in pairs(flows) do
			DrawPipesFlow(v)
		end
	end

	for k, v in pairs(entities) do
		local model = v:GetModel()

		if GetFilterableModelData(model) then
			local lcenter = GetFilterableModelData(model)
			local color = vpointType == POINT_TYPE_FILTER and Color(0, 200, 255) or Color(0, 0, 255)

			if vpointType ~= POINT_TYPE_FILTER or vpointType == POINT_TYPE_FILTER and vent == v then
				render.SetMaterial(CONNTECTION_POINT_MATERIAL)
				if debugmode == 0 then
					render.DrawSprite(v:LocalToWorld(lcenter), 30, 30, color)
				end
			end

			if vpointType == POINT_TYPE_FILTER and vent == v then
				for inx, coord in pairs(GetModelConnectionData(model)) do
					local color = LIB_APERTURECONTINUED:GetFilterColor(inx)
					local coordWorld = v:LocalToWorld(coord.pos)

					render.SetMaterial(CONNTECTION_POINT_MATERIAL)
					if debugmode == 0 then
						render.DrawSprite(coordWorld, 20, 20, color)
					end
				end

				break
			end
		end

		if vpointType ~= POINT_TYPE_FILTER then
			local tbl = GetModelConnectionData(model)
			if tbl then
				for inx, coord in pairs(tbl) do
					if not IsValid(v:GetNWEntity("TA:ConnectedPipe:" .. inx)) then
						local coordWorld = v:LocalToWorld(coord.pos)
						local color = Color(255, 0, 0)
						if vent == v and vindex == inx then
							color = Color(0, 255, 0)
						end

						render.SetMaterial(CONNTECTION_POINT_MATERIAL)
						if debugmode == 0 then
							render.DrawSprite(coordWorld, 20, 20, color)
						end
					end
				end
			end
		end

		if debugmode == 1 then
			DrawDebugSprites(k, v)
		end
	end

	cam.End3D()
end

function DrawDebugSprites(k, v)
	local postoggle = postoggle or 1
	local model = v:GetModel()
	local tbl = GetModelConnectionData(model)
	for inx, coord in pairs(tbl) do
		local coordWorld = v:LocalToWorld(coord.pos)
		local color = Color(255, 255, 255)

		if postoggle == 2 then
			color = Color(244, 182, 66)
			render.SetMaterial(Material("sprites/key_" .. inx))
			render.DrawSprite(coordWorld + Vector(-15, 0, 0), 20, 20, color)
			render.DrawLine(coordWorld, coordWorld + Vector(-15, 0, 0), color, true)
			postoggle = 1
		else
			color = Color(66, 134, 244)
			render.SetMaterial(Material("sprites/key_" .. inx))
			render.DrawSprite(coordWorld + Vector(15, 0, 0), 20, 20, color)
			render.DrawLine(coordWorld, coordWorld + Vector(15, 0, 0), color, true)
			postoggle = 2
		end
	end
end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", {Description = "#tool.aperture_diversity_vent.desc"})
	CPanel:AddControl(
		"PropSelect",
		{ConVar = "aperture_diversity_vent_model", Models = list.Get("DiversityVentModels"), Height = 3}
	)
	CPanel:NumSlider("#tool.aperture_diversity_vent.count", "aperture_diversity_vent_count", 1, 100, 0)
	CPanel:AddControl(
		"CheckBox",
		{Label = "#tool.aperture_diversity_vent.ignorealive", Command = "aperture_diversity_vent_ignorealive", Help = 1}
	)

	CPanel:AddControl(
		"CheckBox",
		{Label = "#tool.aperture_diversity_vent.startenabled", Command = "aperture_diversity_vent_startenabled", Help = 1}
	)
	CPanel:AddControl(
		"Numpad",
		{Label = "#tool.aperture_diversity_vent.keyenable", Command = "aperture_diversity_vent_keyenable"}
	)
	CPanel:AddControl(
		"CheckBox",
		{Label = "#tool.aperture_diversity_vent.toggle", Command = "aperture_diversity_vent_toggle"}
	)

	CPanel:AddControl("CheckBox", {Label = "Show Connection Point Indexes", Command = "aperture_diversity_vent_debug"})
end

list.Set("DiversityVentModels", "models/aperture/vactube_128_straight.mdl", {})
list.Set("DiversityVentModels", "models/aperture/vactube_90deg_01.mdl", {})
list.Set("DiversityVentModels", "models/aperture/vactube_90deg_02.mdl", {})
list.Set("DiversityVentModels", "models/aperture/vactube_90deg_03.mdl", {})
list.Set("DiversityVentModels", "models/aperture/vactube_90deg_04.mdl", {})
list.Set("DiversityVentModels", "models/aperture/vactube_90deg_05.mdl", {})
list.Set("DiversityVentModels", "models/aperture/vactube_90deg_06.mdl", {})
--danger
list.Set("DiversityVentModels", "models/aperture/vactube_tjunction.mdl", {})
list.Set("DiversityVentModels", "models/aperture/vactube_crossroads.mdl", {})
--danger
list.Set("DiversityVentModels", "models/portal_custom/clear_tube_straight.mdl", {})
list.Set("DiversityVentModels", "models/portal_custom/clear_tube_90deg.mdl", {})
