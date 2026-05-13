local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Mouse      = game.Players.LocalPlayer:GetMouse()
local localPlayer = Players.LocalPlayer
local character  = localPlayer.Character or localPlayer.CharacterAdded:Wait()

local AmmoHackEnabled    = false
local StaminaHackEnabled = false

local function AmmoHack()
    if AmmoHackEnabled then
        AmmoHackEnabled = false
    else
        AmmoHackEnabled = true
        task.spawn(function()
            while AmmoHackEnabled do
                pcall(function()
                    character.PrimaryAmmo.Value = 80085
                    character.PrimaryAmmoMax.Value = 80085
                    character.SecondaryAmmo.Value = 80085
                    character.SecondaryAmmoMax.Value = 80085
                    character.GadgetAmmo.Value = 80085
                    character.GadgetAmmoMax.Value = 80085
                end)
                task.wait(0.1)
            end
        end)
    end
end

local function StaminaHack()
    if StaminaHackEnabled then
        StaminaHackEnabled = false
    else
        StaminaHackEnabled = true
        task.spawn(function()
            while StaminaHackEnabled do
                pcall(function()
                    character.Stamina.Value = 80085
                end)
                task.wait(0.1)
            end
        end)
    end
end

local espEnabled = { Guard=false, Civilian=false, Camera=false, Lootable=false }
local espDrawings = {}

local ESP_COLORS = {
    Guard    = Color3.fromRGB(255, 80,  80),
    Civilian = Color3.fromRGB(80,  200, 255),
    Camera   = Color3.fromRGB(255, 220, 50),
    Lootable = Color3.fromRGB(80,  255, 120),
}

local instanceIDs = setmetatable({}, {__mode = "k"})
local nextID = 0
local function getID(inst)
    if not instanceIDs[inst] then
        nextID = nextID + 1
        instanceIDs[inst] = nextID
    end
    return instanceIDs[inst]
end

local function getOrCreateESP(key, color)
    if not espDrawings[key] then
        local box = Drawing.new("Square")
        box.Visible   = false
        box.Filled    = false
        box.Color     = color
        box.Thickness = 1

        local text = Drawing.new("Text")
        text.Visible = false
        text.Center  = true
        text.Outline = true
        text.Color   = color
        text.Size    = 14

        espDrawings[key] = { box = box, text = text }
    end
    return espDrawings[key]
end

local function hideESP(key)
    local d = espDrawings[key]
    if d then d.box.Visible = false; d.text.Visible = false end
end

local function drawCharESP(key, color, root, head, label)
    local ok = pcall(function()
        local torsoScreen, onScreen = WorldToScreen(root.Position)
        local headScreen  = WorldToScreen(head.Position + Vector3.new(0, 0.5, 0))
        local feetScreen  = WorldToScreen(root.Position - Vector3.new(0, 3, 0))
        local d = getOrCreateESP(key, color)
        if onScreen then
            local height = math.abs(headScreen.Y - feetScreen.Y)
            local width  = height / 2
            d.box.Position  = Vector2.new(torsoScreen.X - width/2, headScreen.Y)
            d.box.Size      = Vector2.new(width, height)
            d.box.Color     = color
            d.box.Visible   = true
            d.text.Position = Vector2.new(torsoScreen.X, headScreen.Y - 16)
            d.text.Text     = label
            d.text.Color    = color
            d.text.Visible  = true
        else
            hideESP(key)
        end
    end)
    if not ok then hideESP(key) end
end

local function drawObjectESP(key, color, pos, label, size)
    size = size or 14
    local ok = pcall(function()
        local screen, onScreen = WorldToScreen(pos)
        local d = getOrCreateESP(key, color)
        if onScreen then
            local half = size / 2
            d.box.Position  = Vector2.new(screen.X - half, screen.Y - half)
            d.box.Size      = Vector2.new(size, size)
            d.box.Color     = color
            d.box.Visible   = true
            d.text.Position = Vector2.new(screen.X, screen.Y - size - 4)
            d.text.Text     = label
            d.text.Color    = color
            d.text.Visible  = true
        else
            hideESP(key)
        end
    end)
    if not ok then hideESP(key) end
