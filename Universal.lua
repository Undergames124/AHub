--[[
================================================================================
  ███╗   ███╗███╗   ███╗██████╗     ██╗  ██╗██╗   ██╗██████╗
  ████╗ ████║████╗ ████║██╔══██╗    ██║  ██║██║   ██║██╔══██╗
  ██╔████╔██║██╔████╔██║██████╔╝    ███████║██║   ██║██████╔╝
  ██║╚██╔╝██║██║╚██╔╝██║██╔══██╗    ██╔══██║██║   ██║██╔═══╝
  ██║ ╚═╝ ██║██║ ╚═╝ ██║██████╔╝    ██║  ██║╚██████╔╝██║
  ╚═╝     ╚═╝╚═╝     ╚═╝╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝
--------------------------------------------------------------------------------
  MM2 HUB X  •  v2.6.0  •  KEYLESS  •  Murder Mystery 2
--------------------------------------------------------------------------------
  Совместимость : Solara, Xeno, Delta, Fluxus, KRNL, Wave, Cryptic,
                  Hydrogen, Codex, Arceus X, Synapse Z, Script-Ware, Swift
  Приватность   : keyless, 0 вебхуков, 0 внешних HTTP-запросов,
                  не читает и не отправляет cookie/токены.
  Источники идей: Metan Hub, Mozql Hub, Rubis Hub, YAS, Deadshot
  ВНИМАНИЕ      : использование читов нарушает правила Roblox.
                  Всё, что вы делаете — НА СВОЙ РИСК (альт-аккаунт!).
================================================================================
]]

--==============================================================================
-- 0. ОКРУЖЕНИЕ / ДИАГНОСТИКА
--==============================================================================
local ExecName   = (identifyexecutor and identifyexecutor() or "Unknown")
local ExecLower  = ExecName:lower()
local KNOWN_EXECS = {
    "solara","xeno","delta","fluxus","krnl","wave","cryptic","hydrogen",
    "codex","arceus","synapse","scriptware","voltage","swift","macsploit","ron"
}
local function DetectExecutor()
    for _, name in ipairs(KNOWN_EXECS) do
        if ExecLower:find(name, 1, true) then return name end
    end
    return "unknown"
end

-- Фолбэки на слабых исполнителях (важно для KRNL / старых Fluxus)
local HAS_DRAWING   = (typeof(Drawing) == "table") and true or false
local HAS_WRITEFILE = (typeof(writefile) == "function")
local HAS_READFILE  = (typeof(readfile)  == "function")
local HAS_HOOKMETA  = (typeof(hookmetamethod) == "function")
local HAS_HOOKFUNC  = (typeof(hookfunction) == "function")
local HAS_NEWCC     = (typeof(newcclosure)  == "function") and newcclosure or function(f) return f end
local HAS_FIRECLICK = (typeof(fireclickdetector) == "function")
local HAS_REQUEST   = (typeof(request) == "function") or (typeof(syn and syn.request) == "function")

local COREGUI_OK, CoreGui = pcall(function()
    return (gethui and gethui()) or game:GetService("CoreGui")
end)
if not COREGUI_OK then CoreGui = nil end

--==============================================================================
-- 1. СЕРВИСЫ
--==============================================================================
local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInput       = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local HttpService     = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser     = game:GetService("VirtualUser")
local Workspace       = game:GetService("Workspace")
local Replicated      = game:GetService("ReplicatedStorage")
local GuiParent       = CoreGui or Players.LocalPlayer:WaitForChild("PlayerGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local PlaceId     = game.PlaceId
local JobId       = game.JobId
local Mouse       = LocalPlayer:GetMouse()
local GetFPS      = RunService.RenderStepped

--==============================================================================
-- 2. КОНСТАНТЫ / ЦВЕТА РОЛЕЙ  (КЛЮЧЕВОЕ ТРЕБОВАНИЕ)
--==============================================================================
local ROLE_COLOR = {
    Murderer = Color3.fromRGB(255, 64, 64),   -- МАРДЕР    = КРАСНЫЙ
    Sheriff  = Color3.fromRGB(75, 141, 255),  -- ШЕРИФ     = СИНИЙ
    Innocent = Color3.fromRGB(63, 220, 120),  -- НЕВИНОВНЫЙ= ЗЕЛЁНЫЙ
    None     = Color3.fromRGB(185, 190, 205), -- неизвестно
}
local ROLE_RU = { Murderer = "МАРДЕР", Sheriff = "ШЕРИФ", Innocent = "Инносент", None = "—" }
local RISKY   = { Murderer = true, Sheriff = true }

local KNIFE_PATTERNS = { "knife", "murd", "stab", "blade" }
local GUN_PATTERNS   = { "gun", "pistol", "revolver", "weapon_shoot" }

--==============================================================================
-- 3. УТИЛИТЫ
--==============================================================================
local Util = {}
local Notify = nil -- объявим ниже, до использования

function Util.clamp(v, a, b) return math.max(a, math.min(b, v)) end
function Util.round(v, d) local m = 10 ^ (d or 0) return math.floor(v * m + .5) / m end

function Util.notify(title, text, dur)
    if Notify then Notify(title, text, dur) end
    print(("[MM2 HUB X] %s — %s"):format(tostring(title), tostring(text)))
end

function Util.safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[MM2 HUB X] safe() -> " .. tostring(err)) end
    return ok, err
end

function Util.char(plr)   return plr and plr.Character end
function Util.hum(plr)
    local c = Util.char(plr)
    return c and c:FindFirstChildOfClass("Humanoid")
end
function Util.root(plr)
    local c = Util.char(plr)
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c.PrimaryPart)
end
function Util.head(plr)
    local c = Util.char(plr)
    return c and (c:FindFirstChild("Head") or c:FindFirstChild("UpperTorso") or Util.root(plr))
end
function Util.alive(plr)
    local h = Util.hum(plr)
    return h and h.Health > 0 and Util.root(plr) ~= nil
end
function Util.dist(a, b) return (a - b).Magnitude end
function Util.onScreen(pos3)
    local v, on = Camera:WorldToViewportPoint(pos3)
    return on and v.Z > 0, v
end

-- Райкаст-проверка «виден ли игрок» (Wall Check)
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.IgnoreWater = true

function Util.wallCheck(from, to, ignoreChar)
    RayParams.FilterDescendantsInstances = { ignoreChar or Util.char(LocalPlayer), Camera }
    local dir = to - from
    local res = Workspace:Raycast(from, dir, RayParams)
    if not res then return true end
    return res.Instance:IsDescendantOf(ignoreChar)
end

-- Телепорт с «человеческой» задержкой (для легит-режима — tween)
function Util.tp(pos, instant)
    local root = Util.root(LocalPlayer)
    if not root then return end
    if instant then
        root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        return
    end
    local dist = Util.dist(root.Position, pos)
    local t = Util.clamp(dist / 220, 0.08, 1.4) -- чем дальше — тем дольше, выглядит естественно
    TweenService:Create(root, TweenInfo.new(t, Enum.EasingStyle.Linear), { CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) }):Play()
end

--- Валидна ли позиция (защита от NaN / inf / улетевших координат).
--- Roblox кикает с "Invalid Position" именно по таким значениям.
function Util.isValidPos(pos)
    if typeof(pos) ~= "Vector3" then return false end
    local m = pos.Magnitude
    if m ~= m then return false end               -- NaN
    if m == math.huge or m == -math.huge then return false end
    if m > 1e5 then return false end              -- улетели за карту
    return pos.X == pos.X and pos.Y == pos.Y and pos.Z == pos.Z
end

--- Телепорт, который НИКОГДА не отправит на сервер невалидный CFrame.
function Util.safeTP(cf)
    local root = Util.root(LocalPlayer)
    if not root or typeof(cf) ~= "CFrame" then return false end
    local pos = cf.Position
    if not Util.isValidPos(pos) then
        Util.notify("PositionGuard", "Заблокирован телепорт в невалидную точку", 2)
        return false
    end
    root.CFrame = cf + Vector3.new(0, 3, 0)
    return true
end

--- Ходьба в точку (используется Baritone-режимом и авто-подходом).
function Util.walkTo(pos, speed)
    local hum, root = Util.hum(LocalPlayer), Util.root(LocalPlayer)
    if not hum or not root then return end
    if not Util.isValidPos(pos) then return end
    if speed and speed > 16 then hum.WalkSpeed = speed end
    hum:MoveTo(pos)
end

-- Кэш-скан монет/боксов (НЕ каждый кадр — иначе лаги на 100+ игроков)
local ScanCache, ScanTime = {}, 0
local COIN_PATTERNS  = { "coin", "money", "cash", "cashcoin", "token", "gem", "orbpickup" }
local EVENT_PATTERNS = { "gift", "present", "event", "candy", "egg", "candycane", "snowflake" }
local BOX_PATTERNS   = { "mysterybox", "box", "crate", "chest" }

function Util.scanWorkspace(patterns)
    local now = os.clock()
    if now - ScanTime < 1.2 and #ScanCache > 0 then return ScanCache end
    ScanTime = now
    table.clear(ScanCache)
    local roots = { Workspace }
    local remotes = Replicated:FindFirstChild("Remotes")
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("BasePart") then
            local n = inst.Name:lower()
            for _, p in ipairs(patterns) do
                if n:find(p, 1, true) then
                    table.insert(ScanCache, inst)
                    break
                end
            end
        end
    end
    return ScanCache
end

-- Поиск RemoteEvent по шаблону (названия ремоутов меняются от апдейта к апдейту)
local RemoteCache = {}
function Util.findRemote(patterns)
    local key = table.concat(patterns, "|")
    if RemoteCache[key] ~= nil then return RemoteCache[key] end
    local found = nil
    local function scan(parent)
        for _, inst in ipairs(parent:GetDescendants()) do
            if inst:IsA("RemoteEvent") or inst:IsA("UnreliableRemoteEvent") or inst:IsA("RemoteFunction") then
                local n = inst.Name:lower()
                for _, p in ipairs(patterns) do
                    if n:find(p, 1, true) then found = inst return end
                end
            end
        end
    end
    pcall(scan, Replicated)
    if not found then pcall(scan, Workspace) end
    RemoteCache[key] = found or false
    return found or false
end

--==============================================================================
-- 4. ОПРЕДЕЛЕНИЕ РОЛИ  (КРАСНЫЙ / СИНИЙ / ЗЕЛЁНЫЙ)
--==============================================================================
local Role = {}
local RoleCache, RoleCacheTime = {}, 0
local ROLE_REFRESH = 0.4 -- сек: достаточно для мгновенной реакции на смену ролей

local function toolIs(plr, patterns)
    local c = Util.char(plr)
    if c then
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                for _, p in ipairs(patterns) do if n:find(p, 1, true) then return true end end
            end
        end
    end
    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                for _, p in ipairs(patterns) do if n:find(p, 1, true) then return true end end
            end
        end
    end
    return false
end

local function roleFromData(plr)
    for _, path in ipairs({
        plr:FindFirstChild("PlayerData"),
        plr:FindFirstChild("Data"),
        Util.char(plr),
    }) do
        if path then
            local v = path:FindFirstChild("Role") or path:FindFirstChild("PlayerRole") or path:FindFirstChild("CurrentRole")
            if v and (v:IsA("StringValue") or v:IsA("ObjectValue")) then
                local s = (v.Value or ""):lower()
                if s:find("murd") or s:find("knife") then return "Murderer" end
                if s:find("sher") or s:find("hero") or s:find("gun") then return "Sheriff" end
                if s:find("inno") or s:find("citizen") or s:find("none") then return "Innocent" end
            end
        end
    end
    return nil
end

--- Возвращает "Murderer" | "Sheriff" | "Innocent" | "None"
function Role.Get(plr)
    if not plr then return "None" end
    if plr == LocalPlayer then
        local self_role = Role._local
        if self_role then return self_role end
    end
    local now = os.clock()
    local hit = RoleCache[plr]
    if hit and now - hit.t < ROLE_REFRESH then return hit.r end

    local r = "None"
    if toolIs(plr, KNIFE_PATTERNS) then r = "Murderer"
    elseif toolIs(plr, GUN_PATTERNS) then r = "Sheriff"
    else r = roleFromData(plr) or "Innocent" end

    RoleCache[plr] = { r = r, t = now }
    return r
end

function Role.Color(plr) return ROLE_COLOR[Role.Get(plr)] or ROLE_COLOR.None end
function Role.IsRisky(plr) return RISKY[Role.Get(plr)] == true end

-- Свою роль читаем чаще (нужно для Kill Aura / Silent Aim)
function Role.RefreshSelf()
    Role._local = nil
    Role._local = toolIs(LocalPlayer, KNIFE_PATTERNS) and "Murderer"
        or (toolIs(LocalPlayer, GUN_PATTERNS) and "Sheriff" or "Innocent")
end

--==============================================================================
-- 5. КОНФИГ (сохранение / загрузка / сброс)
--==============================================================================
local CFG_NAME = "MM2HubX_config.json"
local DEFAULT = {
    -- Farming
    CoinFarm = false, CoinMode = "Pathfind", CoinRadius = 150, CoinDelay = 0.12,
    CoinSmartAvoid = true, CoinBagReset = 35,
    -- Baritone-подобный фарм
    CoinInterval = 1.0,      -- FastTP: телепорт к монете раз в N секунд (легит = 1 с)
    PathJump = true,         -- автопрыжок через препятствия
    PathRepath = 0.5,        -- перестроение пути раз в N секунд
    PathAgentRadius = 2.2,   -- "толщина тела" для PathfindingService
    PathStopDist = 3.5,      -- подойти к монете на это расстояние
    -- Защита от кика "Invalid Position"
    PositionGuard = true,
    InvisibleSmooth = true,  -- Invisible без рассинхрона с сервером
    BoxFarm = false, EventFarm = false,
    AutoPrestige = false, PrestigeLevel = 100,
    AutoReconnect = true, AntiAFK = true,
    -- Legit combat
    SilentAim = false, SA_FOV = 70, SA_Priority = "Head", SA_WallCheck = true, SA_Smooth = 0.35,
    GunGrabber = false, KnifeDodge = false, DodgeDist = 45,
    -- Rage combat
    KillAura = false, AuraRadius = 22, AuraAutoThrow = true, AuraOnlyNear = true, AuraDelay = 0.25,
    KillAll = false, AutoApproach = false, ApproachSpeed = 95,
    HitboxExpand = false, HitboxSize = 12,
    -- Авто-килл по ролям
    AutoKillSheriff = false,    -- авто-килл Шерифа через FLING (мы мардер, стрелять нечем)
    AutoKillMurderer = false,   -- авто-килл Мрдера: ТП вплотную + мгновенное убийство
    InstantKillMethod = "Touch",  -- Touch | Remote | Hybrid
    FlingKillMode = "Spin",       -- Spin | Void | Wall
    FlingPower = 100000, FlingDuration = 1.6, FlingVoidY = -80,
    KillCooldown = 1.0, KillRecheckRole = true, KillTeleportClose = true,
    -- ESP
    ESP_Enabled = true, ESP_Box = true, ESP_Name = true, ESP_Dist = true,
    ESP_Tracer = false, ESP_Health = true, ESP_Skeleton = false, ESP_XRay = true,
    ESP_GunESP = true, ESP_Chams = true, ChamsFill = 0.55, ChamsOutline = 0,
    FOV_Circle = false, FOV_Size = 70, StreamerMode = false, ESP_FPS = 30,
    -- Protection
    AntiFling = true, AntiFlingThreshold = 500, GodMode = false, SecondChance = false,
    AntiVoid = true, AntiLava = true, VoidY = -60,
    Invisible = false,
    -- Movement
    WalkSpeed = 16, JumpPower = 50, InfJump = false, Fly = false, FlySpeed = 55,
    Noclip = false, SpinBot = false, SpinSpeed = 14,
    EmoteUnlocker = false, Emote = "Floss",
    AutoFakeCheck = true,
    -- Meta
    UI_Visible = true, WindowSize = 1,
}
local Config = {}
local Flags = {} -- реестр контролов для авто-сохранения

-- Загрузка
local function LoadConfig()
    Config = {}
    for k, v in pairs(DEFAULT) do Config[k] = v end
    if HAS_READFILE and HAS_WRITEFILE then
        local ok, raw = pcall(readfile, CFG_NAME)
        if ok and raw then
            local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
            if ok2 and type(decoded) == "table" then
                for k, v in pairs(decoded) do if DEFAULT[k] ~= nil then Config[k] = v end end
            end
        end
    end
end

local saveQueued = false
local function SaveConfig()
    if not (HAS_WRITEFILE and HAS_READFILE) then return end
    if saveQueued then return end
    saveQueued = true
    task.delay(0.35, function() -- дебаунс: ползунки дергаются сотни раз в секунду
        saveQueued = false
        local out = {}
        for k in pairs(DEFAULT) do out[k] = Config[k] end
        Util.safe(function()
            if not isfolder("MM2HubX") then makefolder("MM2HubX") end
            writefile(CFG_NAME, HttpService:JSONEncode(out))
        end)
    end)
end

local function Set(key, value)
    Config[key] = value
    SaveConfig()
end

LoadConfig()

--==============================================================================
-- 6. ИГРОКИ (кэш списков — нулевой аллокационный шум в цикле)
--==============================================================================
local PlayerList = {}
local function rebuildList()
    table.clear(PlayerList)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(PlayerList, p) end
    end
end
rebuildList()
Players.PlayerAdded:Connect(function(p) table.insert(PlayerList, p) end)
Players.PlayerRemoving:Connect(function(p)
    RoleCache[p] = nil
    for i, x in ipairs(PlayerList) do if x == p then table.remove(PlayerList, i) break end end
end)

local function getTargets()
    local out = {}
    for _, p in ipairs(PlayerList) do
        if Util.alive(p) then table.insert(out, p) end
    end
    return out
end

local function nearestTarget(maxDist, riskyOnly)
    local best, bd = nil, maxDist or math.huge
    local myRoot = Util.root(LocalPlayer)
    if not myRoot then return nil end
    for _, p in ipairs(getTargets()) do
        if not riskyOnly or Role.IsRisky(p) then
            local d = Util.dist(myRoot.Position, Util.root(p).Position)
            if d < bd then best, bd = p, d end
        end
    end
    return best, bd
end

--==============================================================================
-- 7. МОДУЛЬ: ФАРМ (монеты, боксы, ивенты, престиж, реконнект)
--==============================================================================
local Farm = {}
Farm.collected = 0

-- Спавн-точка (нужна для сброса мешка и Anti-Void). Определяем один раз + при респауне.
local SpawnPos = Vector3.new(0, 50, 0)
local function refreshSpawn()
    local root = Util.root(LocalPlayer)
    if root and Util.isValidPos(root.Position) then SpawnPos = root.Position end
    local sp = Workspace:FindFirstChild("Spawns") or Workspace:FindFirstChild("SpawnLocation")
    if sp and sp:IsA("BasePart") then SpawnPos = sp.Position end
end
task.spawn(function()
    if LocalPlayer.Character then refreshSpawn() end
    LocalPlayer.CharacterAdded:Connect(function() task.wait(1) refreshSpawn() end)
end)

-- Ближайшая монета (с учётом радиуса и Smart-обхода игроков)
function Farm.findCoin()
    local root = Util.root(LocalPlayer)
    if not root then return nil end
    local list = Util.scanWorkspace(COIN_PATTERNS)
    if #list == 0 then return nil end

    -- режимы Teleport / FastTP / Pathfind ищут по ВСЕЙ карте, Near — только в радиусе
    local maxR = (Config.CoinMode == "Near") and Config.CoinRadius or 5e4
    local best, bd = nil, maxR
    for _, part in ipairs(list) do
        if part and part.Parent then
            if Util.isValidPos(part.Position) then
                local d = Util.dist(root.Position, part.Position)
                if d < bd then best, bd = part, d end
            end
        end
    end
    if not best then return nil end

    -- Smart: пропускаем монету, у которой стоит живой игрок (меньше подозрений)
    if Config.CoinSmartAvoid then
        for _, p in ipairs(getTargets()) do
            local rp = Util.root(p)
            if rp and Util.dist(rp.Position, best.Position) < 12 then return nil end
        end
    end
    return best, bd
end

--- РЕЖИМ 1+2: Near (легит-твин) и Teleport (мгновенный, вся карта)
function Farm.collectCoins()
    if not Config.CoinFarm then return end
    local mode = Config.CoinMode
    if mode ~= "Near" and mode ~= "Teleport" then return end
    local part = Farm.findCoin()
    if not part then return end
    Util.tp(part.Position, mode == "Teleport")
    Farm.collected = Farm.collected + 1
    if Config.CoinBagReset > 0 and Farm.collected % Config.CoinBagReset == 0 then
        task.wait(0.15) Util.safeTP(CFrame.new(SpawnPos))
        Util.notify("Фарм", "Мешок полон — сброс на спавн", 2)
    end
end

--- РЕЖИМ 3: FastTP — телепорт к монете раз в N секунд (по умолчанию 1 с).
--- Выглядит как «быстрая ходьба», не создаёт поток телепортов каждый кадр.
local lastFastTP = 0
function Farm.fastTP()
    if not Config.CoinFarm or Config.CoinMode ~= "FastTP" then return end
    local now = os.clock()
    if now - lastFastTP < math.max(0.15, Config.CoinInterval) then return end
    lastFastTP = now
    local part = Farm.findCoin()
    if not part then return end
    if Util.safeTP(CFrame.new(part.Position)) then
        Farm.collected = Farm.collected + 1
    end
end

--==============================================================================
--  РЕЖИМ 4: PATHFIND (Baritone-стиль) — реальная ходьба по маршруту
--  • PathfindingService строит путь с обходом стен/лавы/пропастей
--  • Автопрыжок, если следующая точка выше (как Baritone)
--  • Детект застревания → перестроение маршрута
--  • Никаких телепортов: полностью легит-поведение, сервер видит обычную ходьбу
--==============================================================================
Farm.Path = {
    waypoints = {}, idx = 0, goal = nil, lastBuild = 0, stuckTimer = 0, lastPos = nil, moving = false,
}

function Farm.Path.build(targetPos)
    local PS = game:GetService("PathfindingService")
    local ok, path = pcall(function()
        local p = PS:CreatePath({
            AgentRadius = Config.PathAgentRadius or 2.2,
            AgentHeight = 5,
            AgentCanJump = Config.PathJump ~= false,
            AgentCanClimb = true,
            WaypointSpacing = 4,
            Costs = { Water = 20, Lava = math.huge, Danger = math.huge },
        })
        local root = Util.root(LocalPlayer)
        p:ComputeAsync(root.Position, targetPos)
        return p
    end)
    if not ok or not path then Farm.Path.waypoints = {} return false end
    if path.Status ~= Enum.PathStatus.Success then
        -- путь не построен (монета за стеной/в воздухе) → идём напрямую, Baritone-fallback
        Farm.Path.waypoints = { Vector3.new(targetPos.X, targetPos.Y, targetPos.Z) }
        Farm.Path.idx = 1
        return true
    end
    Farm.Path.waypoints = {}
    for _, wp in ipairs(path:GetWaypoints()) do
        if Util.isValidPos(wp.Position) then table.insert(Farm.Path.waypoints, wp.Position) end
    end
    Farm.Path.idx = 2 -- 1 = собственная позиция, пропускаем
    Farm.Path.lastBuild = os.clock()
    return true
end

