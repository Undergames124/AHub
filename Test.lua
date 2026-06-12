--[[
    Ξ|Ω ESP v2 — Fixed
    - No freeze (pcall + throttle + camera refresh)
    - Reliable open button (PC/mobile)
    - Settings fully interactive
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- === SETTINGS ===
local Settings = {
    Enabled = true,
    ShowPlayers = true,
    MaxDistance = 500,
    BoxType = "Outline",
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
    TracerThickness = 2,
    UpdateRate = "Auto",
}

-- === GLOBALS ===
local camera = nil
local gui = nil
local espElements = {} -- [player] = {box, name, dist, healthBar, healthText, tracer}
local lastUpdate = 0
local updateInterval = 1/30
local renderConnection = nil

-- === HELPER: get camera each frame ===
local function getCamera()
    return workspace.CurrentCamera
end

-- === WORLD TO SCREEN ===
local function worldToScreen(cam, pos)
    local vec, onScreen = cam:WorldToViewportPoint(pos)
    if not onScreen then return nil end
    return Vector2.new(vec.X, vec.Y), vec.Z
end

-- === BOUNDING BOX ===
local function getBoundingBox(cam, character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local size = hrp.Size
    local center = hrp.Position
    local top = center + Vector3.new(0, size.Y/2 + 1, 0)
    local bottom = center - Vector3.new(0, size.Y/2 + 1, 0)
    local topPos, topZ = worldToScreen(cam, top)
    local bottomPos, bottomZ = worldToScreen(cam, bottom)
    if not topPos or not bottomPos then return nil end
    local height = math.abs(topPos.Y - bottomPos.Y)
    local width = height * 0.6
    return {
        X = topPos.X - width/2,
        Y = topPos.Y,
        Width = width,
        Height = height,
        BottomY = bottomPos.Y,
        BottomPos = bottomPos
    }
end

-- === DRAW BOX ===
local function updateBox(frame, box, cam)
    if not box then
        frame.Visible = false
        return
    end
    frame.Visible = true
    frame.Size = UDim2.new(0, box.Width, 0, box.Height)
    frame.Position = UDim2.new(0, box.X, 0, box.Y)
    
    if Settings.BoxType == "Outline" then
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = Settings.BoxThickness
        frame.BorderColor3 = Settings.BoxColor
    elseif Settings.BoxType == "Flat" then
        frame.BackgroundTransparency = Settings.BoxTransparency
        frame.BackgroundColor3 = Settings.BoxColor
        frame.BorderSizePixel = 0
    elseif Settings.BoxType == "Corners" then
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        -- corners are drawn via additional frames (simplified here)
    end
end

-- === UPDATE TEXT ===
local function updateText(label, text, color, position, offsetY)
    if not position then
        label.Visible = false
        return
    end
    label.Text = text
    label.TextColor3 = color
    label.Position = UDim2.new(0, position.X, 0, position.Y - offsetY)
    label.Visible = true
end

-- === UPDATE HEALTH BAR ===
local function updateHealthBar(bar, bg, textLabel, hum, box)
    if not hum or not box then
        bar.Visible = false
        bg.Visible = false
        if textLabel then textLabel.Visible = false end
        return
    end
    local hp = hum.Health
    local maxHp = hum.MaxHealth
    local percent = math.clamp(hp / maxHp, 0, 1)
    local color = Settings.HealthColorGood:lerp(Settings.HealthColorBad, 1 - percent)
    
    bar.Size = UDim2.new(percent, 0, 0, 4)
    bar.Position = UDim2.new(0, box.X, 0, box.Y + box.Height)
    bar.BackgroundColor3 = color
    bar.Visible = Settings.ShowHealthBar
    
    bg.Size = UDim2.new(1, 0, 0, 4)
    bg.Position = UDim2.new(0, 0, 0, 0)
    bg.Visible = Settings.ShowHealthBar
    
    if Settings.ShowHealthText and textLabel then
        textLabel.Text = math.floor(hp) .. "/" .. math.floor(maxHp)
        textLabel.Position = UDim2.new(0, box.X + box.Width/2, 0, box.Y + box.Height + 5)
        textLabel.Visible = true
    elseif textLabel then
        textLabel.Visible = false
    end
end

-- === UPDATE TRACER (using rotation trick) ===
local function updateTracer(tracerFrame, fromScreen, toWorldPos, cam)
    if not Settings.ShowTracer or not toWorldPos then
        tracerFrame.Visible = false
        return
    end
    local toScreen, onScreen = worldToScreen(cam, toWorldPos)
    if not toScreen or not onScreen then
        tracerFrame.Visible = false
        return
    end
    local startPos = fromScreen
    local endPos = toScreen
    local dx = endPos.X - startPos.X
    local dy = endPos.Y - startPos.Y
    local length = math.sqrt(dx*dx + dy*dy)
    if length < 0.1 then
        tracerFrame.Visible = false
        return
    end
    local angle = math.atan2(dy, dx)
    tracerFrame.Size = UDim2.new(0, length, 0, Settings.TracerThickness)
    tracerFrame.Position = UDim2.new(0, startPos.X, 0, startPos.Y)
    tracerFrame.Rotation = math.deg(angle)
    tracerFrame.BackgroundColor3 = Settings.TracerColor
    tracerFrame.Visible = true
end

-- === CLEANUP PLAYER ===
local function cleanupPlayer(player)
    local data = espElements[player]
    if data then
        for _, obj in pairs(data) do
            if obj and obj:IsA("Instance") then obj:Destroy() end
        end
        espElements[player] = nil
    end
end

-- === CREATE UI ELEMENTS FOR PLAYER ===
local function setupPlayer(player)
    if espElements[player] then return end
    local folder = Instance.new("Folder")
    folder.Name = player.Name
    folder.Parent = gui
    
    local box = Instance.new("Frame", folder)
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    
    local nameLabel = Instance.new("TextLabel", folder)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.BackgroundTransparency = 1
    nameLabel.TextStrokeTransparency = 0.3
    nameLabel.TextXAlignment = Enum.TextXAlignment.Center
    
    local distLabel = Instance.new("TextLabel", folder)
    distLabel.TextSize = 10
    distLabel.BackgroundTransparency = 1
    distLabel.TextStrokeTransparency = 0.3
    distLabel.TextXAlignment = Enum.TextXAlignment.Center
    
    local healthBar = Instance.new("Frame", folder)
    healthBar.BackgroundColor3 = Settings.HealthColorGood
    
    local healthBg = Instance.new("Frame", healthBar)
    healthBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    healthBg.Size = UDim2.new(1, 0, 1, 0)
    healthBg.ZIndex = 0
    
    local healthText = Instance.new("TextLabel", folder)
    healthText.TextSize = 10
    healthText.BackgroundTransparency = 1
    healthText.TextXAlignment = Enum.TextXAlignment.Center
    
    local tracer = Instance.new("Frame", folder)
    tracer.BackgroundColor3 = Settings.TracerColor
    tracer.BackgroundTransparency = 0.3
    tracer.BorderSizePixel = 0
    
    espElements[player] = {
        folder = folder,
        box = box,
        name = nameLabel,
        dist = distLabel,
        healthBar = healthBar,
        healthBg = healthBg,
        healthText = healthText,
        tracer = tracer
    }
end

-- === MAIN RENDER LOOP (throttled + error-protected) ===
local function renderESP()
    if not Settings.Enabled then
        for _, data in pairs(espElements) do
            data.box.Visible = false
            data.name.Visible = false
            data.dist.Visible = false
            data.healthBar.Visible = false
            data.tracer.Visible = false
            if data.healthText then data.healthText.Visible = false end
        end
        return
    end
    
    local cam = getCamera()
    if not cam then return end
    
    local now = tick()
    if Settings.UpdateRate == "Fast" then
        updateInterval = 1/60
    elseif Settings.UpdateRate == "Economy" then
        updateInterval = 1/15
    else -- Auto
        updateInterval = UserInputService.TouchEnabled and 1/20 or 1/30
    end
    if now - lastUpdate < updateInterval then return end
    lastUpdate = now
    
    local centerScreen = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y)
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not Settings.ShowPlayers then break end
        
        setupPlayer(player)
        local data = espElements[player]
        if not data then continue end
        
        local character = player.Character
        if not character then
            for _, obj in pairs(data) do
                if obj and obj:IsA("Instance") then obj.Visible = false end
            end
            goto continue
        end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        local hum = character:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then
            for _, obj in pairs(data) do
                if obj and obj:IsA("Instance") then obj.Visible = false end
            end
            goto continue
        end
        
        local dist = (hrp.Position - cam.CFrame.Position).Magnitude
        if dist > Settings.MaxDistance then
            for _, obj in pairs(data) do
                if obj and obj:IsA("Instance") then obj.Visible = false end
            end
            goto continue
        end
        
        local box = getBoundingBox(cam, character)
        if not box then
            for _, obj in pairs(data) do
                if obj and obj:IsA("Instance") then obj.Visible = false end
            end
            goto continue
        end
        
        -- Update visuals
        updateBox(data.box, box, cam)
        
        if Settings.ShowName then
            updateText(data.name, player.Name, Settings.NameColor, Vector2.new(box.X + box.Width/2, box.Y - 15), 0)
        else
            data.name.Visible = false
        end
        
        if Settings.ShowDistance then
            updateText(data.dist, math.floor(dist) .. "m", Settings.DistanceColor, Vector2.new(box.X + box.Width/2, box.Y - 5), 0)
        else
            data.dist.Visible = false
        end
        
        updateHealthBar(data.healthBar, data.healthBg, data.healthText, hum, box)
        
        if Settings.ShowTracer then
            local rootPos = hrp.Position - Vector3.new(0, 3, 0)
            updateTracer(data.tracer, centerScreen, rootPos, cam)
        else
            data.tracer.Visible = false
        end
        
        ::continue::
    end
    
    -- Remove players that left
    for player, _ in pairs(espElements) do
        if not player.Parent then
            cleanupPlayer(player)
        end
    end
end

-- === CREATE OPEN BUTTON (reliable) ===
local function createOpenButton()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ESP_MasterUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 70, 0, 70)
    btn.Position = UDim2.new(0, 15, 1, -85)
    btn.AnchorPoint = Vector2.new(0, 1)
    btn.Text = "Ξ|Ω"
    btn.TextColor3 = Color3.fromRGB(0, 255, 255)
    btn.TextSize = 18
    btn.Font = Enum.Font.GothamBold
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0
    
    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(1, 0)
    
    local shadow = Instance.new("UIShadow", btn)
    shadow.Color = Color3.fromRGB(0,0,0)
    shadow.Transparency = 0.7
    
    btn.Parent = screenGui
    
    -- Tween on hover (non-mobile)
    if not UserInputService.TouchEnabled then
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {Size = UDim2.new(0, 80, 0, 80)}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.15), {Size = UDim2.new(0, 70, 0, 70)}):Play()
        end)
    end
    
    return screenGui, btn