end

local function getSafePosition(obj)
    if not obj or obj.Parent == nil then return nil end
    local ok, pos = pcall(function() return obj.Position end)
    if ok and typeof(pos) == "Vector3" then return pos end
    local ok2, part = pcall(function()
        return obj:FindFirstChild("HumanoidRootPart")
            or obj:FindFirstChild("HeadPart")
            or obj:FindFirstChild("Root")
            or obj:FindFirstChild("Torso")
            or obj:FindFirstChild("Handle")
            or obj:FindFirstChildWhichIsA("BasePart")
    end)
    if ok2 and part then
        local ok3, p = pcall(function() return part.Position end)
        if ok3 and typeof(p) == "Vector3" then return p end
    end
    return nil
end

task.spawn(function()
    while true do
        task.wait(0.05)

        do
            local seen = {}
            if espEnabled.Camera then
                local folder = workspace:FindFirstChild("Cameras")
                if folder then
                    for _, cam in ipairs(folder:GetChildren()) do
                        pcall(function()
                            local pos = getSafePosition(cam)
                            if not pos then return end
                            local key = "CAM_" .. getID(cam)
                            seen[key] = true
                            drawObjectESP(key, ESP_COLORS.Camera, pos, "[Cam] " .. cam.Name, 16)
                        end)
                    end
                end
            end
            for key in pairs(espDrawings) do
                if key:sub(1,4) == "CAM_" and not seen[key] then hideESP(key) end
            end
        end

        do
            local seen = {}
            if espEnabled.Lootable then
                local folder = workspace:FindFirstChild("Lootables")
                if folder then
                    for _, obj in ipairs(folder:GetChildren()) do
                        pcall(function()
                            local pos = getSafePosition(obj)
                            if not pos then return end
                            local key = "L_" .. getID(obj)
                            seen[key] = true
                            drawObjectESP(key, ESP_COLORS.Lootable, pos, "[Loot] " .. obj.Name, 12)
                        end)
                    end
                end
            end
            for key in pairs(espDrawings) do
                if key:sub(1,2) == "L_" and not seen[key] then hideESP(key) end
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    local seen = {}

    if espEnabled.Guard then
        local folder = workspace:FindFirstChild("Police")
        if folder then
            for _, npc in ipairs(folder:GetChildren()) do
                pcall(function()
                    if not npc.Parent then return end
                    local root     = npc:FindFirstChild("HumanoidRootPart")
                    local head     = npc:FindFirstChild("Head")
                    local humanoid = npc:FindFirstChildOfClass("Humanoid")
                    if not (root and head and humanoid) then return end
                    if humanoid.Health <= 0 then return end
                    local key = "G_" .. getID(npc)
                    seen[key] = true
                    drawCharESP(key, ESP_COLORS.Guard, root, head, "[Guard] " .. npc.Name)
                end)
            end
        end
    end

    if espEnabled.Civilian then
        local folder = workspace:FindFirstChild("Citizens")
        if folder then
            for _, npc in ipairs(folder:GetChildren()) do
                pcall(function()
                    if not npc.Parent then return end
                    local root     = npc:FindFirstChild("HumanoidRootPart")
                    local head     = npc:FindFirstChild("Head")
                    local humanoid = npc:FindFirstChildOfClass("Humanoid")
                    if not (root and head and humanoid) then return end
                    if humanoid.Health <= 0 then return end
                    local key = "C_" .. getID(npc)
                    seen[key] = true
                    drawCharESP(key, ESP_COLORS.Civilian, root, head, "[Civ] " .. npc.Name)
                end)
            end
        end
    end

    for key in pairs(espDrawings) do
        local prefix = key:sub(1,2)
        if (prefix == "G_" or prefix == "C_") and not seen[key] then
            hideESP(key)
        end
    end
end)

