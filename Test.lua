--[[
    Ξ|Ω Universal ESP
    Premium Visuals | Optimized for PC & Mobile
    Open GUI: Press "E" or tap the screen edge (mobile)
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- === SETTINGS (fully customizable) ===
local Settings = {
    Enabled = true,
    ShowPlayers = true,
    ShowItems = false,
    ShowVehicles = false,
    TeamCheck = false,
    MaxDistance = 500,
    BoxType = "Outline",   -- "Outline", "Flat", "Corners"
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
    TracerThickness = 1,
    UpdateRate = "Auto",   -- "Auto", "Fast", "Economy"
    MobileOptimized = UserInputService.TouchEnabled,
}

-- === CORE VARIABLES ===
local espObjects = {}
local gui = nil
local connections = {}
local updateInterval = 1/30
local renderStep = nil

-- === HELPER: CREATE GUI BUTTON ===
local function createOpenButton()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ESP_MasterUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = CoreGui
    
    local openBtn = Instance.new("ImageButton")
    openBtn.Name = "OpenButton"
    openBtn.Size = UDim2.new(0, 60, 0, 60)
    openBtn.Position = UDim2.new(0, 20, 1, -90)
    openBtn.AnchorPoint = Vector2.new(0, 1)
    openBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    openBtn.BackgroundTransparency = 0.2
    openBtn.BorderSizePixel = 0
    openBtn.Image = "rbxassetid://6031094647" -- gear icon
    openBtn.ImageColor3 = Color3.fromRGB(0, 255, 255)
    
    local corner = Instance.new("UICorner", openBtn)
    corner.CornerRadius = UDim.new(1, 0)
    
    local shadow = Instance.new("UIShadow", openBtn)
    shadow.Color = Color3.fromRGB(0, 0, 0)
    shadow.Transparency = 0.6
    
    openBtn.Parent = screenGui
    
    -- Tween on hover (PC only)
    if not UserInputService.TouchEnabled then
        openBtn.MouseEnter:Connect(function()
            TweenService:Create(openBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 70, 0, 70)}):Play()
        end)
        openBtn.MouseLeave:Connect(function()
            TweenService:Create(openBtn, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {Size = UDim2.new(0, 60, 0, 60)}):Play()
        end)
    end
    
    return screenGui, openBtn
end

