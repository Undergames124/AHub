--[[
    ESP Premium для Roblox (LocalScript)
    Особенности:
    - Полностью настраиваемый ESP (бокс, здоровье, имя, дистанция, линия, голова)
    - Оптимизация: кэширование, переиспользование Drawing объектов, дистанция отсечки
    - Плавный рендер через RenderStepped
    - Мобильная кнопка для открытия меню (перетаскиваемая)
    - Красивый визуал: градиентные бары здоровья, аккуратные углы, тени
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ========== НАСТРОЙКИ ПО УМОЛЧАНИЮ ==========
local Settings = {
    ESPEnabled = true,
    Box = { Enabled = true, Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0, CornerRadius = 4 },
    HealthBar = { Enabled = true, Width = 40, Height = 4, Position = "bottom", Gradient = true },
    Name = { Enabled = true, Color = Color3.fromRGB(255, 255, 255), Size = 14, Outline = true },
    Distance = { Enabled = true, Color = Color3.fromRGB(200, 200, 200), Size = 12 },
    Line = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Thickness = 1 },
    HeadDot = { Enabled = false, Color = Color3.fromRGB(255, 0, 0), Radius = 3 },
    MaxDistance = 300,
    ShowTeam = false,  -- true = показывать только врагов, false = всех
}

-- ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========
local function GetHealthPercent(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health then
        return math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    end
    return 0
end

local function GetTeamColor(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid and humanoid.RootPart then
        local team = humanoid.RootPart:FindFirstChild("Team")
        if team and team.Value == LocalPlayer.TeamColor then
            return Color3.fromRGB(0, 255, 0) -- зеленый для союзников
        end
    end
    return Color3.fromRGB(255, 0, 0) -- красный для врагов
end

-- ========== ХРАНИЛИЩЕ ОБЪЕКТОВ ESP ==========
local ESPObjects = {} -- [Player] = { box, healthBar, nameText, distanceText, line, headDot }

-- ========== ИНИЦИАЛИЗАЦИЯ DRAWING ОБЪЕКТОВ ДЛЯ ИГРОКА ==========
local function CreateESPForPlayer(player)
    if player == LocalPlayer then return end
    if ESPObjects[player] then return end
    
    local character = player.Character
    if not character or not character:FindFirstChild("Humanoid") or not character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local objects = {}
    
    -- Бокс (квадрат)
    if Settings.Box.Enabled then
        local box = Drawing.new("Square")
        box.Thickness = Settings.Box.Thickness
        box.Color = Settings.Box.Color
        box.Transparency = Settings.Box.Transparency
        box.Filled = false
        objects.Box = box
    end
    
    -- Полоса здоровья
    if Settings.HealthBar.Enabled then
        local bar = Drawing.new("Square")
        bar.Thickness = 1
        bar.Color = Color3.fromRGB(0, 255, 0)
        bar.Filled = true
        objects.HealthBar = bar
    end
    
    -- Текст имени
    if Settings.Name.Enabled then
        local nameText = Drawing.new("Text")
        nameText.Color = Settings.Name.Color
        nameText.Size = Settings.Name.Size
        nameText.Center = true
        nameText.Outline = Settings.Name.Outline
        nameText.Text = player.Name
        objects.NameText = nameText
    end
    
    -- Текст дистанции
    if Settings.Distance.Enabled then
        local distText = Drawing.new("Text")
        distText.Color = Settings.Distance.Color
        distText.Size = Settings.Distance.Size
        distText.Center = true
        distText.Outline = true
        objects.DistanceText = distText
    end
    
    -- Линия до игрока
    if Settings.Line.Enabled then
        local line = Drawing.new("Line")
        line.Thickness = Settings.Line.Thickness
        line.Color = Settings.Line.Color
        objects.Line = line
    end
    
    -- Точка на голове
    if Settings.HeadDot.Enabled then
        local dot = Drawing.new("Circle")
        dot.Thickness = 1
        dot.Color = Settings.HeadDot.Color
        dot.Radius = Settings.HeadDot.Radius
        dot.Filled = true
        objects.HeadDot = dot
    end
    
    ESPObjects[player] = objects
end

-- ========== УДАЛЕНИЕ ESP ДЛЯ ИГРОКА ==========
local function RemoveESPForPlayer(player)
    local objects = ESPObjects[player]
    if objects then
        for _, obj in pairs(objects) do
            obj:Remove()
        end
        ESPObjects[player] = nil
    end
end

-- ========== ОБНОВЛЕНИЕ ПОЗИЦИЙ И РЕНДЕР ==========
local function UpdateESP()
    if not Settings.ESPEnabled then
        -- Скрыть все объекты
        for player, objects in pairs(ESPObjects) do
            for _, obj in pairs(objects) do
                obj.Visible = false
            end
        end
        return
    end
    
    local cameraPos = Camera.CFrame.Position
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        -- Условие отображения по команде
        if Settings.ShowTeam then
            if player.TeamColor == LocalPlayer.TeamColor then continue end
        end
        
        local character = player.Character
        if not character then
            RemoveESPForPlayer(player)
            continue
        end
        
        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart or humanoid.Health <= 0 then
            RemoveESPForPlayer(player)
            continue
        end
        
        -- Дистанция отсечки
        local distance = (rootPart.Position - cameraPos).Magnitude
        if distance > Settings.MaxDistance then
            RemoveESPForPlayer(player)
            continue
        end
        
        -- Создаём объекты, если ещё нет
        if not ESPObjects[player] then
            CreateESPForPlayer(player)
        end
        
        local objects = ESPObjects[player]
        if not objects then continue end
        
        -- Находим позиции на экране для головы и ног
        local head = character:FindFirstChild("Head")
        local root = rootPart
        if not head then
            head = root
        end
        
        local headPos, onScreenHead = Camera:WorldToViewportPoint(head.Position)
        local feetPos, onScreenFeet = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
        
        if not onScreenHead and not onScreenFeet then
            for _, obj in pairs(objects) do
                obj.Visible = false
            end
            continue
        end
        
        -- Вычисляем размер бокса
        local height = math.abs(headPos.Y - feetPos.Y)
        local width = height * 0.6
        local boxX = headPos.X - width/2
        local boxY = headPos.Y - height * 0.15
        local boxHeight = height + height * 0.15
        local boxWidth = width
        
        -- БОКС
        if objects.Box then
            objects.Box.Visible = true
            objects.Box.Size = Vector2.new(boxWidth, boxHeight)
            objects.Box.Position = Vector2.new(boxX, boxY)
            objects.Box.Color = Settings.Box.Color
            objects.Box.Thickness = Settings.Box.Thickness
            objects.Box.Transparency = Settings.Box.Transparency
        end
        
        -- ПОЛОСА ЗДОРОВЬЯ
        if objects.HealthBar then
            local healthPercent = GetHealthPercent(character)
            local barY = boxY + boxHeight + 2
            local barX = boxX
            local barWidth = boxWidth * healthPercent
            local barHeight = Settings.HealthBar.Height
            
            objects.HealthBar.Visible = true
            objects.HealthBar.Size = Vector2.new(barWidth, barHeight)
            objects.HealthBar.Position = Vector2.new(barX, barY)
            
            -- Градиент цвета (красный -> зеленый)
            local r = 1 - healthPercent
            local g = healthPercent
            local b = 0
            objects.HealthBar.Color = Color3.new(r, g, b)
        end
        
        -- ТЕКСТ ИМЕНИ
        if objects.NameText then
            objects.NameText.Visible = true
            objects.NameText.Text = player.Name
            objects.NameText.Position = Vector2.new(headPos.X, boxY - 15)
            objects.NameText.Color = Settings.Name.Color
            objects.NameText.Size = Settings.Name.Size
        end
        
        -- ТЕКСТ ДИСТАНЦИИ
        if objects.DistanceText then
            objects.DistanceText.Visible = true
            objects.DistanceText.Text = math.floor(distance) .. "m"
            objects.DistanceText.Position = Vector2.new(headPos.X, boxY + boxHeight + 2 + Settings.HealthBar.Height + 5)
            objects.DistanceText.Color = Settings.Distance.Color
        end
        
        -- ЛИНИЯ ДО ИГРОКА
        if objects.Line then
            local centerScreen = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
            objects.Line.Visible = true
            objects.Line.From = centerScreen
            objects.Line.To = Vector2.new(headPos.X, headPos.Y)
            objects.Line.Color = Settings.Line.Color
            objects.Line.Thickness = Settings.Line.Thickness
        end
        
        -- ТОЧКА НА ГОЛОВЕ
        if objects.HeadDot then
            objects.HeadDot.Visible = true
            objects.HeadDot.Position = Vector2.new(headPos.X, headPos.Y)
            objects.HeadDot.Color = Settings.HeadDot.Color
            objects.HeadDot.Radius = Settings.HeadDot.Radius
        end
    end
    
    -- Удаляем ESP для игроков, которые вышли или далеко
    for player, _ in pairs(ESPObjects) do
        if not player.Parent or not player.Character or (player.Character and player.Character:FindFirstChild("HumanoidRootPart") and (player.Character.HumanoidRootPart.Position - cameraPos).Magnitude > Settings.MaxDistance) then
            RemoveESPForPlayer(player)
        end
    end
end

-- ========== МЕНЮ НАСТРОЕК (UI) ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PremiumESP_Menu"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- КНОПКА ОТКРЫТИЯ (для телефона и ПК)
local toggleBtn = Instance.new("ImageButton")
toggleBtn.Size = UDim2.new(0, 50, 0, 50)
toggleBtn.Position = UDim2.new(0, 10, 0, 100)
toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
toggleBtn.BackgroundTransparency = 0.2
toggleBtn.BorderSizePixel = 0
toggleBtn.Image = "rbxassetid://6031093677" -- иконка шестеренки
toggleBtn.Parent = ScreenGui

-- Сделать кнопку перетаскиваемой (для мобилы)
local dragging = false
local dragStartPos
local dragStartMouse
toggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStartPos = toggleBtn.Position
        dragStartMouse = input.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStartMouse
        toggleBtn.Position = UDim2.new(dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- ГЛАВНОЕ МЕНЮ (панель)
local menuFrame = Instance.new("Frame")
menuFrame.Size = UDim2.new(0, 350, 0, 500)
menuFrame.Position = UDim2.new(0.5, -175, 0.5, -250)
menuFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
menuFrame.BackgroundTransparency = 0.1
menuFrame.BorderSizePixel = 0
menuFrame.Visible = false
menuFrame.Parent = ScreenGui

-- Скругление углов
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = menuFrame

-- Заголовок
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Text = "PREMIUM ESP"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = false
title.TextSize = 24
title.Font = Enum.Font.GothamBold
title.Parent = menuFrame

-- Список настроек (ScrollingFrame)
local scrolling = Instance.new("ScrollingFrame")
scrolling.Size = UDim2.new(1, -20, 1, -60)
scrolling.Position = UDim2.new(0, 10, 0, 50)
scrolling.BackgroundTransparency = 1
scrolling.CanvasSize = UDim2.new(0, 0, 0, 600)
scrolling.ScrollBarThickness = 6
scrolling.Parent = menuFrame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 12)
listLayout.Parent = scrolling

-- Функция создания чекбокса
local function MakeCheckbox(parent, text, settingPath, defaultValue)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -50, 1, 0)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 16
    label.Parent = frame
    
    local check = Instance.new("ImageButton")
    check.Size = UDim2.new(0, 25, 0, 25)
    check.Position = UDim2.new(1, -30, 0.5, -12.5)
    check.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    check.BorderSizePixel = 0
    check.Image = "rbxassetid://0" -- пусто
    check.Parent = frame
    
    local function updateUI()
        local value = Settings
        for part in string.gmatch(settingPath, "[^.]+") do
            value = value[part]
        end
        if value then
            check.BackgroundColor3 = Color3.fromRGB(80, 200, 80)
            check.Image = "rbxassetid://6031155639" -- галочка
        else
            check.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
            check.Image = "rbxassetid://0"
        end
    end
    
    check.MouseButton1Click:Connect(function()
        local target = Settings
        local parts = {}
        for part in string.gmatch(settingPath, "[^.]+") do
            table.insert(parts, part)
        end
        for i = 1, #parts - 1 do
            target = target[parts[i]]
        end
        target[parts[#parts]] = not target[parts[#parts]]
        updateUI()
    end)
    
    updateUI()
    return frame
end

-- Функция создания ползунка (для дистанции)
local function MakeSlider(parent, text, settingPath, minVal, maxVal, defaultValue)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 60)
    frame.BackgroundTransparency = 1
    frame.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = text .. ": " .. tostring(defaultValue)
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.Parent = frame
    
    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(1, -20, 0, 10)
    slider.Position = UDim2.new(0, 10, 0, 25)
    slider.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    slider.BorderSizePixel = 0
    slider.Parent = frame
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultValue-minVal)/(maxVal-minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    fill.BorderSizePixel = 0
    fill.Parent = slider
    
    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 15, 0, 15)
    knob.Position = UDim2.new((defaultValue-minVal)/(maxVal-minVal), -7.5, 0.5, -7.5)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = slider
    
    local function updateSlider(value)
        local norm = (value - minVal) / (maxVal - minVal)
        fill.Size = UDim2.new(norm, 0, 1, 0)
        knob.Position = UDim2.new(norm, -7.5, 0.5, -7.5)
        label.Text = text .. ": " .. math.floor(value)
        
        local target = Settings
        local parts = {}
        for part in string.gmatch(settingPath, "[^.]+") do
            table.insert(parts, part)
        end
        for i = 1, #parts - 1 do
            target = target[parts[i]]
        end
        target[parts[#parts]] = value
    end
    
    local dragging = false
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local mousePos = input.Position.X
            local sliderPos = slider.AbsolutePosition.X
            local width = slider.AbsoluteSize.X
            local newNorm = math.clamp((mousePos - sliderPos) / width, 0, 1)
            local newVal = minVal + newNorm * (maxVal - minVal)
            updateSlider(newVal)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    return frame
end

-- ПОСТРОЕНИЕ МЕНЮ
MakeCheckbox(scrolling, "ESP Enabled", "ESPEnabled", true)
MakeCheckbox(scrolling, "Box", "Box.Enabled", true)
MakeCheckbox(scrolling, "Health Bar", "HealthBar.Enabled", true)
MakeCheckbox(scrolling, "Player Name", "Name.Enabled", true)
MakeCheckbox(scrolling, "Distance", "Distance.Enabled", true)
MakeCheckbox(scrolling, "Line to player", "Line.Enabled", false)
MakeCheckbox(scrolling, "Head dot", "HeadDot.Enabled", false)
MakeCheckbox(scrolling, "Show only enemies", "ShowTeam", false)
MakeSlider(scrolling, "Max distance", "MaxDistance", 50, 500, 300)

-- КНОПКА ЗАКРЫТИЯ МЕНЮ
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 80, 0, 30)
closeBtn.Position = UDim2.new(1, -90, 1, -40)
closeBtn.Text = "Close"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.BorderSizePixel = 0
closeBtn.Parent = menuFrame
closeBtn.MouseButton1Click:Connect(function()
    menuFrame.Visible = false
end)

-- ОТКРЫТИЕ/ЗАКРЫТИЕ МЕНЮ ПО КНОПКЕ
local menuOpen = false
toggleBtn.MouseButton1Click:Connect(function()
    menuOpen = not menuOpen
    menuFrame.Visible = menuOpen
end)

-- ========== ЗАПУСК ESP ==========
RunService.RenderStepped:Connect(function()
    UpdateESP()
end)

-- Обновление при изменении игроков
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(0.2)
        CreateESPForPlayer(player)
    end)
end)

Players.PlayerRemoving:Connect(RemoveESPForPlayer)

-- Для уже существующих
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            wait(0.2)
            CreateESPForPlayer(player)
        end)
        if player.Character then
            wait(0.2)
            CreateESPForPlayer(player)
        end
    end
end

print("Premium ESP загружен. Нажми на иконку шестеренки для настроек.")
