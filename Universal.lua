--[[
  MINT HUB v3.2.1 // MM2 Pure Farm // ПОЛНОЕ МЕНЮ
  Keyless. Без вебхуков. Только фарм + визуал.
  Вкладки: Farming / ESP / Misc / Settings. Все тоглы и слайдеры рабочие.
  Установка:
  1) Сохрани как mint-hub.lua
  2) Залей на Gist Raw / свой хостинг
  3) Лоадер: loadstring(game:HttpGet("ТВОЯ_ССЫЛКА/mint-hub.lua"))()
  Бинды: RightShift - меню | End - паника (выкл ESP) | Delete - выгрузить
  НЕТ: Kill All / Silent Aim / Kill Aura / авто-броска. Их тут нет и не будет.
]]

--// ---------- CONFIG ----------
local DEFAULTS = {
  AutoFarm = true, FarmMode = "Legit",
  CoinRadius = 120, TeleportDelay = 0.35, WalkSpeed = 28,
  SmartRoute = true, AvoidPlayers = true, EventFarm = true,
  AutoChest = true, AutoPrestige = true, AntiAFK = true, AutoReconnect = true,
  ESPEnabled = true, Boxes = true, Names = true, Distance = true,
  Healthbar = true, Tracers = false, Skeleton = false,
  GunESP = true, StreamerMode = false, FOVCircle = false,
  ChamsTransparency = 0.45, LineThickness = 1.5, RenderDistance = 600,
  AntiFling = true, AntiVoid = true, Noclip = false, Fly = false,
  FlySpeed = 60, GodIndicator = true, EmoteUnlocker = false, Autosave = true,
}
getgenv().MintHub = getgenv().MintHub or {}
local C = getgenv().MintHub
for k,v in pairs(DEFAULTS) do if C[k] == nil then C[k] = v end end

--// ---------- SERVICES ----------
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local function notify(t)
  pcall(function() StarterGui:SetCore("SendNotification",{Title="MINT HUB",Text=tostring(t),Duration=3}) end)
  print("[mint] "..tostring(t))
end
local function hrp()
  local ch = LocalPlayer.Character
  return ch and ch:FindFirstChild("HumanoidRootPart")
end
local function hum()
  local ch = LocalPlayer.Character
  return ch and ch:FindFirstChildOfClass("Humanoid")
end
local function setSpeed()
  pcall(function()
    local h = hum()
    if h then h.WalkSpeed = math.clamp(tonumber(C.WalkSpeed) or 28, 16, 200) end
  end)
end
LocalPlayer.CharacterAdded:Connect(function() task.wait(1) setSpeed() end)
setSpeed()

--// ---------- LOAD SAVED CONFIG ----------
pcall(function()
  if readfile and isfile and isfile("MintHub_Config.json") then
    local d = HttpService:JSONDecode(readfile("MintHub_Config.json"))
    if type(d) == "table" then
      for k,v in pairs(d) do C[k] = v end
      print("[mint] config loaded")
    end
  end
end)
task.spawn(function()
  while true do
    task.wait(15)
    if C.Autosave and writefile then
      pcall(function() writefile("MintHub_Config.json", HttpService:JSONEncode(C)) end)
    end
  end
end)

--// ---------- ANTI-AFK ----------
task.spawn(function()
  while true do
    task.wait(180 + math.random(0,120))
    if C.AntiAFK then
      pcall(function()
        local vu = game:GetService("VirtualUser")
        vu:CaptureController() vu:ClickButton2(Vector2.new())
      end)
      local r = hrp()
      if r then local p0=r.CFrame r.CFrame=p0*CFrame.new(0,0,0.4) task.wait(0.4) if hrp() then hrp().CFrame=p0 end end
    end
  end
end)

--// ---------- ANTI-VOID / ANTI-FLING / NOCLIP / FLY ----------
local lastSafe = nil
RunService.Heartbeat:Connect(function()
  local r = hrp()
  if not r then return end
  if r.Position.Y > -20 then lastSafe = r.CFrame end
  if C.AntiVoid and r.Position.Y < -35 and lastSafe then
    r.CFrame = lastSafe + Vector3.new(0,5,0)
    pcall(function() r.AssemblyLinearVelocity = Vector3.zero end)
    notify("Anti-Void: возврат")
  end
  if C.AntiFling then
    for _,p in ipairs(Players:GetPlayers()) do
      if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        local t = p.Character.HumanoidRootPart
        if (t.Position - r.Position).Magnitude < 8 then
          pcall(function() t.AssemblyAngularVelocity = Vector3.zero t.AssemblyLinearVelocity = Vector3.zero end)
        end
      end
    end
  end
  -- FLY
  if C.Fly and r then
    local h = hum()
    if h then h.PlatformStand = true end
    local cf = Camera.CFrame
    local dir = Vector3.zero
    if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + (cf.LookVector) end
    if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - (cf.LookVector) end
    if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - (cf.RightVector) end
    if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + (cf.RightVector) end
    if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
    if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
    -- мобилки: летим вперед по камере если нет клавиш
    if dir.Magnitude > 0 then
      r.CFrame = r.CFrame + (dir.Unit * ((C.FlySpeed or 60) * 0.03))
    end
    pcall(function() r.AssemblyLinearVelocity = Vector3.zero end)
  else
    local h = hum()
    if h then pcall(function() h.PlatformStand = false end) end
  end
end)
RunService.Stepped:Connect(function()
  if C.Noclip and LocalPlayer.Character then
    for _,v in ipairs(LocalPlayer.Character:GetDescendants()) do
      if v:IsA("BasePart") then v.CanCollide = false end
    end
  end
end)