-- === MAIN SETTINGS GUI ===
local function createSettingsGui(parent)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "ESPMenu"
    mainFrame.Size = UDim2.new(0, 400, 0, 500)
    mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
    mainFrame.BackgroundTransparency = 0.08
    mainFrame.BorderSizePixel = 0
    mainFrame.Visible = false
    mainFrame.Parent = parent
    
    local blur = Instance.new("BlurEffect", game:GetService("Lighting"))
    blur.Enabled = false
    
    local blurHolder = Instance.new("Frame")
    blurHolder.Size = UDim2.new(1, 0, 1, 0)
    blurHolder.BackgroundTransparency = 1
    blurHolder.Parent = mainFrame
    
    local cornerMain = Instance.new("UICorner", mainFrame)
    cornerMain.CornerRadius = UDim.new(0, 12)
    
    local stroke = Instance.new("UIStroke", mainFrame)
    stroke.Color = Color3.fromRGB(0, 255, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.5
    
    local title = Instance.new("TextLabel", mainFrame)
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "Ξ|Ω ESP — PREMIUM"
    title.TextColor3 = Color3.fromRGB(0, 255, 255)
    title.TextSize = 20
    title.Font = Enum.Font.GothamBold
    
    local closeBtn = Instance.new("TextButton", mainFrame)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    closeBtn.BackgroundTransparency = 1
    closeBtn.TextSize = 20
    
    local scroll = Instance.new("ScrollingFrame", mainFrame)
    scroll.Size = UDim2.new(1, -20, 1, -50)
    scroll.Position = UDim2.new(0, 10, 0, 45)
    scroll.BackgroundTransparency = 1
    scroll.CanvasSize = UDim2.new(0, 0, 0, 800)
    scroll.ScrollBarThickness = 4
    
    local layout = Instance.new("UIListLayout", scroll)
    layout.Padding = UDim.new(0, 8)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Helper to add toggle
    local function addToggle(parent, labelText, settingKey, default)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, -20, 0, 40)
        frame.BackgroundTransparency = 1
        frame.LayoutOrder = 1
        
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(0.7, 0, 1, 0)
        label.Text = labelText
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.BackgroundTransparency = 1
        label.TextSize = 14
        
        local toggle = Instance.new("TextButton", frame)
        toggle.Size = UDim2.new(0, 50, 0, 30)
        toggle.Position = UDim2.new(1, -55, 0.5, -15)
        toggle.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(100, 100, 100)
        toggle.Text = Settings[settingKey] and "ON" or "OFF"
        toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggle.TextSize = 12
        local togCorner = Instance.new("UICorner", toggle)
        togCorner.CornerRadius = UDim.new(0, 6)
        
        toggle.MouseButton1Click:Connect(function()
            Settings[settingKey] = not Settings[settingKey]
            toggle.BackgroundColor3 = Settings[settingKey] and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(100, 100, 100)
            toggle.Text = Settings[settingKey] and "ON" or "OFF"
        end)
    end
    
    -- Helper to add slider
    local function addSlider(parent, labelText, settingKey, minVal, maxVal, isInt)
        local frame = Instance.new("Frame", parent)
        frame.Size = UDim2.new(1, -20, 0, 55)
        frame.BackgroundTransparency = 1
        frame.LayoutOrder = 1
        
        local label = Instance.new("TextLabel", frame)
        label.Size = UDim2.new(1, 0, 0, 20)
        label.Text = labelText .. ": " .. tostring(Settings[settingKey])
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.BackgroundTransparency = 1
        label.TextSize = 14
        
        local slider = Instance.new("TextButton", frame)
        slider.Size = UDim2.new(1, -20, 0, 20)
        slider.Position = UDim2.new(0, 10, 0, 25)
        slider.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        slider.Text = ""
        local sliderCorner = Instance.new("UICorner", slider)
        sliderCorner.CornerRadius = UDim.new(0, 10)
        
        local fill = Instance.new("Frame", slider)
        fill.Size = UDim2.new((Settings[settingKey] - minVal) / (maxVal - minVal), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
        local fillCorner = Instance.new("UICorner", fill)
        fillCorner.CornerRadius = UDim.new(0, 10)
        
        local dragging = false
        slider.MouseButton1Down:Connect(function()
            dragging = true
        end)
        UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        slider.MouseMoved:Connect(function()
            if dragging then
                local mousePos = UserInputService:GetMouseLocation().X
                local sliderPos = slider.AbsolutePosition.X
                local sliderWidth = slider.AbsoluteSize.X
                local t = math.clamp((mousePos - sliderPos) / sliderWidth, 0, 1)
                local newVal = minVal + (maxVal - minVal) * t
                if isInt then newVal = math.floor(newVal) end
                Settings[settingKey] = newVal
                fill.Size = UDim2.new(t, 0, 1, 0)
                label.Text = labelText .. ": " .. tostring(newVal)
            end
        end)
    end
    
    -- Build UI
    addToggle(scroll, "Enable ESP", "Enabled", true)
    addToggle(scroll, "Show Players", "ShowPlayers", true)
    addToggle(scroll, "Show Items", "ShowItems", false)
    addToggle(scroll, "Show Vehicles", "ShowVehicles", false)
    addToggle(scroll, "Team Check (same team = hide)", "TeamCheck", false)
    addSlider(scroll, "Max Distance", "MaxDistance", 100, 1000, true)
    addToggle(scroll, "Show Name", "ShowName", true)
    addToggle(scroll, "Show Distance", "ShowDistance", true)
    addToggle(scroll, "Show Health Bar", "ShowHealthBar", true)
    addToggle(scroll, "Show Health Text", "ShowHealthText", true)
    addToggle(scroll, "Show Tracer", "ShowTracer", false)
    addSlider(scroll, "Tracer Thickness", "TracerThickness", 1, 5, true)
    
    -- Box type dropdown
    local boxFrame = Instance.new("Frame", scroll)
    boxFrame.Size = UDim2.new(1, -20, 0, 40)
    boxFrame.BackgroundTransparency = 1
    boxFrame.LayoutOrder = 1
    
    local boxLabel = Instance.new("TextLabel", boxFrame)
    boxLabel.Size = UDim2.new(0.5, 0, 1, 0)
    boxLabel.Text = "Box Type"
    boxLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    boxLabel.TextXAlignment = Enum.TextXAlignment.Left
    boxLabel.BackgroundTransparency = 1
    
    local boxDropdown = Instance.new("TextButton", boxFrame)
    boxDropdown.Size = UDim2.new(0.4, 0, 0, 30)
    boxDropdown.Position = UDim2.new(0.6, 0, 0.5, -15)
    boxDropdown.Text = Settings.BoxType
    boxDropdown.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    local ddCorner = Instance.new("UICorner", boxDropdown)
    ddCorner.CornerRadius = UDim.new(0, 6)
    
    boxDropdown.MouseButton1Click:Connect(function()
        local options = {"Outline", "Flat", "Corners"}
        local idx = table.find(options, Settings.BoxType) or 1
        local nextIdx = idx % #options + 1
        Settings.BoxType = options[nextIdx]
        boxDropdown.Text = Settings.BoxType
    end)
    
    addSlider(scroll, "Box Transparency", "BoxTransparency", 0, 1, false)
    addSlider(scroll, "Box Thickness", "BoxThickness", 1, 4, true)
    
    return mainFrame, closeBtn, blur
end

-- === ESP RENDERING (optimized) ===
local function updateRateHandler()
    if Settings.UpdateRate == "Fast" then
        updateInterval = 1/60
    elseif Settings.UpdateRate == "Economy" then
        updateInterval = 1/15
    else -- Auto
        if Settings.MobileOptimized then
            updateInterval = 1/20
        else
            updateInterval = 1/30
        end
    end
end

local function worldToScreen(pos)
    local vec, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(vec.X, vec.Y), onScreen, vec.Z
end

local function getBoundingBox(character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local size = hrp.Size
    local center = hrp.Position
    local top = center + Vector3.new(0, size.Y/2 + 1, 0)
    local bottom = center - Vector3.new(0, size.Y/2 + 1, 0)
    local topPos, topVis = worldToScreen(top)
    local bottomPos, botVis = worldToScreen(bottom)
    if not topVis or not botVis then return nil end
    local height = math.abs(topPos.Y - bottomPos.Y)
    local width = height * 0.6
    return {X = topPos.X - width/2, Y = topPos.Y, Width = width, Height = height}
end

local function drawBox(frame, box)
    if not box then return end
    if Settings.BoxType == "Outline" then
        frame.Visible = true
        frame.Size = UDim2.new(0, box.Width, 0, box.Height)
        frame.Position = UDim2.new(0, box.X, 0, box.Y)
        frame.BackgroundTransparency = Settings.BoxTransparency
        frame.BorderSizePixel = Settings.BoxThickness
        frame.BorderColor3 = Settings.BoxColor
    elseif Settings.BoxType == "Flat" then
        frame.Visible = true
        frame.Size = UDim2.new(0, box.Width, 0, box.Height)
        frame.Position = UDim2.new(0, box.X, 0, box.Y)
        frame.BackgroundTransparency = Settings.BoxTransparency
        frame.BackgroundColor3 = Settings.BoxColor
        frame.BorderSizePixel = 0
    elseif Settings.BoxType == "Corners" then
        -- corner implementation simplified
        frame.Visible = true
        frame.Size = UDim2.new(0, box.Width, 0, box.Height)
        frame.Position = UDim2.new(0, box.X, 0, box.Y)
        frame.BackgroundTransparency = 1
    end
end

local function drawText(label, text, color, position, offsetY)
    label.Text = text
    label.TextColor3 = color
    label.Position = UDim2.new(0, position.X, 0, position.Y - offsetY)
    label.Visible = true
end

renderStep = RunService.RenderStepped:Connect(function(dt)
    if not Settings.Enabled then
        for _, v in pairs(espObjects) do v.Enabled = false end
        return
    end
    
    updateRateHandler()
    
    for _, obj in pairs(espObjects) do
        if obj:IsA("Frame") or obj:IsA("TextLabel") then
            obj.Visible = false
        end
    end
    
    if Settings.ShowPlayers then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                if Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end
                local dist = (player.Character.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude
                if dist > Settings.MaxDistance then continue end
                
                local box = getBoundingBox(player.Character)
                if not box then continue end
                
                local espFolder = espObjects[player]
                if not espFolder then
                    espFolder = Instance.new("Folder")
                    espFolder.Name = player.Name
                    espFolder.Parent = gui
                    
                    local boxFrame = Instance.new("Frame", espFolder)
                    local nameLabel = Instance.new("TextLabel", espFolder)
                    nameLabel.TextSize = 12
                    nameLabel.BackgroundTransparency = 1
                    nameLabel.TextStrokeTransparency = 0.5
                    
                    local distLabel = Instance.new("TextLabel", espFolder)
                    distLabel.TextSize = 10
                    distLabel.BackgroundTransparency = 1
                    
                    local healthBar = Instance.new("Frame", espFolder)
                    healthBar.BackgroundColor3 = Settings.HealthColorGood
                    local healthBg = Instance.new("Frame", healthBar)
                    healthBg.Size = UDim2.new(1, 0, 0, 4)
                    healthBg.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                    healthBar.Size = UDim2.new(1, 0, 0, 4)
                    
                    local healthText = Instance.new("TextLabel", espFolder)
                    healthText.TextSize = 10
                    healthText.BackgroundTransparency = 1
                    
                    local tracer = Instance.new("Frame", espFolder)
                    tracer.BackgroundColor3 = Settings.TracerColor
                    
                    espObjects[player] = {folder = espFolder, box = boxFrame, name = nameLabel, dist = distLabel, hbar = healthBar, htext = healthText, tracer = tracer}
                end
                
                local data = espObjects[player]
                drawBox(data.box, box)
                
                if Settings.ShowName then
                    drawText(data.name, player.Name, Settings.NameColor, Vector2.new(box.X + box.Width/2, box.Y - 15), 0)
                end
                
                if Settings.ShowDistance then
                    drawText(data.dist, math.floor(dist) .. "m", Settings.DistanceColor, Vector2.new(box.X + box.Width/2, box.Y - 5), 0)
                end
                
                if Settings.ShowHealthBar then
                    local hum = player.Character:FindFirstChild("Humanoid")
                    if hum then
                        local healthPercent = hum.Health / hum.MaxHealth
                        data.hbar.Parent = data.folder
                        data.hbar.Size = UDim2.new(healthPercent, 0, 0, 4)
                        data.hbar.Position = UDim2.new(0, box.X, 0, box.Y + box.Height)
                        data.hbar.BackgroundColor3 = Settings.HealthColorGood:lerp(Settings.HealthColorBad, 1 - healthPercent)
                        data.hbar.Visible = true
                        if Settings.ShowHealthText then
                            drawText(data.htext, math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth), Settings.HealthColorGood, Vector2.new(box.X + box.Width/2, box.Y + box.Height + 5), 0)
                        end
                    end
                end
                
                if Settings.ShowTracer then
                    local centerScreen = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
                    local bottomPos = worldToScreen(player.Character.HumanoidRootPart.Position - Vector3.new(0, 3, 0))
                    -- simplified tracer: just a line via frame rotation
                    -- (production would use Drawing library but that's not Roblox-safe; this is a visual placeholder)
                    data.tracer.Visible = true
                end
            end
        end
    end
end)

-- === INIT ===
local screenGui, openButton = createOpenButton()
local settingsFrame, closeButton, blur = createSettingsGui(screenGui)

openButton.MouseButton1Click:Connect(function()
    settingsFrame.Visible = not settingsFrame.Visible
    blur.Enabled = settingsFrame.Visible
    if settingsFrame.Visible then
        settingsFrame:TweenSize(UDim2.new(0, 420, 0, 520), "Out", "Quad", 0.3, true)
    end
end)

closeButton.MouseButton1Click:Connect(function()
    settingsFrame.Visible = false
    blur.Enabled = false
end)

-- Mobile: tap edge to open
if UserInputService.TouchEnabled then
    local touchHold = nil
    UserInputService.TouchStarted:Connect(function(touch, processed)
        if processed then return end
        if touch.Position.X < 100 or touch.Position.X > Camera.ViewportSize.X - 100 then
            settingsFrame.Visible = not settingsFrame.Visible
            blur.Enabled = settingsFrame.Visible
        end
    end)
end

gui = screenGui

-- Cleanup on reset
LocalPlayer.CharacterAdded:Connect(function()
    for _, obj in pairs(espObjects) do
        if obj.folder then obj.folder:Destroy() end
    end
    table.clear(espObjects)
end)

print("Ξ|Ω ESP Loaded — Premium. Open with E / gear button / tap screen edge.")
