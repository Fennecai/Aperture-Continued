TOOL.Tab 		= "Aperture"
TOOL.Category 	= "Puzzle elements"
TOOL.Name 		= "#tool.aperture_tractor_beam.name"

TOOL.ClientConVar["startenabled"] = "0"
TOOL.ClientConVar["startreversed"] = "0"
TOOL.ClientConVar["keyenable"] = "46"
TOOL.ClientConVar["keyreverse"] = "43"
TOOL.ClientConVar["toggle"] = "0"

local FIELD_RADIUS = 50

if CLIENT then
	language.Add("tool.aperture_tractor_beam.name", "Exursion Funnel")
	language.Add("tool.aperture_tractor_beam.desc", "The Exursion Funnel will transport players and entities to some direction or back from it")
	language.Add("tool.aperture_tractor_beam.0", "Left click to place")
	language.Add("tool.aperture_tractor_beam.enable", "Enable")
	language.Add("tool.aperture_tractor_beam.reverse", "Reverse")
	language.Add("tool.aperture_tractor_beam.startenabled", "Enabled")
	language.Add("tool.aperture_tractor_beam.startenabled.help", "Excursion funnel starts enabled when placed")
	language.Add("tool.aperture_tractor_beam.startreversed", "Reversed")
	language.Add("tool.aperture_tractor_beam.startreversed.help", "Excursion funnel starts reversed when placed")
	language.Add("tool.aperture_tractor_beam.toggle", "Toggle")
end

if SERVER then

	function MakeTractorBeam(ply, pos, ang, key_enable, key_reverse, startenabled, startreversed, toggle, data)
		local ent = ents.Create("ent_tractor_beam")
		if not IsValid(ent) then return end
		
		duplicator.DoGeneric(ent, data)

		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:SetStartEnabled(tobool(startenabled))
		ent:SetStartReversed(tobool(startreversed))
		ent:SetToggle(tobool(toggle))
		ent:Spawn()
		
		-- initializing numpad inputs
		ent.NumDown = numpad.OnDown(ply, key_enable, "Tractorbeam_Enable", ent, true)
		ent.NumUp = numpad.OnUp(ply, key_enable, "Tractorbeam_Enable", ent, false)

		ent.NumBackDown = numpad.OnDown(ply, key_reverse, "Tractorbeam_Reverse", ent, true)
		ent.NumBackUp = numpad.OnUp(ply, key_reverse, "Tractorbeam_Reverse", ent, false)

		-- saving data
		local ttable = {
			key_enable = key_enable,
			key_reverse = key_reverse,
			ply = ply,
			startenabled = startenabled,
			startreversed = startreversed,
			toggle = toggle
		}

		table.Merge(ent:GetTable(), ttable)
		
		if IsValid(ply) then
			ply:AddCleanup("#tool.aperture_tractor_beam.name", ent)
		end
		
		return ent
	end

	duplicator.RegisterEntityClass("ent_tractor_beam", MakeTractorBeam, "pos", "ang", "key_enable", "key_reverse", "startenabled", "startreversed", "toggle", "data")

end -- SERVER

function TOOL:LeftClick( trace )

	-- Ignore if place target is Alive
	if trace.Entity and trace.Entity:IsPlayer() then return false end
	if CLIENT then return true end
	//if not APERTURESCIENCE.ALLOWING.tractor_beam and not self:GetOwner():IsSuperAdmin() then self:GetOwner():PrintMessage( HUD_PRINTTALK, "This tool is disabled" ) return end

	local ply = self:GetOwner()
	local key_enable = self:GetClientNumber("keyenable")
	local key_reverse = self:GetClientNumber("keyreverse")
	local startenabled = self:GetClientNumber("startenabled")
	local startreversed = self:GetClientNumber("startreversed")
	local toggle = self:GetClientNumber("toggle")

	local pos = trace.HitPos + trace.HitNormal * 31
	local ang = trace.HitNormal:Angle() + Angle(90, 0, 0)
	
	local ent = MakeTractorBeam(ply, pos, ang, key_enable, key_reverse, startenabled, startreversed, toggle)
	
	undo.Create("#tool.aperture_tractor_beam.name")
		undo.AddEntity(ent)
		undo.SetPlayer(ply)
	undo.Finish()

	return true, ent
end

function TOOL:UpdateGhostTractorBeam(ent, ply)
	if not IsValid(ent) then return end

	local trace = ply:GetEyeTrace()
	if not trace.Hit or trace.Entity and (trace.Entity:IsPlayer() or trace.Entity:IsNPC() or trace.Entity.IsAperture) then
		ent:SetNoDraw(true)
		return
	end
	
	local curPos = ent:GetPos()
	local pos = trace.HitPos + trace.HitNormal * 31
	local ang = trace.HitNormal:Angle() + Angle( 90, 0, 0 )

	ent:SetPos(pos)
	ent:SetAngles(ang)
	ent:SetNoDraw(false)
end

function TOOL:Think()
	local mdl = "models/aperture/tractor_beam.mdl"
	if not util.IsValidModel(mdl) then self:ReleaseGhostEntity() return end

	if not IsValid(self.GhostEntity) or self.GhostEntity:GetModel() != mdl then
		self:MakeGhostEntity( mdl, Vector( 0, 0, 0 ), Angle( 0, 0, 0 ) )
	end

	self:UpdateGhostTractorBeam(self.GhostEntity, self:GetOwner())
end

-- function TOOL:DrawHUD()
	-- local trace = LocalPlayer():GetEyeTrace()
	-- local pos = trace.HitPos + trace.HitNormal * 35
	-- local normal = trace.HitNormal
	-- local offsetX = Vector(0, 1, 0)
	-- offsetX:Rotate(trace.HitNormal:Angle())
	-- local offsetY = Vector(0, 0, 1)
	-- offsetY:Rotate(trace.HitNormal:Angle())
	
	-- local traceEnd = util.QuickTrace(pos, normal * LIB_MATH_TA.HUGE)
	-- cam.Start3D()
	-- render.SetMaterial(Material("effects/projected_wall_rail"))
	-- for i=0,2 do
		-- local angOffset = i * (math.pi * 2 / 3)
		-- local oldPos = Vector()
		-- for i2=0,pos:Distance(traceEnd.HitPos) / 25, 2 do
			-- local offset = offsetX * math.cos(i2 / 3 + angOffset) * FIELD_RADIUS + offsetY * math.sin(i2 / 3 + angOffset) * FIELD_RADIUS + normal * i2 * 25
			-- if i2 > 0 then
				-- render.DrawBeam(pos + offset, oldPos, 10, 1, (pos + offset):Distance(oldPos) / 50, Color(255, 255, 255))
			-- end
			-- oldPos = pos + offset
		-- end
	-- end
	-- cam.End3D()
-- end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", {Description = "#tool.aperture_tractor_beam.desc"})
	CPanel:AddControl("CheckBox", {Label = "#tool.aperture_tractor_beam.startenabled", Command = "aperture_tractor_beam_startenabled", Help = true})
	CPanel:AddControl("CheckBox", {Label = "#tool.aperture_tractor_beam.startreversed", Command = "aperture_tractor_beam_startreversed", Help = true})
	CPanel:AddControl("Numpad", {Label = "#tool.aperture_tractor_beam.enable", Command = "aperture_tractor_beam_keyenable", Label2 = "#tool.aperture_tractor_beam.reverse", Command2 = "aperture_tractor_beam_keyreverse"})
	CPanel:AddControl("CheckBox", {Label = "#tool.aperture_tractor_beam.toggle", Command = "aperture_tractor_beam_toggle"})
end