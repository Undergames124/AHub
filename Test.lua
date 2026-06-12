local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- === НАСТРОЙКИ ПО УМОЛЧАНИЮ (HUMANIZED) ===
local Settings = {
    ESP = {
        Enabled = true,
        Box = true,
        Tracer = false,
        Name = true,
        Distance = true,
        HealthBar = true,
        MaxDistance = 250,
        Thickness = 1,
        Transparency = 0.6
    },
    Aim = {
        Enabled = true,
        Smoothness = 0.25,       -- 0 = мгновенно, 1 = очень медленно
        FOV = 90,                 -- градусы
        HumanizedDelay = 0.12,    -- сек между смещениями
        MaxRandomOffset = 3,      -- пикселей (имитация дрожи)
        HitChance = 85,           -- % попадания
        OnlyVisible = true,
        Teams = false,            -- false = аим на всех
        Key = "RightAlt"          -- клавиша активации (можно "XButton2" для мыши)
    },
    Menu = {
        OpenKey = "Insert",
        Visible = false
    }
}

-- === ГЛОБАЛЬНЫЕ ПЕРЕМЕННЫЕ ===
local Drawings = {}      -- таблица всех линий/боксов
local CurrentTarget = nil
local LastAimTime = 0
local LastFrameTime = tick()

