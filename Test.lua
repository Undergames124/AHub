-- Ξ|Ω ESP v6 — плоский скрипт, без оберток
-- Первая строка — комментарий, никаких вызовов функций

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    LocalPlayer = Players.LocalPlayer
end

-- === НАСТРОЙКИ (меняются через GUI) ===
local Settings = {
    Enabled = true,
    ShowPlayers = true,
    MaxDistance = 500,
    BoxType = "Outline",   -- "Outline", "Flat"
    BoxColor = Color3.fromRGB(0, 255, 255),
    BoxTransparency = 0.4,
    BoxThickness = 2,
    ShowName = true,
    NameColor = Color3.fromRGB(255, 255, 255),
    ShowDistance = true,
    DistanceColor = Color3.fromRGB(200, 200, 200),
    ShowHealthBar = true,
    ShowHealthText = true,
    HealthColorGood = Color3.fromRGB(0, 255, 0),
    HealthColorBad = Color3.fromRGB(255, 0, 0),
    ShowTracer = false,
    TracerColor = Color3.fromRGB(255, 0, 0),
    UpdateRate = "Auto",   -- "Auto", "Fast", "Economy"
}

-- === ВНУТРЕННИЕ ПЕРЕМЕННЫЕ ===
local gui = nil
local espObjects = {}  -- [player] = {box, name, dist, healthBar, healthText, tracer}
local lastUpdate = 0
local updateInterval = 1/30
local renderConnection = nil

-- === ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ===
local function worldToScreen(cam, pos)
    if not cam then return nil end
    local vec, onScreen = cam:WorldToViewportPoint(pos)
    if not onScreen then return nil end
    return Vector2.new(vec.X, vec.Y), vec.Z
end

