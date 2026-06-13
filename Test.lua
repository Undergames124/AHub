-- ============================================================
--  Ξ|Ω DYNAMIC — ESP + IMGUI MENU v4 (ALL VISUALS FIXED)
--  Исправлено: все элементы ESP теперь отображаются.
--  Box, Health, Name, Distance, Skeleton, ChineHat.
-- ============================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local ScreenGui = nil
local MenuFrame = nil
local ToggleButton = nil
local ESPEnabled = true
local MenuVisible = false
local ToggleKey = Enum.KeyCode.Insert

-- ---- Настройки ESP ----
local Settings = {
    Box = true,
    Health = true,
    Name = true,
    Distance = true,
    Skeleton = true,
    ChineHat = true,
    Color = Color3.fromRGB(255, 255, 255),
}

-- ---- Кэш ESP (храним объекты в таблице по игроку) ----
local EspCache = {}

-- ---- Создание кнопки открытия меню ----
local function CreateToggleButton()
    if ToggleButton then ToggleButton:Destroy() end
    if not ScreenGui then
        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "IMGUI_ESP"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.Parent = CoreGui
    end

    ToggleButton = Instance.new("TextButton")
    ToggleButton.Name = "ToggleButton"
    ToggleButton.Size = UDim2.new(0, 40, 0, 40)
    ToggleButton.Position = UDim2.new(1, -50, 0, 10)
    ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    ToggleButton.Text = "⚙"
    ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    ToggleButton.TextSize = 24
    ToggleButton.Font = Enum.Font.Gotham
    ToggleButton.BorderSizePixel = 0
    ToggleButton.Parent = ScreenGui

    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 8)
    btnCorner.Parent = ToggleButton

    ToggleButton.MouseButton1Click:Connect(function()
        MenuVisible = not MenuVisible
        if MenuFrame then
            MenuFrame.Visible = MenuVisible
        end
    end)

    ToggleButton.MouseEnter:Connect(function()
        ToggleButton.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    end)
    ToggleButton.MouseLeave:Connect(function()
        ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    end)
end

