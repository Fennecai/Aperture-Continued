TOOL.Tab = "Aperture"
TOOL.Category = "Puzzle elements"
TOOL.Name = "#tool.aperture_crusher.name"

TOOL.ClientConVar["keyenable"] = "45"
TOOL.ClientConVar["startenabled"] = "0"
TOOL.ClientConVar["toggle"] = "0"
TOOL.ClientConVar["twoside"] = "0"
TOOL.ClientConVar["countx"] = "1"
TOOL.ClientConVar["county"] = "1"

local CRUSHER_GRID = 220
local CRUSHER_MODEL = "models/aperture/crusher.mdl"
local CRUSHER_MODEL_BOX = "models/aperture/crusher_box.mdl"
local ADDING_HEIGHT = 80
local AnimTime = 2

if CLIENT then
     language.Add("tool.aperture_crusher.name", "Crusher")
     language.Add("tool.aperture_crusher.desc", "...This is not a panel. its a crusher. we sell those too.")
     language.Add("tool.aperture_crusher.0", "Left click to place")
     language.Add("tool.aperture_crusher.enable", "Enable")
     language.Add("tool.aperture_crusher.startenabled", "Enabled")
     language.Add("tool.aperture_crusher.startenabled.help", "Crusher will deploy as soon as it is placed")
     language.Add("tool.aperture_crusher.twoside", "Two Sided")
     language.Add(
          "tool.aperture_crusher.twoside.help",
          "Spawn an additional crusher facing the first one from the other direction."
     )
     language.Add("tool.aperture_crusher.countx", "Copies to the back")
     language.Add("tool.aperture_crusher.county", "Copies to the right")
     language.Add("tool.aperture_crusher.toggle", "Toggle")
     language.Add(
          "tool.aperture_crusher.toggle.help",
          "Toggle it on and off, or hold the key down the entire time. Crushers repeatedly crush while activated."
     )
end

local function IsCrushersNearby(pos)
     local entities = ents.FindInSphere(pos, 200)
     for k, v in pairs(entities) do
          if v:GetClass() == "ent_portal_crusher" then
               return v
          end
     end
end

local function GetSpawnPos(pos, ang, ply, normal)
     local crusherPanel = IsCrushersNearby(pos)
     if not IsValid(crusherPanel) then
          return
     end
     local crusherPos = crusherPanel:GetPos()
     local crusherAng = crusherPanel:GetAngles()
     local crusherAngR = crusherPanel:LocalToWorldAngles(Angle(90, 0, 0))
     local gridCrusherPos = LIB_MATH_TA:SnapToGridOnSurface(crusherPos, crusherAngR, CRUSHER_GRID)
     local posOffset = crusherPanel:WorldToLocal(gridCrusherPos)
     local gridPos = LIB_MATH_TA:SnapToGridOnSurface(pos, crusherAngR, CRUSHER_GRID)
     gridPos = LocalToWorld(-posOffset, Angle(), gridPos, crusherAng)
     pos:Set(gridPos)
     ang:Set(crusherAng)

     if crusherPos == gridPos then
          return 1
     end
     return 0
end

local function MakeCrusher(ply, pos, ang, key_enable, length, startenabled, toggle, data)
     local ent = ents.Create("ent_portal_crusher")
     if not IsValid(ent) then
          return
     end

     duplicator.DoGeneric(ent, data)

     ent:SetPos(pos)
     ent:SetAngles(ang)
     ent:SetMoveType(MOVETYPE_NONE)
     ent:SetPlayer(ply)
     ent:SetStartEnabled(tobool(startenabled))
     ent:SetToggle(tobool(toggle))
     ent:SetLength(length)
     ent:Spawn()

     -- initializing numpad inputs
     ent.NumDown = numpad.OnDown(ply, key_enable, "PortalCrusher_Enable", ent, true)
     ent.NumUp = numpad.OnUp(ply, key_enable, "PortalCrusher_Enable", ent, false)

     -- saving data
     local ttable = {
          key_enable = key_enable,
          ply = ply,
          startenabled = startenabled,
          toggle = toggle,
          data = data
     }

     table.Merge(ent:GetTable(), ttable)

     if IsValid(ply) then
          ply:AddCleanup("Crusher", ent)
     end

     return ent
end

if SERVER then
     duplicator.RegisterEntityClass(
          "ent_portal_crusher",
          MakeCrusher,
          "pos",
          "ang",
          "length",
          "key_enable",
          "startenabled",
          "toggle",
          "data"
     )
end

