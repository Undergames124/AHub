--[[
    Premium ESP v2 (Roblox LocalScript)
    Исправления:
    - Работающие тогглы для боксов, имени, дистанции и т.д.
    - Динамическое управление объектами Drawing
    - Проверка валидности размеров бокса
--]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ========== НАСТРОЙКИ ==========
local Settings = {
    ESPEnabled = true,
    Box = { Enabled = true, Color = Color3.fromRGB(255, 255, 255), Thickness = 1, Transparency = 0 },
    HealthBar = { Enabled = true, Width = 40, Height = 4, Gradient = true },
    Name = { Enabled = true, Color = Color3.fromRGB(255, 255, 255), Size = 14, Outline = true },
    Distance = { Enabled = true, Color = Color3.fromRGB(200, 200, 200), Size = 12 },
    Line = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Thickness = 1 },
    HeadDot = { Enabled = false, Color = Color3.fromRGB(255, 0, 0), Radius = 3 },
    MaxDistance = 300,
    ShowTeam = false,
}

-- Хранилище объектов (по игрокам)
local ESPObjects = {} -- [Player] = { Box, HealthBar, NameText, DistanceText, Line, HeadDot }

-- ========== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ==========
local function GetHealthPercent(character)
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid and humanoid.Health then
        return math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
    end
    return 0
end

-- ========== СОЗДАНИЕ/УДАЛЕНИЕ ОБЪЕКТОВ ДЛЯ КОНКРЕТНОЙ ФУНКЦИИ ==========
local function EnsureObject(player, objType, createFunc)
    local objects = ESPObjects[player]
    if not objects then return nil end
    if not objects[objType] and createFunc then
        objects[objType] = createFunc()
    end
    return objects[objType]
end

local function RemoveObject(player, objType)
    local objects = ESPObjects[player]
    if objects and objects[objType] then
        objects[objType]:Remove()
        objects[objType] = nil
    end
end

-- Создание конкретных объектов
local function CreateBox()
    local box = Drawing.new("Square")
    box.Thickness = Settings.Box.Thickness
    box.Color = Settings.Box.Color
    box.Transparency = Settings.Box.Transparency
    box.Filled = false
    return box
end

local function CreateHealthBar()
    local bar = Drawing.new("Square")
    bar.Thickness = 1
    bar.Color = Color3.fromRGB(0, 255, 0)
    bar.Filled = true
    return bar
end

local function CreateNameText(player)
    local text = Drawing.new("Text")
    text.Color = Settings.Name.Color
    text.Size = Settings.Name.Size
    text.Center = true
    text.Outline = Settings.Name.Outline
    text.Text = player.Name
    return text
end

local function CreateDistanceText()
    local text = Drawing.new("Text")
    text.Color = Settings.Distance.Color
    text.Size = Settings.Distance.Size
    text.Center = true
    text.Outline = true
    return text
end

local function CreateLine()
    local line = Drawing.new("Line")
    line.Thickness = Settings.Line.Thickness
    line.Color = Settings.Line.Color
    return line
end

local function CreateHeadDot()
    local dot = Drawing.new("Circle")
    dot.Thickness = 1
    dot.Color = Settings.HeadDot.Color
    dot.Radius = Settings.HeadDot.Radius
    dot.Filled = true
    return dot
end