--- Вызывается КАЖДЫЙ Heartbeat (плавная ходьба без телепортов)
function Farm.Path.step(dt)
    if not Config.CoinFarm or Config.CoinMode ~= "Pathfind" then
        if Farm.Path.moving then
            Farm.Path.moving = false
            local hum, root = Util.hum(LocalPlayer), Util.root(LocalPlayer)
            if hum and root then hum:MoveTo(root.Position) end -- останавливаем персонажа
            Farm.Path.waypoints, Farm.Path.goal = {}, nil
        end
        return
    end
    local hum, root = Util.hum(LocalPlayer), Util.root(LocalPlayer)
    if not hum or not root or hum.Health <= 0 then Farm.Path.waypoints = {} return end

    -- цель
    if not Farm.Path.goal or not Farm.Path.goal.Parent or os.clock() - Farm.Path.lastBuild > Config.PathRepath then
        local part = Farm.findCoin()
        if not part then
            if Farm.Path.moving then hum:MoveTo(root.Position) Farm.Path.moving = false end
            return
        end
        Farm.Path.goal = part
        Farm.Path.build(part.Position)
    end

    local wps = Farm.Path.waypoints
    if #wps == 0 then return end
    local target = wps[Farm.Path.idx]
    if not target then Farm.Path.waypoints = {} return end

    -- пришли в точку? (порог настраивается ползунком "Точность подхода")
    if Util.dist(root.Position, target) < (Config.PathStopDist or 3.5) then
        Farm.Path.idx = Farm.Path.idx + 1
        if Farm.Path.idx > #wps then
            -- маршрут пройден: монета собрана или нужно перестроить путь
            Farm.collected = Farm.collected + 1
            Farm.Path.goal = nil
            Farm.Path.waypoints = {}
            return
        end
        target = wps[Farm.Path.idx]
    end

    -- Baritone-прыжок: следующая точка заметно выше → прыгаем
    if Config.PathJump and target.Y - root.Position.Y > 3.5 and hum.FloorMaterial ~= Enum.Material.Air then
        hum.Jump = true
    end

    -- детект застревания
    if Farm.Path.lastPos then
        if Util.dist(root.Position, Farm.Path.lastPos) < 0.4 then
            Farm.Path.stuckTimer = Farm.Path.stuckTimer + dt
            if Farm.Path.stuckTimer > 0.8 then
                Farm.Path.stuckTimer = 0
                if hum.FloorMaterial ~= Enum.Material.Air then hum.Jump = true end
                Farm.Path.build(target) -- перестраиваем маршрут
            end
        else
            Farm.Path.stuckTimer = 0
        end
    end
    Farm.Path.lastPos = root.Position

    hum:MoveTo(target)
    Farm.Path.moving = true

    -- сброс мешка в Baritone-режиме = вернуться на спавн ПЕШКОМ (один раз, не каждый кадр)
    if Config.CoinBagReset > 0 and Farm.collected > 0
        and Farm.collected % Config.CoinBagReset == 0
        and Farm.Path.lastReset ~= Farm.collected then
        Farm.Path.lastReset = Farm.collected
        Farm.Path.waypoints, Farm.Path.goal = {}, nil
        hum:MoveTo(SpawnPos)
        Util.notify("Фарм", "Мешок полон — иду на спавн пешком", 2)
    end
end

function Farm.openBoxes()
    if not Config.BoxFarm then return end
    local boxes = Util.scanWorkspace(BOX_PATTERNS)
    for _, b in ipairs(boxes) do
        if b.Parent and Util.dist(Util.root(LocalPlayer).Position, b.Position) < 60 then
            Util.tp(b.Position, true)
            -- 1) через ProximityPrompt (самый надёжный путь)
            local prompt = b:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                fireproximityprompt(prompt)
            else
                -- 2) через ремоут
                local r = Util.findRemote({ "openbox", "mysterybox", "buybox", "opencrate" })
                if r then pcall(function() r:FireServer(b) end) end
            end
            task.wait(Config.CoinDelay)
            break -- один бокс за тик
        end
    end
end

function Farm.collectEvents()
    if not Config.EventFarm then return end
    local evs = Util.scanWorkspace(EVENT_PATTERNS)
    for _, e in ipairs(evs) do
        if e.Parent then
            Util.tp(e.Position, true)
            task.wait(Config.CoinDelay)
            break
        end
    end
end

function Farm.myLevel()
    local pd = LocalPlayer:FindFirstChild("PlayerData") or LocalPlayer:FindFirstChild("Data")
    if pd then
        for _, name in ipairs({ "Level", "UserLevel", "PlayerLevel" }) do
            local v = pd:FindFirstChild(name)
            if v and (v:IsA("IntValue") or v:IsA("NumberValue")) then return v.Value end
        end
    end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local mg = pg and pg:FindFirstChild("MainGUI")
    local g = mg and mg:FindFirstChild("Game")
    local l = g and g:FindFirstChild("UserLevel")
    if l and l:IsA("TextLabel") then return tonumber(l.Text:match("%d+")) or 0 end
    return 0
end

function Farm.tryPrestige()
    if not Config.AutoPrestige then return end
    if Farm.myLevel() >= Config.PrestigeLevel then
        local r = Util.findRemote({ "prestige", "rebirth", "resetlevel", "prestigeplayer" })
        if r then
            pcall(function() r:FireServer() end)
            Util.notify("Престиж", "Уровень " .. Config.PrestigeLevel .. " — ребёрт отправлен", 3)
            task.wait(3)
        end
    end
end

-- Anti-AFK + авто-реконнект после кика
function Farm.startSessionGuard()
    if Config.AntiAFK then
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            Util.notify("Anti-AFK", "АФК-кик предотвращён", 2)
        end)
    end
    -- перехват Kick: не блокируем (иначе бан-риск), а просто фиксируем и реконнектимся
    if Config.AutoReconnect and HAS_HOOKMETA then
        HAS_NEWCC(function() end)
        Util.safe(function()
            local old
            old = hookmetamethod(game, "__namecall", HAS_NEWCC(function(self, ...)
                local m = getnamecallmethod()
                if m == "Kick" and self == LocalPlayer then
                    Util.notify("Auto-Reconnect", "Кик обнаружен — перезаходим через 3 с", 4)
                    task.delay(3, function()
                        pcall(function()
                            TeleportService:Teleport(PlaceId, LocalPlayer)
                        end)
                    end)
                end
                return old(self, ...)
            end))
        end)
    end
end

--==============================================================================
-- 8. МОДУЛЬ: КОМБАТ
--==============================================================================
local Combat = {}
Combat.fovTarget = nil

function Combat.visibleTarget(p)
    local myRoot, tHead = Util.root(LocalPlayer), Util.head(p)
    if not myRoot or not tHead then return false end
    return Util.wallCheck(Camera.CFrame.Position, tHead.Position, Util.char(LocalPlayer))
end

-- Выбор цели для Silent Aim (FOV + приоритет + Wall Check)
function Combat.pickAimTarget()
    local best, bs = nil, math.huge
    local center = Camera.ViewportSize / 2
    for _, p in ipairs(getTargets()) do
        local r = Role.Get(p)
        if r == "Murderer" or r == "Sheriff" or r == "Innocent" then
            local head = Config.SA_Priority == "Head" and Util.head(p) or Util.root(p)
            if head then
                local on, sp = Util.onScreen(head.Position)
                if on then
                    local screenDist = Util.dist(Vector2.new(sp.X, sp.Y), Vector2.new(center.X, center.Y))
                    local inFov = screenDist <= (Config.SA_FOV * Camera.ViewportSize.Y / 1000)
                    if inFov and (not Config.SA_WallCheck or Combat.visibleTarget(p)) then
                        local weight = screenDist + (r == "Murderer" and -9000 or (r == "Sheriff" and -4000 or 0))
                        if weight < bs then best, bs = { player = p, part = head, pos = head.Position }, weight end
                    end
                end
            end
        end
    end
    Combat.fovTarget = best
    return best
end

-- Silent Aim: подмена направления выстрела в ремоуте пистолета
function Combat.startSilentAim()
    if not HAS_HOOKMETA then
        Util.notify("Silent Aim", "Исполнитель не поддерживает hookmetamethod — включена камера-пометка", 4)
        return
    end
    local shootRemote = Util.findRemote({ "shoot", "firegun", "gunshot", "shootgun", "bullet" })
    if not shootRemote then
        Util.notify("Silent Aim", "Ремоут выстрела не найден — проверь console (F9)", 4)
    end
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", HAS_NEWCC(function(self, ...)
        local args = { ... }
        local m = getnamecallmethod()
        if Config.SilentAim and (m == "FireServer" or m == "InvokeServer") then
            local isShoot = (self == shootRemote) or self.Name:lower():find("shoot")
            if isShoot then
                local t = Combat.pickAimTarget()
                if t then
                    -- подменяем CFrame/Vector3-аргумент направления (индекс настраивается)
                    for i = 1, #args do
                        if typeof(args[i]) == "CFrame" then args[i] = CFrame.new(t.pos) break end
                        if typeof(args[i]) == "Vector3" then args[i] = t.pos break end
                    end
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        return oldNamecall(self, ...)
    end))
end

-- Kill Aura (Мардер): расширение хитбокса + авто-бросок ножа
function Combat.killAuraStep()
    if not Config.KillAura then return end
    local t, d = nearestTarget(Config.AuraRadius, false)
    if not t then return end
    -- режим «только ближайшие»: игнорируем дальние цели
    if Config.AuraOnlyNear and d > 25 then return end
    if not Util.wallCheck(Util.root(LocalPlayer).Position, Util.root(t).Position, Util.char(LocalPlayer)) then return end
    if Config.AuraAutoThrow then
        local r = Util.findRemote({ "throw", "throwknife", "stab", "attack", "knifehit" })
        if r then
            pcall(function()
                r:FireServer(Util.head(t).CFrame, Util.head(t).Position)
            end)
        end
    else
        Util.tp(Util.root(t).Position, true) -- режим «подойти и ударить»
    end
end

-- Авто-подход к цели (Продвинутый убийца)
function Combat.approachStep()
    if not Config.AutoApproach then return end
    local t = nearestTarget(400, false)
    if t then
        local root = Util.root(LocalPlayer)
        local dir = (Util.root(t).Position - root.Position).Unit
        root.AssemblyLinearVelocity = dir * Config.ApproachSpeed
    end
end

-- Мгновенные действия
function Combat.killAll(onlyRole)
    local n = 0
    for _, p in ipairs(getTargets()) do
        if not onlyRole or Role.Get(p) == onlyRole then
            local r = Util.findRemote({ "throw", "stab", "attack", "knifehit", "shoot" })
            if r then pcall(function() r:FireServer(Util.head(p).CFrame, Util.head(p).Position) end) n = n + 1 end
            task.wait(0.03)
        end
    end
    Util.notify("Kill", ("Целей обработано: %d"):format(n), 3)
end

-- Gun Grabber: автотелепорт к выпавшему пистолету
function Combat.gunGrabber()
    if not Config.GunGrabber then return end
    for _, inst in ipairs(Workspace:GetChildren()) do
        local n = inst.Name:lower()
        if (n:find("gun") or n:find("pistol")) and inst:IsA("BasePart") then
            Util.tp(inst.Position, true)
            task.wait(0.1)
            break
        elseif (n:find("gun") or n:find("pistol")) and inst:IsA("Model") and inst.PrimaryPart then
            Util.tp(inst.PrimaryPart.Position, true)
            task.wait(0.1)
            break
        end
    end
end

-- Авто-додж летящих ножей
local watchedKnives = {}
function Combat.knifeDodge()
    if not Config.KnifeDodge then return end
    local root = Util.root(LocalPlayer)
    if not root then return end
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("BasePart") and inst.Name:lower():find("knife") then
            if not watchedKnives[inst] then
                watchedKnives[inst] = true
                local conn
                conn = RunService.Heartbeat:Connect(function()
                    if not inst.Parent or not Config.KnifeDodge then conn:Disconnect() watchedKnives[inst] = nil return end
                    local d = Util.dist(inst.Position, root.Position)
                    if d < Config.DodgeDist then
                        local away = (root.Position - inst.Position).Unit
                        root.CFrame = root.CFrame + away * 7 + Vector3.new(0, 4, 0)
                    end
                end)
                inst.Destroying:Connect(function() conn:Disconnect() watchedKnives[inst] = nil end)
            end
        end
    end
end

-- Hitbox Expander (визуальный + серверный размер частей)
function Combat.applyHitbox()
    for _, p in ipairs(PlayerList) do
        local c = Util.char(p)
        if c then
            for _, partName in ipairs({ "HumanoidRootPart", "Torso", "UpperTorso" }) do
                local part = c:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    if Config.HitboxExpand then
                        local s = Config.HitboxSize
                        if part.Name == "HumanoidRootPart" and not part:GetAttribute("mm2_orig") then
                            part:SetAttribute("mm2_orig", part.Size.X)
                        end
                        part.Size = Vector3.new(s, s, s)
                        part.Transparency = 0.75
                        part.BrickColor = BrickColor.new(Role.Get(p) == "Murderer" and "Really red" or "Lime green")
                    elseif part:GetAttribute("mm2_orig") then
                        local o = part:GetAttribute("mm2_orig")
                        part.Size = Vector3.new(o, o, o)
                        part.Transparency = 1
                    end
                end
            end
        end
    end
end

--[[
    FLING / FLING-KILL
    ⚠ ВАЖНО: на время СВОЕГО флинга мы ставим метку Combat.ownFlingUntil,
    по которой Guard.antiFling() пропускает проверку. Иначе анти-флинг видит
    всплеск скорости (наш же флинг даёт 1e5 velocity) или «дёргает» наш CFrame
    из-за физики рядом с крутящейся целью — и ЛОМАЕТ собственный флинг.
]]
Combat.ownFlingUntil = 0      -- до какого времени анти-флинг молчит
Combat.flingBusy    = false   -- активен ли хоть один наш флинг

local function flingActive() return os.clock() < Combat.ownFlingUntil end
Combat.flingActive = flingActive

--- Базовый флинг: поднимаем цель к себе, раскручиваем и выдаём огромную скорость.
--- mode: "Spin" (раскрутка на месте) | "Void" (швыряем за карту вниз) | "Wall" (в ближайшую стену)
function Combat.fling(plr, mode)
    local root = Util.root(plr)
    local myRoot = Util.root(LocalPlayer)
    if not root or not myRoot then return false end
    mode = mode or Config.FlingKillMode or "Spin"

    -- ставим метку ДО начала: анти-флинг не должен мешать нам самим
    Combat.ownFlingUntil = os.clock() + (Config.FlingDuration or 1.6) + 0.6
    Combat.flingBusy = true

    local power = tonumber(Config.FlingPower) or 100000
    Util.notify("Fling", "Запущен флинг: " .. plr.Name .. " (" .. mode .. ")", 3)

    -- поднимаем силу вращения части, чтобы сервер принял разлёт
    pcall(function()
        root.CustomPhysicalProperties = PhysicalProperties.new(100, 0.3, 0.5)
        root.CanCollide = true
        root.Anchored = false
    end)

    local t0 = os.clock()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        local done = (os.clock() - t0 > (Config.FlingDuration or 1.6)) or not root.Parent
        if done then
            conn:Disconnect()
            Combat.flingBusy = false
            pcall(function() root.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.3, 0.5) end)
            return
        end

        -- держим цель прямо перед собой, чтобы «зацепить» её телом (классический метод)
        -- ВАЖНО: lastSafePos объявлен позже как local, поэтому здесь используем
        -- геттер Guard.safePos() (в противном случае было бы nil -> флинг падал)
        local anchor = myRoot.Parent and myRoot.CFrame
            or CFrame.new(getSpawnPos())
        root.CFrame = anchor * CFrame.new(0, 0, -3.5) * CFrame.Angles(0, os.clock() * 40, 0)

        if mode == "Void" then
            -- швыряем вниз и далеко в сторону: сервер убивает о FallenPartsDestroyHeight
            root.AssemblyLinearVelocity = Vector3.new(0, -power, -power)
            root.AssemblyAngularVelocity = Vector3.new(power, power, power) * 0.02
        elseif mode == "Wall" then
            -- в ближайшую стену: ищем поверхность и бьём в неё
            local dir = Camera.CFrame.LookVector
            root.AssemblyLinearVelocity = dir * power + Vector3.new(0, power * 0.35, 0)
            root.AssemblyAngularVelocity = Vector3.new(power, power, power) * 0.02
        else -- Spin: раскрутка с разлётом во все стороны
            root.AssemblyLinearVelocity = Vector3.new(
                math.random(-1, 1) * power,
                power * 0.9,
                math.random(-1, 1) * power
            )
            root.AssemblyAngularVelocity = Vector3.new(power, power, power) * 0.02
        end
    end)
    return true
end

--- Флинг с добиванием: после разлёта телепортируемся к цели и бьём ножом,
--- если она ещё жива (для режима Spin флинг часто не убивает сам по себе).
function Combat.flingKill(plr, mode)
    local ok = Combat.fling(plr, mode or "Spin")
    if not ok then return false end
    task.delay((Config.FlingDuration or 1.6) + 0.35, function()
        if plr.Parent and Util.alive(plr) then
            Util.notify("Fling Kill", plr.Name .. " пережил флинг — добиваю", 2)
            Combat.instantKill(plr)
        else
            Util.notify("Fling Kill", "Цель устранена флингом ✓", 2)
        end
    end)
    return true
end

--[[
    МГНОВЕННОЕ УБИЙСТВО: тепаемся вплотную к цели и сразу наносим урон.
    Три способа (перебираются по фолбэку):
      • Touch   — firetouchinterest рукоятью ножа по голове цели (рабочий в MM2)
      • Remote  — прямая отправка knife-hit / throw / attack ремоута с CFrame головы
      • Hybrid  — Touch + Remote одновременно (макс. шанс)
]]
function Combat.hitTarget(plr)
    local head = Util.head(plr)
    if not head then return false end
    local c = Util.char(LocalPlayer)
    local method = Config.InstantKillMethod or "Touch"

    -- 1) TOUCH: «касаемся» цели рукоятью ножа — сервер считает это попаданием ножа
    local function tryTouch()
        if typeof(firetouchinterest) ~= "function" then return false end
        local knife = c and (c:FindFirstChild("Knife") or c:FindFirstChildWhichIsA("Tool"))
        if not knife then return false end
        local handle = knife:FindFirstChild("Handle") or knife:FindFirstChildWhichIsA("BasePart")
        if not handle then return false end
        for _, part in ipairs({ head, Util.root(plr), Util.char(plr) }) do
            if typeof(part) == "Instance" and part:IsA("BasePart") then
                pcall(function()
                    firetouchinterest(handle, part, 0) -- начало касания
                    firetouchinterest(handle, part, 1) -- конец касания
                end)
            end
        end
        return true
    end

    -- 2) REMOTE: шлём попадание напрямую (несколько шаблонов имён ремоутов)
    local function tryRemote()
        local sent = false
        local headCF, headPos = head.CFrame, head.Position
        for _, pat in ipairs({ "throw", "throwknife", "stab", "attack", "knifehit", "hitknife", "melee" }) do
            local r = Util.findRemote({ pat })
            if r then
                pcall(function()
                    r:FireServer(headCF, headPos)          -- типовой формат MM2
                    r:FireServer(headCF, headCF, headPos)  -- альтернативный формат
                    sent = true
                end)
            end
        end
        return sent
    end

    if method == "Remote" then return tryRemote() end
    if method == "Touch" then return tryTouch() end
    -- Hybrid
    local a, b = tryTouch(), tryRemote()
    return a or b
end

--- «Моментальный» килл: ТП вплотную + добивание. Задержки минимальны,
--- роль проверяем заранее, чтобы случайно не убить инносента.
function Combat.instantKill(plr)
    if not plr or not plr.Parent or not Util.alive(plr) then return false end

    -- защита от Friendly Fire: убиваем только разрешённые роли
    if Config.KillRecheckRole then
        local r = Role.Get(plr)
        if r == "Innocent" then
            Util.notify("Kill", plr.Name .. " — инносент, пропуск (Kill Recheck Role)", 2)
            return false
        end
    end

    local head = Util.head(plr)
    if not head then return false end

    -- ТП вплотную (не внутрь модели, чуть сбоку — чтобы не выкинуло античитом)
    if Config.KillTeleportClose then
        local offset = head.CFrame.LookVector * 2.2
        Util.safeTP(CFrame.new(head.Position + offset + Vector3.new(0, 1.2, 0)))
    end

    local ok = Combat.hitTarget(plr)
    if ok then
        Combat.kills = (Combat.kills or 0) + 1
        Util.notify("Kill", "Мгновенное убийство: " .. plr.Name, 2)
    end

    -- добивание вторым ударом через KillCooldown (много клампятся в MM2)
    task.delay(math.max(0.15, Config.KillCooldown or 1), function()
        if plr.Parent and Util.alive(plr) then Combat.hitTarget(plr) end
    end)
    return ok
end

--[[
    АВТО-КИЛЛ ПО РОЛЯМ
      • AutoKillMurderer — цель = МАРДЕР (мы шериф): ТП вплотную + мгновенный выстрел/нож
      • AutoKillSheriff  — цель = ШЕРИФ (мы мардер): флинг-килл, т.к. ножом до шерифа
                           не добраться (он нас убьёт первым) — надёжнее флинг
]]
Combat.killCd = {}          -- кулдауны по игрокам
local function onCd(plr)
    local t = Combat.killCd[plr] or 0
    if os.clock() < t then return true end
    return false
end
local function setCd(plr) Combat.killCd[plr] = os.clock() + math.max(0.2, Config.KillCooldown or 1) end

function Combat.autoKillStep()
    if not (Config.AutoKillMurderer or Config.AutoKillSheriff) then return end
    -- пока активен наш флинг — не начинаем новый (иначе флинги будут перебивать друг друга)
    if Combat.flingBusy or flingActive() then return end

    for _, p in ipairs(getTargets()) do
        local role = Role.Get(p)
        if onCd(p) then continue end

        -- ---------- АВТО-КИЛЛ МРДЕРА (мгновенно: ТП + килл) ----------
        if Config.AutoKillMurderer and role == "Murderer" then
            setCd(p)
            -- сначала быстрый флинг, если цель далеко — иначе не добежим/убьют нас
            local d = Util.dist(Util.root(LocalPlayer).Position, Util.root(p).Position)
            if d > 60 then
                Util.notify("Авто-килл", "Мрдер далеко (" .. math.floor(d) .. ") — подлетаю", 2)
                Util.safeTP(CFrame.new(Util.root(p).Position + Vector3.new(0, 4, 0)))
            end
            task.delay(0.05, function() Combat.instantKill(p) end)
            return -- одна цель за тик
        end

        -- ---------- АВТО-КИЛЛ ШЕРИФА (через FLING) ----------
        if Config.AutoKillSheriff and role == "Sheriff" then
            setCd(p)
            Util.notify("Авто-килл", "Шериф найден: " .. p.Name .. " — флинг-килл", 2)
            Combat.flingKill(p, Config.FlingKillMode or "Spin")
            return
        end
    end
end

-- Проверка «фейкового ножа/оружия» (анти-обман другими скриптами)
function Combat.fakeWeaponCheck()
    if not Config.AutoFakeCheck then return end
    local c = Util.char(LocalPlayer)
    if not c then return end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") then
            local handle = t:FindFirstChild("Handle") or t:FindFirstChildWhichIsA("BasePart")
            local looksReal = handle ~= nil and handle.Size.Magnitude > 0.5
            local isWeapon = t.Name:lower():find("knife") or t.Name:lower():find("gun")
            if isWeapon and not looksReal then
                Util.notify("⚠ Фейк", "Обнаружено поддельное оружие: " .. t.Name, 5)
            end
        end
    end
end

--==============================================================================
-- 9. МОДУЛЬ: ЗАЩИТА
--==============================================================================
local Guard = {}
local lastSafePos = nil