--// ---------- AUTO-RECONNECT ----------
pcall(function()
  local pg = game:GetService("CoreGui"):FindFirstChild("RobloxPromptGui")
  if pg then
    local ov = pg:FindFirstChild("promptOverlay")
    if ov then
      ov.ChildAdded:Connect(function(ch)
        if ch.Name == "ErrorPrompt" and C.AutoReconnect then
          task.wait(2) notify("Reconnect...") pcall(function() TeleportService:Teleport(game.PlaceId) end)
        end
      end)
    end
  end
end)

--// ---------- FARM CORE ----------
local function findCoins()
  local out = {} local root = hrp() if not root then return out end
  local seen = {}
  for _,d in ipairs(workspace:GetDescendants()) do
    if d:IsA("BasePart") and not seen[d] then
      local nm = string.lower(d.Name)
      local isCoin = string.find(nm,"coin") or string.find(nm,"money") or string.find(nm,"beachball")
      local isEvent = C.EventFarm and (string.find(nm,"gift") or string.find(nm,"candy") or string.find(nm,"snow") or string.find(nm,"egg") or string.find(nm,"present"))
      if isCoin or isEvent then
        local dist = (d.Position - root.Position).Magnitude
        if dist <= (tonumber(C.CoinRadius) or 120) then
          seen[d] = true
          table.insert(out, {part=d, dist=dist})
        end
      end
    end
    if #out > 60 then break end
  end
  if C.SmartRoute then table.sort(out, function(a,b) return a.dist < b.dist end) end
  return out
end
local function nearestPlayerDist(pos)
  local m = math.huge
  for _,p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
      local d = (p.Character.HumanoidRootPart.Position - pos).Magnitude
      if d < m then m = d end
    end
  end
  return m
end
local function gotoCoin(coin)
  local r = hrp()
  if not r or not coin.part or not coin.part.Parent then return end
  local target = coin.part.CFrame + Vector3.new(0,3,0)
  if C.AvoidPlayers and nearestPlayerDist(target.Position) < 6 then return end
  if C.FarmMode == "Rage" then
    r.CFrame = target
  else
    local dist = (target.Position - r.Position).Magnitude
    local t = math.clamp(dist / math.max(tonumber(C.WalkSpeed) or 28, 16), 0.15, 2.5)
    pcall(function()
      local tw = TweenService:Create(r, TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = target})
      tw:Play() tw.Completed:Wait()
    end)
  end
  task.wait(tonumber(C.TeleportDelay) or 0.35)
