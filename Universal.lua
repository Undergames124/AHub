--[[
  MINT HUB v3.2.1 // MM2 Pure Farm (template, farm-only)
  Keyless. Без вебхуков. Без агрессивных функций.
  1) Сохрани как mint-hub.lua
  2) Загрузи на GitHub Gist / raw / свой хостинг
  3) Лоадер: loadstring(game:HttpGet("ТВОЯ_ССЫЛКА/mint-hub.lua"))()
  Места -- ADAPT поменяй под структуру своей карты.
  Kill All / Silent Aim / Kill Aura отсутствуют намеренно.
]]
getgenv().MintHub = getgenv().MintHub or {
  AutoFarm = true, FarmMode = "Legit",
  CoinRadius = 120, TeleportDelay = 0.35, WalkSpeed = 28,
  SmartRoute = true, AvoidPlayers = true, EventFarm = true,
  AutoChest = true, AutoPrestige = true, AntiAFK = true, AutoReconnect = true,
  ESPEnabled = true, Names = true, Distance = true, GunESP = true,
  StreamerMode = false, ChamsTransparency = 0.45, RenderDistance = 600,
  AntiFling = true, AntiVoid = true,
}
local C = getgenv().MintHub
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local function notify(t)
  pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification",{Title="MINT HUB",Text=tostring(t),Duration=3})
  end)
  print("[mint] "..tostring(t))
end
local function hrp()
  local ch = LocalPlayer.Character
  return ch and ch:FindFirstChild("HumanoidRootPart")
end
local function setSpeed()
  pcall(function()
    local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
    if h then h.WalkSpeed = math.clamp(C.WalkSpeed or 28, 16, 200) end
  end)
end
LocalPlayer.CharacterAdded:Connect(function() task.wait(1) setSpeed() end)
setSpeed()
-- Anti-AFK каждые 3-5 мин
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
      print("[mint] anti-afk micro-move")
    end
  end
end)
-- Anti-Void + Anti-Fling
local lastSafe=nil
RunService.Heartbeat:Connect(function()
  local r=hrp() if not r then return end
  if r.Position.Y>-20 then lastSafe=r.CFrame end
  if C.AntiVoid and r.Position.Y<-35 and lastSafe then
    r.CFrame=lastSafe+Vector3.new(0,5,0) r.AssemblyLinearVelocity=Vector3.zero
    notify("Anti-Void: возврат в сейф-зону")
  end
  if C.AntiFling then
    for _,p in ipairs(Players:GetPlayers()) do
      if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        local t=p.Character.HumanoidRootPart
        if (t.Position-r.Position).Magnitude<8 then
          pcall(function() t.AssemblyAngularVelocity=Vector3.zero end)
        end
      end
    end
  end
end)
-- Auto-Reconnect
pcall(function()
  game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(ch)
    if ch.Name=="ErrorPrompt" and C.AutoReconnect then
      task.wait(2) notify("Reconnect: новый сервер...") TeleportService:Teleport(game.PlaceId)
    end
  end)
end)
-- Поиск монет (ADAPT: добавь свою папку Coins)
local function findCoins()
  local out={} local root=hrp() if not root then return out end
  local seen={}
  for _,d in ipairs(workspace:GetDescendants()) do
    if d:IsA("BasePart") and not seen[d] then
      local nm=string.lower(d.Name)
      local isCoin=string.find(nm,"coin") or string.find(nm,"money") or string.find(nm,"beachball")
      local isEvent=C.EventFarm and (string.find(nm,"gift") or string.find(nm,"candy") or string.find(nm,"snow") or string.find(nm,"egg"))
      if isCoin or isEvent then
        local dist=(d.Position-root.Position).Magnitude
        if dist<=(C.CoinRadius or 120) then seen[d]=true table.insert(out,{part=d,dist=dist}) end
      end
    end
    if #out>60 then break end
  end
  if C.SmartRoute then table.sort(out,function(a,b) return a.dist<b.dist end) end
  return out
end
local function nearestPlayerDist(pos)
  local m=math.huge
  for _,p in ipairs(Players:GetPlayers()) do
    if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
      local d=(p.Character.HumanoidRootPart.Position-pos).Magnitude if d<m then m=d end
    end
  end
  return m
end
local function gotoCoin(coin)
  local r=hrp() if not r or not coin.part or not coin.part.Parent then return end
  local target=coin.part.CFrame+Vector3.new(0,3,0)
  if C.AvoidPlayers and nearestPlayerDist(target.Position)<6 then return end
  if C.FarmMode=="Rage" then r.CFrame=target
  else
    local dist=(target.Position-r.Position).Magnitude
    local t=math.clamp(dist/math.max(C.WalkSpeed,16),0.15,2.5)
    pcall(function() local tw=TweenService:Create(r,TweenInfo.new(t,Enum.EasingStyle.Linear),{CFrame=target}) tw:Play() tw.Completed:Wait() end)
  end
  task.wait(C.TeleportDelay or 0.35)