--- Безопасная точка для других модулей (Combat.fling / Anti-Void / кнопки UI)
function Guard.safePos()
    if lastSafePos and Util.isValidPos(lastSafePos) then return lastSafePos end
    return getSpawnPos()
end

--[[
    ANTI-FLING
    ⚠ ИСПРАВЛЕНО: раньше анти-флинг срабатывал на всплеск скорости, который
    создавал НАШ СОБСТВЕННЫЙ флинг (1e5 velocity) — и тем самым ломал его.
    Теперь:
      1) на время своего флинга (Combat.ownFlingUntil) проверка полностью молчит;
      2) порог настраивается ползунком (свои физичные движения не считаются флингом);
      3) позиция откатывается только если нас реально тащит В СТОРОНУ от нашей
         последней безопасной точки (признак чужого флинга), а не просто «быстро».
]]
function Guard.antiFling()
    if not Config.AntiFling then return end
    -- ⛔ ИСКЛЮЧЕНИЕ СВОЕГО ФЛИНГА: не дефаемся от самих себя
    if Combat.flingActive and Combat.flingActive() then return end
    if Combat.flingBusy then return end

    local root = Util.root(LocalPlayer)
    if not root then return end

    local vel = root.AssemblyLinearVelocity
    local ang = root.AssemblyAngularVelocity
    local threshold = tonumber(Config.AntiFlingThreshold) or 500

    if vel.Magnitude > threshold or ang.Magnitude > (threshold * 0.6) then
        -- чужой флинг тянет нас В СТОРОНУ от безопасной точки => откатываемся
        local dragged = false
        if lastSafePos and Util.isValidPos(lastSafePos) then
            dragged = Util.dist(root.Position, lastSafePos) > 25
        end
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        if dragged and lastSafePos then root.CFrame = CFrame.new(lastSafePos) end
        -- ломаем чужие BodyMover-ы, которые нас кидают
        for _, m in ipairs(root:GetChildren()) do
            if m:IsA("BodyMover") or m:IsA("AlignPosition") or m:IsA("AlignOrientation") then m:Destroy() end
        end
        Util.notify("Anti-Fling", "Чужой флинг заблокирован", 2)
    else
        -- запоминаем точку ТОЛЬКО если стоим на земле и не летим (иначе «запомним полёт»)
        local hum = Util.hum(LocalPlayer)
        if hum and hum.FloorMaterial ~= Enum.Material.Air and math.abs(vel.Y) < 60 then
            lastSafePos = root.Position
        end
    end
end

function Guard.godMode()
    local h = Util.hum(LocalPlayer)
    if not h then return end
    if Config.GodMode then
        h.MaxHealth = math.huge
        h.Health = math.huge
        h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end
    if Config.SecondChance and h.Health < (h.MaxHealth * 0.35) then
        local r = Util.findRemote({ "revive", "secondchance", "heal", "respawnme" })
        if r then pcall(function() r:FireServer() end) end
        h.Health = h.MaxHealth
    end
end

function Guard.antiVoid()
    if not (Config.AntiVoid or Config.AntiLava) then return end
    local root = Util.root(LocalPlayer)
    if not root then return end
    if root.Position.Y < Config.VoidY then
        -- откат на последнюю безопасную точку, а не на «слепой» спавн
        -- (телепорт в неизвестную точку = источник кика "Invalid Position")
        local safe = (lastSafePos and Util.isValidPos(lastSafePos)) and lastSafePos or SpawnPos
        if Util.safeTP(CFrame.new(safe)) then
            Util.notify("Anti-Void", "Возврат из бездны", 2)
        end
        return
    end
    if Config.AntiLava then
        local feet = Workspace:Raycast(root.Position, Vector3.new(0, -4, 0), RayParams)
        if feet and feet.Instance and feet.Instance.Name:lower():find("lava") then
            root.CFrame = CFrame.new(root.Position + Vector3.new(0, 18, 0))
        end
    end
end

--[[
    НЕВИДИМОСТЬ (безопасная версия — НЕ кикает с "Invalid Position")
    Причина киков у старых версий: скрипты трогают HumanoidRootPart (Size/CFrame)
    и меняют прозрачность на каждом кадре, из-за чего сервер получает
    рассинхрон и часть тела «улетает» → kick "Invalid Position".
    Здесь:  • только Transparency, НИ ОДНОГО изменения CFrame/Size/CanCollide
            • троттлинг 0.4 с (не спамим свойствами каждый тик)
            • атрибуты храним через таблицу (nil/0 больше не путаются)
            • HRP и «невидимые» части сервера не трогаем вовсе
]]
local invisSaved = {}
local lastInvis = 0
local INVIS_SKIP = { ["HumanoidRootPart"] = true } -- этот part сервер считает якорем позиции

function Guard.invisible()
    local now = os.clock()
    if now - lastInvis < 0.4 then return end
    lastInvis = now

    local c = Util.char(LocalPlayer)
    if not c then return end

    for _, d in ipairs(c:GetDescendants()) do
        local isPart = d:IsA("BasePart")
        if isPart or d:IsA("Decal") then
            if Config.Invisible and not INVIS_SKIP[d.Name] then
                if invisSaved[d] == nil then invisSaved[d] = d.Transparency end
                pcall(function()
                    d.Transparency = (Config.InvisibleSmooth == false) and 1 or math.max(0.85, d.Transparency)
                    if isPart then d.CastShadow = false end
                end)
            elseif invisSaved[d] ~= nil then
                pcall(function()
                    d.Transparency = invisSaved[d]
                    if isPart then d.CastShadow = true end
                end)
                invisSaved[d] = nil
            end
        end
    end

    -- при выключении чистим следы, чтобы не «моргал» рендер
    if not Config.Invisible and next(invisSaved) == nil then return end
end

-- Полный сброс невидимости (вызывается при респауне/выключении функции)
function Guard.invisibleReset()
    for obj, tr in pairs(invisSaved) do
        if obj and obj.Parent then pcall(function() obj.Transparency = tr end) end
    end
    table.clear(invisSaved)
end
LocalPlayer.CharacterAdded:Connect(function() Guard.invisibleReset() end)

--[[
    POSITION GUARD — прямой фикс кика "Invalid Position".
    Каждые 0.2 с проверяем HRP: если координаты NaN/inf/за пределами карты
    или персонаж «улетел» вниз — откатываем на последний безопасный CFrame.
]]
function Guard.positionSanity()
    if not Config.PositionGuard then return end
    local root = Util.root(LocalPlayer)
    if not root then return end
    local p = root.Position
    local bad = not Util.isValidPos(p)
        or p ~= p
        or (root.CFrame.LookVector.X ~= root.CFrame.LookVector.X)

    if bad then
        if lastSafePos and Util.isValidPos(lastSafePos) then
            root.CFrame = CFrame.new(lastSafePos)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            Util.notify("PositionGuard", "Исправлена невалидная позиция (кик предотвращён)", 3)
        else
            -- ничего не сохранено — просим сервер пересинхронизироваться штатно
            local hum = Util.hum(LocalPlayer)
            if hum then hum.Health = math.max(1, hum.Health - 1) end
            pcall(function() root.CFrame = CFrame.new(0, 100, 0) end)
        end
        return
    end
    -- сохраняем «безопасную» точку только если стоим на земле и не падаем
    local hum = Util.hum(LocalPlayer)
    if hum and hum.FloorMaterial ~= Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.Y) < 60 then
        lastSafePos = p
    end
end

-- Streamer Mode: скрыть ники всех, кроме себя
function Guard.streamerMode()
    for _, p in ipairs(PlayerList) do
        local h = Util.hum(p)
        if h then
            if Config.StreamerMode then
                h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                local head = Util.head(p)
                if head then
                    for _, g in ipairs(head:GetChildren()) do
                        if g:IsA("BillboardGui") then g.Enabled = false end
                    end
                end
            else
                h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
            end
        end
    end
end

--==============================================================================
-- 10. МОДУЛЬ: ESP / CHAMS / SKELETON (Drawing + фолбэк на Highlight)
--==============================================================================
local ESP = {}
ESP.draw = {}

local function newDraw(kind, props)
    if HAS_DRAWING then
        local ok, obj = pcall(Drawing.new, kind)
        if ok and obj then
            for k, v in pairs(props) do obj[k] = v end
            obj.Visible = false
            return obj
        end
    end
    return nil -- фолбэк: только Highlight/Billboard (работает везде)
end

local function clearPlayerObjects(store)
    for _, o in pairs(store) do
        if typeof(o) == "table" then
            for _, x in pairs(o) do pcall(function() x:Remove() end) end
        else
            pcall(function() o:Remove() end)
        end
    end
end

ESP.objects = {}

local SKELETON_R15 = {
    { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
    { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
    { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}
local SKELETON_R6 = {
    { "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
    { "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}

local function getBone(c, name)
    return c:FindFirstChild(name)
end

function ESP.build(plr)
    if ESP.objects[plr] then return end
    local store = {}
    if HAS_DRAWING then
        store.box      = newDraw("Square",   { Thickness = 1, Filled = false })
        store.boxFill  = newDraw("Square",   { Thickness = 1, Filled = true, Transparency = 0.25 })
        store.name     = newDraw("Text",     { Size = 13, Center = true, Outline = true, Font = 2 })
        store.dist     = newDraw("Text",     { Size = 12, Center = true, Outline = true, Font = 2 })
        store.tracer   = newDraw("Line",     { Thickness = 1 })
        store.hpBG     = newDraw("Square",   { Thickness = 1, Filled = true, Color = Color3.new(0, 0, 0) })
        store.hp       = newDraw("Square",   { Thickness = 1, Filled = true, Color = Color3.fromRGB(60, 220, 120) })
        store.skel = {}
        for i = 1, #SKELETON_R15 do table.insert(store.skel, newDraw("Line", { Thickness = 1 })) end
    end
    -- Chams через Highlight (работает на ВСЕХ исполнителях, включая Xeno/Solara)
    store.chams = Instance.new("Highlight")
    store.chams.Name = "MM2_HUB_CHAMS"
    store.chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    store.chams.Parent = (CoreGui or GuiParent)

    -- 3D-имя для режима без Drawing API
    store.bill = Instance.new("BillboardGui")
    store.bill.Name = "MM2_TAG"
    store.bill.Size = UDim2.fromOffset(140, 44)
    store.bill.AlwaysOnTop = true
    store.bill.StudsOffset = Vector3.new(0, 3.2, 0)
    store.text = Instance.new("TextLabel")
    store.text.BackgroundTransparency = 1
    store.text.Size = UDim2.fromScale(1, 1)
    store.text.Font = Enum.Font.GothamBold
    store.text.TextStrokeTransparency = 0.2
    store.text.TextSize = 13
    store.text.Parent = store.bill
    store.bill.Parent = (CoreGui or GuiParent)

    ESP.objects[plr] = store
end

function ESP.remove(plr)
    local s = ESP.objects[plr]
    if not s then return end
    clearPlayerObjects(s)
    pcall(function() s.chams:Destroy() end)
    pcall(function() s.bill:Destroy() end)
    ESP.objects[plr] = nil
end

function ESP.clearAll()
    for plr in pairs(ESP.objects) do ESP.remove(plr) end
end

local accTime = 0
function ESP.render(dt)
    if not Config.ESP_Enabled then
        accTime = accTime + dt
        return
    end
    accTime = accTime + dt
    if accTime < (1 / Config.ESP_FPS) then return end -- ограничение FPS ESP = главный источник «лагов»
    accTime = 0

    local myRoot = Util.root(LocalPlayer)
    local active = {}
    for _, plr in ipairs(PlayerList) do
        if Util.alive(plr) then active[plr] = true end
    end
    for plr in pairs(ESP.objects) do
        if not active[plr] then ESP.remove(plr) end
    end

    for plr in pairs(active) do
        ESP.build(plr)
        local s = ESP.objects[plr]
        local role = Role.Get(plr)
        local col = ROLE_COLOR[role] or ROLE_COLOR.None
        local root, head, hum = Util.root(plr), Util.head(plr), Util.hum(plr)
        if not (root and head) then continue end

        local pos, on = Camera:WorldToViewportPoint(root.Position)
        local nameTag = Config.StreamerMode and "player" or plr.Name
        local distTxt = myRoot and ("%d м"):format(Util.dist(myRoot.Position, root.Position)) or ""

        -- CHAMS (ролевой цвет + прозрачность)
        do
            local char = Util.char(plr)
            if Config.ESP_Chams and char then
                s.chams.Adornee = char
                s.chams.FillColor = col
                s.chams.OutlineColor = col
                s.chams.FillTransparency = 1 - Config.ChamsFill
                s.chams.OutlineTransparency = Config.ChamsOutline
                s.chams.Enabled = true
            else
                s.chams.Enabled = false
            end
        end

        -- 3D-тэг (фолбэк + всегда видимое имя с ролью)
        do
            s.bill.Adornee = head
            s.bill.Enabled = Config.ESP_Name or not HAS_DRAWING
            s.text.Text = (Config.StreamerMode and "player" or plr.Name) .. "\n" .. ROLE_RU[role] .. (Config.ESP_Dist and ("  " .. distTxt) or "")
            s.text.TextColor3 = col
        end

        if HAS_DRAWING then
            local headPos, onHead = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))
            local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
            local h = math.abs(legPos.Y - headPos.Y)
            local w = h / 2.1
            local visible = on and onHead


            local function show(obj, cond)
                if obj then obj.Visible = (cond == true) and visible or false end
            end

            -- BOX
            if s.box and s.boxFill then
                s.box.Size = Vector2.new(w, h)
                s.box.Position = Vector2.new(pos.X - w / 2, pos.Y - h / 2)
                s.box.Color = col
                s.box.Thickness = 1.4
                s.boxFill.Size = s.box.Size
                s.boxFill.Position = s.box.Position
                s.boxFill.Color = col
                show(s.box, Config.ESP_Box)
                show(s.boxFill, Config.ESP_Box and Config.ESP_XRay)
            end
            -- NAME / DIST
            if s.name then
                s.name.Text = nameTag .. "  [" .. ROLE_RU[role] .. "]"
                s.name.Position = Vector2.new(pos.X, pos.Y - h / 2 - 14)
                s.name.Color = col
                show(s.name, Config.ESP_Name)
            end
            if s.dist then
                s.dist.Text = distTxt
                s.dist.Position = Vector2.new(pos.X, pos.Y + h / 2 + 6)
                s.dist.Color = col
                show(s.dist, Config.ESP_Dist)
            end
            -- HEALTH BAR
            if s.hp and s.hpBG then
                local ratio = Util.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
                s.hpBG.Size = Vector2.new(3, h)
                s.hpBG.Position = Vector2.new(pos.X - w / 2 - 6, pos.Y - h / 2)
                s.hp.Size = Vector2.new(3, h * ratio)
                s.hp.Position = Vector2.new(pos.X - w / 2 - 6, pos.Y + h / 2 - h * ratio)
                s.hp.Color = Color3.fromRGB(255 * (1 - ratio), 220 * ratio, 60)
                show(s.hpBG, Config.ESP_Health)
                show(s.hp, Config.ESP_Health)
            end
            -- TRACER (X-Ray снизу экрана)
            if s.tracer then
                s.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                s.tracer.To = Vector2.new(pos.X, pos.Y + h / 2)
                s.tracer.Color = col
                show(s.tracer, Config.ESP_Tracer)
            end
            -- SKELETON
            local set = Util.hum(plr) and Util.hum(plr).RigType == Enum.HumanoidRigType.R15 and SKELETON_R15 or SKELETON_R6
            for i, line in ipairs(s.skel or {}) do
                local pair = set[i]
                if pair then
                    local a, b = getBone(Util.char(plr), pair[1]), getBone(Util.char(plr), pair[2])
                    if a and b then
                        local pa, oa = Camera:WorldToViewportPoint(a.Position)
                        local pb, ob = Camera:WorldToViewportPoint(b.Position)
                        line.From = Vector2.new(pa.X, pa.Y)
                        line.To = Vector2.new(pb.X, pb.Y)
                        line.Color = col
                        show(line, Config.ESP_Skeleton and oa and ob)
                    else
                        line.Visible = false
                    end
                end
            end
        end
    end

    -- FOV Circle для аимбота
    if HAS_DRAWING and not ESP.fov then
        ESP.fov = newDraw("Circle", { Thickness = 1.5, Filled = false, NumSides = 64 })
    end
    if ESP.fov then
        ESP.fov.Visible = Config.FOV_Circle
        ESP.fov.Radius = Config.FOV_Size * Camera.ViewportSize.Y / 1000
        ESP.fov.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        ESP.fov.Color = Color3.fromRGB(180, 160, 255)
    end

    -- Gun ESP: подсветка выпавшего оружия
    if Config.ESP_GunESP then
        for _, inst in ipairs(Workspace:GetChildren()) do
            local n = inst.Name:lower()
            if (n:find("gun") or n:find("knife")) and inst:IsA("BasePart") then
                local hl = inst:FindFirstChild("MM2_GUN_HL") or Instance.new("Highlight")
                hl.Name = "MM2_GUN_HL"
                hl.Adornee = inst
                hl.FillColor = n:find("gun") and ROLE_COLOR.Sheriff or ROLE_COLOR.Murderer
                hl.FillTransparency = 0.35
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = (CoreGui or GuiParent)
            end
        end
    end
end

--==============================================================================
-- 11. МОДУЛЬ: ДВИЖЕНИЕ
--==============================================================================
local Move = {}
local flyVel, flyGyro

function Move.applyBasics()
    local h = Util.hum(LocalPlayer)
    if h then
        h.WalkSpeed = Config.WalkSpeed
        h.UseJumpPower = true
        h.JumpPower = Config.JumpPower
    end
end

function Move.infJump()
    UserInput.JumpRequest:Connect(function()
        if Config.InfJump then
            local h = Util.hum(LocalPlayer)
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
end

function Move.fly(dt)
    local root = Util.root(LocalPlayer)
    if not root then return end
    if Config.Fly then
        if not flyVel then
            flyVel = Instance.new("BodyVelocity")
            flyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            flyVel.Velocity = Vector3.zero
            flyVel.Parent = root
            flyGyro = Instance.new("BodyGyro")
            flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            flyGyro.P = 9e4
            flyGyro.Parent = root
        end
        local cam = Camera.CFrame
        local dir = Vector3.zero
        if UserInput:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
        flyVel.Velocity = dir.Magnitude > 0 and dir.Unit * Config.FlySpeed or Vector3.zero
        flyGyro.CFrame = cam
    elseif flyVel then
        flyVel:Destroy() flyVel = nil
        if flyGyro then flyGyro:Destroy() flyGyro = nil end
    end
end

function Move.noclip()
    if not Config.Noclip then return end
    local c = Util.char(LocalPlayer)
    if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") then d.CanCollide = false end
    end
end

function Move.spinBot(dt)
    if not Config.SpinBot then return end
    local root = Util.root(LocalPlayer)
    if root then
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed * dt * 60), 0)
    end
end

--==============================================================================
-- 12. МОДУЛЬ: ЭМОЦИИ / EMOTE UNLOCKER
--==============================================================================
local Emotes = {
    ["Floss"]  = { id = 5917459365 },
    ["Dab"]    = { id = 5915779036 },
    ["Ninja"]  = { id = 5915779036 },
    ["Headless"] = { id = 0 },  -- 0 = только визуальная замена головы
    ["Zombie"] = { id = 3134662895 },
}
local playingAnim
function Move.playEmote(name)
    local data = Emotes[name] or Emotes.Floss
    local hum = Util.hum(LocalPlayer)
    if not hum then return end
    -- 1) пробуем штатную систему эмоций MM2
    local r = Util.findRemote({ "emote", "playemote", "dance" })
    if r then pcall(function() r:FireServer(name) end) end
    -- 2) локальная анимация
    if data.id and data.id > 0 then
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. data.id
        local track = hum:FindFirstChildOfClass("Animator"):LoadAnimation(anim)
        if playingAnim then playingAnim:Stop() end
        track:Play()
        playingAnim = track
    end
    if name == "Headless" then
        local head = Util.head(LocalPlayer)
        if head then
            for _, d in ipairs(head:GetDescendants()) do
                if d:IsA("Decal") then d.Transparency = 1 end
            end
        end
    end
    Util.notify("Emote", "Эмоция: " .. name, 2)
end

--==============================================================================
-- 13. МОДУЛЬ: СЕРВЕРА (hop / rejoin / job id)
--==============================================================================
local Server = {}

function Server.copyJobId()
    if setclipboard then setclipboard(JobId) end
    if toclipboard then toclipboard(JobId) end
    Util.notify("Job ID", "Скопирован: " .. JobId, 3)
end

function Server.rejoin()
    TeleportService:Teleport(PlaceId, LocalPlayer)
end

function Server.hop(mode)
    -- mode = "low" | "full"
    if not (HAS_REQUEST or typeof(game.HttpGet) == "function") then
        Util.notify("Server Hop", "HTTP недоступен в этом исполнителе", 4)
        return
    end
    Util.safe(function()
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PlaceId)
        local body = HAS_REQUEST
            and request({ Url = url, Method = "GET" }).Body
            or game:HttpGet(url)
        local data = HttpService:JSONDecode(body)
        local list = {}
        for _, s in ipairs(data.data or {}) do
            if s.id ~= JobId and s.playing < s.maxPlayers then table.insert(list, s) end
        end
        if #list == 0 then Util.notify("Server Hop", "Подходящих серверов нет", 3) return end
        table.sort(list, function(a, b)
            if mode == "full" then return a.playing > b.playing end
            return a.playing < b.playing
        end)
        local pick = list[1]
        TeleportService:TeleportToPlaceInstance(PlaceId, pick.id, LocalPlayer)
        Util.notify("Server Hop", ("→ %d/%d игроков"):format(pick.playing, pick.maxPlayers), 3)
    end)
end

--==============================================================================
-- 14. ГЛАВНЫЙ ЦИКЛ (один Heartbeat = ноль лишних коннектов = нет лагов)
--==============================================================================
local acc = { coin = 0, box = 0, combat = 0, guard = 0, misc = 0 }
local COIN_TICK, BOX_TICK, COMBAT_TICK, GUARD_TICK, MISC_TICK = Config.CoinDelay, 0.8, Config.AuraDelay, 0.1, 0.25

RunService.Heartbeat:Connect(function(dt)
    -- ФАРМ
    -- Pathfind (Baritone) должен работать каждый кадр — иначе ходьба рвётся
    Farm.Path.step(dt)
    if Config.CoinFarm then
        acc.coin = acc.coin + dt
        -- читаем Config.CoinDelay «живьём», чтобы ползунок менял скорость сразу
        if acc.coin >= math.max(0.02, Config.CoinDelay) then acc.coin = 0 Farm.collectCoins() end
        Farm.fastTP() -- внутри свой таймер по CoinInterval
    end
    if Config.BoxFarm or Config.EventFarm then
        acc.box = acc.box + dt
        if acc.box >= BOX_TICK then acc.box = 0
            if Config.BoxFarm then Farm.openBoxes() end
            if Config.EventFarm then Farm.collectEvents() end
        end
    end
    -- КОМБАТ
    if Config.KillAura or Config.AutoApproach or Config.GunGrabber or Config.KnifeDodge
        or Config.AutoKillMurderer or Config.AutoKillSheriff then
        acc.combat = acc.combat + dt
        if acc.combat >= math.max(0.05, Config.AuraDelay) then acc.combat = 0
            if Config.AutoKillMurderer or Config.AutoKillSheriff then Combat.autoKillStep() end
            if Config.KillAura then Farm.tryPrestige() Combat.killAuraStep() end
            if Config.AutoApproach then Combat.approachStep() end
            if Config.GunGrabber then Combat.gunGrabber() end
            if Config.KnifeDodge then Combat.knifeDodge() end
        end
    end
    -- ЗАЩИТА
    acc.guard = acc.guard + dt
    if acc.guard >= GUARD_TICK then acc.guard = 0
        if Config.PositionGuard then Guard.positionSanity() end -- фикс кика "Invalid Position"
        if Config.AntiFling then Guard.antiFling() end
        if Config.AntiVoid or Config.AntiLava then Guard.antiVoid() end
        if Config.GodMode or Config.SecondChance then Guard.godMode() end
        if Config.HitboxExpand then Combat.applyHitbox() end
    end
    -- ПРОЧЕЕ
    acc.misc = acc.misc + dt
    if acc.misc >= MISC_TICK then acc.misc = 0
        Role.RefreshSelf()
        Move.applyBasics()
        if Config.Noclip then Move.noclip() end
        if Config.Invisible then Guard.invisible() end
        if Config.StreamerMode then Guard.streamerMode() end
        if Config.AutoFakeCheck then Combat.fakeWeaponCheck() end
        -- Kill All / Kill Sheriff / Kill Murderer вызываются кнопками вкладки Rage,
        -- чтобы не спамить ремоуты каждый тик (меньше следов в логах сервера)
    end
    Move.fly(dt)
    Move.spinBot(dt)
end)