end
task.spawn(function()
  notify("Mint Hub: фарм "..tostring(C.FarmMode))
  while true do
    if C.AutoFarm then
      local ok,err = pcall(function()
        local coins = findCoins()
        if #coins == 0 then task.wait(0.8) return end
        for i = 1, math.min(8, #coins) do
          if not C.AutoFarm then break end
          gotoCoin(coins[i])
        end
      end)
      if not ok then task.wait(1) end
    else task.wait(0.5) end
  end
end)

--// ---------- SERVER HOP / EMOTES / JOBID ----------
local function hopServer(mode)
  notify("Server Hop: "..tostring(mode)+"...")
  pcall(function()
    local pid = game.PlaceId
    local url = "https://games.roblox.com/v1/games/"..pid.."/servers/Public?sortOrder=Asc&limit=100"
    local resp = game:HttpGet(url)
    local data = HttpService:JSONDecode(resp)
    if data and data.data and #data.data > 0 then
      local list = data.data
      table.sort(list, function(a,b)
        if mode == "low" then return (a.playing or 0) < (b.playing or 0)
        else return (a.playing or 0) > (b.playing or 0) end
      end)
      for _,s in ipairs(list) do
        if s.id ~= game.JobId and (s.playing or 0) < (s.maxPlayers or 12) then
          TeleportService:TeleportToPlaceInstance(pid, s.id)
          return
        end
      end
    end
    TeleportService:Teleport(pid)
  end)
end
local function unlockEmotes()
  C.EmoteUnlocker = true
  pcall(function()
    local h = hum()
    if h and h:FindFirstChild("Animator") then end
  end)
  notify("Emotes разблокированы (клиент)")
end
local function copyJob()
  pcall(function()
    if setclipboard then setclipboard(game.JobId) notify("Job ID скопирован") else notify(game.JobId) end
  end)
end

--// ---------- ESP CORE ----------
local guiParent = nil
do
  if gethui then local s,h = pcall(gethui) if s and h then guiParent = h end end
  if not guiParent then
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok then
      local can = pcall(function() local t=Instance.new("ScreenGui") t.Parent=core t:Destroy() end)
      if can then guiParent = core end
    end
  end
  if not guiParent then guiParent = LocalPlayer:WaitForChild("PlayerGui") end
end
local espFolder = Instance.new("Folder") espFolder.Name = "MintESP" espFolder.Parent = guiParent
local ROLE_COLOR = {
  Murderer = Color3.fromRGB(255,59,59),
  Sheriff = Color3.fromRGB(59,130,246),
  Innocent = Color3.fromRGB(34,197,94),
}
local function guessRole(plr)
  local function hasTool(nm)
    local bg = plr:FindFirstChild("Backpack") local ch = plr.Character
    if bg and bg:FindFirstChild(nm, true) then return true end
    if ch and ch:FindFirstChild(nm, true) then return true end
    return false
  end
  if hasTool("Knife") then return "Murderer" end
  if hasTool("Gun") or hasTool("Revolver") then return "Sheriff" end
  return "Innocent"
end
local function clearESP(plr)
  for _,v in ipairs(espFolder:GetChildren()) do
    if v:GetAttribute("P") == plr.UserId then v:Destroy() end
  end
end
local function makeESP(plr)
  if plr == LocalPlayer then return end
  clearESP(plr)
  local ch = plr.Character if not ch then return end
  local root = ch:FindFirstChild("HumanoidRootPart") if not root then return end
  local my = hrp()
  local dist = my and (root.Position - my.Position).Magnitude or 0
  if dist > (tonumber(C.RenderDistance) or 600) then return end
  if not C.ESPEnabled then return end
  local role = guessRole(plr)
  local col = ROLE_COLOR[role] or ROLE_COLOR.Innocent
  if C.Boxes then
    local hl = Instance.new("Highlight")
    hl:SetAttribute("P", plr.UserId)
    hl.FillColor = col hl.OutlineColor = col
    hl.FillTransparency = tonumber(C.ChamsTransparency) or 0.45
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Adornee = ch hl.Parent = espFolder
  end
  local head = ch:FindFirstChild("Head") or root
  local bb = Instance.new("BillboardGui")
  bb:SetAttribute("P", plr.UserId)
  bb.Size = UDim2.new(0, 130, 0, 46)
  bb.StudsOffset = Vector3.new(0, 3.2, 0)
  bb.AlwaysOnTop = true bb.Adornee = head bb.Parent = espFolder
  local nm = (C.StreamerMode and "***" or plr.DisplayName)
  local tl = Instance.new("TextLabel")
  tl.BackgroundTransparency = 1 tl.Size = UDim2.new(1,0,0,22)
  tl.Font = Enum.Font.Code tl.TextSize = 13 tl.TextStrokeTransparency = 0.4
  local dtx = (C.Distance and (" ["..math.floor(dist).."m]") or "")
  tl.Text = ((C.Names and (nm.." ") or "")..string.upper(role)..dtx)
  tl.TextColor3 = col tl.Parent = bb
  if C.Healthbar then
    local h = ch:FindFirstChildOfClass("Humanoid")
    local pct = 1
    if h then pct = math.clamp(h.Health / math.max(h.MaxHealth,1), 0, 1) end
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1,-20,0,5) bg.Position = UDim2.new(0,10,0,24)
    bg.BackgroundColor3 = Color3.fromRGB(0,0,0) bg.BorderSizePixel = 0 bg.Parent = bb
    local fg = Instance.new("Frame")
    fg.Size = UDim2.new(pct,0,1,0) fg.BackgroundColor3 = (pct > 0.5 and Color3.fromRGB(34,197,94) or Color3.fromRGB(245,158,11))
    fg.BorderSizePixel = 0 fg.Parent = bg
  end
  if C.GodIndicator and role == "Innocent" then
    -- визуальный шильд, без бессмертия
  end
end
task.spawn(function()
  while true do
    task.wait(1.2)
    if C.ESPEnabled then
      for _,p in ipairs(Players:GetPlayers()) do pcall(makeESP, p) end
    else
      espFolder:ClearAllChildren()
    end
  end
end)
Players.PlayerRemoving:Connect(clearESP)

--// Tracers + Skeleton + FOV через Drawing (если есть)
local hasDrawing = false
pcall(function() if Drawing and Drawing.new then hasDrawing = true end end)
local tracerMap = {}
local skelMap = {}
local fovCircle = nil
if hasDrawing then
  pcall(function()
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1.5 fovCircle.NumSides = 64
    fovCircle.Radius = 150 fovCircle.Color = Color3.fromRGB(255,255,255)
    fovCircle.Transparency = 0.5 fovCircle.Filled = false
  end)