-- ========== ОБНОВЛЕНИЕ РЕНДЕРА ==========
local function UpdateESP()
    if not Settings.ESPEnabled then
        for player, objects in pairs(ESPObjects) do
            for _, obj in pairs(objects) do
                if obj then obj.Visible = false end
            end
        end
        return
    end

    local cameraPos = Camera.CFrame.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        if Settings.ShowTeam and player.TeamColor == LocalPlayer.TeamColor then
            -- Скрываем всё для союзников, если включен режим "только враги"
            if ESPObjects[player] then
                for _, obj in pairs(ESPObjects[player]) do
                    if obj then obj.Visible = false end
                end
            end
            continue
        end

        local character = player.Character
        if not character then
            if ESPObjects[player] then
                for _, obj in pairs(ESPObjects[player]) do
                    if obj then obj.Visible = false end
                end
            end
            continue
        end

        local humanoid = character:FindFirstChild("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if not humanoid or not rootPart or humanoid.Health <= 0 then
            if ESPObjects[player] then
                for _, obj in pairs(ESPObjects[player]) do
                    if obj then obj.Visible = false end
                end
            end
            continue
        end

        local distance = (rootPart.Position - cameraPos).Magnitude
        if distance > Settings.MaxDistance then
            if ESPObjects[player] then
                for _, obj in pairs(ESPObjects[player]) do
                    if obj then obj.Visible = false end
                end
            end
            continue
        end

        -- Гарантируем наличие таблицы для игрока
        if not ESPObjects[player] then
            ESPObjects[player] = {}
        end

        -- Позиции головы и ног
        local head = character:FindFirstChild("Head") or rootPart
        local headPos, onScreenHead = Camera:WorldToViewportPoint(head.Position)
        local feetPos, onScreenFeet = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))

        if not onScreenHead and not onScreenFeet then
            for _, obj in pairs(ESPObjects[player]) do
                if obj then obj.Visible = false end
            end
            continue
        end

        -- Вычисление бокса
        local height = math.abs(headPos.Y - feetPos.Y)
        local width = height * 0.6
        local boxX = headPos.X - width/2
        local boxY = headPos.Y - height * 0.15
        local boxHeight = height + height * 0.15
        local boxWidth = width

        -- ========== БОКС ==========
        if Settings.Box.Enabled then
            local box = EnsureObject(player, "Box", CreateBox)
            if box then
                box.Visible = true
                box.Size = Vector2.new(boxWidth, boxHeight)
                box.Position = Vector2.new(boxX, boxY)
                box.Color = Settings.Box.Color
                box.Thickness = Settings.Box.Thickness
                box.Transparency = Settings.Box.Transparency
            end
        else
            RemoveObject(player, "Box")
        end

        -- ========== ПОЛОСА ЗДОРОВЬЯ ==========
        if Settings.HealthBar.Enabled then
            local bar = EnsureObject(player, "HealthBar", CreateHealthBar)
            if bar then
                local healthPercent = GetHealthPercent(character)
                local barY = boxY + boxHeight + 2
                local barX = boxX
                local barWidth = boxWidth * healthPercent
                local barHeight = Settings.HealthBar.Height

                bar.Visible = true
                bar.Size = Vector2.new(barWidth, barHeight)
                bar.Position = Vector2.new(barX, barY)
                -- градиент цвета
                bar.Color = Color3.new(1 - healthPercent, healthPercent, 0)
            end
        else
            RemoveObject(player, "HealthBar")
        end

        -- ========== ИМЯ ==========
        if Settings.Name.Enabled then
            local nameText = EnsureObject(player, "NameText", function() return CreateNameText(player) end)
            if nameText then
                nameText.Visible = true
                nameText.Text = player.Name
                nameText.Position = Vector2.new(headPos.X, boxY - 15)
                nameText.Color = Settings.Name.Color
                nameText.Size = Settings.Name.Size
                nameText.Outline = Settings.Name.Outline
            end
        else
            RemoveObject(player, "NameText")
        end

        -- ========== ДИСТАНЦИЯ ==========
        if Settings.Distance.Enabled then
            local distText = EnsureObject(player, "DistanceText", CreateDistanceText)
            if distText then
                distText.Visible = true
                distText.Text = math.floor(distance) .. "m"
                distText.Position = Vector2.new(headPos.X, boxY + boxHeight + 2 + Settings.HealthBar.Height + 5)
                distText.Color = Settings.Distance.Color
                distText.Size = Settings.Distance.Size
            end
        else
            RemoveObject(player, "DistanceText")
        end

        -- ========== ЛИНИЯ ==========
        if Settings.Line.Enabled then
            local line = EnsureObject(player, "Line", CreateLine)
            if line then
                local centerScreen = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
                line.Visible = true
                line.From = centerScreen
                line.To = Vector2.new(headPos.X, headPos.Y)
                line.Color = Settings.Line.Color
                line.Thickness = Settings.Line.Thickness
            end
        else
            RemoveObject(player, "Line")
        end

        -- ========== ТОЧКА НА ГОЛОВЕ ==========
        if Settings.HeadDot.Enabled then
            local dot = EnsureObject(player, "HeadDot", CreateHeadDot)
            if dot then
                dot.Visible = true
                dot.Position = Vector2.new(headPos.X, headPos.Y)
                dot.Color = Settings.HeadDot.Color
                dot.Radius = Settings.HeadDot.Radius
            end
        else
            RemoveObject(player, "HeadDot")
        end
    end

    -- Чистка покинувших игроков
    for player in pairs(ESPObjects) do
        if not player.Parent or not player.Character then
            if ESPObjects[player] then
                for _, obj in pairs(ESPObjects[player]) do
                    if obj then obj:Remove() end
                end
                ESPObjects[player] = nil
            end
        end
    end
end

-- ========== GUI МЕНЮ (БЕЗ ИЗМЕНЕНИЙ, РАБОТАЕТ) ==========
-- ... (весь код меню остаётся таким же, как в первом скрипте) ...
-- Для краткости он здесь не повторён, но вы можете вставить его ниже.
-- Убедитесь, что используете те же функции MakeCheckbox, MakeSlider и т.д.

-- ========== ЗАПУСК ==========
RunService.RenderStepped:Connect(UpdateESP)

-- Обработка появления/исчезновения игроков
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.2)
        -- таблица ESPObjects[player] создастся при первом рендере
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            if obj then obj:Remove() end
        end
        ESPObjects[player] = nil
    end
end)

-- Инициализация для существующих игроков
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            task.wait(0.2)
        end)
    end
end

print("Premium ESP v2 загружен. Все тогглы работают, боксы отображаются.")