local function getBoundingBox(cam, character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local size = hrp.Size
    local top = hrp.Position + Vector3.new(0, size.Y/2 + 1.5, 0)
    local bottom = hrp.Position - Vector3.new(0, size.Y/2 + 1.5, 0)
    local topPos = worldToScreen(cam, top)
    local bottomPos = worldToScreen(cam, bottom)
    if not topPos or not bottomPos then return nil end
    local height = math.abs(topPos.Y - bottomPos.Y)
    local width = height * 0.55
    return {
        X = topPos.X - width/2,
        Y = topPos.Y,
        Width = width,
        Height = height,
    }
end

-- === СОЗДАНИЕ GUI ДЛЯ КАЖДОГО ИГРОКА ===
local function setupPlayerUI(player)
    if espObjects[player] then return end
    local folder = Instance.new("Folder")
    folder.Name = player.Name
    folder.Parent = gui
    
    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Parent = folder
    
    local nameLabel = Instance.new("TextLabel")
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    nameLabel.Parent = folder
    
    local distLabel = Instance.new("TextLabel")
    distLabel.TextSize = 10
    distLabel.BackgroundTransparency = 1
    distLabel.TextStrokeTransparency = 0.3
    distLabel.TextXAlignment = Enum.TextXAlignment.Center
    distLabel.Parent = folder
    
    local healthBar = Instance.new("Frame")
    healthBar.BackgroundColor3 = Settings.HealthColorGood
    healthBar.Parent = folder
    
    local healthBg = Instance.new("Frame")
    healthBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    healthBg.Size = UDim2.new(1, 0, 1, 0)
    healthBg.Parent = healthBar
    
    local healthText = Instance.new("TextLabel")
    healthText.TextSize = 10
    healthText.BackgroundTransparency = 1
    healthText.TextXAlignment = Enum.TextXAlignment.Center
    healthText.Parent = folder
    
    local tracer = Instance.new("Frame")
    tracer.BackgroundColor3 = Settings.TracerColor
    tracer.BackgroundTransparency = 0.3
    tracer.BorderSizePixel = 0
    tracer.Parent = folder
    
    espObjects[player] = {
        folder = folder,
        box = box,
        name = nameLabel,
        dist = distLabel,
        healthBar = healthBar,
        healthText = healthText,
        tracer = tracer
    }
end

-- === ОСНОВНОЙ РЕНДЕР ===
local function renderESP()
    local cam = workspace.CurrentCamera
    if not cam or not Settings.Enabled then
        for _, data in pairs(espObjects) do
            if data.box then data.box.Visible = false end
            if data.name then data.name.Visible = false end
            if data.dist then data.dist.Visible = false end
            if data.healthBar then data.healthBar.Visible = false end
            if data.tracer then data.tracer.Visible = false end
        end
        return
    end
    
    -- Настройка частоты обновления
    local now = tick()
    if Settings.UpdateRate == "Fast" then
        updateInterval = 1/60
    elseif Settings.UpdateRate == "Economy" then
        updateInterval = 1/15
    else
        updateInterval = UserInputService.TouchEnabled and 1/20 or 1/30
    end
    if now - lastUpdate < updateInterval then return end
    lastUpdate = now
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not Settings.ShowPlayers then break end
        
        setupPlayerUI(player)
        local data = espObjects[player]
        if not data then continue end
        
        local char = player.Character
        if not char then
            data.box.Visible = false
            data.name.Visible = false
            data.dist.Visible = false
            data.healthBar.Visible = false
            data.tracer.Visible = false
            goto continue
        end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then
            data.box.Visible = false
            data.name.Visible = false
            data.dist.Visible = false
            data.healthBar.Visible = false
            data.tracer.Visible = false
            goto continue
        end
        
        local dist = (hrp.Position - cam.CFrame.Position).Magnitude
        if dist > Settings.MaxDistance then
            data.box.Visible = false
            data.name.Visible = false
            data.dist.Visible = false
            data.healthBar.Visible = false
            data.tracer.Visible = false
            goto continue
        end
        
        local box = getBoundingBox(cam, char)
        if not box then
            data.box.Visible = false
            goto continue
        end
        
        -- Отрисовка бокса
        data.box.Visible = true
        data.box.Size = UDim2.new(0, box.Width, 0, box.Height)
        data.box.Position = UDim2.new(0, box.X, 0, box.Y)
        if Settings.BoxType == "Outline" then
            data.box.BackgroundTransparency = 1
            data.box.BorderSizePixel = Settings.BoxThickness
            data.box.BorderColor3 = Settings.BoxColor
        else -- Flat
            data.box.BackgroundTransparency = Settings.BoxTransparency
            data.box.BackgroundColor3 = Settings.BoxColor
            data.box.BorderSizePixel = 0
        end
        
        -- Имя
        if Settings.ShowName then
            data.name.Visible = true
            data.name.Text = player.Name
            data.name.TextColor3 = Settings.NameColor
            data.name.Position = UDim2.new(0, box.X + box.Width/2, 0, box.Y - 15)
        else
            data.name.Visible = false
        end
        
        -- Дистанция
        if Settings.ShowDistance then
            data.dist.Visible = true
            data.dist.Text = math.floor(dist) .. "m"
            data.dist.TextColor3 = Settings.DistanceColor
            data.dist.Position = UDim2.new(0, box.X + box.Width/2, 0, box.Y - 5)
        else
            data.dist.Visible = false
        end
        
        -- Здоровье
        if Settings.ShowHealthBar then
            local hpPercent = hum.Health / hum.MaxHealth
            local color = Settings.HealthColorGood:lerp(Settings.HealthColorBad, 1 - hpPercent)
            data.healthBar.Visible = true
            data.healthBar.Size = UDim2.new(hpPercent, 0, 0, 4)
            data.healthBar.Position = UDim2.new(0, box.X, 0, box.Y + box.Height)
            data.healthBar.BackgroundColor3 = color
            if Settings.ShowHealthText then
                if not data.healthText then
                    local ht = Instance.new("TextLabel", data.folder)
                    ht.TextSize = 10
                    ht.BackgroundTransparency = 1
                    ht.TextXAlignment = Enum.TextXAlignment.Center
                    data.healthText = ht
                end
                data.healthText.Visible = true
                data.healthText.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                data.healthText.Position = UDim2.new(0, box.X + box.Width/2, 0, box.Y + box.Height + 5)
            elseif data.healthText then
                data.healthText.Visible = false
            end
        else
            data.healthBar.Visible = false
            if data.healthText then data.healthText.Visible = false end
        end
        
        -- Трасcир (линия от центра экрана к ногам)
        if Settings.ShowTracer then
            local centerX = cam.ViewportSize.X / 2
            local footPos = worldToScreen(cam, hrp.Position - Vector3.new(0, 3, 0))
            if footPos then
                data.tracer.Visible = true
                local length = footPos.Y
                data.tracer.Size = UDim2.new(0, 2, 0, length)
                data.tracer.Position = UDim2.new(0, centerX - 1, 0, 0)
                data.tracer.BackgroundColor3 = Settings.TracerColor
            else
                data.tracer.Visible = false
            end
        else
            data.tracer.Visible = false
        end
        
        ::continue::
    end
    
    -- Очистка удалённых игроков
    for player, data in pairs(espObjects) do
        if not player.Parent then
            if data.folder then data.folder:Destroy() end
            espObjects[player] = nil
        end
    end
end

-- === СОЗДАНИЕ КНОПКИ И ГЛАВНОГО GUI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ESP_MasterUI"
screenGui.ResetOnSpawn = false
screenGui.Parent = CoreGui

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 65, 0, 65)
openBtn.Position = UDim2.new(0, 10, 1, -80)
openBtn.AnchorPoint = Vector2.new(0, 1)
openBtn.Text = "Ω"
openBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
openBtn.TextSize = 24
openBtn.Font = Enum.Font.GothamBold
openBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
openBtn.BackgroundTransparency = 0.15
openBtn.BorderSizePixel = 0
local btnCorner = Instance.new("UICorner", openBtn)
btnCorner.CornerRadius = UDim.new(1, 0)
openBtn.Parent = screenGui