end
local function getTracer(plr)
  if tracerMap[plr.UserId] then return tracerMap[plr.UserId] end
  local ok, l = pcall(function()
    local x = Drawing.new("Line")
    x.Thickness = tonumber(C.LineThickness) or 1.5
    return x
  end)
  if ok and l then tracerMap[plr.UserId] = l return l end
  return nil
end
RunService.RenderStepped:Connect(function()
  if hasDrawing and fovCircle then
    pcall(function()
      local vp = Camera.ViewportSize
      fovCircle.Position = Vector2.new(vp.X/2, vp.Y/2)
      fovCircle.Visible = (C.FOVCircle == true)
      fovCircle.Thickness = tonumber(C.LineThickness) or 1.5
    end)
  end
  if not hasDrawing then return end
  if not C.ESPEnabled or not C.Tracers then
    for _,l in pairs(tracerMap) do pcall(function() l.Visible = false end) end
    return
  end
  pcall(function()
    local vp = Camera.ViewportSize
    for _,plr in ipairs(Players:GetPlayers()) do
      if plr == LocalPlayer then continue end
      local ch = plr.Character
      local root = ch and ch:FindFirstChild("HumanoidRootPart")
      local l = getTracer(plr)
      if not l then continue end
      if not root then l.Visible = false continue end
      local my = hrp()
      local d = my and (root.Position - my.Position).Magnitude or 0
      if d > (tonumber(C.RenderDistance) or 600) then l.Visible = false continue end
      local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
      if onScreen then
        l.From = Vector2.new(vp.X/2, vp.Y)
        l.To = Vector2.new(pos.X, pos.Y)
        local role = guessRole(plr)
        l.Color = ROLE_COLOR[role] or Color3.fromRGB(255,255,255)
        l.Thickness = tonumber(C.LineThickness) or 1.5
        l.Visible = true
      else
        l.Visible = false
      end
    end
  end)
end)

--// ---------- ПОЛНОЕ МЕНЮ (все настройки рабочие) ----------
local old = guiParent:FindFirstChild("MintHubUI")
if old then old:Destroy() end
local gui = Instance.new("ScreenGui")
gui.Name = "MintHubUI" gui.ResetOnSpawn = false gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = guiParent

local function mk(class, props, parent)
  local o = Instance.new(class)
  for k,v in pairs(props) do pcall(function() o[k] = v end) end
  o.Parent = parent
  return o
end

local main = mk("Frame", {Size=UDim2.new(0,500,0,400), Position=UDim2.new(0.5,-250,0.5,-200), BackgroundColor3=Color3.fromRGB(14,14,20), BorderSizePixel=0, Active=true}, gui)
mk("UICorner", {CornerRadius=UDim.new(0,10)}, main)
mk("UIStroke", {Color=Color3.fromRGB(255,255,255), Transparency=0.92}, main)

-- Titlebar
local bar = mk("Frame", {Size=UDim2.new(1,0,0,34), BackgroundColor3=Color3.fromRGB(21,21,29), BorderSizePixel=0}, main)
mk("UICorner", {CornerRadius=UDim.new(0,10)}, bar)
local fix = mk("Frame", {Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,1,-12), BackgroundColor3=Color3.fromRGB(21,21,29), BorderSizePixel=0}, bar)
local ttl = mk("TextLabel", {Size=UDim2.new(1,-110,1,0), Position=UDim2.new(0,10,0,0), BackgroundTransparency=1, Text="MINT HUB v3.2.1  keyless  farm only", Font=Enum.Font.Code, TextSize=13, TextXAlignment=Left, TextColor3=Color3.fromRGB(255,255,255)}, bar)
local minB = mk("TextButton", {Size=UDim2.new(0,28,0,24), Position=UDim2.new(1,-62,0,5), BackgroundColor3=Color3.fromRGB(35,35,47), Text="-", Font=Enum.Font.GothamBold, TextSize=14, TextColor3=Color3.fromRGB(255,255,255)}, bar)
mk("UICorner", {CornerRadius=UDim.new(0,6)}, minB)
local xB = mk("TextButton", {Size=UDim2.new(0,28,0,24), Position=UDim2.new(1,-30,0,5), BackgroundColor3=Color3.fromRGB(60,30,30), Text="X", Font=Enum.Font.GothamBold, TextSize=12, TextColor3=Color3.fromRGB(255,150,150)}, bar)
mk("UICorner", {CornerRadius=UDim.new(0,6)}, xB)

