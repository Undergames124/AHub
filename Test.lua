-- Ξ|Ω ESP v5 — Delta native, no root-level function calls
-- Everything wrapped in an anonymous function to avoid "nil call" on line 1

(function()
    -- Wait for environment to stabilize (Delta injection)
    task.wait(0.5)
    
    -- === SAFE SERVICE FETCH ===
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local CoreGui = game:GetService("CoreGui")
    
    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then
        Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        LocalPlayer = Players.LocalPlayer
    end
    
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
        ShowTracer = false,
        TracerColor = Color3.fromRGB(255, 0, 0),
        UpdateRate = "Auto",
    }
    
    -- === GLOBALS ===
    local gui = nil
    local espElements = {}
    local lastUpdate = 0
    local updateInterval = 1/30
    local renderConnection = nil
    
    -- === Helper functions ===
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
        local center = hrp.Position
        local top = center + Vector3.new(0, size.Y/2 + 1.5, 0)
        local bottom = center - Vector3.new(0, size.Y/2 + 1.5, 0)
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
    
    local function setupPlayerUI(player)
        if espElements[player] then return end
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
    
    local function renderESP()
        local cam = workspace.CurrentCamera
        if not cam or not Settings.Enabled then
            for _, data in pairs(espElements) do
                if data.box then data.box.Visible = false end
                if data.name then data.name.Visible = false end
                if data.dist then data.dist.Visible = false end
                if data.healthBar then data.healthBar.Visible = false end
                if data.tracer then data.tracer.Visible = false end
            end
            return
        end
        
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
            local data = espElements[player]
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
            
            -- Draw box
            data.box.Visible = true
            data.box.Size = UDim2.new(0, box.Width, 0, box.Height)
            data.box.Position = UDim2.new(0, box.X, 0, box.Y)
            if Settings.BoxType == "Outline" then
                data.box.BackgroundTransparency = 1
                data.box.BorderSizePixel = Settings.BoxThickness
                data.box.BorderColor3 = Settings.BoxColor
            elseif Settings.BoxType == "Flat" then
                data.box.BackgroundTransparency = Settings.BoxTransparency
                data.box.BackgroundColor3 = Settings.BoxColor
                data.box.BorderSizePixel = 0
            end
            
            -- Name
            if Settings.ShowName then
                data.name.Visible = true
                data.name.Text = player.Name
                data.name.TextColor3 = Settings.NameColor
                data.name.Position = UDim2.new(0, box.X + box.Width/2, 0, box.Y - 15)
            else
                data.name.Visible = false
            end
            
            -- Distance
            if Settings.ShowDistance then
                data.dist.Visible = true
                data.dist.Text = math.floor(dist) .. "m"
                data.dist.TextColor3 = Settings.DistanceColor
                data.dist.Position = UDim2.new(0, box.X + box.Width/2, 0, box.Y - 5)
            else
                data.dist.Visible = false
            end
            
            -- Health
            if Settings.ShowHealthBar then
                local hpPercent = hum.Health / hum.MaxHealth
                local color = Settings.HealthColorGood:lerp(Settings.HealthColorBad, 1 - hpPercent)
                data.healthBar.Visible = true
                data.healthBar.Size = UDim2.new(hpPercent, 0, 0, 4)
                data.healthBar.Position = UDim2.new(0, box.X, 0, box.Y + box.Height)
                data.healthBar.BackgroundColor3 = color
                if Settings.ShowHealthText then
                    data.healthText.Visible = true
                    data.healthText.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                    data.healthText.Position = UDim2.new(0, box.X + box.Width/2, 0, box.Y + box.Height + 5)
                else
                    data.healthText.Visible = false
                end
            else
                data.healthBar.Visible = false
                data.healthText.Visible = false
            end
            
            -- Tracer
            if Settings.ShowTracer then
                local centerX = cam.ViewportSize.X / 2
                data.tracer.Visible = true
                data.tracer.Size = UDim2.new(0, 2, 0, box.Y + box.Height)
                data.tracer.Position = UDim2.new(0, centerX - 1, 0, 0)
                data.tracer.BackgroundColor3 = Settings.TracerColor
            else
                data.tracer.Visible = false
            end
            
            ::continue::
        end
        
        -- Cleanup
        for player, _ in pairs(espElements) do
            if not player.Parent then
                if espElements[player] and espElements[player].folder then
                    espElements[player].folder:Destroy()
                end
                espElements[player] = nil
            end
        end
    end
    
    -- === CREATE GUI ===
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
    titleBar.Text = "Ξ|Ω ESP — PREMIUM"
    titleBar.TextColor3 = Color3.fromRGB(0, 255, 255)
    titleBar.BackgroundTransparency = 1
    titleBar.TextSize = 18
    
    local closeBtn = Instance.new("TextButton", settingsFrame)
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    closeBtn.BackgroundTransparency = 1
    
    openBtn.MouseButton1Click:Connect(function()
        settingsFrame.Visible = not settingsFrame.Visible
    end)
    closeBtn.MouseButton1Click:Connect(function()
        settingsFrame.Visible = false
    end)
    
    gui = screenGui
    
    -- Start render
    renderConnection = RunService.RenderStepped:Connect(function()
        pcall(renderESP)
    end)
    
    print("Ξ|Ω ESP loaded — Delta compatible, line 1 safe")
end)()