-- Панель настроек
local settingsFrame = Instance.new("Frame")
settingsFrame.Size = UDim2.new(0, 400, 0, 480)
settingsFrame.Position = UDim2.new(0.5, -200, 0.5, -240)
settingsFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
settingsFrame.BackgroundTransparency = 0.05
settingsFrame.BorderSizePixel = 0
settingsFrame.Visible = false
settingsFrame.Parent = screenGui
local frameCorner = Instance.new("UICorner", settingsFrame)
frameCorner.CornerRadius = UDim.new(0, 12)

local titleBar = Instance.new("TextLabel", settingsFrame)
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.Text = "Ξ|Ω ESP — ПРЕМИУМ"
titleBar.TextColor3 = Color3.fromRGB(0, 255, 255)
titleBar.BackgroundTransparency = 1
titleBar.TextSize = 18
titleBar.Font = Enum.Font.GothamBold

local closeBtn = Instance.new("TextButton", settingsFrame)
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.BackgroundTransparency = 1
closeBtn.TextSize = 18

local scroll = Instance.new("ScrollingFrame", settingsFrame)
scroll.Size = UDim2.new(1, -20, 1, -50)
scroll.Position = UDim2.new(0, 10, 0, 45)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 700)
scroll.ScrollBarThickness = 4

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0, 8)

-- === ФУНКЦИИ ДЛЯ НАСТРОЕК ===
local function addToggle(text, setting)
    local frame = Instance.new("Frame", scroll)
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.BackgroundTransparency = 1
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.TextSize = 14
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0, 60, 0, 32)
    btn.Position = UDim2.new(1, -65, 0.5, -16)
    btn.Text = Settings[setting] and "ON" or "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BackgroundColor3 = Settings[setting] and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(80, 80, 90)
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 6)
    
    btn.MouseButton1Click:Connect(function()
        Settings[setting] = not Settings[setting]
        btn.Text = Settings[setting] and "ON" or "OFF"
        btn.BackgroundColor3 = Settings[setting] and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(80, 80, 90)
    end)
end