function TOOL:LeftClick(trace)
     -- Ignore if place target is Alive
     --if ( trace.Entity and ( trace.Entity:IsPlayer() or trace.Entity:IsNPC() or APERTURESCIENCE:GASLStuff( trace.Entity ) ) ) then return false end
     if CLIENT then
          return true
     end

     -- if not APERTURESCIENCE.ALLOWING.paint and not self:GetOwner():IsSuperAdmin() then self:GetOwner():PrintMessageHUD_PRINTTALK, "This tool is disabled" return end
     local ply = self:GetOwner()
     local twoside = self:GetClientNumber("twoside")
     local countx = self:GetClientNumber("countx")
     local county = self:GetClientNumber("county")
     local key_enable = self:GetClientNumber("keyenable")
     local startenabled = self:GetClientNumber("startenabled")
     local toggle = self:GetClientNumber("toggle")
     local pos = trace.HitPos + trace.HitNormal * ADDING_HEIGHT
     local ang = trace.HitNormal:Angle()
     local result = GetSpawnPos(pos, ang, ply, trace.HitNormal)
     if result == 1 then
          return true
     end
     local crusherPanelTable = {}
     local undocrushers = {}

     for x = 0, countx - 1 do
          for y = 0, county - 1 do
               if twoside == 1 then
                    local maxleng = 1280 + ADDING_HEIGHT * 2
                    local offset = Vector(0, y, -x) * CRUSHER_GRID
                    offset:Rotate(ang)
                    local lpos = pos + offset
                    local tpos = lpos - trace.HitNormal * ADDING_HEIGHT
                    local ltrace =
                         util.TraceLine(
                         {
                              start = tpos,
                              endpos = tpos + trace.HitNormal * maxleng,
                              mask = MASK_SHOT
                         }
                    )
                    local length = math.max(0, (maxleng * ltrace.Fraction - 220 * 2 - ADDING_HEIGHT * 2) / 2)

                    local ent1 = MakeCrusher(ply, pos, ang, key_enable, length, startenabled, toggle)

                    table.insert(crusherPanelTable, ent1)
                    table.insert(undocrushers, ent1)
                    for k, v in pairs(crusherPanelTable) do
                         lpos = ltrace.HitPos - trace.HitNormal * ADDING_HEIGHT
                         local lang = v:LocalToWorldAngles(Angle(0, 180, 0))
                         local ent2 = MakeCrusher(ply, lpos, lang, key_enable, length, startenabled, toggle)
                         table.insert(undocrushers, ent2)
                    end
               else
                    local offset = Vector(0, y, -x) * CRUSHER_GRID
                    offset:Rotate(ang)
                    local pos = pos + offset
                    local trace1 =
                         util.TraceLine(
                         {
                              start = pos,
                              endpos = pos + trace.HitNormal * 640,
                              mask = MASK_SHOT
                         }
                    )
                    local length = math.max(0, 640 * trace1.Fraction - 220)

                    local ent = MakeCrusher(ply, pos, ang, key_enable, length, startenabled, toggle)
                    table.insert(undocrushers, ent)
               end
          end
     end

     undo.Create("Crusher")
     for k, v in pairs(undocrushers) do
          undo.AddEntity(v)
     end
     undo.SetPlayer(ply)
     undo.Finish()

     return true, ent
end

if CLIENT then
     function TOOL:MakeGhostEntityInx(inx, model, subinx)
          if not self.TA_GhostEntityArray then
               self.TA_GhostEntityArray = {}
          end
          local subinx = subinx and subinx or 0
          local inxName = inx .. "_" .. subinx
          local ent = self.TA_GhostEntityArray[inxName]
          if IsValid(ent) then
               return
          end
          local ent = ClientsideModel(model)
          ent.AutomaticFrameAdvance = true
          if not IsValid(ent) then
               return
          end
          ent:SetRenderMode(RENDERMODE_TRANSALPHA)

          self.TA_GhostEntityArray[inxName] = ent
     end

     function TOOL:RemoveGhostEntitityInx(inx, subinx)
          if not self.TA_GhostEntityArray then
               return
          end
          local subinx = subinx and subinx or 0
          local inxName = inx .. "_" .. subinx
          local ent = self.TA_GhostEntityArray[inxName]
          if not IsValid(ent) then
               return
          end
          ent:Remove()
     end

     function TOOL:GetGhostEntityInx(inx, subinx)
          if not self.TA_GhostEntityArray then
               return
          end
          local subinx = subinx and subinx or 0
          local inxName = inx .. "_" .. subinx

          return self.TA_GhostEntityArray[inxName]
     end

     function TOOL:RemoveGhostEntityRange(minInx, maxInx, subinx)
          for i = minInx, maxInx do
               self:RemoveGhostEntitityInx(i, subinx)
          end
     end

     function TOOL:ClearGhostEntities()
          if not self.TA_GhostEntityArray then
               return
          end
          for k, v in pairs(self.TA_GhostEntityArray) do
               v:Remove()
               self.TA_GhostEntityArray[k] = nil
          end
     end
end

function TOOL:TransformGhostCrusher(ent)
     if not IsValid(ent) then
          return
     end
     local mult = math.min(1, (CurTime() - math.floor(CurTime() / AnimTime) * AnimTime) / (AnimTime - 0.5))
     local multF = math.min(1, (CurTime() - math.floor(CurTime() / AnimTime) * AnimTime) / AnimTime)

     ent:SetPos(ent:LocalToWorld(Vector(mult * 400, 0, 0)))
     ent:SetColor(Color(255, 255, 255, math.sin(multF * math.pi) * 50))