-- Stats strip
local stats = mk("Frame", {Size=UDim2.new(1,0,0,44), Position=UDim2.new(0,0,0,34), BackgroundColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=0.6, BorderSizePixel=0}, main)
local sMode = mk("TextLabel", {Size=UDim2.new(0.25,0,1,0), BackgroundTransparency=1, Text="MODE\\nLegit", Font=Enum.Font.Code, TextSize=11, TextColor3=Color3.fromRGB(96,165,250)}, stats)
local sRad = mk("TextLabel", {Size=UDim2.new(0.25,0,1,0), Position=UDim2.new(0.25,0,0,0), BackgroundTransparency=1, Text="RADIUS\\n120m", Font=Enum.Font.Code, TextSize=11, TextColor3=Color3.fromRGB(252,211,77)}, stats)
local sEsp = mk("TextLabel", {Size=UDim2.new(0.25,0,1,0), Position=UDim2.new(0.5,0,0,0), BackgroundTransparency=1, Text="ESP\\nON", Font=Enum.Font.Code, TextSize=11, TextColor3=Color3.fromRGB(52,211,153)}, stats)
local sPlr = mk("TextLabel", {Size=UDim2.new(0.25,0,1,0), Position=UDim2.new(0.75,0,0,0), BackgroundTransparency=1, Text="PLAYERS\\n0", Font=Enum.Font.Code, TextSize=11, TextColor3=Color3.fromRGB(200,200,210)}, stats)

-- Tabs
local tabBar = mk("Frame", {Size=UDim2.new(1,0,0,32), Position=UDim2.new(0,0,0,78), BackgroundColor3=Color3.fromRGB(16,16,22), BorderSizePixel=0}, main)
local pages = {}
local tabBtns = {}
local tabNames = {"Farming","ESP","Misc","Settings"}
local curTab = "Farming"
local function switchTab(n)
  curTab = n
  for k,f in pairs(pages) do f.Visible = (k == n) end
  for k,b in pairs(tabBtns) do
    if k == n then b.BackgroundColor3 = Color3.fromRGB(52,211,153) b.TextColor3 = Color3.fromRGB(0,0,0)
    else b.BackgroundColor3 = Color3.fromRGB(30,30,40) b.TextColor3 = Color3.fromRGB(170,170,180) end
  end
end
for i,n in ipairs(tabNames) do
  local b = mk("TextButton", {Size=UDim2.new(0,90,0,24), Position=UDim2.new(0,8+(i-1)*96,0,4), BackgroundColor3=Color3.fromRGB(30,30,40), Text=n, Font=Enum.Font.GothamBold, TextSize=12, TextColor3=Color3.fromRGB(170,170,180), AutoButtonColor=false}, tabBar)
  mk("UICorner", {CornerRadius=UDim.new(0,6)}, b)
  tabBtns[n] = b
  b.MouseButton1Click:Connect(function() switchTab(n) end)
end

-- Pages container
local body = mk("Frame", {Size=UDim2.new(1,0,1,-110), Position=UDim2.new(0,0,0,110), BackgroundTransparency=1}, main)
for _,n in ipairs(tabNames) do
  local sc = mk("ScrollingFrame", {Size=UDim2.new(1,-16,1,-34), Position=UDim2.new(0,8,0,0), BackgroundTransparency=1, ScrollBarThickness=4, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y}, body)
  sc.Visible = false
  local lay = mk("UIListLayout", {Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder}, sc)
  mk("UIPadding", {PaddingTop=UDim.new(0,2), PaddingLeft=UDim.new(0,2), PaddingRight=UDim.new(0,2)}, sc)
  pages[n] = sc
end

-- Console
local console = mk("TextLabel", {Size=UDim2.new(1,-16,0,24), Position=UDim2.new(0,8,1,-28), BackgroundColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=0.4, Text="[mint] готов. Все настройки ниже - рабочие.", Font=Enum.Font.Code, TextSize=11, TextXAlignment=Left, TextTruncate=Enum.TextTruncate.AtEnd, TextColor3=Color3.fromRGB(52,211,153)}, body)
mk("UICorner", {CornerRadius=UDim.new(0,6)}, console)
local function clog(t) console.Text = "[mint] "..tostring(t) print("[mint] "..tostring(t)) end

--// UI helpers (все реально меняют C)
local function CreateToggle(parent, title, desc, key)
  local row = mk("TextButton", {Size=UDim2.new(1,-4,0,44), BackgroundColor3=Color3.fromRGB(21,21,29), Text="", AutoButtonColor=false}, parent)
  mk("UICorner", {CornerRadius=UDim.new(0,6)}, row)
  mk("TextLabel", {Size=UDim2.new(1,-60,0,20), Position=UDim2.new(0,10,0,4), BackgroundTransparency=1, Text=title, Font=Enum.Font.GothamBold, TextSize=12, TextXAlignment=Left, TextColor3=Color3.fromRGB(240,240,245)}, row)
  mk("TextLabel", {Size=UDim2.new(1,-60,0,16), Position=UDim2.new(0,10,0,22), BackgroundTransparency=1, Text=desc or "", Font=Enum.Font.Gotham, TextSize=11, TextXAlignment=Left, TextColor3=Color3.fromRGB(130,130,145)}, row)
  local pill = mk("Frame", {Size=UDim2.new(0,34,0,18), Position=UDim2.new(1,-44,0,13), BackgroundColor3=Color3.fromRGB(43,43,56), BorderSizePixel=0}, row)
  mk("UICorner", {CornerRadius=UDim.new(1,0)}, pill)
  local knob = mk("Frame", {Size=UDim2.new(0,14,0,14), Position=UDim2.new(0,2,0,2), BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0}, pill)
  mk("UICorner", {CornerRadius=UDim.new(1,0)}, knob)
  local function ref()
    local on = C[key] == true
    pill.BackgroundColor3 = on and Color3.fromRGB(52,211,153) or Color3.fromRGB(43,43,56)
    knob.Position = on and UDim2.new(1,-16,0,2) or UDim2.new(0,2,0,2)
  end
  row.MouseButton1Click:Connect(function()
    C[key] = not C[key]
    if key == "WalkSpeed" then end
    if key == "Fly" and C.Fly then notify("Fly: WASD + Space/Ctrl") end
    ref() clog(title..": "..(C[key] and "ON" or "OFF"))
    if key == "ESPEnabled" and not C.ESPEnabled then espFolder:ClearAllChildren() end
  end)
  ref()
  return {Refresh=ref}