end
task.spawn(function()
  notify("Mint Hub loaded. Режим: "..tostring(C.FarmMode))
  while true do
    if C.AutoFarm then
      local ok,err=pcall(function()
        local coins=findCoins()
        if #coins==0 then task.wait(0.8) return end
        for i=1, math.min(8,#coins) do if not C.AutoFarm then break end gotoCoin(coins[i]) end
        -- ADAPT авто-сундук/престиж: remote:FireServer("OpenChest")
      end)
      if not ok then warn("[mint] farm err: "..tostring(err)) task.wait(1) end
    else task.wait(0.5) end
  end
end)
-- ESP только визуал
local espFolder=Instance.new("Folder") espFolder.Name="MintESP" espFolder.Parent=game:GetService("CoreGui")
local ROLE_COLOR={Murderer=Color3.fromRGB(255,59,59),Sheriff=Color3.fromRGB(59,130,246),Innocent=Color3.fromRGB(34,197,94)}
local function guessRole(plr)
  local function hasTool(nm)
    local bg=plr:FindFirstChild("Backpack") local ch=plr.Character
    if bg and bg:FindFirstChild(nm,true) then return true end
    if ch and ch:FindFirstChild(nm,true) then return true end
    return false
  end
  if hasTool("Knife") then return "Murderer" end
  if hasTool("Gun") or hasTool("Revolver") then return "Sheriff" end
  return "Innocent"
end
local function clearESP(plr)
  for _,v in ipairs(espFolder:GetChildren()) do if v:GetAttribute("P")==plr.UserId then v:Destroy() end end
end
local function makeESP(plr)
  if plr==LocalPlayer then return end
  clearESP(plr)
  local ch=plr.Character if not ch then return end
  local root=ch:FindFirstChild("HumanoidRootPart") if not root then return end
  local dist=hrp() and (root.Position-hrp().Position).Magnitude or 0
  if dist>(C.RenderDistance or 600) then return end
  if not C.ESPEnabled then return end
  local role=guessRole(plr) local col=ROLE_COLOR[role] or ROLE_COLOR.Innocent
  local hl=Instance.new("Highlight")
  hl:SetAttribute("P",plr.UserId) hl.FillColor=col hl.OutlineColor=col
  hl.FillTransparency=C.ChamsTransparency or 0.45 hl.OutlineTransparency=0
  hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop hl.Adornee=ch hl.Parent=espFolder
  local bb=Instance.new("BillboardGui")
  bb:SetAttribute("P",plr.UserId) bb.Size=UDim2.new(0,120,0,40)
  bb.StudsOffset=Vector3.new(0,3,0) bb.AlwaysOnTop=true
  bb.Adornee=ch:FindFirstChild("Head") or root bb.Parent=espFolder
  local nm=C.StreamerMode and "***" or plr.DisplayName
  local tl=Instance.new("TextLabel")
  tl.BackgroundTransparency=1 tl.Size=UDim2.new(1,0,1,0)
  tl.Font=Enum.Font.Code tl.TextSize=13 tl.TextStrokeTransparency=0.5
  local dtxt=C.Distance and (" ["..math.floor(dist).."m]") or ""
  tl.Text=((C.Names and (nm.." ") or "")..string.upper(role)..dtxt)
  tl.TextColor3=col tl.Parent=bb
end
task.spawn(function()
  while true do
    task.wait(1.2)
    if C.ESPEnabled then for _,p in ipairs(Players:GetPlayers()) do pcall(makeESP,p) end
    else espFolder:ClearAllChildren() end
  end
end)
Players.PlayerRemoving:Connect(clearESP)
-- Мини-окно
pcall(function()
  local gui=Instance.new("ScreenGui") gui.Name="MintHubUI" gui.ResetOnSpawn=false gui.Parent=game:GetService("CoreGui")
  local main=Instance.new("Frame")
  main.Size=UDim2.new(0,380,0,300) main.Position=UDim2.new(0.5,-190,0.5,-150)
  main.BackgroundColor3=Color3.fromRGB(14,14,20) main.BorderSizePixel=0 main.Active=true main.Draggable=true main.Parent=gui
  Instance.new("UICorner",main).CornerRadius=UDim.new(0,10)
  local title=Instance.new("TextLabel")
  title.Size=UDim2.new(1,0,0,32) title.BackgroundColor3=Color3.fromRGB(21,21,29)
  title.Text="  MINT HUB v3.2.1 - keyless - farm only" title.Font=Enum.Font.Code title.TextSize=13
  title.TextXAlignment=Enum.TextXAlignment.Left title.TextColor3=Color3.fromRGB(255,255,255) title.Parent=main
  Instance.new("UICorner",title).CornerRadius=UDim.new(0,10)
  local info=Instance.new("TextLabel")
  info.Position=UDim2.new(0,12,0,48) info.Size=UDim2.new(1,-24,1,-60) info.BackgroundTransparency=1
  info.TextWrapped=true info.TextYAlignment=Enum.TextYAlignment.Top info.TextXAlignment=Enum.TextXAlignment.Left
  info.Font=Enum.Font.Code info.TextSize=12 info.TextColor3=Color3.fromRGB(180,180,190)
  info.Text="Farming: "..tostring(C.FarmMode).." | R="..tostring(C.CoinRadius).." | D="..tostring(C.TeleportDelay).."s\\nESP: вкл | Мардер=красный Шериф=синий\\nRightShift - показать/скрыть\\n\\nНЕТ Kill All / Silent Aim / Aura."
  info.Parent=main
  game:GetService("UserInputService").InputBegan:Connect(function(i,g)
    if g then return end
    if i.KeyCode==Enum.KeyCode.RightShift then gui.Enabled=not gui.Enabled end
    if i.KeyCode==Enum.KeyCode.End then espFolder:ClearAllChildren() C.ESPEnabled=false end
  end)
end)
pcall(function()
  if writefile then
    task.spawn(function()
      while true do task.wait(15) pcall(function() writefile("MintHub_Config.json",game:GetService("HttpService"):JSONEncode(C)) end) end
    end)
  end
end)
notify("Mint Hub готов. Приятного фарма!")