end

function TOOL:UpdateGhostCrusherInx(offsetx, offsety, inx, ply)
     local ent = self:GetGhostEntityInx(inx)
     if not IsValid(ent) then
          return
     end
     local crusherModel = self:GetGhostEntityInx(inx, 1)
     local animCrusher = self:GetGhostEntityInx(inx, 2)

     local trace = ply:GetEyeTrace()
     if not trace.Hit or trace.Entity and (trace.Entity:IsPlayer() or trace.Entity:IsNPC() or trace.Entity.IsAperture) then
          ent:SetNoDraw(true)
          return
     end
     local curPos = ent:GetPos()
     local pos = trace.HitPos + trace.HitNormal * 80
     local ang = trace.HitNormal:Angle()
     local result = GetSpawnPos(pos, ang, ply, trace.HitNormal)
     if result == 1 then
          ent:SetNoDraw(true)
          return
     end
     local offset = Vector(0, offsety, -offsetx) * CRUSHER_GRID
     offset:Rotate(ang)
     pos = pos + offset
     ent:SetPos(pos)
     ent:SetAngles(ang)
     ent:SetNoDraw(false)
     ent:SetColor(Color(255, 255, 255, 100))
     --box
     crusherModel:SetPos(pos)
     crusherModel:SetAngles(ang)
     crusherModel:SetColor(Color(255, 255, 255, 100))

     if IsValid(animCrusher) then
          animCrusher:SetPos(pos)
          animCrusher:SetAngles(ang)
          animCrusher:SetNoDraw(false)
          self:TransformGhostCrusher(animCrusher)
     end
end

function TOOL:UpdateGhostCrushers(ply)
     local countx = self:GetClientNumber("countx")
     local county = self:GetClientNumber("county")
     local amount = countx * county
     local inx = 0
     for x = 0, countx - 1 do
          for y = 0, county - 1 do
               self:UpdateGhostCrusherInx(x, y, inx, self:GetOwner())
               inx = inx + 1
          end
     end
end

function TOOL:Think()
     if SERVER then
          return true
     end
     if self.HolserTime and CurTime() < (self.HolserTime + 0.1) then
          return
     end
     local countx = self:GetClientNumber("countx")
     local county = self:GetClientNumber("county")
     local amount = countx * county
     local lastAmount = self.LastPanelAmount

     if lastAmount ~= amount then
          local inx = 0
          for i1 = 1, countx do
               for i2 = 1, county do
                    self:MakeGhostEntityInx(inx, CRUSHER_MODEL_BOX)
                    self:MakeGhostEntityInx(inx, CRUSHER_MODEL, 1)
                    self:MakeGhostEntityInx(inx, CRUSHER_MODEL, 2)
                    inx = inx + 1
               end
          end

          if lastAmount and lastAmount > amount then
               self:RemoveGhostEntityRange(amount, lastAmount)
               self:RemoveGhostEntityRange(amount, lastAmount, 1)
               self:RemoveGhostEntityRange(amount, lastAmount, 2)
          end
          self.LastPanelAmount = amount
     end

     self:UpdateGhostCrushers(ply)

     -- if CLIENT then
     -- self:CreateAnimatedCrusher()
     -- if IsValid(self.TA_AnimatedCrusher) then
     -- self:UpdateGhostCrusherInx(self.TA_AnimatedCrusher)
     -- end
     -- end
end

function TOOL:RightClick(trace)
end

function TOOL:Holster()
     if SERVER then
          return true
     end
     self.HolserTime = CurTime()
     self:ClearGhostEntities()
     self.LastPanelAmount = 0
     return true
end

local ConVarsDefault = TOOL:BuildConVarList()

function TOOL.BuildCPanel(CPanel)
     CPanel:AddControl("Header", {Description = "#tool.aperture_crusher.desc"})
     CPanel:NumSlider("#tool.aperture_crusher.county", "aperture_crusher_county", 1, 10, 0)
     CPanel:NumSlider("#tool.aperture_crusher.countx", "aperture_crusher_countx", 1, 10, 0)
     CPanel:AddControl(
          "CheckBox",
          {Label = "#tool.aperture_crusher.twoside", Command = "aperture_crusher_twoside", Help = true}
     )
     CPanel:AddControl(
          "CheckBox",
          {Label = "#tool.aperture_crusher.startenabled", Command = "aperture_crusher_startenabled", Help = true}
     )
     CPanel:AddControl("Numpad", {Label = "#tool.aperture_crusher.enable", Command = "aperture_crusher_keyenable"})
     CPanel:AddControl(
          "CheckBox",
          {Label = "#tool.aperture_crusher.toggle", Command = "aperture_crusher_toggle", Help = true}
     )
end