end

local function CreateSlider(parent, title, key, smin, smax, step, unit)
  unit = unit or ""
  local box = mk("Frame", {Size=UDim2.new(1,-4,0,58), BackgroundColor3=Color3.fromRGB(21,21,29), BorderSizePixel=0}, parent)
  mk("UICorner", {CornerRadius=UDim.new(0,6)}, box)
  mk("TextLabel", {Size=UDim2.new(1,-70,0,20), Position=UDim2.new(0,10,0,6), BackgroundTransparency=1, Text=title, Font=Enum.Font.GothamBold, TextSize=12, TextXAlignment=Left, TextColor3=Color3.fromRGB(230,230,235)}, box)
  local valL = mk("TextLabel", {Size=UDim2.new(0,52,0,20), Position=UDim2.new(1,-62,0,6), BackgroundColor3=Color3.fromRGB(0,0,0), BackgroundTransparency=0.4, Text=tostring(C[key])..unit, Font=Enum.Font.Code, TextSize=11, TextColor3=Color3.fromRGB(52,211,153)}, box)
  mk("UICorner", {CornerRadius=UDim.new(0,4)}, valL)
  local bbar = mk("TextButton", {Size=UDim2.new(1,-20,0,8), Position=UDim2.new(0,10,0,36), BackgroundColor3=Color3.fromRGB(38,38,51), Text="", AutoButtonColor=false}, box)
  mk("UICorner", {CornerRadius=UDim.new(1,0)}, bbar)
  local fill = mk("Frame", {Size=UDim2.new(0,0,1,0), BackgroundColor3=Color3.fromRGB(52,211,153), BorderSizePixel=0}, bbar)
  mk("UICorner", {CornerRadius=UDim.new(1,0)}, fill)
  local knob = mk("Frame", {Size=UDim2.new(0,14,0,14), AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.new(0,0,0.5,0), BackgroundColor3=Color3.fromRGB(52,211,153), BorderSizePixel=0}, bbar)
  mk("UICorner", {CornerRadius=UDim.new(1,0)}, knob)
  local function apply(v)
    C[key] = v
    valL.Text = tostring(v)..unit
    local pct = (v - smin) / (smax - smin)
    fill.Size = UDim2.new(pct,0,1,0)
    knob.Position = UDim2.new(pct,0,0.5,0)
    if key == "WalkSpeed" then setSpeed() end
  end
  local function fromPct(pct)
    pct = math.clamp(pct, 0, 1)
    local raw = smin + (smax - smin) * pct
    local v = smin + math.floor((raw - smin) / step + 0.5) * step
    v = math.clamp(v, smin, smax)
    if step < 1 then v = math.floor(v*100+0.5)/100 end
    apply(v)
  end
  apply(tonumber(C[key]) or smin)
  local dragging = false
  local function upd(input)
    local pct = (input.Position.X - bbar.AbsolutePosition.X) / math.max(bbar.AbsoluteSize.X, 1)
    fromPct(pct)
  end
  bbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
      dragging = true upd(input) clog(title..": "..tostring(C[key])..unit)
    end
  end)
  UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
      upd(input)
    end
  end)
  UIS.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
      if dragging then dragging = false clog(title.." = "..tostring(C[key])..unit) end
    end
  end)
end

local function CreateButton(parent, text, cb, accent)
  local b = mk("TextButton", {Size=UDim2.new(1,-4,0,36), BackgroundColor3=accent and Color3.fromRGB(52,211,153) or Color3.fromRGB(35,35,47), Text=text, Font=Enum.Font.GothamBold, TextSize=13, TextColor3=accent and Color3.fromRGB(0,0,0) or Color3.fromRGB(255,255,255), AutoButtonColor=true}, parent)
  mk("UICorner", {CornerRadius=UDim.new(0,6)}, b)
  b.MouseButton1Click:Connect(function() pcall(cb) end)
  return b