RunService.RenderStepped:Connect(function(dt)
    ESP.render(dt)
end)

Farm.startSessionGuard()
Move.infJump()

--==============================================================================
-- 15. UI-ДВИЖОК (Rayfield-совместимый по API, собственная реализация)
--      Window:Tab / :Section / :Toggle / :Slider / :Dropdown / :Button /
--      :Keybind / :ColorPicker / :Paragraph — тот же синтаксис вызова
--==============================================================================
local UI = {}
UI.__index = UI
local THEME = {
    bg = Color3.fromRGB(11, 14, 23), panel = Color3.fromRGB(17, 22, 36),
    line = Color3.fromRGB(30, 36, 54), text = Color3.fromRGB(230, 233, 242),
    dim = Color3.fromRGB(148, 158, 180), accent = Color3.fromRGB(124, 92, 255),
    accent2 = Color3.fromRGB(34, 211, 238),
}

local function mk(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

function UI.new(cfg)
    cfg = cfg or {}
    local self = setmetatable({}, UI)
    self.state = { minimized = not (Config.UI_Visible) }

    local gui = mk("ScreenGui", {
        Name = "MM2_HUB_X", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true, DisplayOrder = 9999,
    }, GuiParent)

    local main = mk("Frame", {
        Size = UDim2.fromOffset(700, 470), Position = UDim2.fromScale(.5, .5),
        AnchorPoint = Vector2.new(.5, .5), BackgroundColor3 = THEME.bg, BorderSizePixel = 0,
    }, gui)
    mk("UICorner", { CornerRadius = UDim.new(0, 14) }, main)
    mk("UIStroke", { Color = THEME.line, Thickness = 1 }, main)

    -- Тайтлбар + drag
    local title = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = THEME.panel, BorderSizePixel = 0,
    }, main)
    mk("UICorner", { CornerRadius = UDim.new(0, 14) }, title)
    mk("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = THEME.line, BorderSizePixel = 0 }, title)
    mk("TextLabel", {
        Size = UDim2.new(1, -110, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1,
        Text = "  MM2 HUB X  •  " .. (cfg.Version or "2.5.0"), TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = THEME.text, Font = Enum.Font.GothamBold, TextSize = 15,
    }, title)
    mk("TextLabel", {
        Size = UDim2.new(0, 260, 1, 0), Position = UDim2.new(1, -274, 0, 0), BackgroundTransparency = 1,
        Text = ExecName .. "  |  KEYLESS", TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = THEME.dim, Font = Enum.Font.Gotham, TextSize = 11,
    }, title)

    local minBtn = mk("TextButton", {
        Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -34, .5, -13),
        BackgroundColor3 = THEME.line, Text = "—", TextColor3 = THEME.text,
        Font = Enum.Font.GothamBold, TextSize = 14,
    }, title)
    mk("UICorner", { CornerRadius = UDim.new(0, 8) }, minBtn)

    -- Перетаскивание окна
    do
        local dragging, dragStart, startPos = false, nil, nil
        title.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true dragStart = input.Position startPos = main.Position
            end
        end)
        UserInput.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        UserInput.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
    end

    -- Таб-бар
    local sidebar = mk("Frame", {
        Size = UDim2.new(0, 168, 1, -42), Position = UDim2.new(0, 0, 0, 42),
        BackgroundColor3 = THEME.bg, BorderSizePixel = 0,
    }, main)
    mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
    mk("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, sidebar)

    local body = mk("Frame", {
        Size = UDim2.new(1, -168, 1, -42), Position = UDim2.new(0, 168, 0, 42),
        BackgroundTransparency = 1, BorderSizePixel = 0,
    }, main)
    mk("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }, body)

    self.gui, self.main, self.sidebar, self.body = gui, main, sidebar, body
    self.tabs, self.current = {}, nil

    minBtn.MouseButton1Click:Connect(function() self:SetMinimized(not self.state.minimized) end)
    UserInput.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            self:SetMinimized(not self.state.minimized)
        end
    end)

    -- Уведомления
    Notify = function(title, text, dur)
        local n = mk("Frame", {
            Size = UDim2.fromOffset(280, 62), Position = UDim2.new(1, 300, 1, -80),
            AnchorPoint = Vector2.new(0, 1), BackgroundColor3 = THEME.panel, BorderSizePixel = 0,
        }, gui)
        mk("UICorner", { CornerRadius = UDim.new(0, 12) }, n)
        mk("UIStroke", { Color = THEME.accent, Thickness = 1, Transparency = .4 }, n)
        mk("TextLabel", {
            Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 12, 0, 8), BackgroundTransparency = 1,
            Text = title, TextColor3 = THEME.accent2, Font = Enum.Font.GothamBold, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, n)
        mk("TextLabel", {
            Size = UDim2.new(1, -24, 0, 30), Position = UDim2.new(0, 12, 0, 28), BackgroundTransparency = 1,
            Text = text, TextColor3 = THEME.text, Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, n)
        TweenService:Create(n, TweenInfo.new(.35, Enum.EasingStyle.Quint), { Position = UDim2.new(1, -300, 1, -80) }):Play()
        task.delay(dur or 3, function()
            TweenService:Create(n, TweenInfo.new(.3), { Position = UDim2.new(1, 300, 1, -80) }):Play()
            task.wait(.32) n:Destroy()
        end)
    end

    return self
end

function UI:SetMinimized(v)
    self.state.minimized = v
    Set("UI_Visible", not v)
    local goal = v and UDim2.fromOffset(220, 42) or UDim2.fromOffset(700, 470)
    TweenService:Create(self.main, TweenInfo.new(.28, Enum.EasingStyle.Quint), { Size = goal }):Play()
    self.sidebar.Visible = not v
    self.body.Visible = not v
end

function UI:Tab(name, order)
    local btn = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = THEME.bg, Text = "  " .. name,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = THEME.dim,
        Font = Enum.Font.GothamMedium, TextSize = 13, AutoButtonColor = false,
        LayoutOrder = order or #self.tabs + 1,
    }, self.sidebar)
    mk("UICorner", { CornerRadius = UDim.new(0, 9) }, btn)

    local page = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.new(), ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.accent,
        Visible = false, LayoutOrder = order or 1,
    }, self.body)
    mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    mk("UIPadding", { PaddingBottom = UDim.new(0, 12) }, page)

    local tab = { name = name, btn = btn, page = page }
    table.insert(self.tabs, tab)
    btn.MouseButton1Click:Connect(function() self:Select(name) end)
    if #self.tabs == 1 then self:Select(name) end
    return tab
end

function UI:Select(name)
    for _, t in ipairs(self.tabs) do
        local on = t.name == name
        t.page.Visible = on
        t.btn.TextColor3 = on and THEME.text or THEME.dim
        TweenService:Create(t.btn, TweenInfo.new(.2), {
            BackgroundColor3 = on and Color3.fromRGB(124, 92, 255) or THEME.bg,
        }):Play()
        if on then
            t.page.CanvasSize = UDim2.new(0, 0, 0, t.page.UIListLayout.AbsoluteContentSize.Y + 24)
        end
    end
end

-- --- контролы ---------------------------------------------------------------
--[[ ИСПРАВЛЕНО: раньше LayoutOrder = #tab.page:GetChildren() ДО добавления элемента.
     Секция и первая строка получали одинаковый order и НАКЛАДЫВАЛИСЬ друг на друга —
     из-за этого ползунки были перекрыты и не нажимались.
     Теперь у каждой вкладки свой счётчик, а CanvasSize пересчитывается сразу. ]]

local function nextOrder(tab)
    tab._order = (tab._order or 0) + 1
    return tab._order
end

local function refreshCanvas(tab)
    local page = tab.page
    local layout = page:FindFirstChildOfClass("UIListLayout")
    if layout then
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 26)
    end
end

function UI._section(tab, title)
    return mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = title,
        TextColor3 = THEME.accent2, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = nextOrder(tab),
    }, tab.page)
end

function UI._row(tab, h)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, h or 34), BackgroundColor3 = THEME.panel,
        BorderSizePixel = 0, LayoutOrder = nextOrder(tab),
    }, tab.page)
    mk("UICorner", { CornerRadius = UDim.new(0, 10) }, row)
    mk("UIStroke", { Color = THEME.line, Thickness = 1 }, row)
    -- контент мог добавиться после выбора вкладки → обновляем высоту скролла
    task.defer(refreshCanvas, tab)
    return row
end