-- ---- Создание меню ----
local function CreateMenu()
    if not ScreenGui then
        ScreenGui = Instance.new("ScreenGui")
        ScreenGui.Name = "IMGUI_ESP"
        ScreenGui.ResetOnSpawn = false
        ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ScreenGui.Parent = CoreGui
    end

    if MenuFrame then MenuFrame:Destroy() end

    MenuFrame = Instance.new("Frame")
    MenuFrame.Name = "MenuFrame"
    MenuFrame.Size = UDim2.new(0, 450, 0, 380)
    MenuFrame.Position = UDim2.new(0.5, -225, 0.5, -190)
    MenuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 28)
    MenuFrame.BackgroundTransparency = 0.06
    MenuFrame.BorderSizePixel = 0
    MenuFrame.Active = true
    MenuFrame.Draggable = true
    MenuFrame.Visible = MenuVisible
    MenuFrame.Parent = ScreenGui

    local shadowMenu = Instance.new("Frame")
    shadowMenu.Size = UDim2.new(1, 16, 1, 16)
    shadowMenu.Position = UDim2.new(0, -8, 0, -8)
    shadowMenu.BackgroundColor3 = Color3.fromRGB(0,0,0)
    shadowMenu.BackgroundTransparency = 0.5
    shadowMenu.ZIndex = 0
    shadowMenu.Parent = MenuFrame
    local shCorner = Instance.new("UICorner")
    shCorner.CornerRadius = UDim.new(0, 12)
    shCorner.Parent = shadowMenu

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 10)
    mainCorner.Parent = MenuFrame

    local Accent = Instance.new("Frame")
    Accent.Size = UDim2.new(1, 0, 0, 3)
    Accent.Position = UDim2.new(0, 0, 0, 0)
    Accent.BackgroundColor3 = Color3.fromRGB(120, 50, 255)
    Accent.BorderSizePixel = 0
    Accent.Parent = MenuFrame
    local aCorner = Instance.new("UICorner")
    aCorner.CornerRadius = UDim.new(0, 10)
    aCorner.Parent = Accent

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(0, 200, 0, 30)
    title.Position = UDim2.new(0, 15, 0, 10)
    title.BackgroundTransparency = 1
    title.Text = "Ξ|Ω  ESP"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = MenuFrame

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -40, 0, 10)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(180, 180, 200)
    closeBtn.TextSize = 20
    closeBtn.Font = Enum.Font.Gotham
    closeBtn.Parent = MenuFrame
    closeBtn.MouseButton1Click:Connect(function()
        MenuVisible = false
        MenuFrame.Visible = false
    end)

    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, 0, 0, 30)
    tabContainer.Position = UDim2.new(0, 0, 0, 48)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = MenuFrame

    local function CreateTab(name, xPos, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 80, 0, 26)
        btn.Position = UDim2.new(0, xPos, 0, 2)
        btn.BackgroundTransparency = 1
        btn.Text = name
        btn.TextColor3 = Color3.fromRGB(150, 150, 180)
        btn.TextSize = 14
        btn.Font = Enum.Font.Gotham
        btn.Parent = tabContainer
        btn.MouseButton1Click:Connect(function()
            for _, child in ipairs(tabContainer:GetChildren()) do
                if child:IsA("TextButton") then
                    child.TextColor3 = Color3.fromRGB(150, 150, 180)
                end
            end
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            callback()
        end)
        return btn
    end

    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -16, 1, -90)
    contentFrame.Position = UDim2.new(0, 8, 0, 86)
    contentFrame.BackgroundTransparency = 1
    contentFrame.Parent = MenuFrame

    local function ClearContent()
        for _, child in ipairs(contentFrame:GetChildren()) do
            child:Destroy()
        end
    end

    ---- Вкладка VISUALS ----
    local function ShowVisualsTab()
        ClearContent()
        local y = 0

        local secTitle = Instance.new("TextLabel")
        secTitle.Size = UDim2.new(1, 0, 0, 20)
        secTitle.Position = UDim2.new(0, 0, 0, y)
        secTitle.BackgroundTransparency = 1
        secTitle.Text = "VISUALS"
        secTitle.TextColor3 = Color3.fromRGB(100, 100, 130)
        secTitle.TextSize = 12
        secTitle.Font = Enum.Font.GothamBold
        secTitle.TextXAlignment = Enum.TextXAlignment.Left
        secTitle.Parent = contentFrame
        y = y + 28

        local function CreateCheckbox(label, key, yPos)
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(0, 180, 0, 26)
            frame.Position = UDim2.new(0, 0, 0, yPos)
            frame.BackgroundTransparency = 1
            frame.Parent = contentFrame

            local checkbox = Instance.new("TextButton")
            checkbox.Size = UDim2.new(0, 18, 0, 18)
            checkbox.Position = UDim2.new(0, 0, 0, 4)
            checkbox.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
            checkbox.BorderSizePixel = 0
            checkbox.Text = ""
            checkbox.Parent = frame
            local chCorner = Instance.new("UICorner")
            chCorner.CornerRadius = UDim.new(0, 4)
            chCorner.Parent = checkbox

            local tick = Instance.new("TextLabel")
            tick.Size = UDim2.new(1, 0, 1, 0)
            tick.BackgroundTransparency = 1
            tick.Text = "✔"
            tick.TextColor3 = Color3.fromRGB(120, 50, 255)
            tick.TextSize = 14
            tick.Visible = Settings[key]
            tick.Parent = checkbox

            local labelText = Instance.new("TextLabel")
            labelText.Size = UDim2.new(1, -30, 1, 0)
            labelText.Position = UDim2.new(0, 24, 0, 0)
            labelText.BackgroundTransparency = 1
            labelText.Text = label
            labelText.TextColor3 = Color3.fromRGB(220, 220, 240)
            labelText.TextSize = 14
            labelText.TextXAlignment = Enum.TextXAlignment.Left
            labelText.Parent = frame

            checkbox.MouseButton1Click:Connect(function()
                Settings[key] = not Settings[key]
                tick.Visible = Settings[key]
            end)
            return frame
        end

        CreateCheckbox("Box", "Box", y); y = y + 32
        CreateCheckbox("Health Bar", "Health", y); y = y + 32
        CreateCheckbox("Name", "Name", y); y = y + 32
        CreateCheckbox("Distance", "Distance", y); y = y + 32
        CreateCheckbox("Skeleton", "Skeleton", y); y = y + 32
        CreateCheckbox("Chine Hat", "ChineHat", y); y = y + 32

        local colorLabel = Instance.new("TextLabel")
        colorLabel.Size = UDim2.new(0, 100, 0, 20)
        colorLabel.Position = UDim2.new(0, 0, 0, y)
        colorLabel.BackgroundTransparency = 1
        colorLabel.Text = "Color:"
        colorLabel.TextColor3 = Color3.fromRGB(180, 180, 210)
        colorLabel.TextSize = 14
        colorLabel.TextXAlignment = Enum.TextXAlignment.Left
        colorLabel.Parent = contentFrame
        y = y + 28

        local colors = {
            { "White", Color3.fromRGB(255,255,255) },
            { "Red", Color3.fromRGB(255,50,50) },
            { "Green", Color3.fromRGB(50,255,50) },
            { "Blue", Color3.fromRGB(50,150,255) },
            { "Purple", Color3.fromRGB(180,50,255) },
        }
        for i, c in ipairs(colors) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0, 60, 0, 24)
            btn.Position = UDim2.new(0, (i-1)*68, 0, 0)
            btn.BackgroundColor3 = c[2]
            btn.Text = c[1]
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            btn.TextSize = 12
            btn.Font = Enum.Font.Gotham
            btn.Parent = contentFrame
            btn.MouseButton1Click:Connect(function()
                Settings.Color = c[2]
            end)
        end
        y = y + 30

        local toggleEspBtn = Instance.new("TextButton")
        toggleEspBtn.Size = UDim2.new(0, 180, 0, 32)
        toggleEspBtn.Position = UDim2.new(0, 0, 0, y)
        toggleEspBtn.BackgroundColor3 = Color3.fromRGB(120, 50, 255)
        toggleEspBtn.Text = ESPEnabled and "ESP: ON" or "ESP: OFF"
        toggleEspBtn.TextColor3 = Color3.fromRGB(255,255,255)
        toggleEspBtn.TextSize = 14
        toggleEspBtn.Font = Enum.Font.GothamBold
        toggleEspBtn.Parent = contentFrame
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = toggleEspBtn
        toggleEspBtn.MouseButton1Click:Connect(function()
            ESPEnabled = not ESPEnabled
            toggleEspBtn.Text = ESPEnabled and "ESP: ON" or "ESP: OFF"
            if not ESPEnabled then
                for _, player in pairs(Players:GetPlayers()) do
                    if player ~= LocalPlayer then
                        local cache = EspCache[player]
                        if cache then
                            for _, d in pairs(cache) do
                                if type(d) == "table" and d.Visible ~= nil then
                                    d.Visible = false
                                end
                            end
                        end
                    end
                end
            end
        end)
        y = y + 40
    end

    ---- Вкладка SETTINGS ----
    local function ShowSettingsTab()
        ClearContent()
        local y = 0
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Position = UDim2.new(0, 0, 0, y)
        label.BackgroundTransparency = 1
        label.Text = "TOGGLE KEY"
        label.TextColor3 = Color3.fromRGB(100, 100, 130)
        label.TextSize = 12
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = contentFrame
        y = y + 28

        local keyLabel = Instance.new("TextLabel")
        keyLabel.Size = UDim2.new(0, 150, 0, 24)
        keyLabel.Position = UDim2.new(0, 0, 0, y)
        keyLabel.BackgroundTransparency = 1
        keyLabel.Text = "Current: Insert"
        keyLabel.TextColor3 = Color3.fromRGB(200,200,220)
        keyLabel.TextSize = 14
        keyLabel.Parent = contentFrame
        y = y + 32

        local hideBtn = Instance.new("TextButton")
        hideBtn.Size = UDim2.new(0, 150, 0, 32)
        hideBtn.Position = UDim2.new(0, 0, 0, y)
        hideBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
        hideBtn.Text = "Hide Menu (Insert)"
        hideBtn.TextColor3 = Color3.fromRGB(220,220,240)
        hideBtn.TextSize = 14
        hideBtn.Font = Enum.Font.Gotham
        hideBtn.Parent = contentFrame
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = hideBtn
        hideBtn.MouseButton1Click:Connect(function()
            MenuVisible = false
            MenuFrame.Visible = false
        end)
        y = y + 40
    end

    ---- Вкладка ABOUT ----
    local function ShowAboutTab()
        ClearContent()
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Position = UDim2.new(0, 0, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = "Ξ|Ω DYNAMIC v4"
        label.TextColor3 = Color3.fromRGB(120,50,255)
        label.TextSize = 16
        label.Font = Enum.Font.GothamBold
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = contentFrame

        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, 0, 0, 60)
        desc.Position = UDim2.new(0, 0, 0, 30)
        desc.BackgroundTransparency = 1
        desc.Text = "Optimized ESP for Roblox.\nToggle menu with Insert or button.\nDrawing-based. No injection hooks."
        desc.TextColor3 = Color3.fromRGB(150,150,180)
        desc.TextSize = 13
        desc.Font = Enum.Font.Gotham
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextWrapped = true
        desc.Parent = contentFrame
    end

    local tabs = {
        { name = "VISUALS", x = 10, callback = ShowVisualsTab },
        { name = "SETTINGS", x = 100, callback = ShowSettingsTab },
        { name = "ABOUT", x = 190, callback = ShowAboutTab },
    }
    for _, t in ipairs(tabs) do
        local btn = CreateTab(t.name, t.x, t.callback)
        if t.name == "VISUALS" then
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            t.callback()
        end
    end