local Container = Drawing.new("Square")
Container.Visible      = true
Container.Transparency = 1
Container.ZIndex       = 10
Container.Color        = Color3.fromHex("#171717")
Container.Position     = Vector2.new(225, 50)
Container.Size         = Vector2.new(350, 500)
Container.Filled       = true
Container.Corner       = 15

local Container_Border = Drawing.new("Square")
Container_Border.Visible      = true
Container_Border.Transparency = 1
Container_Border.ZIndex       = 11
Container_Border.Color        = Color3.fromHex("#242424")
Container_Border.Filled       = false
Container_Border.Thickness    = 8
Container_Border.Position     = Container.Position
Container_Border.Size         = Container.Size
Container_Border.Corner       = 15

local bugwaretext = Drawing.new("Text")
bugwaretext.Visible      = true
bugwaretext.Transparency = 1
bugwaretext.ZIndex       = 20
bugwaretext.Color        = Color3.fromHex("#FFFFFF")
bugwaretext.Position     = Container.Position + Vector2.new(75, 10)
bugwaretext.Text         = "bugware.cc — private"
bugwaretext.Size         = 22
bugwaretext.Center       = false
bugwaretext.Outline      = true
bugwaretext.Font         = Drawing.Fonts.UI

-- Ammo Hack button
local Button_AmmoHack = Drawing.new("Square")
Button_AmmoHack.Visible      = true
Button_AmmoHack.Transparency = 1
Button_AmmoHack.ZIndex       = 30
Button_AmmoHack.Color        = Color3.fromHex("#212121")
Button_AmmoHack.Position     = Container.Position + Vector2.new(14, 50)
Button_AmmoHack.Size         = Vector2.new(100, 30)
Button_AmmoHack.Filled       = true
Button_AmmoHack.Corner       = 15

local Button_AmmoHack_Border = Drawing.new("Square")
Button_AmmoHack_Border.Visible      = true
Button_AmmoHack_Border.Transparency = 1
Button_AmmoHack_Border.ZIndex       = 31
Button_AmmoHack_Border.Color        = Color3.fromHex("#363636")
Button_AmmoHack_Border.Filled       = false
Button_AmmoHack_Border.Thickness    = 1
Button_AmmoHack_Border.Position     = Button_AmmoHack.Position
Button_AmmoHack_Border.Size         = Button_AmmoHack.Size
Button_AmmoHack_Border.Corner       = 15

local Button_AmmoHack_Text = Drawing.new("Text")
Button_AmmoHack_Text.Text     = "Ammo Hack"
Button_AmmoHack_Text.Size     = 17
Button_AmmoHack_Text.Center   = true
Button_AmmoHack_Text.Outline  = true
Button_AmmoHack_Text.Font     = 0
Button_AmmoHack_Text.Color    = Color3.fromHex("#ffffff")
Button_AmmoHack_Text.Position = Button_AmmoHack.Position + Vector2.new(50, 15)
Button_AmmoHack_Text.Visible  = true
Button_AmmoHack_Text.ZIndex   = 32

local Button_StaminaHack = Drawing.new("Square")
Button_StaminaHack.Visible      = true
Button_StaminaHack.Transparency = 1
Button_StaminaHack.ZIndex       = 30
Button_StaminaHack.Color        = Color3.fromHex("#212121")
Button_StaminaHack.Position     = Container.Position + Vector2.new(236, 50)
Button_StaminaHack.Size         = Vector2.new(100, 30)
Button_StaminaHack.Filled       = true
Button_StaminaHack.Corner       = 15

local Button_StaminaHack_Border = Drawing.new("Square")
Button_StaminaHack_Border.Visible      = true
Button_StaminaHack_Border.Transparency = 1
Button_StaminaHack_Border.ZIndex       = 31
Button_StaminaHack_Border.Color        = Color3.fromHex("#363636")
Button_StaminaHack_Border.Filled       = false
Button_StaminaHack_Border.Thickness    = 1
Button_StaminaHack_Border.Position     = Button_StaminaHack.Position
Button_StaminaHack_Border.Size         = Button_StaminaHack.Size
Button_StaminaHack_Border.Corner       = 15