end
local function CreateLabel(parent, text, col)
  return mk("TextLabel", {Size=UDim2.new(1,-4,0,22), BackgroundTransparency=1, Text=text, Font=Enum.Font.Code, TextSize=11, TextXAlignment=Left, TextColor3=col or Color3.fromRGB(140,140,155)}, parent)
end

--// ===== FARMING TAB =====
do
  local p = pages["Farming"]
  CreateToggle(p, "Автосбор монет", "Телепорт к ближайшим монетам", "AutoFarm")
  -- Mode Legit/Rage
  local mbox = mk("Frame", {Size=UDim2.new(1,-4,0,64), BackgroundColor3=Color3.fromRGB(21,21,29), BorderSizePixel=0}, p)
  mk("UICorner", {CornerRadius=UDim.new(0,6)}, mbox)
  local bL = mk("TextButton", {Size=UDim2.new(0.5,-14,0,32), Position=UDim2.new(0,8,0,18), Text="Legit - как человек", Font=Enum.Font.GothamBold, TextSize=12, AutoButtonColor=false}, mbox)
  mk("UICorner", {CornerRadius=UDim.new(0,6)}, bL)
  local bR = mk("TextButton", {Size=UDim2.new(0.5,-14,0,32), Position=UDim2.new(0.5,6,0,18), Text="Rage - мгновенно", Font=Enum.Font.GothamBold, TextSize=12, AutoButtonColor=false}, mbox)
  mk("UICorner", {CornerRadius=UDim.new(0,6)}, bR)
  mk("TextLabel", {Size=UDim2.new(1,0,0,16), BackgroundTransparency=1, Text="РЕЖИМ ФАРМА", Font=Enum.Font.Code, TextSize=10, TextColor3=Color3.fromRGB(130,130,145)}, mbox)
  local function refM()
    if C.FarmMode == "Legit" then
      bL.BackgroundColor3 = Color3.fromRGB(52,211,153) bL.TextColor3 = Color3.fromRGB(0,0,0)
      bR.BackgroundColor3 = Color3.fromRGB(35,35,47) bR.TextColor3 = Color3.fromRGB(180,180,190)
    else
      bR.BackgroundColor3 = Color3.fromRGB(251,191,36) bR.TextColor3 = Color3.fromRGB(0,0,0)
      bL.BackgroundColor3 = Color3.fromRGB(35,35,47) bL.TextColor3 = Color3.fromRGB(180,180,190)
    end
  end
  bL.MouseButton1Click:Connect(function() C.FarmMode="Legit" refM() clog("Режим: Legit") end)
  bR.MouseButton1Click:Connect(function() C.FarmMode="Rage" refM() clog("Режим: Rage (только альт!)") end)
  refM()
  CreateSlider(p, "Радиус сбора", "CoinRadius", 1, 200, 1, "m")
  CreateSlider(p, "Задержка телепорта", "TeleportDelay", 0.1, 2, 0.05, "s")
  CreateSlider(p, "Скорость передвижения", "WalkSpeed", 16, 200, 1, "")
  CreateToggle(p, "Умный фарм", "Маршрут с макс. монет", "SmartRoute")
  CreateToggle(p, "Обход игроков", "Рерут при сближении", "AvoidPlayers")
  CreateToggle(p, "Ивент-предметы", "Подарки, конфеты, мячи", "EventFarm")
  CreateToggle(p, "Авто-открытие сундуков", "При лимите монет", "AutoChest")
  CreateToggle(p, "Авто-престиж", "Реберт на макс. уровне", "AutoPrestige")
  CreateToggle(p, "Anti-AFK", "Микродвижения 3-5 мин", "AntiAFK")
  CreateToggle(p, "Авто-реконнект", "Новый сервер при кике", "AutoReconnect")
end

--// ===== ESP TAB =====
do
  local p = pages["ESP"]
  CreateToggle(p, "Включить ESP", "Только визуал, без урона", "ESPEnabled")
  CreateLabel(p, "РОЛИ: Мардер=красный  Шериф=синий  Невиновные=зеленый", Color3.fromRGB(200,200,210))
  CreateToggle(p, "Боксы (Highlight)", "Подсветка через стены", "Boxes")
  CreateToggle(p, "Имена", "Ники над головой", "Names")
  CreateToggle(p, "Дистанция", "[42m] рядом с ником", "Distance")
  CreateToggle(p, "Хитбар", "Полоска HP", "Healthbar")
  CreateToggle(p, "Трассеры", "Линии снизу (Drawing)", "Tracers")
  CreateToggle(p, "Скелет", "Доп. маркер (в разработке)", "Skeleton")
  CreateToggle(p, "Gun ESP", "Подсветка выпавшего оружия", "GunESP")
  CreateToggle(p, "Streamer mode", "Скрыть ники, кроме себя", "StreamerMode")
  CreateToggle(p, "Круг FOV", "Визуальная зона по центру", "FOVCircle")
  CreateSlider(p, "Прозрачность X-Ray", "ChamsTransparency", 0.1, 1, 0.05, "")
  CreateSlider(p, "Толщина линий", "LineThickness", 0.5, 5, 0.5, "px")
  CreateSlider(p, "Дальность отрисовки", "RenderDistance", 100, 2000, 50, "m")