local function addSlider(text, setting, minVal, maxVal, isInt)
    local frame = Instance.new("Frame", scroll)
    frame.Size = UDim2.new(1, -20, 0, 55)
    frame.BackgroundTransparency = 1
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = text .. ": " .. tostring(Settings[setting])
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.TextSize = 14
    
    local sliderBg = Instance.new("Frame", frame)
    sliderBg.Size = UDim2.new(1, -20, 0, 6)
    sliderBg.Position = UDim2.new(0, 10, 0, 35)
    sliderBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    local bgCorner = Instance.new("UICorner", sliderBg)
    bgCorner.CornerRadius = UDim.new(0, 3)
    
    local fill = Instance.new("Frame", sliderBg)
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
    local fillCorner = Instance.new("UICorner", fill)
    fillCorner.CornerRadius = UDim.new(0, 3)
    
    local valueLabel = Instance.new("TextLabel", frame)
    valueLabel.Size = UDim2.new(0, 50, 0, 20)
    valueLabel.Position = UDim2.new(1, -55, 0, 32)
    valueLabel.Text = tostring(Settings[setting])
    valueLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    valueLabel.TextSize = 12
    valueLabel.BackgroundTransparency = 1
    
    local function updateSlider(t)
        local newVal = minVal + (maxVal - minVal) * t
        if isInt then newVal = math.floor(newVal) end
        Settings[setting] = newVal
        fill.Size = UDim2.new(t, 0, 1, 0)
        label.Text = text .. ": " .. tostring(newVal)
        valueLabel.Text = tostring(newVal)
    end
    
    local dragging = false
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            local x = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            updateSlider(x)
        end
    end)
    sliderBg.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    sliderBg.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local x = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
            updateSlider(x)
        end
    end)
    
    local initT = (Settings[setting] - minVal) / (maxVal - minVal)
    fill.Size = UDim2.new(initT, 0, 1, 0)
end

local function addDropdown(text, setting, options)
    local frame = Instance.new("Frame", scroll)
    frame.Size = UDim2.new(1, -20, 0, 40)
    frame.BackgroundTransparency = 1
    
    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(0.5, 0, 1, 0)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(220, 220, 220)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    
    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(0.4, 0, 0, 32)
    btn.Position = UDim2.new(0.55, 0, 0.5, -16)
    btn.Text = Settings[setting]
    btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(0, 6)
    
    btn.MouseButton1Click:Connect(function()
        local current = Settings[setting]
        local idx = 1
        for i, opt in ipairs(options) do
            if opt == current then idx = i break end
        end
        local nextIdx = idx % #options + 1
        Settings[setting] = options[nextIdx]
        btn.Text = Settings[setting]
    end)
end

-- Построение интерфейса настроек
addToggle("Включить ESP", "Enabled")
addToggle("Показывать игроков", "ShowPlayers")
addSlider("Макс. дистанция", "MaxDistance", 100, 1000, true)
addDropdown("Тип бокса", "BoxType", {"Outline", "Flat"})
addSlider("Прозрачность бокса", "BoxTransparency", 0, 1, false)
addSlider("Толщина рамки", "BoxThickness", 1, 4, true)
addToggle("Показывать имя", "ShowName")
addToggle("Показывать дистанцию", "ShowDistance")
addToggle("Показывать здоровье (полоса)", "ShowHealthBar")
addToggle("Показывать здоровье (цифры)", "ShowHealthText")
addToggle("Показывать трассер", "ShowTracer")
addDropdown("Режим производительности", "UpdateRate", {"Auto", "Fast", "Economy"})

-- Открытие/закрытие
openBtn.MouseButton1Click:Connect(function()
    settingsFrame.Visible = not settingsFrame.Visible
    if settingsFrame.Visible then
        settingsFrame:TweenSize(UDim2.new(0, 400, 0, 480), "Out", "Quad", 0.2, true)
    end
end)

closeBtn.MouseButton1Click:Connect(function()
    settingsFrame.Visible = false
end)

-- Для мобильных: тап по краю экрана
if UserInputService.TouchEnabled then
    UserInputService.TouchStarted:Connect(function(touch)
        if touch.Position.X < 80 or touch.Position.X > workspace.CurrentCamera.ViewportSize.X - 80 then
            settingsFrame.Visible = not settingsFrame.Visible
        end
    end)
end

gui = screenGui

-- Запуск рендера
renderConnection = RunService.RenderStepped:Connect(function()
    pcall(renderESP)
end)

-- Очистка при уходе игрока
Players.PlayerRemoving:Connect(function(player)
    if espObjects[player] and espObjects[player].folder then
        espObjects[player].folder:Destroy()
    end
    espObjects[player] = nil
end)

print("Ξ|Ω ESP v6 загружен — без оберток, работает стабильно")
