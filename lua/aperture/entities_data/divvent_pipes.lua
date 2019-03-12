AddCSLuaFile()

if not LIB_APERTURE then error("Error: Aperture lib does not exit!!!") return end

-- ================================ PIPES DATA ============================

local FilterRoutesColor = {
	[1] = Color(255, 0, 0),
	[2] = Color(0, 255, 0),
	[3] = Color(0, 0, 255),
	[4] = Color(255, 255, 0),
	[5] = Color(255, 0, 255),
	[6] = Color(0, 255,255),
}

local ModelConnectionData = {
	["models/aperture/vacum_flange_a.mdl"] = {
		[1] = {pos = Vector(0, 20, 0), ang = Angle(0, 0, 90)}
	},
	["models/aperture/vactube_128_straight.mdl"] = {
		[1] = {pos = Vector(), ang = Angle(0, 0, -90)}, 
		[2] = {pos = Vector(0, 128, 0), ang = Angle(0, 0, 90)}
	},
	["models/aperture/vactube_90deg_01.mdl"] = {
		[1] = {pos = Vector(), ang = Angle(0, 0, -90)}, 
		[2] = {pos = Vector(0, 64, -64), ang = Angle()}
	},
	["models/aperture/vactube_90deg_02.mdl"] = {
		[1] = {pos = Vector(), ang = Angle(0, 0, -90)}, 
		[2] = {pos = Vector(0, 128, -128), ang = Angle()}
	},
	["models/aperture/vactube_90deg_03.mdl"] = {
		[1] = {pos = Vector(), ang = Angle(0, 0, -90)}, 
		[2] = {pos = Vector(0, 192, -192), ang = Angle()}
	},
	["models/aperture/vactube_90deg_04.mdl"] = {
		[1] = {pos = Vector(), ang = Angle(0, 0, -90)}, 
		[2] = {pos = Vector(0, 256, -256), ang = Angle()}
	},
	["models/aperture/vactube_90deg_05.mdl"] = {
		[1] = {pos = Vector(), ang = Angle(0, 0, -90)}, 
		[2] = {pos = Vector(0, 320, -320), ang = Angle()}
	},
	["models/aperture/vactube_90deg_06.mdl"] = {
		[1] = {pos = Vector(), ang = Angle(0, 0, -90)}, 
		[2] = {pos = Vector(0, 384, -384), ang = Angle()}
	},
	["models/aperture/vactube_tjunction.mdl"] = { 
		[1] = {pos = Vector(), ang = Angle(0, 0, -90)},
		[2] = {pos = Vector(-192, 64, 0), ang = Angle(90, 0, 0)},
		[3] = {pos = Vector(0, 128, 0), ang = Angle(0, 0, 90)}
	},
	["models/aperture/vactube_crossroads.mdl"] = { 
		[1] = {pos = Vector(), ang = Angle(0, 0, -90)},
		[2] = {pos = Vector(192, 64, 0), ang = Angle(-90, 0, 0)},
		[3] = {pos = Vector(0, 128, 0), ang = Angle(0, 0, 90)},
		[4] = {pos = Vector(-192, 64, 0), ang = Angle(90, 0, 0)} 
	},
}

local ModelFlowData = {
	["models/aperture/vactube_128_straight.mdl"] = {
		[1] = {pos = Vector(), connected = {2}, outinx = 1},
		[2] = {pos = Vector(0, 128, 0), connected = {1}, outinx = 2},
	},
	["models/aperture/vactube_90deg_01.mdl"] = {
		[1] = {pos = Vector(), connected = {3}, outinx = 1},
		[2] = {pos = Vector(0, 64, -64), connected = {3}, outinx = 2},
		[3] = {pos = Vector(0, 50, -15), connected = {1, 2}}
	},
	["models/aperture/vactube_90deg_02.mdl"] = {
		[1] = {pos = Vector(), connected = {3}, outinx = 1},
		[2] = {pos = Vector(0, 128, -128), connected = {3}, outinx = 2},
		[3] = {pos = Vector(0, 95, -35), connected = {1, 2}}
	},
	["models/aperture/vactube_90deg_03.mdl"] = {
		[1] = {pos = Vector(), connected = {3}, outinx = 1},
		[2] = {pos = Vector(0, 192, -192), connected = {4}, outinx = 2},
		[3] = {pos = Vector(0, 90, -20), connected = {1, 4}},
		[4] = {pos = Vector(0, 160, -80), connected = {2, 3}}
	},
	["models/aperture/vactube_90deg_04.mdl"] = {
		[1] = {pos = Vector(), connected = {3}, outinx = 1},
		[2] = {pos = Vector(0, 256, -256), connected = {4}, outinx = 2},
		[3] = {pos = Vector(0, 110, -20), connected = {1, 4}},
		[4] = {pos = Vector(0, 190, -80), connected = {3, 5}},
		[5] = {pos = Vector(0, 240, -160), connected = {2, 4}}
	},
	["models/aperture/vactube_90deg_05.mdl"] = {
		[1] = {pos = Vector(), connected = {3}, outinx = 1},
		[2] = {pos = Vector(0, 320, -320), connected = {4}, outinx = 2},
		[3] = {pos = Vector(0, 130, -25), connected = {1, 4}},
		[4] = {pos = Vector(0, 230, -95), connected = {3, 5}},
		[5] = {pos = Vector(0, 300, -200), connected = {2, 4}}
	},
	["models/aperture/vactube_90deg_06.mdl"] = {
		[1] = {pos = Vector(), connected = {3}, outinx = 1},
		[2] = {pos = Vector(0, 384, -384), connected = {4}, outinx = 2},
		[3] = {pos = Vector(0, 150, -30), connected = {1, 4}},
		[4] = {pos = Vector(0, 275, -110), connected = {3, 5}},
		[5] = {pos = Vector(0, 365, -250), connected = {2, 4}}
	},
	["models/aperture/vactube_tjunction.mdl"] = {
		[1] = {pos = Vector(), connected = {4}, outinx = 1},
		[2] = {pos = Vector(-192, 64, 0), connected = {4}, outinx = 2},
		[3] = {pos = Vector(0, 128, 0), connected = {4}, outinx = 3},
		[4] = {pos = Vector(0, 64, 0), connected = {1, 2, 3}}
	},
	["models/aperture/vactube_crossroads.mdl"] = {
		[1] = {pos = Vector(), connected = {5}, outinx = 1},
		[2] = {pos = Vector(192, 64, 0), connected = {5}, outinx = 2},
		[3] = {pos = Vector(0, 128, 0), connected = {5}, outinx = 3},
		[4] = {pos = Vector(-192, 64, 0), connected = {5}, outinx = 4},
		[5] = {pos = Vector(0, 64, 0), connected = {1, 2, 3, 4}}
	},
}

local FilterableModelData = {
	["models/aperture/vactube_tjunction.mdl"] = Vector(0, 64, 0),
	["models/aperture/vactube_crossroads.mdl"] = Vector(0, 64, 0),
}

function LIB_APERTURE:GetFilterColor(inx)
	return FilterRoutesColor[inx]
end

function LIB_APERTURE:GetModelConnectionData(val)
	if isentity(val) then
		return ModelConnectionData[val:GetModel()]
	else
		return ModelConnectionData[val]
	end
end

function LIB_APERTURE:GetModelFlowData(val)
	if isentity(val) then
		return ModelFlowData[val:GetModel()]
	else
		return ModelFlowData[val]
	end
end

function LIB_APERTURE:GetFilterableModelData(val)
	if isentity(val) then
		return FilterableModelData[val:GetModel()]
	else
		return FilterableModelData[val]
	end
end