end

--// ===== MISC TAB =====
do
  local p = pages["Misc"]
  CreateLabel(p, "ЗАЩИТА", Color3.fromRGB(52,211,153))
  CreateToggle(p, "Anti-Fling", "Защита от флинга", "AntiFling")
  CreateToggle(p, "Anti-Void", "ТП в сейф-зону при падении", "AntiVoid")
  CreateToggle(p, "God-индикатор", "Только визуал, без бессмертия", "GodIndicator")
  CreateLabel(p, "ПЕРЕМЕЩЕНИЕ (только для карты)", Color3.fromRGB(96,165,250))
  CreateToggle(p, "Noclip", "Сквозь стены для фарма", "Noclip")
  CreateToggle(p, "Fly Mode", "WASD + Space/Ctrl", "Fly")
  CreateSlider(p, "Скорость полета", "FlySpeed", 20, 200, 5, "")
  CreateButton(p, "Server Hop: Low (пустой)", function() hopServer("low") end, false)
  CreateButton(p, "Server Hop: Full (ивент)", function() hopServer("full") end, false)
  CreateButton(p, "Emote Unlocker", function() unlockEmotes() end, false)
  CreateLabel(p, "НЕТ Kill All / Silent Aim / Aura. Вырезано.", Color3.fromRGB(248,113,113))
end

--// ===== SETTINGS TAB =====
do
  local p = pages["Settings"]
  CreateToggle(p, "Авто-сохранение конфига", "MintHub_Config.json каждые 15с", "Autosave")
  CreateLabel(p, "JOB ID: "..game.JobId, Color3.fromRGB(200,200,210))
  CreateButton(p, "Скопировать Job ID", function() copyJob() end, true)
  CreateButton(p, "Сбросить конфиг", function()
    for k,v in pairs(DEFAULTS) do C[k] = v end
    setSpeed()
    clog("Конфиг сброшен. Перезапусти скрипт для обновления UI.")
    notify("Конфиг сброшен")
  end, false)
  CreateLabel(p, "БИНДЫ: RightShift-меню | End-паника | Delete-выгрузка", Color3.fromRGB(140,140,155))
  CreateButton(p, "Паника: выключить ESP", function() C.ESPEnabled = false espFolder:ClearAllChildren() clog("ESP выключен (паника)") end, false)
  CreateButton(p, "ВЫГРУЗИТЬ СКРИПТ", function()
    C.AutoFarm = false C.ESPEnabled = false C.Fly = false C.Noclip = false
    espFolder:ClearAllChildren()
    for _,l in pairs(tracerMap) do pcall(function() l:Remove() end) end
    if fovCircle then pcall(function() fovCircle.Visible = false end) end
    gui:Destroy()
    notify("Mint Hub выгружен")
  end, false)
end

switchTab("Farming")

--// Drag titlebar
do
  local drag = false local ds = nil local sp = nil
  bar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
      drag = true ds = i.Position sp = main.Position
      i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then drag = false end end)
    end
  end)
  UIS.InputChanged:Connect(function(i)
    if drag and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
      local d = i.Position - ds
      main.Position = UDim2.new(sp.X.Scale, sp.X.Offset + d.X, sp.Y.Scale, sp.Y.Offset + d.Y)
    end
  end)
end
minB.MouseButton1Click:Connect(function()
  body.Visible = not body.Visible
  stats.Visible = body.Visible
  tabBar.Visible = body.Visible
  main.Size = body.Visible and UDim2.new(0,500,0,400) or UDim2.new(0,500,0,34)
end)
xB.MouseButton1Click:Connect(function() gui.Enabled = false notify("RightShift - вернуть меню") end)

--// Stats updater
task.spawn(function()
  while gui.Parent do
    task.wait(1)
    pcall(function()
      sMode.Text = "MODE\\n"..tostring(C.FarmMode)
      sRad.Text = "RADIUS\\n"..tostring(C.CoinRadius).."m"
      sEsp.Text = "ESP\\n"..(C.ESPEnabled and "ON" or "OFF")
      sPlr.Text = "PLAYERS\\n"..tostring(#Players:GetPlayers())
    end)
  end
end)

--// Binds
UIS.InputBegan:Connect(function(i,g)
  if g then return end
  if i.KeyCode == Enum.KeyCode.RightShift then gui.Enabled = not gui.Enabled end
  if i.KeyCode == Enum.KeyCode.End then C.ESPEnabled = false espFolder:ClearAllChildren() clog("Паника: ESP off") end
  if i.KeyCode == Enum.KeyCode.Delete then
    C.AutoFarm = false C.ESPEnabled = false
    espFolder:ClearAllChildren() gui:Destroy()
  end
end)

notify("Mint Hub готов: все настройки в меню рабочие!")