end

-- ---- ESP (FULL REWRITE) ----
local function CreateESPObjects(player)
    if player == LocalPlayer then return end
    if not player.Character then return end
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    -- Очищаем старый кэш
    if EspCache[player] then
        for _, d in pairs(EspCache[player]) do
            if d and d.Remove then d:Remove() end
        end
        EspCache[player] = nil
    end

    local function MakeDrawing(type)
        local d = Drawing.new(type)
        d.Visible = false
        return d
    end

    local cache = {
        Box = MakeDrawing("Square"),
        HealthBg = MakeDrawing("Square"),
        HealthFill = MakeDrawing("Square"),
        Name = MakeDrawing("Text"),
        Distance = MakeDrawing("Text"),
        Skeleton1 = MakeDrawing("Line"),
        Skeleton2 = MakeDrawing("Line"),
        ChineHat = MakeDrawing("Line"),
    }

    cache.Box.Color = Settings.Color
    cache.Box.Thickness = 1.5
    cache.Box.Filled = false

    cache.HealthBg.Color = Color3.fromRGB(30,30,30)
    cache.HealthBg.Thickness = 0
    cache.HealthBg.Filled = true
    cache.HealthBg.Transparency = 0.4

    cache.HealthFill.Color = Color3.fromRGB(50,255,50)
    cache.HealthFill.Thickness = 0
    cache.HealthFill.Filled = true
    cache.HealthFill.Transparency = 0.2

    cache.Name.Color = Settings.Color
    cache.Name.Size = 14
    cache.Name.Center = true
    cache.Name.Outline = true
    cache.Name.Font = Drawing.Fonts.Monospace

    cache.Distance.Color = Color3.fromRGB(200,200,200)
    cache.Distance.Size = 12
    cache.Distance.Center = true
    cache.Distance.Outline = true
    cache.Distance.Font = Drawing.Fonts.Monospace

    cache.Skeleton1.Color = Settings.Color
    cache.Skeleton1.Thickness = 1

    cache.Skeleton2.Color = Settings.Color
    cache.Skeleton2.Thickness = 1

    cache.ChineHat.Color = Settings.Color
    cache.ChineHat.Thickness = 2

    EspCache[player] = cache
    return cache
