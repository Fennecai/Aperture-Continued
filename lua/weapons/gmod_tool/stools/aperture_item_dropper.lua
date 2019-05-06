TOOL.Tab = "Aperture"
TOOL.Category = "Puzzle elements"
TOOL.Name = "#tool.aperture_item_dropper.name"

TOOL.ClientConVar["model"] = "models/aperture/item_dropper.mdl"
TOOL.ClientConVar["respawn"] = "0"
TOOL.ClientConVar["drop_type"] = "1"
TOOL.ClientConVar["initdrop"] = "0"
TOOL.ClientConVar["keyenable"] = "42"
TOOL.ClientConVar["dropforce"] = "0"

if CLIENT then
	language.Add("tool.aperture_item_dropper.name", "Item Dropper")
	language.Add("tool.aperture_item_dropper.desc", "The Item Dropper will deploy specific items")
	language.Add("tool.aperture_item_dropper.0", "Left click to place")
	language.Add("tool.aperture_item_dropper.keyenable", "Drop Button")
	language.Add("tool.aperture_item_dropper.dropType", "Drop Type")
	language.Add("tool.aperture_item_dropper.drop_at_start", "Drop when Placed")
	language.Add("tool.aperture_item_dropper.drop_at_start.help", "Item Dropper will drop an item as soon as it is placed")
	language.Add("tool.aperture_item_dropper.respawn", "Respawn on item lost")
	language.Add("tool.aperture_item_dropper.respawn.help", "Drop another item if the last one ceases to exist")
	language.Add("tool.aperture_item_dropper.dropforce", "Drop Force")
	language.Add(
		"tool.aperture_item_dropper.dropforce.help",
		"How much force is applied to the item when it is dropped. useful for droppers that arent on the ceiling, and for rogue A.Is that want to slam cubes down on test subjects really really hard."
	)
end

if SERVER then
	function MakeDropper(pl, pos, ang, model, key_enable, drop_type, drop_at_start, respawnthecube, dforce, data)
		local ent = ents.Create("ent_item_dropper")
		if not IsValid(ent) then
			return
		end
		ent:SetModel(model)
		ent:SetPos(pos)
		ent:SetAngles(ang)
		ent:SetMoveType(MOVETYPE_NONE)
		ent:SetRespawn(tobool(respawnthecube))
		ent:SetDropType(drop_type)
		ent:SetDropAtStart(drop_at_start)
		ent:SetDropForce(dforce)
		ent:Spawn()

		duplicator.DoGeneric(ent, data)

		-- initializing numpad inputs
		ent.NumDown = numpad.OnDown(ply, key_enable, "PortalItemDropper_Drop", ent, true)
		ent.NumUp = numpad.OnUp(ply, key_enable, "PortalItemDropper_Drop", ent, false)

		-- saving data
		local ttable = {
			model = model,
			key_enable = key_enable,
			ply = ply,
			drop_type = drop_type,
			drop_at_start = drop_at_start,
			respawn = respawn,
			data = data
		}

		table.Merge(ent:GetTable(), ttable)

		if IsValid(ply) then
			ply:AddCleanup("#tool.aperture_item_dropper.name", ent)
		end

		return ent
	end

	duplicator.RegisterEntityClass(
		"ent_item_dropper",
		MakeDropper,
		"pos",
		"ang",
		"model",
		"key_enable",
		"drop_type",
		"drop_at_start",
		"respawnthecube",
		"dforce",
		"data"
	)
end

function TOOL:LeftClick(trace)
	-- Ignore if place target is Alive
	-- if trace.Entity and trace.Entity:IsPlayer() then return false end
	if CLIENT then
		return true
	end
	--if not LIB_APERTURECONTINUED.ALLOWING.item_dropper and  notself:GetOwner():IsSuperAdmin() then self:GetOwner():PrintMessage( HUD_PRINTTALK, "This tool is disabled" ) return end

	local normal = trace.HitNormal

	local ply = self:GetOwner()
	local model = self:GetClientInfo("model")
	local key_enable = self:GetClientNumber("keyenable")
	local respawnthecube = self:GetClientNumber("respawn")
	local dropType = self:GetClientNumber("drop_type")
	local drop_at_start = tobool(self:GetClientNumber("initdrop"))
	local dforce = self:GetClientNumber("dropforce") * 1000
	local pos = trace.HitPos + normal * 85
	local ang = normal:Angle() - Angle(90, 0, 0)
	--local ent = MakeDropper(ply, pos, ang, model, key_enable, dropType, drop_at_start, respawn)
	local ent = MakeDropper(ply, pos, ang, model, key_enable, dropType, drop_at_start, respawnthecube, dforce)

	undo.Create("Item Dropper")
	undo.AddEntity(ent)
	undo.SetPlayer(ply)
	undo.Finish()

	return true, ent
end

function TOOL:UpdateGhostItemDropper(ent, ply)
	if not IsValid(ent) then
		return
	end

	local trace = ply:GetEyeTrace()
	local normal = trace.HitNormal

	if not trace.Hit or trace.Entity and trace.Entity:IsPlayer() or trace.Entity:IsNPC() then
		ent:SetNoDraw(true)
		return
	end

	local ang = normal:Angle() - Angle(90, 0, 0)
	local pos = trace.HitPos

	-- if math.Round(normal.z) == -1 then
	-- 	ent:SetColor(Color(255, 255, 255, ent:GetColor().a))
	-- else
	-- 	ent:SetColor(Color(255, 0, 0, ent:GetColor().a))
	-- end

	ent:SetPos(pos + normal * 85)
	ent:SetAngles(ang)
	ent:SetNoDraw(false)
end

function TOOL:Think()
	local mdl = self:GetClientInfo("model")
	if not util.IsValidModel(mdl) then
		self:ReleaseGhostEntity()
		return
	end

	if not IsValid(self.GhostEntity) or self.GhostEntity:GetModel() ~= mdl then
		self:MakeGhostEntity(mdl, Vector(), Angle())
	end
	self:UpdateGhostItemDropper(self.GhostEntity, self:GetOwner())
end

function TOOL:RightClick(trace)
end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(CPanel)
	CPanel:AddControl("Header", {Description = "#tool.aperture_item_dropper.desc"})
	local combobox = CPanel:ComboBox("#tool.aperture_item_dropper.dropType", "aperture_item_dropper_drop_type")
	for k, v in pairs(LIB_APERTURECONTINUED.ITEM_DROPPER_ITEMS) do
		combobox:AddChoice(v, k)
	end

	CPanel:AddControl(
		"PropSelect",
		{ConVar = "aperture_item_dropper_model", Models = list.Get("PortalItemDropperModels"), Height = 1}
	)
	CPanel:AddControl(
		"Numpad",
		{Label = "#tool.aperture_item_dropper.keyenable", Command = "aperture_item_dropper_keyenable"}
	)
	CPanel:AddControl(
		"CheckBox",
		{Label = "#tool.aperture_item_dropper.drop_at_start", Command = "aperture_item_dropper_initdrop", Help = true}
	)
	CPanel:AddControl(
		"CheckBox",
		{Label = "#tool.aperture_item_dropper.respawn", Command = "aperture_item_dropper_respawn", Help = true}
	)
	CPanel:NumSlider("#tool.aperture_item_dropper.dropforce", "aperture_item_dropper_dropforce", 0, 1000, 3)
end

list.Set("PortalItemDropperModels", "models/aperture/item_dropper.mdl", {})
list.Set("PortalItemDropperModels", "models/aperture/underground_boxdropper.mdl", {})