local Button_StaminaHack_Text = Drawing.new("Text")
Button_StaminaHack_Text.Text     = "Stamina Hack"
Button_StaminaHack_Text.Size     = 17
Button_StaminaHack_Text.Center   = true
Button_StaminaHack_Text.Outline  = true
Button_StaminaHack_Text.Font     = 0
Button_StaminaHack_Text.Color    = Color3.fromHex("#ffffff")
Button_StaminaHack_Text.Position = Button_StaminaHack.Position + Vector2.new(50, 15)
Button_StaminaHack_Text.Visible  = true
Button_StaminaHack_Text.ZIndex   = 32

local function MakeSwitch(posX, posY, labelText)
    local bg = Drawing.new("Square")
    bg.Visible=true; bg.Transparency=1
    bg.Color=Color3.fromHex("#3d3d3d"); bg.Filled=true
    bg.Size=Vector2.new(40,20); bg.Position=Vector2.new(posX,posY)
    bg.ZIndex=60; bg.Corner=15

    local outline = Drawing.new("Square")
    outline.Visible=true; outline.Transparency=1
    outline.Color=Color3.fromHex("#000000"); outline.Filled=false
    outline.Thickness=2; outline.Size=Vector2.new(40,20)
    outline.Position=Vector2.new(posX,posY); outline.ZIndex=60; outline.Corner=15

    local indBorder = Drawing.new("Square")
    indBorder.Visible=true; indBorder.Transparency=1
    indBorder.Color=Color3.fromHex("#000000"); indBorder.Filled=false
    indBorder.Thickness=2; indBorder.Size=Vector2.new(16,16)
    indBorder.ZIndex=62; indBorder.Corner=15
    indBorder.Position=Vector2.new(posX+2, posY+2)

    local ind = Drawing.new("Square")
    ind.Visible=true; ind.Transparency=1
    ind.Color=Color3.fromHex("#ffffff"); ind.Filled=true
    ind.Size=Vector2.new(16,16); ind.ZIndex=62; ind.Corner=15
    ind.Position=Vector2.new(posX+2, posY+2)

    local lbl = Drawing.new("Text")
    lbl.Visible=true; lbl.Text=labelText; lbl.Size=16
    lbl.Color=Color3.fromHex("#FFFFFF"); lbl.Outline=true
    lbl.Font=Drawing.Fonts.UI
    lbl.Position=Vector2.new(posX+50, posY+2); lbl.ZIndex=61

    local sw = {bg=bg, outline=outline, indBorder=indBorder, ind=ind, lbl=lbl, isChecked=false}

    local function refresh()
        local ox = sw.isChecked and 22 or 2
        sw.indBorder.Position = sw.bg.Position + Vector2.new(ox, 2)
        sw.ind.Position       = sw.bg.Position + Vector2.new(ox, 2)
        sw.bg.Color = sw.isChecked and Color3.fromHex("#4caf50") or Color3.fromHex("#3d3d3d")
    end

    function sw:Toggle()   self.isChecked = not self.isChecked; refresh() end
    function sw:SetPos(p)
        self.bg.Position      = p
        self.outline.Position = p
        self.lbl.Position     = p + Vector2.new(50, 2)
        refresh()
    end
    function sw:HitTest(m)
        return m.X >= self.bg.Position.X
           and m.X <= self.bg.Position.X + self.bg.Size.X
           and m.Y >= self.bg.Position.Y
           and m.Y <= self.bg.Position.Y + self.bg.Size.Y
    end
    return sw
end