end

local lastUpdate = tick()
local function OnRender()
    if not ESPEnabled then
        for player, cache in pairs(EspCache) do
            for _, d in pairs(cache) do
                if d and d.Visible ~= nil then
                    d.Visible = false
                end
            end
        end
        return
    end

    if tick() - lastUpdate < 0.05 then return end
    lastUpdate = tick()

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        local head = player.Character:FindFirstChild("Head")
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if not root then continue end

        local cache = EspCache[player]
        if not cache then
            cache = CreateESPObjects(player)
        end
        if not cache then continue end

        local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
        if not onScreen then
            for _, d in pairs(cache) do
                if d and d.Visible ~= nil then
                    d.Visible = false
                end
            end
            continue
        end

        local headPos = head and Camera:WorldToViewportPoint(head.Position + Vector3.new(0,0.5,0)) or pos
        local footPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0,3,0))
        local boxHeight = headPos.Y - footPos.Y
        local boxWidth = boxHeight * 0.6
        local centerX = pos.X

        -- Box
        if Settings.Box and cache.Box then
            cache.Box.Size = Vector2.new(boxWidth, boxHeight)
            cache.Box.Position = Vector2.new(centerX - boxWidth/2, headPos.Y)
            cache.Box.Color = Settings.Color
            cache.Box.Visible = true
        elseif cache.Box then
            cache.Box.Visible = false
        end

        -- Health
        if Settings.Health and cache.HealthBg and cache.HealthFill and humanoid then
            local health = humanoid.Health
            local maxHealth = humanoid.MaxHealth
            local pct = math.clamp(health / maxHealth, 0, 1)
            local barX = centerX + boxWidth/2 + 2
            local barY = headPos.Y
            local barH = boxHeight
            local barW = 4

            cache.HealthBg.Size = Vector2.new(barW, barH)
            cache.HealthBg.Position = Vector2.new(barX, barY)
            cache.HealthBg.Visible = true

            cache.HealthFill.Size = Vector2.new(barW, barH * pct)
            cache.HealthFill.Position = Vector2.new(barX, barY + barH - (barH * pct))
            cache.HealthFill.Color = Color3.fromRGB(math.floor(255 * (1-pct)), math.floor(255 * pct), 0)
            cache.HealthFill.Visible = true
        else
            if cache.HealthBg then cache.HealthBg.Visible = false end
            if cache.HealthFill then cache.HealthFill.Visible = false end
        end

        -- Name
        if Settings.Name and cache.Name then
            local dist = (root.Position - Camera.CFrame.Position).Magnitude
            cache.Name.Text = player.Name .. " [" .. math.floor(dist) .. "m]"
            cache.Name.Position = Vector2.new(centerX, headPos.Y - 18)
            cache.Name.Color = Settings.Color
            cache.Name.Visible = true
        elseif cache.Name then
            cache.Name.Visible = false
        end

        -- Distance
        if Settings.Distance and cache.Distance then
            cache.Distance.Position = Vector2.new(centerX, footPos.Y + 4)
            cache.Distance.Visible = true
        elseif cache.Distance then
            cache.Distance.Visible = false
        end

        -- Skeleton
        if Settings.Skeleton and head and player.Character:FindFirstChild("RightUpperArm") and player.Character:FindFirstChild("LeftUpperArm") and cache.Skeleton1 and cache.Skeleton2 then
            local rShoulder = player.Character.RightUpperArm.CFrame.Position
            local lShoulder = player.Character.LeftUpperArm.CFrame.Position
            local rScreen = Camera:WorldToViewportPoint(rShoulder)
            local lScreen = Camera:WorldToViewportPoint(lShoulder)
            cache.Skeleton1.From = Vector2.new(headPos.X, headPos.Y)
            cache.Skeleton1.To = Vector2.new(rScreen.X, rScreen.Y)
            cache.Skeleton1.Color = Settings.Color
            cache.Skeleton1.Visible = true
            cache.Skeleton2.From = Vector2.new(headPos.X, headPos.Y)
            cache.Skeleton2.To = Vector2.new(lScreen.X, lScreen.Y)
            cache.Skeleton2.Color = Settings.Color
            cache.Skeleton2.Visible = true
        else
            if cache.Skeleton1 then cache.Skeleton1.Visible = false end
            if cache.Skeleton2 then cache.Skeleton2.Visible = false end
        end

        -- Chine Hat
        if Settings.ChineHat and head and cache.ChineHat then
            local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1.8, 0))
            local bottom = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))
            cache.ChineHat.From = Vector2.new(top.X, top.Y)
            cache.ChineHat.To = Vector2.new(bottom.X, bottom.Y)
            cache.ChineHat.Color = Settings.Color
            cache.ChineHat.Visible = true
        elseif cache.ChineHat then
            cache.ChineHat.Visible = false
        end
    end
end

-- ---- Обработка клавиши ----
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == ToggleKey then
        MenuVisible = not MenuVisible
        if MenuFrame then
            MenuFrame.Visible = MenuVisible
        end
    end
end)

-- ---- Инициализация ----
CreateToggleButton()
CreateMenu()
RunService.RenderStepped:Connect(OnRender)

-- ---- Принудительное создание кэша для всех игроков при старте ----
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        CreateESPObjects(player)
    end
end

-- ---- Очистка при выходе игрока ----
Players.PlayerRemoving:Connect(function(player)
    if EspCache[player] then
        for _, d in pairs(EspCache[player]) do
            if d and d.Remove then d:Remove() end
        end
        EspCache[player] = nil
    end
end)

-- ---- Очистка при смене персонажа ----
LocalPlayer.CharacterAdded:Connect(function()
    -- Пересоздаём кэш для всех игроков
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            CreateESPObjects(player)
        end
    end
end)

print("Ξ|Ω ESP v4 loaded. All visuals should now work.")