-- === ФУНКЦИЯ ДЛЯ СОЗДАНИЯ "IMGUI" СТИЛЯ ===
local function CreateMenu()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "OmegaMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = game:GetService("CoreGui")
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 380, 0, 520)
    frame.Position = UDim2.new(0.5, -190, 0.5, -260)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    frame.BackgroundTransparency = 0.08
    frame.BorderSizePixel = 1
    frame.BorderColor3 = Color3.fromRGB(80, 80, 90)
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screenGui
    
    -- Заголовок как в ImGui
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    title.Text = "  Ξ|Ω  MENU  [ Insert to toggle ]"
    title.TextColor3 = Color3.fromRGB(220, 220, 220)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Font = Enum.Font.GothamMedium
    title.TextSize = 14
    title.Parent = frame
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 1, -4)
    closeBtn.Position = UDim2.new(1, -34, 0, 2)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    closeBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
    closeBtn.Parent = title
    closeBtn.MouseButton1Click:Connect(function()
        Settings.Menu.Visible = false
        frame.Visible = false
    end)
    
    -- === ВКЛАДКИ ===
    local tabs = {"ESP", "AIM", "HUMANIZE"}
    local activeTab = "ESP"
    
    local tabBar = Instance.new("Frame")
    tabBar.Size = UDim2.new(1, 0, 0, 30)
    tabBar.Position = UDim2.new(0, 0, 0, 30)
    tabBar.BackgroundTransparency = 1
    tabBar.Parent = frame
    
    local tabButtons = {}
    for i, t in ipairs(tabs) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 100, 1, 0)
        btn.Position = UDim2.new(0, (i-1)*100, 0, 0)
        btn.Text = t
        btn.BackgroundColor3 = Color3.fromRGB(40,40,45)
        btn.TextColor3 = Color3.fromRGB(200,200,200)
        btn.Parent = tabBar
        btn.MouseButton1Click:Connect(function()
            activeTab = t
            for _, b in pairs(tabButtons) do
                b.BackgroundColor3 = Color3.fromRGB(40,40,45)
            end
            btn.BackgroundColor3 = Color3.fromRGB(70,70,80)
            RefreshContent()
        end)
        table.insert(tabButtons, btn)
    end
    
    local content = Instance.new("ScrollingFrame")
    content.Size = UDim2.new(1, -10, 1, -70)
    content.Position = UDim2.new(0, 5, 0, 65)
    content.BackgroundTransparency = 1
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.ScrollBarThickness = 6
    content.Parent = frame
    
    local function AddToggle(label, getter, setter)
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, -10, 0, 25)
        line.BackgroundTransparency = 1
        line.Parent = content
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(0.7, 0, 1, 0)
        lbl.Text = label
        lbl.TextColor3 = Color3.fromRGB(210,210,210)
        lbl.BackgroundTransparency = 1
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = line
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 50, 0, 20)
        btn.Position = UDim2.new(1, -55, 0.5, -10)
        btn.Text = getter() and "ON" or "OFF"
        btn.BackgroundColor3 = getter() and Color3.fromRGB(0,180,0) or Color3.fromRGB(100,40,40)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Parent = line
        btn.MouseButton1Click:Connect(function()
            setter(not getter())
            btn.Text = getter() and "ON" or "OFF"
            btn.BackgroundColor3 = getter() and Color3.fromRGB(0,180,0) or Color3.fromRGB(100,40,40)
        end)
    end
    
    local function AddSlider(label, minVal, maxVal, getter, setter, format)
        local line = Instance.new("Frame")
        line.Size = UDim2.new(1, -10, 0, 40)
        line.BackgroundTransparency = 1
        line.Parent = content
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, 0, 0, 20)
        lbl.Text = label .. ": " .. string.format(format or "%.2f", getter())
        lbl.TextColor3 = Color3.fromRGB(210,210,210)
        lbl.BackgroundTransparency = 1
        lbl.Parent = line
        
        local slider = Instance.new("TextButton")
        slider.Size = UDim2.new(1, -20, 0, 20)
        slider.Position = UDim2.new(0, 10, 0, 20)
        slider.BackgroundColor3 = Color3.fromRGB(60,60,70)
        slider.AutoButtonColor = false
        slider.Text = ""
        slider.Parent = line
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((getter()-minVal)/(maxVal-minVal), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(0,150,200)
        fill.BorderSizePixel = 0
        fill.Parent = slider
        
        local dragging = false
        slider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
            end
        end)
        slider.InputEnded:Connect(function()
            dragging = false
        end)
        slider.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local pos = input.Position.X - slider.AbsolutePosition.X
                local newVal = minVal + (pos / slider.AbsoluteSize.X) * (maxVal - minVal)
                newVal = math.clamp(newVal, minVal, maxVal)
                setter(newVal)
                fill.Size = UDim2.new((newVal-minVal)/(maxVal-minVal), 0, 1, 0)
                lbl.Text = label .. ": " .. string.format(format or "%.2f", newVal)
            end
        end)
    end
    
    local function RefreshContent()
        for _, v in pairs(content:GetChildren()) do
            if v:IsA("Frame") then v:Destroy() end
        end
        if activeTab == "ESP" then
            AddToggle("Enable ESP", function() return Settings.ESP.Enabled end, function(v) Settings.ESP.Enabled = v end)
            AddToggle("Box ESP", function() return Settings.ESP.Box end, function(v) Settings.ESP.Box = v end)
            AddToggle("Tracer", function() return Settings.ESP.Tracer end, function(v) Settings.ESP.Tracer = v end)
            AddToggle("Names", function() return Settings.ESP.Name end, function(v) Settings.ESP.Name = v end)
            AddToggle("Distance", function() return Settings.ESP.Distance end, function(v) Settings.ESP.Distance = v end)
            AddSlider("Max Distance", 50, 500, function() return Settings.ESP.MaxDistance end, function(v) Settings.ESP.MaxDistance = v end, "%.0f")
        elseif activeTab == "AIM" then
            AddToggle("Enable AimBot", function() return Settings.Aim.Enabled end, function(v) Settings.Aim.Enabled = v end)
            AddToggle("Only Visible", function() return Settings.Aim.OnlyVisible end, function(v) Settings.Aim.OnlyVisible = v end)
            AddToggle("Ignore Team", function() return not Settings.Aim.Teams end, function(v) Settings.Aim.Teams = not v end)
            AddSlider("FOV (degrees)", 30, 180, function() return Settings.Aim.FOV end, function(v) Settings.Aim.FOV = v end, "%.0f")
            AddSlider("Hit Chance %", 0, 100, function() return Settings.Aim.HitChance end, function(v) Settings.Aim.HitChance = v end, "%.0f")
        elseif activeTab == "HUMANIZE" then
            AddSlider("Smoothness", 0.05, 0.8, function() return Settings.Aim.Smoothness end, function(v) Settings.Aim.Smoothness = v end, "%.2f")
            AddSlider("Delay (sec)", 0.03, 0.35, function() return Settings.Aim.HumanizedDelay end, function(v) Settings.Aim.HumanizedDelay = v end, "%.3f")
            AddSlider("Random offset (px)", 0, 12, function() return Settings.Aim.MaxRandomOffset end, function(v) Settings.Aim.MaxRandomOffset = v end, "%.0f")
        end
        content.CanvasSize = UDim2.new(0, 0, 0, #content:GetChildren() * 30)
    end
    
    RefreshContent()
    frame.Visible = false
    return screenGui, frame
end

local MenuGui, MenuFrame = CreateMenu()

-- === РЕНДЕР ESP ЧЕРЕЗ DRAWING (ОБХОД АНТИЧИТА) ===
local function UpdateESP()
    if not Settings.ESP.Enabled then
        for _, drawing in pairs(Drawings) do
            drawing:Remove()
        end
        Drawings = {}
        return
    end
    
    local newDrawings = {}
    local camPos = Camera.CFrame.Position
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local root = player.Character.HumanoidRootPart
            local screenPos, onScreen = Camera:WorldToViewportPoint(root.Position)
            local distance = (camPos - root.Position).Magnitude
            if onScreen and distance <= Settings.ESP.MaxDistance then
                local size = 4 / screenPos.Z * 2
                local topLeft = Vector2.new(screenPos.X - 50 * size, screenPos.Y - 100 * size)
                local bottomRight = Vector2.new(screenPos.X + 50 * size, screenPos.Y + 20 * size)
                
                if Settings.ESP.Box then
                    local box = Drawings[player .. "box"] or Drawing.new("Square")
                    box.Visible = true
                    box.Thickness = Settings.ESP.Thickness
                    box.Color = Color3.fromRGB(0, 200, 255)
                    box.Transparency = Settings.ESP.Transparency
                    box.Filled = false
                    box.Size = Vector2.new(bottomRight.X - topLeft.X, bottomRight.Y - topLeft.Y)
                    box.Position = topLeft
                    newDrawings[player .. "box"] = box
                end
                
                if Settings.ESP.Name then
                    local nameDraw = Drawings[player .. "name"] or Drawing.new("Text")
                    nameDraw.Visible = true
                    nameDraw.Text = player.Name
                    nameDraw.Color = Color3.fromRGB(255,255,255)
                    nameDraw.Size = 12
                    nameDraw.Position = Vector2.new(screenPos.X - 40, topLeft.Y - 15)
                    newDrawings[player .. "name"] = nameDraw
                end
            end
        end
    end
    
    for k, v in pairs(Drawings) do
        if not newDrawings[k] then v:Remove() end
    end
    Drawings = newDrawings
end

-- === AIMBOT HUMANIZED ===
local function GetClosestPlayer()
    local closest = nil
    local minDist = Settings.Aim.FOV
    local mouseLoc = UserInputService:GetMouseLocation()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            if Settings.Aim.OnlyVisible then
                local ray = Ray.new(Camera.CFrame.Position, (player.Character.Head.Position - Camera.CFrame.Position).Unit * 999)
                local hit, _ = workspace:FindPartOnRay(ray, LocalPlayer.Character)
                if hit and hit:IsDescendantOf(player.Character) == false then continue end
            end
            local screenPos, onScreen = Camera:WorldToViewportPoint(player.Character.Head.Position)
            if onScreen then
                local delta = Vector2.new(screenPos.X - mouseLoc.X, screenPos.Y - mouseLoc.Y)
                local dist = delta.Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = player
                end
            end
        end
    end
    return closest
end

local function SmoothAim(targetPos)
    if not targetPos then return end
    local now = tick()
    if now - LastAimTime < Settings.Aim.HumanizedDelay then return end
    LastAimTime = now
    
    local randomOffset = Vector2.new(
        math.random(-Settings.Aim.MaxRandomOffset, Settings.Aim.MaxRandomOffset),
        math.random(-Settings.Aim.MaxRandomOffset, Settings.Aim.MaxRandomOffset)
    )
    local targetScreen = Camera:WorldToViewportPoint(targetPos)
    local targetVector = Vector2.new(targetScreen.X, targetScreen.Y) + randomOffset
    local currentMouse = UserInputService:GetMouseLocation()
    local delta = targetVector - currentMouse
    local step = delta * (1 - Settings.Aim.Smoothness)
    
    mousemoverel(step.X, step.Y)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode[Settings.Menu.OpenKey] then
        Settings.Menu.Visible = not Settings.Menu.Visible
        MenuFrame.Visible = Settings.Menu.Visible
    end
    if Settings.Aim.Enabled and input.KeyCode == Enum.KeyCode[Settings.Aim.Key] then
        if math.random(1,100) <= Settings.Aim.HitChance then
            local target = GetClosestPlayer()
            if target and target.Character and target.Character:FindFirstChild("Head") then
                SmoothAim(target.Character.Head.Position)
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    UpdateESP()
end)