local GuardESP_SW    = MakeSwitch(Container.Position.X+14, Container.Position.Y+94,  "Guard ESP")
local CivilianESP_SW = MakeSwitch(Container.Position.X+14, Container.Position.Y+121, "Civilian ESP")
local CameraESP_SW   = MakeSwitch(Container.Position.X+14, Container.Position.Y+148, "Camera ESP")
local LootableESP_SW = MakeSwitch(Container.Position.X+14, Container.Position.Y+175, "Lootable ESP")

local function setButtonActive(btn, active)
    btn.Color = active and Color3.fromHex("#1a472a") or Color3.fromHex("#212121")
end

local dragging, dragStart, startPos, lastMouse1 = nil, nil, nil, false

while true do
    wait(0.01)
    if isrbxactive() then
        local mouse1 = ismouse1pressed()
        local mPos   = Vector2.new(Mouse.X, Mouse.Y)

        if mouse1 and not lastMouse1 then
            if Button_AmmoHack.Visible
               and mPos.X >= Button_AmmoHack.Position.X
               and mPos.X <= Button_AmmoHack.Position.X + Button_AmmoHack.Size.X
               and mPos.Y >= Button_AmmoHack.Position.Y
               and mPos.Y <= Button_AmmoHack.Position.Y + Button_AmmoHack.Size.Y then
                AmmoHack()
                setButtonActive(Button_AmmoHack, AmmoHackEnabled)
            end
            if Button_StaminaHack.Visible
               and mPos.X >= Button_StaminaHack.Position.X
               and mPos.X <= Button_StaminaHack.Position.X + Button_StaminaHack.Size.X
               and mPos.Y >= Button_StaminaHack.Position.Y
               and mPos.Y <= Button_StaminaHack.Position.Y + Button_StaminaHack.Size.Y then
                StaminaHack()
                setButtonActive(Button_StaminaHack, StaminaHackEnabled)
            end
            if GuardESP_SW:HitTest(mPos) then
                GuardESP_SW:Toggle(); espEnabled.Guard = GuardESP_SW.isChecked
            end
            if CivilianESP_SW:HitTest(mPos) then
                CivilianESP_SW:Toggle(); espEnabled.Civilian = CivilianESP_SW.isChecked
            end
            if CameraESP_SW:HitTest(mPos) then
                CameraESP_SW:Toggle(); espEnabled.Camera = CameraESP_SW.isChecked
            end
            if LootableESP_SW:HitTest(mPos) then
                LootableESP_SW:Toggle(); espEnabled.Lootable = LootableESP_SW.isChecked
            end
            if Container.Visible
               and mPos.X >= Container.Position.X
               and mPos.X <= Container.Position.X + Container.Size.X
               and mPos.Y >= Container.Position.Y
               and mPos.Y <= Container.Position.Y + Container.Size.Y then
                dragging=Container; dragStart=mPos; startPos=Container.Position
            end
        end

        if not mouse1 and lastMouse1 then dragging=nil end

        if dragging and mouse1 then
            local delta  = mPos - dragStart
            local newPos = startPos + delta
            dragging.Position = newPos

            Container_Border.Position          = newPos
            bugwaretext.Position               = newPos + Vector2.new(75, 10)
            Button_AmmoHack.Position           = newPos + Vector2.new(14, 50)
            Button_AmmoHack_Border.Position    = Button_AmmoHack.Position
            Button_AmmoHack_Text.Position      = Button_AmmoHack.Position + Vector2.new(50, 15)
            Button_StaminaHack.Position        = newPos + Vector2.new(236, 50)
            Button_StaminaHack_Border.Position = Button_StaminaHack.Position
            Button_StaminaHack_Text.Position   = Button_StaminaHack.Position + Vector2.new(50, 15)
            GuardESP_SW:SetPos(newPos    + Vector2.new(14, 94))
            CivilianESP_SW:SetPos(newPos + Vector2.new(14, 121))
            CameraESP_SW:SetPos(newPos   + Vector2.new(14, 148))
            LootableESP_SW:SetPos(newPos + Vector2.new(14, 175))
        end

        lastMouse1 = mouse1
    end
end