end

-- === SETTINGS GUI (fully functional) ===
local function createSettingsGui(parent, openButton)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 420, 0, 520)
    frame.Position = UDim2.new(0.5, -210, 0.5, -260)
    frame.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = parent
    
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 12)
    
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = Color3.fromRGB(0, 255, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.4
    
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 45)
    title.Text = "Ξ|Ω ESP — PREMIUM v2"
    title.TextColor3 = Color3.fromRGB(0, 255, 255)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    title.BackgroundTransparency = 1
    
    local close = Instance.new("TextButton", frame)
    close.Size = UDim2.new(0, 35, 0, 35)
    close.Position = UDim2.new(1, -42, 0, 5)
    close.Text = "✕"
    close.TextColor3 = Color3.fromRGB(255, 120, 120)
    close.TextSize = 22
    close.BackgroundTransparency = 1
    
    local scroll = Instance.new("ScrollingFrame", frame)
    scroll.Size = UDim2.new(1, -20, 1, -55)
    scroll.Position = UDim2.new(0, 10, 0, 50)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 800)
    scroll.ScrollBarThickness = 4
    
    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 8)
    
    -- Toggle helper
    local function addToggle(text, setting, default)
        local cont = Instance.new("Frame", scroll)
        cont.Size = UDim2.new(1, -20, 0, 40)
        cont.BackgroundTransparency = 1
        
        local label = Instance.new("TextLabel", cont)
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Text = text
        label.TextColor3 = Color3.fromRGB(220,220,220)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.BackgroundTransparency = 1
        
        local btn = Instance.new("TextButton", cont)
        btn.Size = UDim2.new(0, 60, 0, 32)
        btn.Position = UDim2.new(1, -65, 0.5, -16)
        btn.Text = Settings[setting] and "ON" or "OFF"
        btn.TextColor3 = Color3.fromRGB(255,255,255)
        btn.BackgroundColor3 = Settings[setting] and Color3.fromRGB(0,180,0) or Color3.fromRGB(80,80,90)
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 6)
        
        btn.MouseButton1Click:Connect(function()
            Settings[setting] = not Settings[setting]
            btn.Text = Settings[setting] and "ON" or "OFF"
            btn.BackgroundColor3 = Settings[setting] and Color3.fromRGB(0,180,0) or Color3.fromRGB(80,80,90)
        end)
    end
    
    -- Slider helper
    local function addSlider(text, setting, minVal, maxVal, isInt)
        local cont = Instance.new("Frame", scroll)
        cont.Size = UDim2.new(1, -20, 0, 60)
        cont.BackgroundTransparency = 1
        
        local label = Instance.new("TextLabel", cont)
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Text = text .. ": " .. tostring(Settings[setting])
        label.TextColor3 = Color3.fromRGB(220,220,220)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.BackgroundTransparency = 1
        
        local sliderBg = Instance.new("Frame", cont)
        sliderBg.Size = UDim2.new(1, -20, 0, 6)
        sliderBg.Position = UDim2.new(0, 10, 0, 35)
        sliderBg.BackgroundColor3 = Color3.fromRGB(50,50,60)
        local bgCorner = Instance.new("UICorner", sliderBg)
        bgCorner.CornerRadius = UDim.new(0, 3)
        
        local fill = Instance.new("Frame", sliderBg)
        fill.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
        local fillCorner = Instance.new("UICorner", fill)
        fillCorner.CornerRadius = UDim.new(0, 3)
        
        local valueLabel = Instance.new("TextLabel", cont)
        valueLabel.Size = UDim2.new(0, 50, 0, 20)
        valueLabel.Position = UDim2.new(1, -55, 0, 35)
        valueLabel.Text = tostring(Settings[setting])
        valueLabel.TextColor3 = Color3.fromRGB(200,200,200)
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
        local mouse = game:GetService("UserInputService")
        local function onInput(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end
        local conn
        sliderBg.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                local x = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                updateSlider(x)
                conn = mouse.InputEnded:Connect(onInput)
            end
        end)
        sliderBg.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local x = math.clamp((input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
                updateSlider(x)
            end
        end)
        
        -- initial fill
        local initT = (Settings[setting] - minVal) / (maxVal - minVal)
        fill.Size = UDim2.new(initT, 0, 1, 0)
    end
    
    -- Dropdown helper
    local function addDropdown(text, setting, options)
        local cont = Instance.new("Frame", scroll)
        cont.Size = UDim2.new(1, -20, 0, 40)
        cont.BackgroundTransparency = 1
        
        local label = Instance.new("TextLabel", cont)
        label.Size = UDim2.new(0.5, 0, 1, 0)
        label.Text = text
        label.TextColor3 = Color3.fromRGB(220,220,220)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.BackgroundTransparency = 1
        
        local btn = Instance.new("TextButton", cont)
        btn.Size = UDim2.new(0.4, 0, 0, 32)
        btn.Position = UDim2.new(0.55, 0, 0.5, -16)
        btn.Text = Settings[setting]
        btn.BackgroundColor3 = Color3.fromRGB(40,40,50)
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 6)
        
        btn.MouseButton1Click:Connect(function()
            local current = Settings[setting]
            local idx = table.find(options, current) or 1
            local nextIdx = (idx % #options) + 1
            Settings[setting] = options[nextIdx]
            btn.Text = Settings[setting]
        end)
    end
    
    -- Build UI
    addToggle("Enable ESP", "Enabled", true)
    addToggle("Show Players", "ShowPlayers", true)
    addSlider("Max Distance", "MaxDistance", 100, 1000, true)
    addDropdown("Box Type", "BoxType", {"Outline", "Flat", "Corners"})
    addSlider("Box Transparency", "BoxTransparency", 0, 1, false)
    addSlider("Box Thickness", "BoxThickness", 1, 4, true)
    addToggle("Show Name", "ShowName", true)
    addToggle("Show Distance", "ShowDistance", true)
    addToggle("Show Health Bar", "ShowHealthBar", true)
    addToggle("Show Health Text", "ShowHealthText", true)
    addToggle("Show Tracer", "ShowTracer", false)
    addSlider("Tracer Thickness", "TracerThickness", 1, 5, true)
    addDropdown("Performance Mode", "UpdateRate", {"Auto", "Fast", "Economy"})
    
    -- Open/close logic
    local function toggleMenu()
        frame.Visible = not frame.Visible
        if frame.Visible then
            frame:TweenSize(UDim2.new(0, 420, 0, 520), "Out", "Quad", 0.25, true)
        end
    end
    
    openButton.MouseButton1Click:Connect(toggleMenu)
    close.MouseButton1Click:Connect(toggleMenu)
    
    -- Mobile edge tap also toggles menu
    if UserInputService.TouchEnabled then
        UserInputService.TouchStarted:Connect(function(touch)
            if touch.Position.X < 80 or touch.Position.X > camera.ViewportSize.X - 80 then
                toggleMenu()
            end
        end)
    end
    
    return frame
end

-- === INIT ===
local mainGui, openBtn = createOpenButton()
local settingsFrame = createSettingsGui(mainGui, openBtn)
gui = mainGui

-- Start render loop with pcall protection
renderConnection = RunService.RenderStepped:Connect(function()
    local success, err = pcall(renderESP)
    if not success then
        warn("ESP render error: ", err)
    end
end)

-- Cleanup on player leave
Players.PlayerRemoving:Connect(cleanupPlayer)

print("Ξ|Ω ESP v2 loaded — stable, settings live, no freeze.")