function UI:Paragraph(tab, props)
    local row = UI._row(tab, 0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    -- Content может быть строкой ИЛИ функцией (живой текст, например статистика фарма)
    local body = (type(props.Content) == "function") and tostring(props.Content()) or (props.Content or "")
    mk("TextLabel", {
        Size = UDim2.new(1, -24, 0, 0), Position = UDim2.new(0, 12, 0, 8), BackgroundTransparency = 1,
        Text = (props.Title and props.Title .. "\n" or "") .. body,
        TextColor3 = props.Color or THEME.text, TextWrapped = true, RichText = true,
        Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    return row
end

function UI:Toggle(tab, props)
    local row = UI._row(tab)
    mk("TextLabel", {
        Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
        Text = props.Name, TextColor3 = THEME.text, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local sw = mk("TextButton", {
        Size = UDim2.fromOffset(44, 22), Position = UDim2.new(1, -56, .5, -11),
        BackgroundColor3 = Color3.fromRGB(27, 33, 51), Text = "",
    }, row)
    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, sw)
    local knob = mk("Frame", {
        Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 3, .5, -8),
        BackgroundColor3 = Color3.fromRGB(120, 130, 160),
    }, sw)
    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local state = Config[props.Flag] == true
    local function paint(on)
        TweenService:Create(sw, TweenInfo.new(.2), {
            BackgroundColor3 = on and THEME.accent or Color3.fromRGB(27, 33, 51),
        }):Play()
        TweenService:Create(knob, TweenInfo.new(.2), {
            Position = on and UDim2.new(1, -19, .5, -8) or UDim2.new(0, 3, .5, -8),
            BackgroundColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(120, 130, 160),
        }):Play()
    end
    paint(state)

    local function set(v, silent)
        state = v
        paint(v)
        Set(props.Flag, v)
        if props.Callback then pcall(props.Callback, v) end
    end
    sw.MouseButton1Click:Connect(function() set(not state) end)

    Flags[props.Flag] = { type = "toggle", set = function(v) set(v, true) end }
    if state and props.Callback then task.spawn(props.Callback, state) end
    return { Set = set, Get = function() return state end }
end

function UI:Slider(tab, props)
    local row = UI._row(tab, 46)
    local label = mk("TextLabel", {
        Size = UDim2.new(1, -24, 0, 18), Position = UDim2.new(0, 12, 0, 5), BackgroundTransparency = 1,
        Text = props.Name, TextColor3 = THEME.text, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local value = mk("TextLabel", {
        Size = UDim2.new(0, 90, 0, 18), Position = UDim2.new(1, -102, 0, 5), BackgroundTransparency = 1,
        Text = "", TextColor3 = THEME.accent2, Font = Enum.Font.Code, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)
    local bar = mk("TextButton", {
        Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 12, 0, 30),
        BackgroundColor3 = Color3.fromRGB(27, 33, 51), Text = "", AutoButtonColor = false,
    }, row)
    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
    local fill = mk("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = THEME.accent, BorderSizePixel = 0 }, bar)
    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

    local function pct(v) return (v - props.Min) / (props.Max - props.Min) end
    local function apply(v, silent)
        v = Util.clamp(math.floor(v / (props.Increment or 1) + .5) * (props.Increment or 1), props.Min, props.Max)
        fill.Size = UDim2.new(pct(v), 0, 1, 0)
        value.Text = tostring(v) .. (props.Suffix or "")
        Set(props.Flag, v)
        if props.Callback and not silent then pcall(props.Callback, v) end
    end
    apply(Config[props.Flag] or props.Default or props.Min, true)

    --[[
        ИСПРАВЛЕНО: перетаскивание работает по ВСЕЙ строке (а не только по полоске),
        поддерживается тач (Delta/Hydrogen/Codex) и колёсико мыши.
        Позиция берётся из AbsolutePosition в момент движения, поэтому
        скроллинг вкладки во время драга не ломает значение.
    ]]
    bar.Active = true
    row.Active = true
    local sliding = false
    local function relFrom(input)
        local minX = bar.AbsolutePosition.X
        local w = math.max(1, bar.AbsoluteSize.X)
        return Util.clamp((input.Position.X - minX) / w, 0, 1)
    end
    local function drag(input)
        if not sliding then return end
        local kind = input.UserInputType
        if kind == Enum.UserInputType.MouseMovement or kind == Enum.UserInputType.Touch then
            apply(props.Min + relFrom(input) * (props.Max - props.Min))
        end
    end
    local function startDrag(i)
        local k = i.UserInputType
        if k == Enum.UserInputType.MouseButton1 or k == Enum.UserInputType.Touch then
            sliding = true
            apply(props.Min + relFrom(i) * (props.Max - props.Min))
        end
    end
    bar.InputBegan:Connect(startDrag)
    row.InputBegan:Connect(startDrag)
    UserInput.InputChanged:Connect(drag)
    UserInput.InputEnded:Connect(function(i)
        local k = i.UserInputType
        if k == Enum.UserInputType.MouseButton1 or k == Enum.UserInputType.Touch then sliding = false end
    end)
    -- колёсико мыши над строкой = шаг значения
    row.InputChanged:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseWheel then
            local step = props.Increment or math.max(1, math.floor((props.Max - props.Min) / 100))
            apply(Config[props.Flag] + (i.Position.Z > 0 and step or -step))
        end
    end)

    Flags[props.Flag] = { type = "slider", set = function(v) apply(v, true) end }
    return { Set = apply, Get = function() return Config[props.Flag] end }
end

function UI:Dropdown(tab, props)
    local row = UI._row(tab, 40)
    mk("TextLabel", {
        Size = UDim2.new(1, -24, 0, 16), Position = UDim2.new(0, 12, 0, 4), BackgroundTransparency = 1,
        Text = props.Name, TextColor3 = THEME.dim, Font = Enum.Font.Gotham, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local btn = mk("TextButton", {
        Size = UDim2.new(1, -24, 0, 0), Position = UDim2.new(0, 12, 0, 19), BackgroundTransparency = 1,
        Text = tostring(Config[props.Flag] or props.Options[1]) .. "  ▾", TextColor3 = THEME.text,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local current = Config[props.Flag] or props.Options[1]
    local open, list = false, nil
    btn.MouseButton1Click:Connect(function()
        open = not open
        if open and not list then
            list = mk("Frame", {
                Size = UDim2.new(1, -24, 0, #props.Options * 24), Position = UDim2.new(0, 12, 0, 19),
                BackgroundColor3 = Color3.fromRGB(9, 12, 20), BorderSizePixel = 0, ZIndex = 5,
            }, row)
            mk("UICorner", { CornerRadius = UDim.new(0, 8) }, list)
            for i, opt in ipairs(props.Options) do
                local b = mk("TextButton", {
                    Size = UDim2.new(1, -8, 0, 22), Position = UDim2.new(0, 4, 0, (i - 1) * 23),
                    BackgroundTransparency = 1, Text = "  " .. tostring(opt), TextColor3 = THEME.dim,
                    Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
                }, list)
                b.MouseButton1Click:Connect(function()
                    current = opt
                    btn.Text = tostring(opt) .. "  ▾"
                    Set(props.Flag, opt)
                    if props.Callback then pcall(props.Callback, opt) end
                    open = false list:Destroy() list = nil
                end)
            end
        elseif list then
            list:Destroy() list = nil
        end
    end)
    Flags[props.Flag] = { type = "dropdown", set = function(v) current = v btn.Text = tostring(v) .. "  ▾" end }
end

function UI:Button(tab, props)
    local row = UI._row(tab, 32)
    local b = mk("TextButton", {
        Size = UDim2.new(1, -24, 0, 22), Position = UDim2.new(0, 12, .5, -11),
        BackgroundColor3 = Color3.fromRGB(27, 33, 51), Text = props.Name, TextColor3 = THEME.text,
        Font = Enum.Font.GothamMedium, TextSize = 13,
    }, row)
    mk("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
    b.MouseButton1Click:Connect(function()
        TweenService:Create(b, TweenInfo.new(.08), { BackgroundColor3 = THEME.accent }):Play()
        task.delay(.1, function() TweenService:Create(b, TweenInfo.new(.2), { BackgroundColor3 = Color3.fromRGB(27, 33, 51) }):Play() end)
        if props.Callback then task.spawn(props.Callback) end
    end)
    return b
end

function UI:Keybind(tab, props)
    local row = UI._row(tab, 32)
    mk("TextLabel", {
        Size = UDim2.new(1, -120, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
        Text = props.Name, TextColor3 = THEME.text, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local btn = mk("TextButton", {
        Size = UDim2.fromOffset(96, 22), Position = UDim2.new(1, -108, .5, -11),
        BackgroundColor3 = Color3.fromRGB(27, 33, 51), Text = props.Default and props.Default.Name or "None",
        TextColor3 = THEME.accent2, Font = Enum.Font.Code, TextSize = 12,
    }, row)
    mk("UICorner", { CornerRadius = UDim.new(0, 8) }, btn)
    local listening = false
    btn.MouseButton1Click:Connect(function() listening = true btn.Text = "..." end)
    UserInput.InputBegan:Connect(function(input, gp)
        if not listening or gp then return end
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            listening = false
            btn.Text = input.KeyCode.Name
            if props.Callback then pcall(props.Callback, input.KeyCode) end
        end
    end)
end

function UI:ColorPicker(tab, props)
    local row = UI._row(tab, 32)
    mk("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
        Text = props.Name, TextColor3 = THEME.text, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local cur = props.Default or Color3.fromRGB(124, 92, 255)
    local btn = mk("TextButton", {
        Size = UDim2.fromOffset(44, 20), Position = UDim2.new(1, -56, .5, -10),
        BackgroundColor3 = cur, Text = "",
    }, row)
    mk("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
    btn.MouseButton1Click:Connect(function()
        -- простой HSV-перебор по клику (без внешних библиотек)
        local h, s, v = cur:ToHSV()
        cur = Color3.fromHSV((h + .07) % 1, s, v)
        btn.BackgroundColor3 = cur
        if props.Callback then pcall(props.Callback, cur) end
    end)
end

--==============================================================================
-- 16. СБОРКА ИНТЕРФЕЙСА
--==============================================================================
local Window = UI.new({ Title = "MM2 HUB X", Version = "2.6.0" })

-- ------------------------------- LEGIT --------------------------------------
local Legit = Window:Tab("Legit", 1)
UI._section(Legit, "СИЛЕНТ АИМ (ШЕРИФ)")
UI:Toggle(Legit, { Name = "Silent Aim", Flag = "SilentAim", Callback = function(v)
    if v then Combat.startSilentAim() end
end })
UI:Slider(Legit, { Name = "FOV аимбота", Flag = "SA_FOV", Min = 10, Max = 360, Default = 70, Suffix = "°", Callback = function(v)
    Config.SA_FOV = v Config.FOV_Size = v Set("FOV_Size", v)
end })
UI:Dropdown(Legit, { Name = "Приоритет", Flag = "SA_Priority", Options = { "Head", "Torso", "Nearest" },
    Callback = function(v) Config.SA_Priority = (v == "Nearest" and "Head" or v) end })
UI:Toggle(Legit, { Name = "Wall Check", Flag = "SA_WallCheck" })
UI:Slider(Legit, { Name = "Плавность", Flag = "SA_Smooth", Min = 0, Max = 1, Default = .35, Increment = .05, Callback = function(v) Config.SA_Smooth = v end })
UI:Toggle(Legit, { Name = "Круг FOV", Flag = "FOV_Circle" })
UI._section(Legit, "ЛЕГИТ-ПОДДЕРЖКА")
UI:Toggle(Legit, { Name = "Gun Grabber (авто-подбор пистолета)", Flag = "GunGrabber" })
UI:Toggle(Legit, { Name = "Auto Dodge Knives", Flag = "KnifeDodge" })
UI:Slider(Legit, { Name = "Радиус доджа", Flag = "DodgeDist", Min = 10, Max = 150, Default = 45, Suffix = " ст." })
UI:Paragraph(Legit, {
    Title = "⚠ ВНИМАНИЕ",
    Content = "Использование на свой риск. Рекомендуется аккаунт-альтернатива.",
    Color = Color3.fromRGB(255, 205, 110),
})

-- ------------------------------- RAGE ---------------------------------------
local Rage = Window:Tab("Rage", 2)
UI._section(Rage, "KILL AURA (МАРДЕР)")
UI:Toggle(Rage, { Name = "Kill Aura", Flag = "KillAura" })
UI:Slider(Rage, { Name = "Радиус убийства", Flag = "AuraRadius", Min = 5, Max = 100, Default = 22, Suffix = " ст." })
UI:Toggle(Rage, { Name = "Авто-бросок ножа", Flag = "AuraAutoThrow" })
UI:Toggle(Rage, { Name = "Только ближайшие цели", Flag = "AuraOnlyNear" })
UI:Slider(Rage, { Name = "Задержка атаки", Flag = "AuraDelay", Min = .05, Max = 2, Default = .25, Increment = .05, Suffix = " с" })
UI:Toggle(Rage, { Name = "Продвинутый: авто-подход к цели", Flag = "AutoApproach" })
UI:Slider(Rage, { Name = "Скорость подхода", Flag = "ApproachSpeed", Min = 16, Max = 200, Default = 95 })
UI._section(Rage, "ХИТБОКС И ДЕЙСТВИЯ")
UI:Toggle(Rage, { Name = "Hitbox Expander", Flag = "HitboxExpand" })
UI:Slider(Rage, { Name = "Размер хитбокса", Flag = "HitboxSize", Min = 2, Max = 100, Default = 12, Suffix = " ст." })
UI:Button(Rage, { Name = "🔪 KILL ALL", Callback = function() Combat.killAll(nil) end })
UI:Button(Rage, { Name = "⭐ KILL SHERIFF", Callback = function() Combat.killAll("Sheriff") end })
UI:Button(Rage, { Name = "🩸 KILL MURDERER", Callback = function() Combat.killAll("Murderer") end })
UI._section(Rage, "АВТО-КИЛЛ ПО РОЛЯМ")
UI:Toggle(Rage, { Name = "🩸 АВТО-КИЛЛ МРДЕРА (ТП вплотную + моментально)", Flag = "AutoKillMurderer", Callback = function(v)
    if v then Util.notify("Авто-килл", "Ищу Мрдера: телепорт вплотную + мгновенное убийство", 4) end
end })
UI:Toggle(Rage, { Name = "⭐ АВТО-КИЛЛ ШЕРИФА (через FLING)", Flag = "AutoKillSheriff", Callback = function(v)
    if v then
        if Config.AntiFling then
            Util.notify("Авто-килл", "Шериф: флинг-килл. Anti-Fling пропускает свой флинг ✓", 4)
        else
            Util.notify("Авто-килл", "⚠ Anti-Fling выключен — включи, иначе чужой флинг собьёт твой", 4)
        end
    end
end })
UI:Dropdown(Rage, { Name = "Способ мгновенного убийства", Flag = "InstantKillMethod", Options = { "Touch", "Remote", "Hybrid" },
    Callback = function(v)
        local info = {
            Touch  = "firetouchinterest рукоятью ножа — самый стабильный в MM2",
            Remote = "прямая отправка knife-hit / throw ремоута",
            Hybrid = "Touch + Remote одновременно (максимальный шанс)",
        }
        Util.notify("Kill Method", info[v] or v, 4)
    end })
UI:Dropdown(Rage, { Name = "Режим флинг-килла", Flag = "FlingKillMode", Options = { "Spin", "Void", "Wall" },
    Callback = function(v)
        local info = {
            Spin = "раскрутка с разлётом во все стороны + добивание",
            Void = "швыряем за FallenPartsDestroyHeight — сервер убивает сам",
            Wall = "бьём в ближайшую стену по направлению камеры",
        }
        Util.notify("Fling Mode", info[v] or v, 4)
    end })
UI:Slider(Rage, { Name = "Сила флинга", Flag = "FlingPower", Min = 1000, Max = 500000, Default = 100000, Increment = 1000 })
UI:Slider(Rage, { Name = "Длительность флинга", Flag = "FlingDuration", Min = .3, Max = 6, Default = 1.6, Increment = .1, Suffix = " с" })
UI:Slider(Rage, { Name = "Кулдаун между киллами", Flag = "KillCooldown", Min = .2, Max = 5, Default = 1, Increment = .1, Suffix = " с" })
UI:Toggle(Rage, { Name = "Репроверять роль (не убивать инносента)", Flag = "KillRecheckRole" })
UI:Toggle(Rage, { Name = "Телепортироваться вплотную перед киллом", Flag = "KillTeleportClose" })

UI._section(Rage, "FLING (РУЧНОЙ)")
UI:Button(Rage, { Name = "☠ FLING БЛИЖАЙШЕГО (подтверждение)", Callback = function()
    local t = nearestTarget(80, false)
    if t then
        -- двойное подтверждение = защита от случайного нажатия
        local confirmed = false
        Util.notify("Fling", "Цель: " .. t.Name .. " — нажмите кнопку ещё раз", 4)
        UI._flingArmed = t.Name
        task.delay(3, function() UI._flingArmed = nil end)
    end
end })
UI:Button(Rage, { Name = "☠ FLING — ПОДТВЕРДИТЬ", Callback = function()
    if UI._flingArmed then
        local t = nil
        for _, p in ipairs(PlayerList) do if p.Name == UI._flingArmed then t = p end end
        if t then Combat.flingKill(t, Config.FlingKillMode) UI._flingArmed = nil end
    else
        Util.notify("Fling", "Сначала выберите цель предыдущей кнопкой", 3)
    end
end })

-- ------------------------------ FARMING -------------------------------------
local FarmTab = Window:Tab("Farming", 3)
UI._section(FarmTab, "ФАРМ МОНЕТ")
UI:Toggle(FarmTab, { Name = "Авто-сбор монет", Flag = "CoinFarm" })
UI:Dropdown(FarmTab, { Name = "Режим фарма", Flag = "CoinMode", Options = { "Pathfind", "FastTP", "Near", "Teleport" },
    Callback = function(v)
        Config.CoinMode = v
        Util.notify("Фарм", "Режим: " .. v, 2)
    end })
UI:Slider(FarmTab, { Name = "Радиус поиска (для Near)", Flag = "CoinRadius", Min = 20, Max = 2000, Default = 150, Suffix = " ст." })
UI:Slider(FarmTab, { Name = "Пауза между сборами (Near/Teleport)", Flag = "CoinDelay", Min = .02, Max = 1.5, Default = .12, Increment = .02, Suffix = " с" })
UI:Toggle(FarmTab, { Name = "Smart: обходить игроков", Flag = "CoinSmartAvoid" })
UI:Slider(FarmTab, { Name = "Сброс при полном мешке (шт.)", Flag = "CoinBagReset", Min = 0, Max = 200, Default = 35, Suffix = " шт." })

UI._section(FarmTab, "PATHFIND — ХОДЬБА КАК BARITONE (100% ЛЕГИТ)")
UI:Paragraph(FarmTab, {
    Title = "Как работает",
    Content = "PathfindingService строит настоящий маршрут до монеты: скрипт ИДЁТ по нему (Humanoid:MoveTo), обходит стены и лаву, прыгает через препятствия, детектит застревание и перестраивает путь. Ни одного телепорта — для сервера это обычный игрок.",
})
UI:Toggle(FarmTab, { Name = "Автопрыжок через препятствия", Flag = "PathJump" })
UI:Slider(FarmTab, { Name = "Перестроение пути", Flag = "PathRepath", Min = .2, Max = 3, Default = .5, Increment = .1, Suffix = " с" })
UI:Slider(FarmTab, { Name = "Толщина «тела» (AgentRadius)", Flag = "PathAgentRadius", Min = 1, Max = 8, Default = 2.2, Increment = .2 })
UI:Slider(FarmTab, { Name = "Точность подхода к монете", Flag = "PathStopDist", Min = 2, Max = 12, Default = 3.5, Increment = .5, Suffix = " ст." })

UI._section(FarmTab, "FASTTP — ТЕЛЕПОРТ РАЗ В N СЕКУНД")
UI:Paragraph(FarmTab, {
    Title = "1 телепорт в секунду",
    Content = "Максимально «человечный» телепорт-фарм: один прыжок к монете в заданный интервал (по умолчанию 1 с), без потока телепортов каждый кадр. Поставь 0.5–2 с под свой сервер.",
})
UI:Slider(FarmTab, { Name = "Интервал телепорта", Flag = "CoinInterval", Min = .15, Max = 5, Default = 1, Increment = .05, Suffix = " с" })
UI:Button(FarmTab, { Name = "⚡ Телепорт к ближайшей монете сейчас", Callback = function()
    local p = Farm.findCoin()
    if p then Util.safeTP(CFrame.new(p.Position)) Farm.collected = Farm.collected + 1
    else Util.notify("Фарм", "Монет в радиусе нет", 2) end
end })
UI._section(FarmTab, "БОКСЫ / ИВЕНТЫ / ПРОГРЕСС")
UI:Toggle(FarmTab, { Name = "Авто-открытие Mystery Box", Flag = "BoxFarm" })
UI:Toggle(FarmTab, { Name = "Авто-сбор ивентовых предметов", Flag = "EventFarm" })
UI:Toggle(FarmTab, { Name = "Авто-престиж / ребёрт", Flag = "AutoPrestige" })
UI:Slider(FarmTab, { Name = "Уровень для престижа", Flag = "PrestigeLevel", Min = 10, Max = 1000, Default = 100 })
UI._section(FarmTab, "СЕССИЯ")
UI:Toggle(FarmTab, { Name = "Anti-AFK", Flag = "AntiAFK" })
UI:Toggle(FarmTab, { Name = "Авто-реконнект после кика", Flag = "AutoReconnect" })
UI:Paragraph(FarmTab, {
    Title = "Статистика фарма",
    Content = function() return ("Собрано за сессию: %d монет | Киллов: %d | Уровень: %d"):format(Farm.collected, Combat.kills or 0, Farm.myLevel()) end,
})

-- -------------------------------- ESP ---------------------------------------
local EspTab = Window:Tab("ESP", 4)
UI._section(EspTab, "ОСНОВНОЙ ESP")
UI:Toggle(EspTab, { Name = "Player ESP", Flag = "ESP_Enabled" })
UI:Toggle(EspTab, { Name = "Boxes", Flag = "ESP_Box" })
UI:Toggle(EspTab, { Name = "Names", Flag = "ESP_Name" })
UI:Toggle(EspTab, { Name = "Дистанция", Flag = "ESP_Dist" })
UI:Toggle(EspTab, { Name = "Tracers", Flag = "ESP_Tracer" })
UI:Toggle(EspTab, { Name = "Health Bar", Flag = "ESP_Health" })
UI:Toggle(EspTab, { Name = "Skeleton", Flag = "ESP_Skeleton" })
UI:Toggle(EspTab, { Name = "X-Ray (через стены)", Flag = "ESP_XRay" })
UI._section(EspTab, "РОЛЕВЫЕ ЦВЕТА (CHAMS)")
UI:Toggle(EspTab, { Name = "Chams: Мардер=красный / Шериф=синий / Инносент=зелёный", Flag = "ESP_Chams" })
UI:Slider(EspTab, { Name = "Прозрачность заливки", Flag = "ChamsFill", Min = 0, Max = 1, Default = .55, Increment = .05 })
UI:Slider(EspTab, { Name = "Прозрачность контура", Flag = "ChamsOutline", Min = 0, Max = 1, Default = 0, Increment = .05 })
UI:Toggle(EspTab, { Name = "Gun ESP (выпавшее оружие)", Flag = "ESP_GunESP" })
UI._section(EspTab, "ПРОЧЕЕ")
UI:Toggle(EspTab, { Name = "Streamer Mode (скрыть ники)", Flag = "StreamerMode" })
UI:Slider(EspTab, { Name = "FPS ESP (оптимизация)", Flag = "ESP_FPS", Min = 10, Max = 60, Default = 30, Suffix = " fps" })
UI:ColorPicker(EspTab, { Name = "Цвет FOV-круга", Default = Color3.fromRGB(180, 160, 255) })

-- -------------------------------- MISC --------------------------------------
local MiscTab = Window:Tab("Misc", 5)
UI._section(MiscTab, "ЗАЩИТА")
UI:Toggle(MiscTab, { Name = "Anti-Fling (пропускает СВОЙ флинг)", Flag = "AntiFling" })
UI:Slider(MiscTab, { Name = "Порог срабатывания Anti-Fling", Flag = "AntiFlingThreshold", Min = 100, Max = 5000, Default = 500, Increment = 50,
    Callback = function(v) Util.notify("Anti-Fling", "Порог: " .. v .. " (свой флинг всё равно пропускается)", 2) end })
UI:Toggle(MiscTab, { Name = "God Mode", Flag = "GodMode" })
UI:Toggle(MiscTab, { Name = "Second Chance (двойная жизнь)", Flag = "SecondChance" })
UI:Toggle(MiscTab, { Name = "Anti-Void", Flag = "AntiVoid" })
UI:Toggle(MiscTab, { Name = "Anti-Lava", Flag = "AntiLava" })
UI:Slider(MiscTab, { Name = "Порог бездны (Y)", Flag = "VoidY", Min = -500, Max = -10, Default = -60 })
UI:Toggle(MiscTab, { Name = "Invisible Mode (безопасный)", Flag = "Invisible" })
UI:Toggle(MiscTab, { Name = "Invisible Smooth (без кика Invalid Position)", Flag = "InvisibleSmooth" })
UI:Toggle(MiscTab, { Name = "Position Guard (анти-кик Invalid Position)", Flag = "PositionGuard" })
UI:Button(MiscTab, { Name = "🧭 Вернуть персонажа на безопасную точку", Callback = function()
    local safe = (lastSafePos and Util.isValidPos(lastSafePos)) and lastSafePos or SpawnPos
    if Util.safeTP(CFrame.new(safe)) then Util.notify("Misc", "Позиция восстановлена", 2) end
end })
UI._section(MiscTab, "ДВИЖЕНИЕ")
UI:Slider(MiscTab, { Name = "Walk Speed", Flag = "WalkSpeed", Min = 16, Max = 200, Default = 16 })
UI:Slider(MiscTab, { Name = "Jump Power", Flag = "JumpPower", Min = 50, Max = 300, Default = 50 })
UI:Toggle(MiscTab, { Name = "Infinite Jump", Flag = "InfJump" })
UI:Toggle(MiscTab, { Name = "Fly (WASD + Space/Shift)", Flag = "Fly" })
UI:Slider(MiscTab, { Name = "Fly Speed", Flag = "FlySpeed", Min = 10, Max = 300, Default = 55 })
UI:Toggle(MiscTab, { Name = "Noclip", Flag = "Noclip" })
UI:Toggle(MiscTab, { Name = "SpinBot", Flag = "SpinBot" })
UI:Slider(MiscTab, { Name = "Скорость SpinBot", Flag = "SpinSpeed", Min = 1, Max = 60, Default = 14 })
UI._section(MiscTab, "ЭМОЦИИ")
UI:Toggle(MiscTab, { Name = "Emote Unlocker", Flag = "EmoteUnlocker" })
UI:Dropdown(MiscTab, { Name = "Эмоция", Flag = "Emote", Options = { "Floss", "Dab", "Ninja", "Headless", "Zombie" },
    Callback = function(v) if Config.EmoteUnlocker then Move.playEmote(v) end end })
UI:Button(MiscTab, { Name = "▶ Воспроизвести эмоцию", Callback = function() Move.playEmote(Config.Emote) end })
UI._section(MiscTab, "СЕРВЕР")
UI:Button(MiscTab, { Name = "🔁 Rejoin", Callback = function() Server.rejoin() end })
UI:Button(MiscTab, { Name = "🌐 Server Hop → LOW сервер", Callback = function() Server.hop("low") end })
UI:Button(MiscTab, { Name = "🌐 Server Hop → FULL сервер", Callback = function() Server.hop("full") end })
UI:Button(MiscTab, { Name = "📋 Copy Job ID", Callback = function() Server.copyJobId() end })
UI:Toggle(MiscTab, { Name = "Проверка фейкового ножа/оружия", Flag = "AutoFakeCheck" })

-- ------------------------------ SETTINGS ------------------------------------
local SetTab = Window:Tab("Settings", 6)
UI._section(SetTab, "КОНФИГ")
UI:Button(SetTab, { Name = "💾 Сохранить конфиг", Callback = function()
    SaveConfig() Util.notify("Конфиг", "Сохранён: " .. CFG_NAME, 3)
end })
UI:Button(SetTab, { Name = "📂 Загрузить конфиг", Callback = function()
    LoadConfig()
    for flag, c in pairs(Flags) do pcall(c.set, Config[flag]) end
    Util.notify("Конфиг", "Загружен", 3)
end })
UI:Button(SetTab, { Name = "♻ Сбросить настройки", Callback = function()
    Config = {}
    for k, v in pairs(DEFAULT) do Config[k] = v end
    for flag, c in pairs(Flags) do pcall(c.set, Config[flag]) end
    SaveConfig()
    Util.notify("Конфиг", "Все настройки сброшены", 3)
end })
UI:Paragraph(SetTab, {
    Title = "ℹ Инфо",
    Content = ("Исполнитель: %s\nDrawing API: %s\nwritefile: %s\nhookmetamethod: %s\nВерсия: %s")
        :format(ExecName, tostring(HAS_DRAWING), tostring(HAS_WRITEFILE), tostring(HAS_HOOKMETA), "2.6.0"),
})
UI:Paragraph(SetTab, {
    Title = "⚠ Отказ от ответственности",
    Content = "Использование на свой риск. Рекомендуется аккаунт-альтернатива.\nСкрипт не содержит key-системы, вебхуков и не обращается к вашим токенам.",
    Color = Color3.fromRGB(255, 205, 110),
})

--==============================================================================
-- 17. СТАРТ
--==============================================================================
task.delay(1, function()
    Util.notify("MM2 HUB X 2.6.0", "Загружен | " .. ExecName .. " | RightControl = свернуть", 5)
    print(("=== MM2 HUB X 2.6.0 ===\nexecutor: %s | drawing: %s | writefile: %s | hook: %s | players: %d | фарм-режим: %s")
        :format(ExecName, tostring(HAS_DRAWING), tostring(HAS_WRITEFILE), tostring(HAS_HOOKMETA), #PlayerList + 1, tostring(Config.CoinMode)))
    print("[MM2 HUB X] Позиция спавна: " .. tostring(SpawnPos))
    if Config.SilentAim then Combat.startSilentAim() end
    if Config.CoinFarm and Config.CoinMode == "Pathfind" then
        Util.notify("Фарм", "Baritone-режим активен — иду по маршруту к монетам", 4)
    end
end)

return {
    Config = Config, Util = Util, Role = Role, Farm = Farm,
    Combat = Combat, Guard = Guard, ESP = ESP, Move = Move, Server = Server, UI = Window,
}local UserInput       = game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local HttpService     = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser     = game:GetService("VirtualUser")
local Workspace       = game:GetService("Workspace")
local Replicated      = game:GetService("ReplicatedStorage")
local GuiParent       = CoreGui or Players.LocalPlayer:WaitForChild("PlayerGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local PlaceId     = game.PlaceId
local JobId       = game.JobId
local Mouse       = LocalPlayer:GetMouse()
local GetFPS      = RunService.RenderStepped

--==============================================================================
-- 2. КОНСТАНТЫ / ЦВЕТА РОЛЕЙ  (КЛЮЧЕВОЕ ТРЕБОВАНИЕ)
--==============================================================================
local ROLE_COLOR = {
    Murderer = Color3.fromRGB(255, 64, 64),   -- МАРДЕР    = КРАСНЫЙ
    Sheriff  = Color3.fromRGB(75, 141, 255),  -- ШЕРИФ     = СИНИЙ
    Innocent = Color3.fromRGB(63, 220, 120),  -- НЕВИНОВНЫЙ= ЗЕЛЁНЫЙ
    None     = Color3.fromRGB(185, 190, 205), -- неизвестно
}
local ROLE_RU = { Murderer = "МАРДЕР", Sheriff = "ШЕРИФ", Innocent = "Инносент", None = "—" }
local RISKY   = { Murderer = true, Sheriff = true }

local KNIFE_PATTERNS = { "knife", "murd", "stab", "blade" }
local GUN_PATTERNS   = { "gun", "pistol", "revolver", "weapon_shoot" }

--==============================================================================
-- 3. УТИЛИТЫ
--==============================================================================
local Util = {}
local Notify = nil -- объявим ниже, до использования

function Util.clamp(v, a, b) return math.max(a, math.min(b, v)) end
function Util.round(v, d) local m = 10 ^ (d or 0) return math.floor(v * m + .5) / m end

function Util.notify(title, text, dur)
    if Notify then Notify(title, text, dur) end
    print(("[MM2 HUB X] %s — %s"):format(tostring(title), tostring(text)))
end

function Util.safe(fn, ...)
    local ok, err = pcall(fn, ...)
    if not ok then warn("[MM2 HUB X] safe() -> " .. tostring(err)) end
    return ok, err
end

function Util.char(plr)   return plr and plr.Character end
function Util.hum(plr)
    local c = Util.char(plr)
    return c and c:FindFirstChildOfClass("Humanoid")
end
function Util.root(plr)
    local c = Util.char(plr)
    return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("Torso") or c.PrimaryPart)
end
function Util.head(plr)
    local c = Util.char(plr)
    return c and (c:FindFirstChild("Head") or c:FindFirstChild("UpperTorso") or Util.root(plr))
end
function Util.alive(plr)
    local h = Util.hum(plr)
    return h and h.Health > 0 and Util.root(plr) ~= nil
end
function Util.dist(a, b) return (a - b).Magnitude end
function Util.onScreen(pos3)
    local v, on = Camera:WorldToViewportPoint(pos3)
    return on and v.Z > 0, v
end

-- Райкаст-проверка «виден ли игрок» (Wall Check)
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.IgnoreWater = true

function Util.wallCheck(from, to, ignoreChar)
    RayParams.FilterDescendantsInstances = { ignoreChar or Util.char(LocalPlayer), Camera }
    local dir = to - from
    local res = Workspace:Raycast(from, dir, RayParams)
    if not res then return true end
    return res.Instance:IsDescendantOf(ignoreChar)
end

-- Телепорт с «человеческой» задержкой (для легит-режима — tween)
function Util.tp(pos, instant)
    local root = Util.root(LocalPlayer)
    if not root then return end
    if instant then
        root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        return
    end
    local dist = Util.dist(root.Position, pos)
    local t = Util.clamp(dist / 220, 0.08, 1.4) -- чем дальше — тем дольше, выглядит естественно
    TweenService:Create(root, TweenInfo.new(t, Enum.EasingStyle.Linear), { CFrame = CFrame.new(pos + Vector3.new(0, 3, 0)) }):Play()
end

-- Кэш-скан монет/боксов (НЕ каждый кадр — иначе лаги на 100+ игроков)
local ScanCache, ScanTime = {}, 0
local COIN_PATTERNS  = { "coin", "money", "cash", "cashcoin", "token", "gem", "orbpickup" }
local EVENT_PATTERNS = { "gift", "present", "event", "candy", "egg", "candycane", "snowflake" }
local BOX_PATTERNS   = { "mysterybox", "box", "crate", "chest" }

function Util.scanWorkspace(patterns)
    local now = os.clock()
    if now - ScanTime < 1.2 and #ScanCache > 0 then return ScanCache end
    ScanTime = now
    table.clear(ScanCache)
    local roots = { Workspace }
    local remotes = Replicated:FindFirstChild("Remotes")
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("BasePart") then
            local n = inst.Name:lower()
            for _, p in ipairs(patterns) do
                if n:find(p, 1, true) then
                    table.insert(ScanCache, inst)
                    break
                end
            end
        end
    end
    return ScanCache
end

-- Поиск RemoteEvent по шаблону (названия ремоутов меняются от апдейта к апдейту)
local RemoteCache = {}
function Util.findRemote(patterns)
    local key = table.concat(patterns, "|")
    if RemoteCache[key] ~= nil then return RemoteCache[key] end
    local found = nil
    local function scan(parent)
        for _, inst in ipairs(parent:GetDescendants()) do
            if inst:IsA("RemoteEvent") or inst:IsA("UnreliableRemoteEvent") or inst:IsA("RemoteFunction") then
                local n = inst.Name:lower()
                for _, p in ipairs(patterns) do
                    if n:find(p, 1, true) then found = inst return end
                end
            end
        end
    end
    pcall(scan, Replicated)
    if not found then pcall(scan, Workspace) end
    RemoteCache[key] = found or false
    return found or false
end

--==============================================================================
-- 4. ОПРЕДЕЛЕНИЕ РОЛИ  (КРАСНЫЙ / СИНИЙ / ЗЕЛЁНЫЙ)
--==============================================================================
local Role = {}
local RoleCache, RoleCacheTime = {}, 0
local ROLE_REFRESH = 0.4 -- сек: достаточно для мгновенной реакции на смену ролей

local function toolIs(plr, patterns)
    local c = Util.char(plr)
    if c then
        for _, t in ipairs(c:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                for _, p in ipairs(patterns) do if n:find(p, 1, true) then return true end end
            end
        end
    end
    local bp = plr:FindFirstChildOfClass("Backpack")
    if bp then
        for _, t in ipairs(bp:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                for _, p in ipairs(patterns) do if n:find(p, 1, true) then return true end end
            end
        end
    end
    return false
end

local function roleFromData(plr)
    for _, path in ipairs({
        plr:FindFirstChild("PlayerData"),
        plr:FindFirstChild("Data"),
        Util.char(plr),
    }) do
        if path then
            local v = path:FindFirstChild("Role") or path:FindFirstChild("PlayerRole") or path:FindFirstChild("CurrentRole")
            if v and (v:IsA("StringValue") or v:IsA("ObjectValue")) then
                local s = (v.Value or ""):lower()
                if s:find("murd") or s:find("knife") then return "Murderer" end
                if s:find("sher") or s:find("hero") or s:find("gun") then return "Sheriff" end
                if s:find("inno") or s:find("citizen") or s:find("none") then return "Innocent" end
            end
        end
    end
    return nil
end

--- Возвращает "Murderer" | "Sheriff" | "Innocent" | "None"
function Role.Get(plr)
    if not plr then return "None" end
    if plr == LocalPlayer then
        local self_role = Role._local
        if self_role then return self_role end
    end
    local now = os.clock()
    local hit = RoleCache[plr]
    if hit and now - hit.t < ROLE_REFRESH then return hit.r end

    local r = "None"
    if toolIs(plr, KNIFE_PATTERNS) then r = "Murderer"
    elseif toolIs(plr, GUN_PATTERNS) then r = "Sheriff"
    else r = roleFromData(plr) or "Innocent" end

    RoleCache[plr] = { r = r, t = now }
    return r
end

function Role.Color(plr) return ROLE_COLOR[Role.Get(plr)] or ROLE_COLOR.None end
function Role.IsRisky(plr) return RISKY[Role.Get(plr)] == true end

-- Свою роль читаем чаще (нужно для Kill Aura / Silent Aim)
function Role.RefreshSelf()
    Role._local = nil
    Role._local = toolIs(LocalPlayer, KNIFE_PATTERNS) and "Murderer"
        or (toolIs(LocalPlayer, GUN_PATTERNS) and "Sheriff" or "Innocent")
end

--==============================================================================
-- 5. КОНФИГ (сохранение / загрузка / сброс)
--==============================================================================
local CFG_NAME = "MM2HubX_config.json"
local DEFAULT = {
    -- Farming
    CoinFarm = false, CoinMode = "Near", CoinRadius = 150, CoinDelay = 0.12,
    CoinSmartAvoid = true, CoinBagReset = 35,
    BoxFarm = false, EventFarm = false,
    AutoPrestige = false, PrestigeLevel = 100,
    AutoReconnect = true, AntiAFK = true,
    -- Legit combat
    SilentAim = false, SA_FOV = 70, SA_Priority = "Head", SA_WallCheck = true, SA_Smooth = 0.35,
    GunGrabber = false, KnifeDodge = false, DodgeDist = 45,
    -- Rage combat
    KillAura = false, AuraRadius = 22, AuraAutoThrow = true, AuraOnlyNear = true, AuraDelay = 0.25,
    KillAll = false, AutoApproach = false, ApproachSpeed = 95,
    HitboxExpand = false, HitboxSize = 12,
    -- ESP
    ESP_Enabled = true, ESP_Box = true, ESP_Name = true, ESP_Dist = true,
    ESP_Tracer = false, ESP_Health = true, ESP_Skeleton = false, ESP_XRay = true,
    ESP_GunESP = true, ESP_Chams = true, ChamsFill = 0.55, ChamsOutline = 0,
    FOV_Circle = false, FOV_Size = 70, StreamerMode = false, ESP_FPS = 30,
    -- Protection
    AntiFling = true, GodMode = false, SecondChance = false,
    AntiVoid = true, AntiLava = true, VoidY = -60,
    Invisible = false,
    -- Movement
    WalkSpeed = 16, JumpPower = 50, InfJump = false, Fly = false, FlySpeed = 55,
    Noclip = false, SpinBot = false, SpinSpeed = 14,
    EmoteUnlocker = false, Emote = "Floss",
    AutoFakeCheck = true,
    -- Meta
    UI_Visible = true, WindowSize = 1,
}
local Config = {}
local Flags = {} -- реестр контролов для авто-сохранения

-- Загрузка
local function LoadConfig()
    Config = {}
    for k, v in pairs(DEFAULT) do Config[k] = v end
    if HAS_READFILE and HAS_WRITEFILE then
        local ok, raw = pcall(readfile, CFG_NAME)
        if ok and raw then
            local ok2, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
            if ok2 and type(decoded) == "table" then
                for k, v in pairs(decoded) do if DEFAULT[k] ~= nil then Config[k] = v end end
            end
        end
    end
end

local saveQueued = false
local function SaveConfig()
    if not (HAS_WRITEFILE and HAS_READFILE) then return end
    if saveQueued then return end
    saveQueued = true
    task.delay(0.35, function() -- дебаунс: ползунки дергаются сотни раз в секунду
        saveQueued = false
        local out = {}
        for k in pairs(DEFAULT) do out[k] = Config[k] end
        Util.safe(function()
            if not isfolder("MM2HubX") then makefolder("MM2HubX") end
            writefile(CFG_NAME, HttpService:JSONEncode(out))
        end)
    end)
end

local function Set(key, value)
    Config[key] = value
    SaveConfig()
end

LoadConfig()

--==============================================================================
-- 6. ИГРОКИ (кэш списков — нулевой аллокационный шум в цикле)
--==============================================================================
local PlayerList = {}
local function rebuildList()
    table.clear(PlayerList)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(PlayerList, p) end
    end
end
rebuildList()
Players.PlayerAdded:Connect(function(p) table.insert(PlayerList, p) end)
Players.PlayerRemoving:Connect(function(p)
    RoleCache[p] = nil
    for i, x in ipairs(PlayerList) do if x == p then table.remove(PlayerList, i) break end end
end)

local function getTargets()
    local out = {}
    for _, p in ipairs(PlayerList) do
        if Util.alive(p) then table.insert(out, p) end
    end
    return out
end

local function nearestTarget(maxDist, riskyOnly)
    local best, bd = nil, maxDist or math.huge
    local myRoot = Util.root(LocalPlayer)
    if not myRoot then return nil end
    for _, p in ipairs(getTargets()) do
        if not riskyOnly or Role.IsRisky(p) then
            local d = Util.dist(myRoot.Position, Util.root(p).Position)
            if d < bd then best, bd = p, d end
        end
    end
    return best, bd
end

--==============================================================================
-- 7. МОДУЛЬ: ФАРМ (монеты, боксы, ивенты, престиж, реконнект)
--==============================================================================
local Farm = {}
Farm.collected = 0

function Farm.collectCoins()
    if not Config.CoinFarm then return end
    local root = Util.root(LocalPlayer)
    if not root then return end
    local list = Util.scanWorkspace(COIN_PATTERNS)
    if #list == 0 then return end

    -- умный выбор цели
    local best, bd = nil, (Config.CoinMode == "Near" and Config.CoinRadius or 5e4)
    for _, part in ipairs(list) do
        if part.Parent then
            local d = Util.dist(root.Position, part.Position)
            if d < bd then best, bd = part, d end
        end
    end
    if not best then return end

    -- Smart: игнорируем монету, если рядом стоит живой игрок (меньше подозрений)
    if Config.CoinSmartAvoid and Config.CoinMode == "Near" then
        for _, p in ipairs(getTargets()) do
            if Util.dist(Util.root(p).Position, best.Position) < 12 then return end
        end
    end

    Util.tp(best.Position, Config.CoinMode == "Teleport")
    Farm.collected = Farm.collected + 1

    -- Полный мешок -> сброс на спавн (анти-подозрение + продолжает фарм)
    if Config.CoinBagReset > 0 and Farm.collected % Config.CoinBagReset == 0 then
        task.wait(0.15)
        Util.tp(SpawnPos, false)
        Util.notify("Фарм", "Мешок полон — сброс на спавн", 2)
    end
end

function Farm.openBoxes()
    if not Config.BoxFarm then return end
    local boxes = Util.scanWorkspace(BOX_PATTERNS)
    for _, b in ipairs(boxes) do
        if b.Parent and Util.dist(Util.root(LocalPlayer).Position, b.Position) < 60 then
            Util.tp(b.Position, true)
            -- 1) через ProximityPrompt (самый надёжный путь)
            local prompt = b:FindFirstChildWhichIsA("ProximityPrompt", true)
            if prompt then
                fireproximityprompt(prompt)
            else
                -- 2) через ремоут
                local r = Util.findRemote({ "openbox", "mysterybox", "buybox", "opencrate" })
                if r then pcall(function() r:FireServer(b) end) end
            end
            task.wait(Config.CoinDelay)
            break -- один бокс за тик
        end
    end
end

function Farm.collectEvents()
    if not Config.EventFarm then return end
    local evs = Util.scanWorkspace(EVENT_PATTERNS)
    for _, e in ipairs(evs) do
        if e.Parent then
            Util.tp(e.Position, true)
            task.wait(Config.CoinDelay)
            break
        end
    end
end

function Farm.myLevel()
    local pd = LocalPlayer:FindFirstChild("PlayerData") or LocalPlayer:FindFirstChild("Data")
    if pd then
        for _, name in ipairs({ "Level", "UserLevel", "PlayerLevel" }) do
            local v = pd:FindFirstChild(name)
            if v and (v:IsA("IntValue") or v:IsA("NumberValue")) then return v.Value end
        end
    end
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    local mg = pg and pg:FindFirstChild("MainGUI")
    local g = mg and mg:FindFirstChild("Game")
    local l = g and g:FindFirstChild("UserLevel")
    if l and l:IsA("TextLabel") then return tonumber(l.Text:match("%d+")) or 0 end
    return 0
end

function Farm.tryPrestige()
    if not Config.AutoPrestige then return end
    if Farm.myLevel() >= Config.PrestigeLevel then
        local r = Util.findRemote({ "prestige", "rebirth", "resetlevel", "prestigeplayer" })
        if r then
            pcall(function() r:FireServer() end)
            Util.notify("Престиж", "Уровень " .. Config.PrestigeLevel .. " — ребёрт отправлен", 3)
            task.wait(3)
        end
    end
end

-- Anti-AFK + авто-реконнект после кика
function Farm.startSessionGuard()
    if Config.AntiAFK then
        LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            Util.notify("Anti-AFK", "АФК-кик предотвращён", 2)
        end)
    end
    -- перехват Kick: не блокируем (иначе бан-риск), а просто фиксируем и реконнектимся
    if Config.AutoReconnect and HAS_HOOKMETA then
        HAS_NEWCC(function() end)
        Util.safe(function()
            local old
            old = hookmetamethod(game, "__namecall", HAS_NEWCC(function(self, ...)
                local m = getnamecallmethod()
                if m == "Kick" and self == LocalPlayer then
                    Util.notify("Auto-Reconnect", "Кик обнаружен — перезаходим через 3 с", 4)
                    task.delay(3, function()
                        pcall(function()
                            TeleportService:Teleport(PlaceId, LocalPlayer)
                        end)
                    end)
                end
                return old(self, ...)
            end))
        end)
    end
end

--==============================================================================
-- 8. МОДУЛЬ: КОМБАТ
--==============================================================================
local Combat = {}
Combat.fovTarget = nil

function Combat.visibleTarget(p)
    local myRoot, tHead = Util.root(LocalPlayer), Util.head(p)
    if not myRoot or not tHead then return false end
    return Util.wallCheck(Camera.CFrame.Position, tHead.Position, Util.char(LocalPlayer))
end

-- Выбор цели для Silent Aim (FOV + приоритет + Wall Check)
function Combat.pickAimTarget()
    local best, bs = nil, math.huge
    local center = Camera.ViewportSize / 2
    for _, p in ipairs(getTargets()) do
        local r = Role.Get(p)
        if r == "Murderer" or r == "Sheriff" or r == "Innocent" then
            local head = Config.SA_Priority == "Head" and Util.head(p) or Util.root(p)
            if head then
                local on, sp = Util.onScreen(head.Position)
                if on then
                    local screenDist = Util.dist(Vector2.new(sp.X, sp.Y), Vector2.new(center.X, center.Y))
                    local inFov = screenDist <= (Config.SA_FOV * Camera.ViewportSize.Y / 1000)
                    if inFov and (not Config.SA_WallCheck or Combat.visibleTarget(p)) then
                        local weight = screenDist + (r == "Murderer" and -9000 or (r == "Sheriff" and -4000 or 0))
                        if weight < bs then best, bs = { player = p, part = head, pos = head.Position }, weight end
                    end
                end
            end
        end
    end
    Combat.fovTarget = best
    return best
end

-- Silent Aim: подмена направления выстрела в ремоуте пистолета
function Combat.startSilentAim()
    if not HAS_HOOKMETA then
        Util.notify("Silent Aim", "Исполнитель не поддерживает hookmetamethod — включена камера-пометка", 4)
        return
    end
    local shootRemote = Util.findRemote({ "shoot", "firegun", "gunshot", "shootgun", "bullet" })
    if not shootRemote then
        Util.notify("Silent Aim", "Ремоут выстрела не найден — проверь console (F9)", 4)
    end
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", HAS_NEWCC(function(self, ...)
        local args = { ... }
        local m = getnamecallmethod()
        if Config.SilentAim and (m == "FireServer" or m == "InvokeServer") then
            local isShoot = (self == shootRemote) or self.Name:lower():find("shoot")
            if isShoot then
                local t = Combat.pickAimTarget()
                if t then
                    -- подменяем CFrame/Vector3-аргумент направления (индекс настраивается)
                    for i = 1, #args do
                        if typeof(args[i]) == "CFrame" then args[i] = CFrame.new(t.pos) break end
                        if typeof(args[i]) == "Vector3" then args[i] = t.pos break end
                    end
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        return oldNamecall(self, ...)
    end))
end

-- Kill Aura (Мардер): расширение хитбокса + авто-бросок ножа
function Combat.killAuraStep()
    if not Config.KillAura then return end
    local t, d = nearestTarget(Config.AuraRadius, false)
    if not t then return end
    -- режим «только ближайшие»: игнорируем дальние цели
    if Config.AuraOnlyNear and d > 25 then return end
    if not Util.wallCheck(Util.root(LocalPlayer).Position, Util.root(t).Position, Util.char(LocalPlayer)) then return end
    if Config.AuraAutoThrow then
        local r = Util.findRemote({ "throw", "throwknife", "stab", "attack", "knifehit" })
        if r then
            pcall(function()
                r:FireServer(Util.head(t).CFrame, Util.head(t).Position)
            end)
        end
    else
        Util.tp(Util.root(t).Position, true) -- режим «подойти и ударить»
    end
end

-- Авто-подход к цели (Продвинутый убийца)
function Combat.approachStep()
    if not Config.AutoApproach then return end
    local t = nearestTarget(400, false)
    if t then
        local root = Util.root(LocalPlayer)
        local dir = (Util.root(t).Position - root.Position).Unit
        root.AssemblyLinearVelocity = dir * Config.ApproachSpeed
    end
end

-- Мгновенные действия
function Combat.killAll(onlyRole)
    local n = 0
    for _, p in ipairs(getTargets()) do
        if not onlyRole or Role.Get(p) == onlyRole then
            local r = Util.findRemote({ "throw", "stab", "attack", "knifehit", "shoot" })
            if r then pcall(function() r:FireServer(Util.head(p).CFrame, Util.head(p).Position) end) n = n + 1 end
            task.wait(0.03)
        end
    end
    Util.notify("Kill", ("Целей обработано: %d"):format(n), 3)
end

-- Gun Grabber: автотелепорт к выпавшему пистолету
function Combat.gunGrabber()
    if not Config.GunGrabber then return end
    for _, inst in ipairs(Workspace:GetChildren()) do
        local n = inst.Name:lower()
        if (n:find("gun") or n:find("pistol")) and inst:IsA("BasePart") then
            Util.tp(inst.Position, true)
            task.wait(0.1)
            break
        elseif (n:find("gun") or n:find("pistol")) and inst:IsA("Model") and inst.PrimaryPart then
            Util.tp(inst.PrimaryPart.Position, true)
            task.wait(0.1)
            break
        end
    end
end

-- Авто-додж летящих ножей
local watchedKnives = {}
function Combat.knifeDodge()
    if not Config.KnifeDodge then return end
    local root = Util.root(LocalPlayer)
    if not root then return end
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("BasePart") and inst.Name:lower():find("knife") then
            if not watchedKnives[inst] then
                watchedKnives[inst] = true
                local conn
                conn = RunService.Heartbeat:Connect(function()
                    if not inst.Parent or not Config.KnifeDodge then conn:Disconnect() watchedKnives[inst] = nil return end
                    local d = Util.dist(inst.Position, root.Position)
                    if d < Config.DodgeDist then
                        local away = (root.Position - inst.Position).Unit
                        root.CFrame = root.CFrame + away * 7 + Vector3.new(0, 4, 0)
                    end
                end)
                inst.Destroying:Connect(function() conn:Disconnect() watchedKnives[inst] = nil end)
            end
        end
    end
end

-- Hitbox Expander (визуальный + серверный размер частей)
function Combat.applyHitbox()
    for _, p in ipairs(PlayerList) do
        local c = Util.char(p)
        if c then
            for _, partName in ipairs({ "HumanoidRootPart", "Torso", "UpperTorso" }) do
                local part = c:FindFirstChild(partName)
                if part and part:IsA("BasePart") then
                    if Config.HitboxExpand then
                        local s = Config.HitboxSize
                        if part.Name == "HumanoidRootPart" and not part:GetAttribute("mm2_orig") then
                            part:SetAttribute("mm2_orig", part.Size.X)
                        end
                        part.Size = Vector3.new(s, s, s)
                        part.Transparency = 0.75
                        part.BrickColor = BrickColor.new(Role.Get(p) == "Murderer" and "Really red" or "Lime green")
                    elseif part:GetAttribute("mm2_orig") then
                        local o = part:GetAttribute("mm2_orig")
                        part.Size = Vector3.new(o, o, o)
                        part.Transparency = 1
                    end
                end
            end
        end
    end
end

-- Fling Player (троллинг, с подтверждением из UI)
function Combat.fling(plr)
    local root = Util.root(plr)
    local myRoot = Util.root(LocalPlayer)
    if not root or not myRoot then return end
    Util.notify("Fling", "Запущен флинг: " .. plr.Name, 3)
    local t0 = os.clock()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if os.clock() - t0 > 4 or not root.Parent then conn:Disconnect() return end
        root.CFrame = CFrame.new(myRoot.Position) * CFrame.Angles(0, os.clock() * 40, 0)
        root.AssemblyLinearVelocity = Vector3.new(math.random(-900, 900), 1e5, math.random(-900, 900))
    end)
end

-- Проверка «фейкового ножа/оружия» (анти-обман другими скриптами)
function Combat.fakeWeaponCheck()
    if not Config.AutoFakeCheck then return end
    local c = Util.char(LocalPlayer)
    if not c then return end
    for _, t in ipairs(c:GetChildren()) do
        if t:IsA("Tool") then
            local handle = t:FindFirstChild("Handle") or t:FindFirstChildWhichIsA("BasePart")
            local looksReal = handle ~= nil and handle.Size.Magnitude > 0.5
            local isWeapon = t.Name:lower():find("knife") or t.Name:lower():find("gun")
            if isWeapon and not looksReal then
                Util.notify("⚠ Фейк", "Обнаружено поддельное оружие: " .. t.Name, 5)
            end
        end
    end
end

--==============================================================================
-- 9. МОДУЛЬ: ЗАЩИТА
--==============================================================================
local Guard = {}
local lastSafePos = nil

function Guard.antiFling()
    if not Config.AntiFling then return end
    local root = Util.root(LocalPlayer)
    if not root then return end
    local vel = root.AssemblyLinearVelocity
    if vel.Magnitude > 500 or root.AssemblyAngularVelocity.Magnitude > 300 then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        if lastSafePos then root.CFrame = CFrame.new(lastSafePos) end
        -- ломаем чужие BodyMover-ы, которые нас кидают
        for _, m in ipairs(root:GetChildren()) do
            if m:IsA("BodyMover") or m:IsA("AlignPosition") or m:IsA("AlignOrientation") then m:Destroy() end
        end
        Util.notify("Anti-Fling", "Попытка флинга заблокирована", 2)
    else
        lastSafePos = root.Position
    end
end

function Guard.godMode()
    local h = Util.hum(LocalPlayer)
    if not h then return end
    if Config.GodMode then
        h.MaxHealth = math.huge
        h.Health = math.huge
        h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end
    if Config.SecondChance and h.Health < (h.MaxHealth * 0.35) then
        local r = Util.findRemote({ "revive", "secondchance", "heal", "respawnme" })
        if r then pcall(function() r:FireServer() end) end
        h.Health = h.MaxHealth
    end
end

function Guard.antiVoid()
    if not (Config.AntiVoid or Config.AntiLava) then return end
    local root = Util.root(LocalPlayer)
    if not root then return end
    if root.Position.Y < Config.VoidY then
        Util.tp(SpawnPos, true)
        Util.notify("Anti-Void", "Возврат из бездны", 2)
        return
    end
    if Config.AntiLava then
        local feet = Workspace:Raycast(root.Position, Vector3.new(0, -4, 0), RayParams)
        if feet and feet.Instance and feet.Instance.Name:lower():find("lava") then
            root.CFrame = CFrame.new(root.Position + Vector3.new(0, 18, 0))
        end
    end
end

-- «Невидимость» (локальная + подмена прозрачности для стрима)
function Guard.invisible()
    local c = Util.char(LocalPlayer)
    if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") or d:IsA("Decal") then
            if Config.Invisible then
                if not d:GetAttribute("mm2_tr") then d:SetAttribute("mm2_tr", d.Transparency) end
                d.Transparency = 1
                if d:IsA("BasePart") then d.CastShadow = false end
            elseif d:GetAttribute("mm2_tr") ~= nil then
                d.Transparency = d:GetAttribute("mm2_tr")
            end
        end
    end
end

-- Streamer Mode: скрыть ники всех, кроме себя
function Guard.streamerMode()
    for _, p in ipairs(PlayerList) do
        local h = Util.hum(p)
        if h then
            if Config.StreamerMode then
                h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                local head = Util.head(p)
                if head then
                    for _, g in ipairs(head:GetChildren()) do
                        if g:IsA("BillboardGui") then g.Enabled = false end
                    end
                end
            else
                h.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
            end
        end
    end
end

--==============================================================================
-- 10. МОДУЛЬ: ESP / CHAMS / SKELETON (Drawing + фолбэк на Highlight)
--==============================================================================
local ESP = {}
ESP.draw = {}

local function newDraw(kind, props)
    if HAS_DRAWING then
        local ok, obj = pcall(Drawing.new, kind)
        if ok and obj then
            for k, v in pairs(props) do obj[k] = v end
            obj.Visible = false
            return obj
        end
    end
    return nil -- фолбэк: только Highlight/Billboard (работает везде)
end

local function clearPlayerObjects(store)
    for _, o in pairs(store) do
        if typeof(o) == "table" then
            for _, x in pairs(o) do pcall(function() x:Remove() end) end
        else
            pcall(function() o:Remove() end)
        end
    end
end

ESP.objects = {}

local SKELETON_R15 = {
    { "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
    { "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
    { "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
    { "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
    { "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}
local SKELETON_R6 = {
    { "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
    { "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}

local function getBone(c, name)
    return c:FindFirstChild(name)
end

function ESP.build(plr)
    if ESP.objects[plr] then return end
    local store = {}
    if HAS_DRAWING then
        store.box      = newDraw("Square",   { Thickness = 1, Filled = false })
        store.boxFill  = newDraw("Square",   { Thickness = 1, Filled = true, Transparency = 0.25 })
        store.name     = newDraw("Text",     { Size = 13, Center = true, Outline = true, Font = 2 })
        store.dist     = newDraw("Text",     { Size = 12, Center = true, Outline = true, Font = 2 })
        store.tracer   = newDraw("Line",     { Thickness = 1 })
        store.hpBG     = newDraw("Square",   { Thickness = 1, Filled = true, Color = Color3.new(0, 0, 0) })
        store.hp       = newDraw("Square",   { Thickness = 1, Filled = true, Color = Color3.fromRGB(60, 220, 120) })
        store.skel = {}
        for i = 1, #SKELETON_R15 do table.insert(store.skel, newDraw("Line", { Thickness = 1 })) end
    end
    -- Chams через Highlight (работает на ВСЕХ исполнителях, включая Xeno/Solara)
    store.chams = Instance.new("Highlight")
    store.chams.Name = "MM2_HUB_CHAMS"
    store.chams.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    store.chams.Parent = (CoreGui or GuiParent)

    -- 3D-имя для режима без Drawing API
    store.bill = Instance.new("BillboardGui")
    store.bill.Name = "MM2_TAG"
    store.bill.Size = UDim2.fromOffset(140, 44)
    store.bill.AlwaysOnTop = true
    store.bill.StudsOffset = Vector3.new(0, 3.2, 0)
    store.text = Instance.new("TextLabel")
    store.text.BackgroundTransparency = 1
    store.text.Size = UDim2.fromScale(1, 1)
    store.text.Font = Enum.Font.GothamBold
    store.text.TextStrokeTransparency = 0.2
    store.text.TextSize = 13
    store.text.Parent = store.bill
    store.bill.Parent = (CoreGui or GuiParent)

    ESP.objects[plr] = store
end

function ESP.remove(plr)
    local s = ESP.objects[plr]
    if not s then return end
    clearPlayerObjects(s)
    pcall(function() s.chams:Destroy() end)
    pcall(function() s.bill:Destroy() end)
    ESP.objects[plr] = nil
end

function ESP.clearAll()
    for plr in pairs(ESP.objects) do ESP.remove(plr) end
end

local accTime = 0
function ESP.render(dt)
    if not Config.ESP_Enabled then
        accTime = accTime + dt
        return
    end
    accTime = accTime + dt
    if accTime < (1 / Config.ESP_FPS) then return end -- ограничение FPS ESP = главный источник «лагов»
    accTime = 0

    local myRoot = Util.root(LocalPlayer)
    local active = {}
    for _, plr in ipairs(PlayerList) do
        if Util.alive(plr) then active[plr] = true end
    end
    for plr in pairs(ESP.objects) do
        if not active[plr] then ESP.remove(plr) end
    end

    for plr in pairs(active) do
        ESP.build(plr)
        local s = ESP.objects[plr]
        local role = Role.Get(plr)
        local col = ROLE_COLOR[role] or ROLE_COLOR.None
        local root, head, hum = Util.root(plr), Util.head(plr), Util.hum(plr)
        if not (root and head) then continue end

        local pos, on = Camera:WorldToViewportPoint(root.Position)
        local nameTag = Config.StreamerMode and "player" or plr.Name
        local distTxt = myRoot and ("%d м"):format(Util.dist(myRoot.Position, root.Position)) or ""

        -- CHAMS (ролевой цвет + прозрачность)
        do
            local char = Util.char(plr)
            if Config.ESP_Chams and char then
                s.chams.Adornee = char
                s.chams.FillColor = col
                s.chams.OutlineColor = col
                s.chams.FillTransparency = 1 - Config.ChamsFill
                s.chams.OutlineTransparency = Config.ChamsOutline
                s.chams.Enabled = true
            else
                s.chams.Enabled = false
            end
        end

        -- 3D-тэг (фолбэк + всегда видимое имя с ролью)
        do
            s.bill.Adornee = head
            s.bill.Enabled = Config.ESP_Name or not HAS_DRAWING
            s.text.Text = (Config.StreamerMode and "player" or plr.Name) .. "\n" .. ROLE_RU[role] .. (Config.ESP_Dist and ("  " .. distTxt) or "")
            s.text.TextColor3 = col
        end

        if HAS_DRAWING then
            local headPos, onHead = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.6, 0))
            local legPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
            local h = math.abs(legPos.Y - headPos.Y)
            local w = h / 2.1
            local visible = on and onHead


            local function show(obj, cond)
                if obj then obj.Visible = (cond == true) and visible or false end
            end

            -- BOX
            if s.box and s.boxFill then
                s.box.Size = Vector2.new(w, h)
                s.box.Position = Vector2.new(pos.X - w / 2, pos.Y - h / 2)
                s.box.Color = col
                s.box.Thickness = 1.4
                s.boxFill.Size = s.box.Size
                s.boxFill.Position = s.box.Position
                s.boxFill.Color = col
                show(s.box, Config.ESP_Box)
                show(s.boxFill, Config.ESP_Box and Config.ESP_XRay)
            end
            -- NAME / DIST
            if s.name then
                s.name.Text = nameTag .. "  [" .. ROLE_RU[role] .. "]"
                s.name.Position = Vector2.new(pos.X, pos.Y - h / 2 - 14)
                s.name.Color = col
                show(s.name, Config.ESP_Name)
            end
            if s.dist then
                s.dist.Text = distTxt
                s.dist.Position = Vector2.new(pos.X, pos.Y + h / 2 + 6)
                s.dist.Color = col
                show(s.dist, Config.ESP_Dist)
            end
            -- HEALTH BAR
            if s.hp and s.hpBG then
                local ratio = Util.clamp(hum.Health / math.max(1, hum.MaxHealth), 0, 1)
                s.hpBG.Size = Vector2.new(3, h)
                s.hpBG.Position = Vector2.new(pos.X - w / 2 - 6, pos.Y - h / 2)
                s.hp.Size = Vector2.new(3, h * ratio)
                s.hp.Position = Vector2.new(pos.X - w / 2 - 6, pos.Y + h / 2 - h * ratio)
                s.hp.Color = Color3.fromRGB(255 * (1 - ratio), 220 * ratio, 60)
                show(s.hpBG, Config.ESP_Health)
                show(s.hp, Config.ESP_Health)
            end
            -- TRACER (X-Ray снизу экрана)
            if s.tracer then
                s.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                s.tracer.To = Vector2.new(pos.X, pos.Y + h / 2)
                s.tracer.Color = col
                show(s.tracer, Config.ESP_Tracer)
            end
            -- SKELETON
            local set = Util.hum(plr) and Util.hum(plr).RigType == Enum.HumanoidRigType.R15 and SKELETON_R15 or SKELETON_R6
            for i, line in ipairs(s.skel or {}) do
                local pair = set[i]
                if pair then
                    local a, b = getBone(Util.char(plr), pair[1]), getBone(Util.char(plr), pair[2])
                    if a and b then
                        local pa, oa = Camera:WorldToViewportPoint(a.Position)
                        local pb, ob = Camera:WorldToViewportPoint(b.Position)
                        line.From = Vector2.new(pa.X, pa.Y)
                        line.To = Vector2.new(pb.X, pb.Y)
                        line.Color = col
                        show(line, Config.ESP_Skeleton and oa and ob)
                    else
                        line.Visible = false
                    end
                end
            end
        end
    end

    -- FOV Circle для аимбота
    if HAS_DRAWING and not ESP.fov then
        ESP.fov = newDraw("Circle", { Thickness = 1.5, Filled = false, NumSides = 64 })
    end
    if ESP.fov then
        ESP.fov.Visible = Config.FOV_Circle
        ESP.fov.Radius = Config.FOV_Size * Camera.ViewportSize.Y / 1000
        ESP.fov.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        ESP.fov.Color = Color3.fromRGB(180, 160, 255)
    end

    -- Gun ESP: подсветка выпавшего оружия
    if Config.ESP_GunESP then
        for _, inst in ipairs(Workspace:GetChildren()) do
            local n = inst.Name:lower()
            if (n:find("gun") or n:find("knife")) and inst:IsA("BasePart") then
                local hl = inst:FindFirstChild("MM2_GUN_HL") or Instance.new("Highlight")
                hl.Name = "MM2_GUN_HL"
                hl.Adornee = inst
                hl.FillColor = n:find("gun") and ROLE_COLOR.Sheriff or ROLE_COLOR.Murderer
                hl.FillTransparency = 0.35
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = (CoreGui or GuiParent)
            end
        end
    end
end

--==============================================================================
-- 11. МОДУЛЬ: ДВИЖЕНИЕ
--==============================================================================
local Move = {}
local flyVel, flyGyro

function Move.applyBasics()
    local h = Util.hum(LocalPlayer)
    if h then
        h.WalkSpeed = Config.WalkSpeed
        h.UseJumpPower = true
        h.JumpPower = Config.JumpPower
    end
end

function Move.infJump()
    UserInput.JumpRequest:Connect(function()
        if Config.InfJump then
            local h = Util.hum(LocalPlayer)
            if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
end

function Move.fly(dt)
    local root = Util.root(LocalPlayer)
    if not root then return end
    if Config.Fly then
        if not flyVel then
            flyVel = Instance.new("BodyVelocity")
            flyVel.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            flyVel.Velocity = Vector3.zero
            flyVel.Parent = root
            flyGyro = Instance.new("BodyGyro")
            flyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            flyGyro.P = 9e4
            flyGyro.Parent = root
        end
        local cam = Camera.CFrame
        local dir = Vector3.zero
        if UserInput:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.LookVector end
        if UserInput:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.RightVector end
        if UserInput:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0, 1, 0) end
        if UserInput:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0, 1, 0) end
        flyVel.Velocity = dir.Magnitude > 0 and dir.Unit * Config.FlySpeed or Vector3.zero
        flyGyro.CFrame = cam
    elseif flyVel then
        flyVel:Destroy() flyVel = nil
        if flyGyro then flyGyro:Destroy() flyGyro = nil end
    end
end

function Move.noclip()
    if not Config.Noclip then return end
    local c = Util.char(LocalPlayer)
    if not c then return end
    for _, d in ipairs(c:GetDescendants()) do
        if d:IsA("BasePart") then d.CanCollide = false end
    end
end

function Move.spinBot(dt)
    if not Config.SpinBot then return end
    local root = Util.root(LocalPlayer)
    if root then
        root.CFrame = root.CFrame * CFrame.Angles(0, math.rad(Config.SpinSpeed * dt * 60), 0)
    end
end

--==============================================================================
-- 12. МОДУЛЬ: ЭМОЦИИ / EMOTE UNLOCKER
--==============================================================================
local Emotes = {
    ["Floss"]  = { id = 5917459365 },
    ["Dab"]    = { id = 5915779036 },
    ["Ninja"]  = { id = 5915779036 },
    ["Headless"] = { id = 0 },  -- 0 = только визуальная замена головы
    ["Zombie"] = { id = 3134662895 },
}
local playingAnim
function Move.playEmote(name)
    local data = Emotes[name] or Emotes.Floss
    local hum = Util.hum(LocalPlayer)
    if not hum then return end
    -- 1) пробуем штатную систему эмоций MM2
    local r = Util.findRemote({ "emote", "playemote", "dance" })
    if r then pcall(function() r:FireServer(name) end) end
    -- 2) локальная анимация
    if data.id and data.id > 0 then
        local anim = Instance.new("Animation")
        anim.AnimationId = "rbxassetid://" .. data.id
        local track = hum:FindFirstChildOfClass("Animator"):LoadAnimation(anim)
        if playingAnim then playingAnim:Stop() end
        track:Play()
        playingAnim = track
    end
    if name == "Headless" then
        local head = Util.head(LocalPlayer)
        if head then
            for _, d in ipairs(head:GetDescendants()) do
                if d:IsA("Decal") then d.Transparency = 1 end
            end
        end
    end
    Util.notify("Emote", "Эмоция: " .. name, 2)
end

--==============================================================================
-- 13. МОДУЛЬ: СЕРВЕРА (hop / rejoin / job id)
--==============================================================================
local Server = {}

function Server.copyJobId()
    if setclipboard then setclipboard(JobId) end
    if toclipboard then toclipboard(JobId) end
    Util.notify("Job ID", "Скопирован: " .. JobId, 3)
end

function Server.rejoin()
    TeleportService:Teleport(PlaceId, LocalPlayer)
end

function Server.hop(mode)
    -- mode = "low" | "full"
    if not (HAS_REQUEST or typeof(game.HttpGet) == "function") then
        Util.notify("Server Hop", "HTTP недоступен в этом исполнителе", 4)
        return
    end
    Util.safe(function()
        local url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100"):format(PlaceId)
        local body = HAS_REQUEST
            and request({ Url = url, Method = "GET" }).Body
            or game:HttpGet(url)
        local data = HttpService:JSONDecode(body)
        local list = {}
        for _, s in ipairs(data.data or {}) do
            if s.id ~= JobId and s.playing < s.maxPlayers then table.insert(list, s) end
        end
        if #list == 0 then Util.notify("Server Hop", "Подходящих серверов нет", 3) return end
        table.sort(list, function(a, b)
            if mode == "full" then return a.playing > b.playing end
            return a.playing < b.playing
        end)
        local pick = list[1]
        TeleportService:TeleportToPlaceInstance(PlaceId, pick.id, LocalPlayer)
        Util.notify("Server Hop", ("→ %d/%d игроков"):format(pick.playing, pick.maxPlayers), 3)
    end)
end

--==============================================================================
-- 14. ГЛАВНЫЙ ЦИКЛ (один Heartbeat = ноль лишних коннектов = нет лагов)
--==============================================================================
local acc = { coin = 0, box = 0, combat = 0, guard = 0, misc = 0 }
local COIN_TICK, BOX_TICK, COMBAT_TICK, GUARD_TICK, MISC_TICK = Config.CoinDelay, 0.8, Config.AuraDelay, 0.1, 0.25

RunService.Heartbeat:Connect(function(dt)
    -- ФАРМ
    if Config.CoinFarm then
        acc.coin = acc.coin + dt
        if acc.coin >= COIN_TICK then acc.coin = 0 Farm.collectCoins() end
    end
    if Config.BoxFarm or Config.EventFarm then
        acc.box = acc.box + dt
        if acc.box >= BOX_TICK then acc.box = 0
            if Config.BoxFarm then Farm.openBoxes() end
            if Config.EventFarm then Farm.collectEvents() end
        end
    end
    -- КОМБАТ
    if Config.KillAura or Config.AutoApproach or Config.GunGrabber or Config.KnifeDodge then
        acc.combat = acc.combat + dt
        if acc.combat >= COMBAT_TICK then acc.combat = 0
            if Config.KillAura then Farm.tryPrestige() Combat.killAuraStep() end
            if Config.AutoApproach then Combat.approachStep() end
            if Config.GunGrabber then Combat.gunGrabber() end
            if Config.KnifeDodge then Combat.knifeDodge() end
        end
    end
    -- ЗАЩИТА
    acc.guard = acc.guard + dt
    if acc.guard >= GUARD_TICK then acc.guard = 0
        if Config.AntiFling then Guard.antiFling() end
        if Config.AntiVoid or Config.AntiLava then Guard.antiVoid() end
        if Config.GodMode or Config.SecondChance then Guard.godMode() end
        if Config.HitboxExpand then Combat.applyHitbox() end
    end
    -- ПРОЧЕЕ
    acc.misc = acc.misc + dt
    if acc.misc >= MISC_TICK then acc.misc = 0
        Role.RefreshSelf()
        Move.applyBasics()
        if Config.Noclip then Move.noclip() end
        if Config.Invisible then Guard.invisible() end
        if Config.StreamerMode then Guard.streamerMode() end
        if Config.AutoFakeCheck then Combat.fakeWeaponCheck() end
        -- Kill All / Kill Sheriff / Kill Murderer вызываются кнопками вкладки Rage,
        -- чтобы не спамить ремоуты каждый тик (меньше следов в логах сервера)
    end
    Move.fly(dt)
    Move.spinBot(dt)
end)

RunService.RenderStepped:Connect(function(dt)
    ESP.render(dt)
end)

Farm.startSessionGuard()
Move.infJump()

--==============================================================================
-- 15. UI-ДВИЖОК (Rayfield-совместимый по API, собственная реализация)
--      Window:Tab / :Section / :Toggle / :Slider / :Dropdown / :Button /
--      :Keybind / :ColorPicker / :Paragraph — тот же синтаксис вызова
--==============================================================================
local UI = {}
UI.__index = UI
local THEME = {
    bg = Color3.fromRGB(11, 14, 23), panel = Color3.fromRGB(17, 22, 36),
    line = Color3.fromRGB(30, 36, 54), text = Color3.fromRGB(230, 233, 242),
    dim = Color3.fromRGB(148, 158, 180), accent = Color3.fromRGB(124, 92, 255),
    accent2 = Color3.fromRGB(34, 211, 238),
}

local function mk(class, props, parent)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

function UI.new(cfg)
    cfg = cfg or {}
    local self = setmetatable({}, UI)
    self.state = { minimized = not (Config.UI_Visible) }

    local gui = mk("ScreenGui", {
        Name = "MM2_HUB_X", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true, DisplayOrder = 9999,
    }, GuiParent)

    local main = mk("Frame", {
        Size = UDim2.fromOffset(700, 470), Position = UDim2.fromScale(.5, .5),
        AnchorPoint = Vector2.new(.5, .5), BackgroundColor3 = THEME.bg, BorderSizePixel = 0,
    }, gui)
    mk("UICorner", { CornerRadius = UDim.new(0, 14) }, main)
    mk("UIStroke", { Color = THEME.line, Thickness = 1 }, main)

    -- Тайтлбар + drag
    local title = mk("Frame", {
        Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = THEME.panel, BorderSizePixel = 0,
    }, main)
    mk("UICorner", { CornerRadius = UDim.new(0, 14) }, title)
    mk("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), BackgroundColor3 = THEME.line, BorderSizePixel = 0 }, title)
    mk("TextLabel", {
        Size = UDim2.new(1, -110, 1, 0), Position = UDim2.new(0, 14, 0, 0), BackgroundTransparency = 1,
        Text = "  MM2 HUB X  •  " .. (cfg.Version or "2.5.0"), TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = THEME.text, Font = Enum.Font.GothamBold, TextSize = 15,
    }, title)
    mk("TextLabel", {
        Size = UDim2.new(0, 260, 1, 0), Position = UDim2.new(1, -274, 0, 0), BackgroundTransparency = 1,
        Text = ExecName .. "  |  KEYLESS", TextXAlignment = Enum.TextXAlignment.Right,
        TextColor3 = THEME.dim, Font = Enum.Font.Gotham, TextSize = 11,
    }, title)

    local minBtn = mk("TextButton", {
        Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -34, .5, -13),
        BackgroundColor3 = THEME.line, Text = "—", TextColor3 = THEME.text,
        Font = Enum.Font.GothamBold, TextSize = 14,
    }, title)
    mk("UICorner", { CornerRadius = UDim.new(0, 8) }, minBtn)

    -- Перетаскивание окна
    do
        local dragging, dragStart, startPos = false, nil, nil
        title.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true dragStart = input.Position startPos = main.Position
            end
        end)
        UserInput.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
        UserInput.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
        end)
    end

    -- Таб-бар
    local sidebar = mk("Frame", {
        Size = UDim2.new(0, 168, 1, -42), Position = UDim2.new(0, 0, 0, 42),
        BackgroundColor3 = THEME.bg, BorderSizePixel = 0,
    }, main)
    mk("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }, sidebar)
    mk("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, sidebar)

    local body = mk("Frame", {
        Size = UDim2.new(1, -168, 1, -42), Position = UDim2.new(0, 168, 0, 42),
        BackgroundTransparency = 1, BorderSizePixel = 0,
    }, main)
    mk("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12) }, body)

    self.gui, self.main, self.sidebar, self.body = gui, main, sidebar, body
    self.tabs, self.current = {}, nil

    minBtn.MouseButton1Click:Connect(function() self:SetMinimized(not self.state.minimized) end)
    UserInput.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.RightControl then
            self:SetMinimized(not self.state.minimized)
        end
    end)

    -- Уведомления
    Notify = function(title, text, dur)
        local n = mk("Frame", {
            Size = UDim2.fromOffset(280, 62), Position = UDim2.new(1, 300, 1, -80),
            AnchorPoint = Vector2.new(0, 1), BackgroundColor3 = THEME.panel, BorderSizePixel = 0,
        }, gui)
        mk("UICorner", { CornerRadius = UDim.new(0, 12) }, n)
        mk("UIStroke", { Color = THEME.accent, Thickness = 1, Transparency = .4 }, n)
        mk("TextLabel", {
            Size = UDim2.new(1, -20, 0, 20), Position = UDim2.new(0, 12, 0, 8), BackgroundTransparency = 1,
            Text = title, TextColor3 = THEME.accent2, Font = Enum.Font.GothamBold, TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, n)
        mk("TextLabel", {
            Size = UDim2.new(1, -24, 0, 30), Position = UDim2.new(0, 12, 0, 28), BackgroundTransparency = 1,
            Text = text, TextColor3 = THEME.text, Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, n)
        TweenService:Create(n, TweenInfo.new(.35, Enum.EasingStyle.Quint), { Position = UDim2.new(1, -300, 1, -80) }):Play()
        task.delay(dur or 3, function()
            TweenService:Create(n, TweenInfo.new(.3), { Position = UDim2.new(1, 300, 1, -80) }):Play()
            task.wait(.32) n:Destroy()
        end)
    end

    return self
end

function UI:SetMinimized(v)
    self.state.minimized = v
    Set("UI_Visible", not v)
    local goal = v and UDim2.fromOffset(220, 42) or UDim2.fromOffset(700, 470)
    TweenService:Create(self.main, TweenInfo.new(.28, Enum.EasingStyle.Quint), { Size = goal }):Play()
    self.sidebar.Visible = not v
    self.body.Visible = not v
end

function UI:Tab(name, order)
    local btn = mk("TextButton", {
        Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = THEME.bg, Text = "  " .. name,
        TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = THEME.dim,
        Font = Enum.Font.GothamMedium, TextSize = 13, AutoButtonColor = false,
        LayoutOrder = order or #self.tabs + 1,
    }, self.sidebar)
    mk("UICorner", { CornerRadius = UDim.new(0, 9) }, btn)

    local page = mk("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0,
        CanvasSize = UDim2.new(), ScrollBarThickness = 4, ScrollBarImageColor3 = THEME.accent,
        Visible = false, LayoutOrder = order or 1,
    }, self.body)
    mk("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, page)
    mk("UIPadding", { PaddingBottom = UDim.new(0, 12) }, page)

    local tab = { name = name, btn = btn, page = page }
    table.insert(self.tabs, tab)
    btn.MouseButton1Click:Connect(function() self:Select(name) end)
    if #self.tabs == 1 then self:Select(name) end
    return tab
end

function UI:Select(name)
    for _, t in ipairs(self.tabs) do
        local on = t.name == name
        t.page.Visible = on
        t.btn.TextColor3 = on and THEME.text or THEME.dim
        TweenService:Create(t.btn, TweenInfo.new(.2), {
            BackgroundColor3 = on and Color3.fromRGB(124, 92, 255) or THEME.bg,
        }):Play()
        if on then
            t.page.CanvasSize = UDim2.new(0, 0, 0, t.page.UIListLayout.AbsoluteContentSize.Y + 24)
        end
    end
end

-- --- контролы ---------------------------------------------------------------
function UI._section(tab, title)
    return mk("TextLabel", {
        Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1, Text = title,
        TextColor3 = THEME.accent2, Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = #tab.page:GetChildren(),
    }, tab.page)
end

function UI._row(tab, h)
    local row = mk("Frame", {
        Size = UDim2.new(1, 0, 0, h or 34), BackgroundColor3 = THEME.panel,
        BorderSizePixel = 0, LayoutOrder = #tab.page:GetChildren(),
    }, tab.page)
    mk("UICorner", { CornerRadius = UDim.new(0, 10) }, row)
    mk("UIStroke", { Color = THEME.line, Thickness = 1 }, row)
    return row
end

function UI:Paragraph(tab, props)
    local row = UI._row(tab, 0)
    row.AutomaticSize = Enum.AutomaticSize.Y
    -- Content может быть строкой ИЛИ функцией (живой текст, например статистика фарма)
    local body = (type(props.Content) == "function") and tostring(props.Content()) or (props.Content or "")
    mk("TextLabel", {
        Size = UDim2.new(1, -24, 0, 0), Position = UDim2.new(0, 12, 0, 8), BackgroundTransparency = 1,
        Text = (props.Title and props.Title .. "\n" or "") .. body,
        TextColor3 = props.Color or THEME.text, TextWrapped = true, RichText = true,
        Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    return row
end

function UI:Toggle(tab, props)
    local row = UI._row(tab)
    mk("TextLabel", {
        Size = UDim2.new(1, -80, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
        Text = props.Name, TextColor3 = THEME.text, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local sw = mk("TextButton", {
        Size = UDim2.fromOffset(44, 22), Position = UDim2.new(1, -56, .5, -11),
        BackgroundColor3 = Color3.fromRGB(27, 33, 51), Text = "",
    }, row)
    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, sw)
    local knob = mk("Frame", {
        Size = UDim2.fromOffset(16, 16), Position = UDim2.new(0, 3, .5, -8),
        BackgroundColor3 = Color3.fromRGB(120, 130, 160),
    }, sw)
    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)

    local state = Config[props.Flag] == true
    local function paint(on)
        TweenService:Create(sw, TweenInfo.new(.2), {
            BackgroundColor3 = on and THEME.accent or Color3.fromRGB(27, 33, 51),
        }):Play()
        TweenService:Create(knob, TweenInfo.new(.2), {
            Position = on and UDim2.new(1, -19, .5, -8) or UDim2.new(0, 3, .5, -8),
            BackgroundColor3 = on and Color3.new(1, 1, 1) or Color3.fromRGB(120, 130, 160),
        }):Play()
    end
    paint(state)

    local function set(v, silent)
        state = v
        paint(v)
        Set(props.Flag, v)
        if props.Callback then pcall(props.Callback, v) end
    end
    sw.MouseButton1Click:Connect(function() set(not state) end)

    Flags[props.Flag] = { type = "toggle", set = function(v) set(v, true) end }
    if state and props.Callback then task.spawn(props.Callback, state) end
    return { Set = set, Get = function() return state end }
end

function UI:Slider(tab, props)
    local row = UI._row(tab, 46)
    local label = mk("TextLabel", {
        Size = UDim2.new(1, -24, 0, 18), Position = UDim2.new(0, 12, 0, 5), BackgroundTransparency = 1,
        Text = props.Name, TextColor3 = THEME.text, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local value = mk("TextLabel", {
        Size = UDim2.new(0, 90, 0, 18), Position = UDim2.new(1, -102, 0, 5), BackgroundTransparency = 1,
        Text = "", TextColor3 = THEME.accent2, Font = Enum.Font.Code, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)
    local bar = mk("TextButton", {
        Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 12, 0, 30),
        BackgroundColor3 = Color3.fromRGB(27, 33, 51), Text = "", AutoButtonColor = false,
    }, row)
    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
    local fill = mk("Frame", { Size = UDim2.new(0, 0, 1, 0), BackgroundColor3 = THEME.accent, BorderSizePixel = 0 }, bar)
    mk("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)

    local function pct(v) return (v - props.Min) / (props.Max - props.Min) end
    local function apply(v, silent)
        v = Util.clamp(math.floor(v / (props.Increment or 1) + .5) * (props.Increment or 1), props.Min, props.Max)
        fill.Size = UDim2.new(pct(v), 0, 1, 0)
        value.Text = tostring(v) .. (props.Suffix or "")
        Set(props.Flag, v)
        if props.Callback and not silent then pcall(props.Callback, v) end
    end
    apply(Config[props.Flag] or props.Default or props.Min, true)

    local sliding = false
    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end
    end)
    UserInput.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = Util.clamp((i.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            apply(props.Min + rel * (props.Max - props.Min))
        end
    end)
    UserInput.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)

    Flags[props.Flag] = { type = "slider", set = function(v) apply(v, true) end }
    return { Set = apply, Get = function() return Config[props.Flag] end }
end

function UI:Dropdown(tab, props)
    local row = UI._row(tab, 40)
    mk("TextLabel", {
        Size = UDim2.new(1, -24, 0, 16), Position = UDim2.new(0, 12, 0, 4), BackgroundTransparency = 1,
        Text = props.Name, TextColor3 = THEME.dim, Font = Enum.Font.Gotham, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local btn = mk("TextButton", {
        Size = UDim2.new(1, -24, 0, 0), Position = UDim2.new(0, 12, 0, 19), BackgroundTransparency = 1,
        Text = tostring(Config[props.Flag] or props.Options[1]) .. "  ▾", TextColor3 = THEME.text,
        Font = Enum.Font.GothamMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local current = Config[props.Flag] or props.Options[1]
    local open, list = false, nil
    btn.MouseButton1Click:Connect(function()
        open = not open
        if open and not list then
            list = mk("Frame", {
                Size = UDim2.new(1, -24, 0, #props.Options * 24), Position = UDim2.new(0, 12, 0, 19),
                BackgroundColor3 = Color3.fromRGB(9, 12, 20), BorderSizePixel = 0, ZIndex = 5,
            }, row)
            mk("UICorner", { CornerRadius = UDim.new(0, 8) }, list)
            for i, opt in ipairs(props.Options) do
                local b = mk("TextButton", {
                    Size = UDim2.new(1, -8, 0, 22), Position = UDim2.new(0, 4, 0, (i - 1) * 23),
                    BackgroundTransparency = 1, Text = "  " .. tostring(opt), TextColor3 = THEME.dim,
                    Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 6,
                }, list)
                b.MouseButton1Click:Connect(function()
                    current = opt
                    btn.Text = tostring(opt) .. "  ▾"
                    Set(props.Flag, opt)
                    if props.Callback then pcall(props.Callback, opt) end
                    open = false list:Destroy() list = nil
                end)
            end
        elseif list then
            list:Destroy() list = nil
        end
    end)
    Flags[props.Flag] = { type = "dropdown", set = function(v) current = v btn.Text = tostring(v) .. "  ▾" end }
end

function UI:Button(tab, props)
    local row = UI._row(tab, 32)
    local b = mk("TextButton", {
        Size = UDim2.new(1, -24, 0, 22), Position = UDim2.new(0, 12, .5, -11),
        BackgroundColor3 = Color3.fromRGB(27, 33, 51), Text = props.Name, TextColor3 = THEME.text,
        Font = Enum.Font.GothamMedium, TextSize = 13,
    }, row)
    mk("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
    b.MouseButton1Click:Connect(function()
        TweenService:Create(b, TweenInfo.new(.08), { BackgroundColor3 = THEME.accent }):Play()
        task.delay(.1, function() TweenService:Create(b, TweenInfo.new(.2), { BackgroundColor3 = Color3.fromRGB(27, 33, 51) }):Play() end)
        if props.Callback then task.spawn(props.Callback) end
    end)
    return b
end

function UI:Keybind(tab, props)
    local row = UI._row(tab, 32)
    mk("TextLabel", {
        Size = UDim2.new(1, -120, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
        Text = props.Name, TextColor3 = THEME.text, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local btn = mk("TextButton", {
        Size = UDim2.fromOffset(96, 22), Position = UDim2.new(1, -108, .5, -11),
        BackgroundColor3 = Color3.fromRGB(27, 33, 51), Text = props.Default and props.Default.Name or "None",
        TextColor3 = THEME.accent2, Font = Enum.Font.Code, TextSize = 12,
    }, row)
    mk("UICorner", { CornerRadius = UDim.new(0, 8) }, btn)
    local listening = false
    btn.MouseButton1Click:Connect(function() listening = true btn.Text = "..." end)
    UserInput.InputBegan:Connect(function(input, gp)
        if not listening or gp then return end
        if input.KeyCode ~= Enum.KeyCode.Unknown then
            listening = false
            btn.Text = input.KeyCode.Name
            if props.Callback then pcall(props.Callback, input.KeyCode) end
        end
    end)
end

function UI:ColorPicker(tab, props)
    local row = UI._row(tab, 32)
    mk("TextLabel", {
        Size = UDim2.new(1, -70, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1,
        Text = props.Name, TextColor3 = THEME.text, Font = Enum.Font.GothamMedium, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local cur = props.Default or Color3.fromRGB(124, 92, 255)
    local btn = mk("TextButton", {
        Size = UDim2.fromOffset(44, 20), Position = UDim2.new(1, -56, .5, -10),
        BackgroundColor3 = cur, Text = "",
    }, row)
    mk("UICorner", { CornerRadius = UDim.new(0, 6) }, btn)
    btn.MouseButton1Click:Connect(function()
        -- простой HSV-перебор по клику (без внешних библиотек)
        local h, s, v = cur:ToHSV()
        cur = Color3.fromHSV((h + .07) % 1, s, v)
        btn.BackgroundColor3 = cur
        if props.Callback then pcall(props.Callback, cur) end
    end)
end

--==============================================================================
-- 16. СБОРКА ИНТЕРФЕЙСА
--==============================================================================
local Window = UI.new({ Title = "MM2 HUB X", Version = "2.5.0" })

-- ------------------------------- LEGIT --------------------------------------
local Legit = Window:Tab("Legit", 1)
UI._section(Legit, "СИЛЕНТ АИМ (ШЕРИФ)")
UI:Toggle(Legit, { Name = "Silent Aim", Flag = "SilentAim", Callback = function(v)
    if v then Combat.startSilentAim() end
end })
UI:Slider(Legit, { Name = "FOV аимбота", Flag = "SA_FOV", Min = 10, Max = 360, Default = 70, Suffix = "°", Callback = function(v)
    Config.SA_FOV = v Config.FOV_Size = v Set("FOV_Size", v)
end })
UI:Dropdown(Legit, { Name = "Приоритет", Flag = "SA_Priority", Options = { "Head", "Torso", "Nearest" },
    Callback = function(v) Config.SA_Priority = (v == "Nearest" and "Head" or v) end })
UI:Toggle(Legit, { Name = "Wall Check", Flag = "SA_WallCheck" })
UI:Slider(Legit, { Name = "Плавность", Flag = "SA_Smooth", Min = 0, Max = 1, Default = .35, Increment = .05, Callback = function(v) Config.SA_Smooth = v end })
UI:Toggle(Legit, { Name = "Круг FOV", Flag = "FOV_Circle" })
UI._section(Legit, "ЛЕГИТ-ПОДДЕРЖКА")
UI:Toggle(Legit, { Name = "Gun Grabber (авто-подбор пистолета)", Flag = "GunGrabber" })
UI:Toggle(Legit, { Name = "Auto Dodge Knives", Flag = "KnifeDodge" })
UI:Slider(Legit, { Name = "Радиус доджа", Flag = "DodgeDist", Min = 10, Max = 150, Default = 45, Suffix = " ст." })
UI:Paragraph(Legit, {
    Title = "⚠ ВНИМАНИЕ",
    Content = "Использование на свой риск. Рекомендуется аккаунт-альтернатива.",
    Color = Color3.fromRGB(255, 205, 110),
})

-- ------------------------------- RAGE ---------------------------------------
local Rage = Window:Tab("Rage", 2)
UI._section(Rage, "KILL AURA (МАРДЕР)")
UI:Toggle(Rage, { Name = "Kill Aura", Flag = "KillAura" })
UI:Slider(Rage, { Name = "Радиус убийства", Flag = "AuraRadius", Min = 5, Max = 100, Default = 22, Suffix = " ст." })
UI:Toggle(Rage, { Name = "Авто-бросок ножа", Flag = "AuraAutoThrow" })
UI:Toggle(Rage, { Name = "Только ближайшие цели", Flag = "AuraOnlyNear" })
UI:Slider(Rage, { Name = "Задержка атаки", Flag = "AuraDelay", Min = .05, Max = 2, Default = .25, Increment = .05, Suffix = " с" })
UI:Toggle(Rage, { Name = "Продвинутый: авто-подход к цели", Flag = "AutoApproach" })
UI:Slider(Rage, { Name = "Скорость подхода", Flag = "ApproachSpeed", Min = 16, Max = 200, Default = 95 })
UI._section(Rage, "ХИТБОКС И ДЕЙСТВИЯ")
UI:Toggle(Rage, { Name = "Hitbox Expander", Flag = "HitboxExpand" })
UI:Slider(Rage, { Name = "Размер хитбокса", Flag = "HitboxSize", Min = 2, Max = 100, Default = 12, Suffix = " ст." })
UI:Button(Rage, { Name = "🔪 KILL ALL", Callback = function() Combat.killAll(nil) end })
UI:Button(Rage, { Name = "⭐ KILL SHERIFF", Callback = function() Combat.killAll("Sheriff") end })
UI:Button(Rage, { Name = "🩸 KILL MURDERER", Callback = function() Combat.killAll("Murderer") end })
UI:Button(Rage, { Name = "☠ FLING БЛИЖАЙШЕГО (подтверждение)", Callback = function()
    local t = nearestTarget(80, false)
    if t then
        -- двойное подтверждение = защита от случайного нажатия
        local confirmed = false
        Util.notify("Fling", "Цель: " .. t.Name .. " — нажмите кнопку ещё раз", 4)
        UI._flingArmed = t.Name
        task.delay(3, function() UI._flingArmed = nil end)
    end
end })
UI:Button(Rage, { Name = "☠ FLING — ПОДТВЕРДИТЬ", Callback = function()
    if UI._flingArmed then
        local t = nil
        for _, p in ipairs(PlayerList) do if p.Name == UI._flingArmed then t = p end end
        if t then Combat.fling(t) UI._flingArmed = nil end
    else
        Util.notify("Fling", "Сначала выберите цель предыдущей кнопкой", 3)
    end
end })

-- ------------------------------ FARMING -------------------------------------
local FarmTab = Window:Tab("Farming", 3)
UI._section(FarmTab, "ФАРМ МОНЕТ")
UI:Toggle(FarmTab, { Name = "Авто-сбор монет", Flag = "CoinFarm" })
UI:Dropdown(FarmTab, { Name = "Режим", Flag = "CoinMode", Options = { "Near", "Teleport" },
    Callback = function(v) Config.CoinMode = v end })
UI:Slider(FarmTab, { Name = "Радиус поиска", Flag = "CoinRadius", Min = 20, Max = 2000, Default = 150, Suffix = " ст." })
UI:Slider(FarmTab, { Name = "Скорость сбора", Flag = "CoinDelay", Min = .02, Max = 1.5, Default = .12, Increment = .02, Suffix = " с" })
UI:Toggle(FarmTab, { Name = "Smart: обходить игроков", Flag = "CoinSmartAvoid" })
UI:Slider(FarmTab, { Name = "Сброс при полном мешке (шт.)", Flag = "CoinBagReset", Min = 0, Max = 200, Default = 35, Suffix = " шт." })
UI._section(FarmTab, "БОКСЫ / ИВЕНТЫ / ПРОГРЕСС")
UI:Toggle(FarmTab, { Name = "Авто-открытие Mystery Box", Flag = "BoxFarm" })
UI:Toggle(FarmTab, { Name = "Авто-сбор ивентовых предметов", Flag = "EventFarm" })
UI:Toggle(FarmTab, { Name = "Авто-престиж / ребёрт", Flag = "AutoPrestige" })
UI:Slider(FarmTab, { Name = "Уровень для престижа", Flag = "PrestigeLevel", Min = 10, Max = 1000, Default = 100 })
UI._section(FarmTab, "СЕССИЯ")
UI:Toggle(FarmTab, { Name = "Anti-AFK", Flag = "AntiAFK" })
UI:Toggle(FarmTab, { Name = "Авто-реконнект после кика", Flag = "AutoReconnect" })
UI:Paragraph(FarmTab, {
    Title = "Статистика фарма",
    Content = function() return ("Собрано за сессию: %d монет | Уровень: %d"):format(Farm.collected, Farm.myLevel()) end,
})

-- -------------------------------- ESP ---------------------------------------
local EspTab = Window:Tab("ESP", 4)
UI._section(EspTab, "ОСНОВНОЙ ESP")
UI:Toggle(EspTab, { Name = "Player ESP", Flag = "ESP_Enabled" })
UI:Toggle(EspTab, { Name = "Boxes", Flag = "ESP_Box" })
UI:Toggle(EspTab, { Name = "Names", Flag = "ESP_Name" })
UI:Toggle(EspTab, { Name = "Дистанция", Flag = "ESP_Dist" })
UI:Toggle(EspTab, { Name = "Tracers", Flag = "ESP_Tracer" })
UI:Toggle(EspTab, { Name = "Health Bar", Flag = "ESP_Health" })
UI:Toggle(EspTab, { Name = "Skeleton", Flag = "ESP_Skeleton" })
UI:Toggle(EspTab, { Name = "X-Ray (через стены)", Flag = "ESP_XRay" })
UI._section(EspTab, "РОЛЕВЫЕ ЦВЕТА (CHAMS)")
UI:Toggle(EspTab, { Name = "Chams: Мардер=красный / Шериф=синий / Инносент=зелёный", Flag = "ESP_Chams" })
UI:Slider(EspTab, { Name = "Прозрачность заливки", Flag = "ChamsFill", Min = 0, Max = 1, Default = .55, Increment = .05 })
UI:Slider(EspTab, { Name = "Прозрачность контура", Flag = "ChamsOutline", Min = 0, Max = 1, Default = 0, Increment = .05 })
UI:Toggle(EspTab, { Name = "Gun ESP (выпавшее оружие)", Flag = "ESP_GunESP" })
UI._section(EspTab, "ПРОЧЕЕ")
UI:Toggle(EspTab, { Name = "Streamer Mode (скрыть ники)", Flag = "StreamerMode" })
UI:Slider(EspTab, { Name = "FPS ESP (оптимизация)", Flag = "ESP_FPS", Min = 10, Max = 60, Default = 30, Suffix = " fps" })
UI:ColorPicker(EspTab, { Name = "Цвет FOV-круга", Default = Color3.fromRGB(180, 160, 255) })

-- -------------------------------- MISC --------------------------------------
local MiscTab = Window:Tab("Misc", 5)
UI._section(MiscTab, "ЗАЩИТА")
UI:Toggle(MiscTab, { Name = "Anti-Fling", Flag = "AntiFling" })
UI:Toggle(MiscTab, { Name = "God Mode", Flag = "GodMode" })
UI:Toggle(MiscTab, { Name = "Second Chance (двойная жизнь)", Flag = "SecondChance" })
UI:Toggle(MiscTab, { Name = "Anti-Void", Flag = "AntiVoid" })
UI:Toggle(MiscTab, { Name = "Anti-Lava", Flag = "AntiLava" })
UI:Slider(MiscTab, { Name = "Порог бездны (Y)", Flag = "VoidY", Min = -500, Max = -10, Default = -60 })
UI:Toggle(MiscTab, { Name = "Invisible Mode", Flag = "Invisible" })
UI._section(MiscTab, "ДВИЖЕНИЕ")
UI:Slider(MiscTab, { Name = "Walk Speed", Flag = "WalkSpeed", Min = 16, Max = 200, Default = 16 })
UI:Slider(MiscTab, { Name = "Jump Power", Flag = "JumpPower", Min = 50, Max = 300, Default = 50 })
UI:Toggle(MiscTab, { Name = "Infinite Jump", Flag = "InfJump" })
UI:Toggle(MiscTab, { Name = "Fly (WASD + Space/Shift)", Flag = "Fly" })
UI:Slider(MiscTab, { Name = "Fly Speed", Flag = "FlySpeed", Min = 10, Max = 300, Default = 55 })
UI:Toggle(MiscTab, { Name = "Noclip", Flag = "Noclip" })
UI:Toggle(MiscTab, { Name = "SpinBot", Flag = "SpinBot" })
UI:Slider(MiscTab, { Name = "Скорость SpinBot", Flag = "SpinSpeed", Min = 1, Max = 60, Default = 14 })
UI._section(MiscTab, "ЭМОЦИИ")
UI:Toggle(MiscTab, { Name = "Emote Unlocker", Flag = "EmoteUnlocker" })
UI:Dropdown(MiscTab, { Name = "Эмоция", Flag = "Emote", Options = { "Floss", "Dab", "Ninja", "Headless", "Zombie" },
    Callback = function(v) if Config.EmoteUnlocker then Move.playEmote(v) end end })
UI:Button(MiscTab, { Name = "▶ Воспроизвести эмоцию", Callback = function() Move.playEmote(Config.Emote) end })
UI._section(MiscTab, "СЕРВЕР")
UI:Button(MiscTab, { Name = "🔁 Rejoin", Callback = function() Server.rejoin() end })
UI:Button(MiscTab, { Name = "🌐 Server Hop → LOW сервер", Callback = function() Server.hop("low") end })
UI:Button(MiscTab, { Name = "🌐 Server Hop → FULL сервер", Callback = function() Server.hop("full") end })
UI:Button(MiscTab, { Name = "📋 Copy Job ID", Callback = function() Server.copyJobId() end })
UI:Toggle(MiscTab, { Name = "Проверка фейкового ножа/оружия", Flag = "AutoFakeCheck" })

-- ------------------------------ SETTINGS ------------------------------------
local SetTab = Window:Tab("Settings", 6)
UI._section(SetTab, "КОНФИГ")
UI:Button(SetTab, { Name = "💾 Сохранить конфиг", Callback = function()
    SaveConfig() Util.notify("Конфиг", "Сохранён: " .. CFG_NAME, 3)
end })
UI:Button(SetTab, { Name = "📂 Загрузить конфиг", Callback = function()
    LoadConfig()
    for flag, c in pairs(Flags) do pcall(c.set, Config[flag]) end
    Util.notify("Конфиг", "Загружен", 3)
end })
UI:Button(SetTab, { Name = "♻ Сбросить настройки", Callback = function()
    Config = {}
    for k, v in pairs(DEFAULT) do Config[k] = v end
    for flag, c in pairs(Flags) do pcall(c.set, Config[flag]) end
    SaveConfig()
    Util.notify("Конфиг", "Все настройки сброшены", 3)
end })
UI:Paragraph(SetTab, {
    Title = "ℹ Инфо",
    Content = ("Исполнитель: %s\nDrawing API: %s\nwritefile: %s\nhookmetamethod: %s\nВерсия: %s")
        :format(ExecName, tostring(HAS_DRAWING), tostring(HAS_WRITEFILE), tostring(HAS_HOOKMETA), "2.5.0"),
})
UI:Paragraph(SetTab, {
    Title = "⚠ Отказ от ответственности",
    Content = "Использование на свой риск. Рекомендуется аккаунт-альтернатива.\nСкрипт не содержит key-системы, вебхуков и не обращается к вашим токенам.",
    Color = Color3.fromRGB(255, 205, 110),
})

--==============================================================================
-- 17. СТАРТ
--==============================================================================
task.delay(1, function()
    Util.notify("MM2 HUB X", "Загружен | " .. ExecName .. " | RightControl = свернуть", 5)
    print(("=== MM2 HUB X 2.5.0 ===\nexecutor: %s | drawing: %s | writefile: %s | hook: %s | players: %d")
        :format(ExecName, tostring(HAS_DRAWING), tostring(HAS_WRITEFILE), tostring(HAS_HOOKMETA), #PlayerList + 1))
    if Config.SilentAim then Combat.startSilentAim() end
end)

return {
    Config = Config, Util = Util, Role = Role, Farm = Farm,
    Combat = Combat, Guard = Guard, ESP = ESP, Move = Move, Server = Server, UI = Window,
}
