local ok, err = pcall(function()

if _G.XenoLoaded then
    if _G.XenoCleanup then _G.XenoCleanup() end
    task.wait(0.3)
end
_G.XenoLoaded = true

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local WS = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local Plr = Players.LocalPlayer
local Cam = WS.CurrentCamera
local Mouse = Plr:GetMouse()
local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local SC = function(p,m) return IsMobile and m or p end

local Exec = {name="Unknown",canSilent=false,canCoreGui=false}
pcall(function() if identifyexecutor then Exec.name=identifyexecutor() elseif getexecutorname then Exec.name=getexecutorname() end end)
pcall(function() local t=Instance.new("Folder");t.Parent=CoreGui;t:Destroy();Exec.canCoreGui=true end)
local hasHM=typeof(hookmetamethod)=="function"
local hasNC=typeof(getnamecallmethod)=="function"
local hasRM=typeof(getrawmetatable)=="function"
local hasSR=typeof(setreadonly)=="function" or typeof(make_writeable)=="function"
Exec.canSilent=(hasHM and hasNC) or (hasRM and hasSR)

local drawOK=false
pcall(function() local t=Drawing.new("Line");t.Visible=false;t:Remove();drawOK=true end)

local function Notify(t,m,d) pcall(function() StarterGui:SetCore("SendNotification",{Title=t,Text=m or"",Duration=d or 4}) end) end
local function SafeP() if Exec.canCoreGui then return CoreGui end;if typeof(gethui)=="function" then local o,r=pcall(gethui);if o and r then return r end end;return Plr:WaitForChild("PlayerGui") end
local function Protect(g) if typeof(syn)=="table" and syn.protect_gui then pcall(syn.protect_gui,g) end;if typeof(protect_gui)=="function" then pcall(protect_gui,g) end end
local function Kill(d) if d then pcall(function() d:Remove() end) end end
local function ND(t) if not drawOK then return nil end;local o,d=pcall(Drawing.new,t);if o and d then pcall(function() d.Visible=false end);return d end;return nil end
local function DS(d,p,v) if d then pcall(function() d[p]=v end) end end
local function DV(d,v) if d then pcall(function() d.Visible=v end) end end
local function IV(d) if not d then return false end;local o=pcall(function() return d.Visible end);return o end

Notify("XENO","Loading v9.1...",3)

-- ═══════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════
local Cfg={
    On=false,AimMode=Exec.canSilent and"silent"or"normal",
    Part="Head",Priority="FOV",Sticky=true,StickyTime=3,Aim360=false,
    FOV={On=true,R=SC(120,200),Show=true,Color=Color3.fromRGB(90,130,255),Trans=0.7,Thick=1.5},
    Smooth={On=true,Amt=SC(0.15,0.25),Dynamic=true,Max=0.5,Min=0.05},
    Pred={On=false,Factor=0.12,VelSmooth=0.3},
    Silent={On=Exec.canSilent,Chance=100,Use360=false},
    Flick={On=not Exec.canSilent,Restore=true,Chance=100,Speed=1.0,MobileAuto=IsMobile},
    TB={On=false,Auto=false,Delay=0.1},
    Vis={Dot=true,DotClr=Color3.fromRGB(255,50,50),DotSz=SC(6,10),Line=not IsMobile,LineClr=Color3.fromRGB(255,255,255),LineW=1.5},
    ESP={
        On=false,MaxDist=1500,ShowTeam=false,
        Style="Corner",
        Render={FPS=0,Interp=true,InterpSpeed=18},
        Colors={
            EBox=Color3.fromRGB(255,50,50),EBoxBot=Color3.fromRGB(255,120,30),
            EName=Color3.fromRGB(255,255,255),EGlow=Color3.fromRGB(255,40,40),
            ECyber=Color3.fromRGB(255,60,60),ECyberAccent=Color3.fromRGB(255,180,50),
            ETracer=Color3.fromRGB(255,80,80),ESkel=Color3.fromRGB(255,100,100),
            TBox=Color3.fromRGB(50,255,50),TBoxBot=Color3.fromRGB(30,200,120),
            TName=Color3.fromRGB(255,255,255),TGlow=Color3.fromRGB(40,255,80),
            TCyber=Color3.fromRGB(60,255,100),TCyberAccent=Color3.fromRGB(50,200,255),
            TTracer=Color3.fromRGB(80,255,80),TSkel=Color3.fromRGB(100,255,100),
            Outline=Color3.fromRGB(0,0,0),NameShadow=Color3.fromRGB(0,0,0),
            HPLo=Color3.fromRGB(255,50,50),HPMid=Color3.fromRGB(255,200,50),HPHi=Color3.fromRGB(80,220,120),
            HPBg=Color3.fromRGB(25,25,25),DistClr=Color3.fromRGB(180,180,200),
            WeaponClr=Color3.fromRGB(200,180,140),FlagsClr=Color3.fromRGB(180,180,255),
            HeadDotClr=Color3.fromRGB(255,255,255),OFSClr=Color3.fromRGB(255,50,50),
        },
        Box={On=true,W=SC(1.5,1),CL=0.25,OW=2,Outline=true,
            VisCheck=false,VisClr=Color3.fromRGB(50,255,50),InvisClr=Color3.fromRGB(255,50,50)},
        Name={On=true,Sz=SC(14,12),Pos="Top",Fmt="Name+Distance",OL=true,Shadow=true},
        HP={On=true,W=3,Off=5,Pos="Left",Txt=true,TFmt="HP",OL=true,Smooth=true,SmoothSpd=10},
        Dist={On=false,Sz=12,Pos="Bottom"},
        Weapon={On=false,Sz=11},
        Tracer={On=false,W=1.5,Origin="Bottom",Outline=false,OW=1},
        Skel={On=false,W=1.5,VisCheck=false},
        HeadDot={On=false,Rad=SC(3,4),Filled=true,Sides=16,Outline=true,OW=1},
        Flags={On=false,Sz=11,ShowTool=true,ShowDist=true,ShowVis=false},
        OFS={On=false,Sz=14,Rad=200},
        Glow={Layers=3,Spread=3,BaseTrans=0.4,FadeStep=0.2},
        Cyber={ScanLine=true,ScanSpeed=2,TickMarks=true,TickLen=6},
        Grad={Steps=4},
    },
    WH={On=false,Fill=Color3.fromRGB(255,0,0),FT=0.5,Out=Color3.fromRGB(255,255,255),OT=0,
        TFill=Color3.fromRGB(0,255,0),TOut=Color3.fromRGB(200,255,200),UseTC=true,ShowTeam=false},
    Wall={Thresh=0.5,MaxPierce=6},
    Checks={Team=true,Alive=true,Wall=true,FF=true,Dist=true},
    Limits={MaxD=800,MaxA=SC(75,90),MinD=5},
    TP={On=false,Dist=12,Unlock=true},Spin={On=false,Spd=15},Speed={On=false,Mult=1.5},
    AC={On=true,AltDetect=true,CacheRate=0.3,DeepScan=true},
    TInfo={On=true,Weapon=true,Dist=true},Notif=true,Debug=false
}

local S={
    tgt={part=nil,plr=nil,dist=0,hp=0,mhp=0,name="",lastT=0,vis=false,lastPos=nil,sVel=Vector3.zero},
    me={char=nil,hum=nil,root=nil,alive=false},
    aim={silentPos=nil,hooked=false,flickOn=false,flickCF=nil},
    fire={last=0,method="none"},draw={},espC={},whC={},
    charMap={},charMapTick=0,spinAng=0,conns={},
    gui=nil,mobFrame=nil,subMenu=nil,
    -- Combat Arena specific
    arenaCache={},arenaTick=0,
}

-- ═══════════════════════════════════════
-- MATH / UTIL
-- ═══════════════════════════════════════
local function W2S(pos) if not Cam then return nil,0,false end;local o,v,on=pcall(Cam.WorldToViewportPoint,Cam,pos);if not o or not v then return nil,0,false end;return on and Vector2.new(v.X,v.Y) or nil,v.Z,on end
local function W2SR(pos) if not Cam then return nil,0 end;local o,v=pcall(Cam.WorldToViewportPoint,Cam,pos);if not o or not v then return nil,0 end;return Vector2.new(v.X,v.Y),v.Z end
local function SCC() if not Cam then return Vector2.new() end;return Vector2.new(Cam.ViewportSize.X*0.5,Cam.ViewportSize.Y*0.5) end
local function SDist(wp) local sp,_,on=W2S(wp);return(sp and on)and(sp-SCC()).Magnitude or math.huge end
local function HPCol(pct) pct=math.clamp(pct,0,1);local C2=Cfg.ESP.Colors;if pct>0.6 then local t=(pct-0.6)/0.4;local a,b=C2.HPMid,C2.HPHi;return Color3.new(a.R+(b.R-a.R)*t,a.G+(b.G-a.G)*t,a.B+(b.B-a.B)*t) end;local t=pct/0.6;local a,b=C2.HPLo,C2.HPMid;return Color3.new(a.R+(b.R-a.R)*t,a.G+(b.G-a.G)*t,a.B+(b.B-a.B)*t) end
local function Lerp3(a,b,t) return Color3.new(a.R+(b.R-a.R)*t,a.G+(b.G-a.G)*t,a.B+(b.B-a.B)*t) end
local function TeamEq(p1,p2) if not p1 or not p2 then return false end;local t1,t2;pcall(function() t1=p1.Team end);pcall(function() t2=p2.Team end);return t1 and t2 and t1==t2 end
local function GetTool(ch) if not ch then return nil end;for _,c in ipairs(ch:GetChildren()) do if c:IsA("Tool") then return c end end;return nil end
local function IgnoreP(p) if not p then return true end;if p.Transparency>=Cfg.Wall.Thresh then return true end;if not p.CanCollide then return true end;return false end

local function CanSee(part,myCh)
    if not part or not myCh or not Cam then return true end
    local o=Cam.CFrame.Position;local tp=part.Position;local dir=tp-o;local dist=dir.Magnitude
    if dist<3 then return true end;dir=dir.Unit
    local ign={myCh};local tCh=part.Parent;if tCh then table.insert(ign,tCh) end
    local par=RaycastParams.new();par.FilterType=Enum.RaycastFilterType.Exclude;par.FilterDescendantsInstances=ign;par.RespectCanCollide=false
    local cur=o;local rem=dist-1
    for _=1,Cfg.Wall.MaxPierce do
        if rem<=0 then return true end;local r=WS:Raycast(cur,dir*rem,par)
        if not r then return true end;if(r.Position-o).Magnitude>=dist-1 then return true end
        if IgnoreP(r.Instance) then table.insert(ign,r.Instance);par.FilterDescendantsInstances=ign;cur=r.Position+dir*0.15;rem=dist-(cur-o).Magnitude-1
        else return false end
    end;return false
end

-- ═══════════════════════════════════════════════════════════
-- RESOLVER v3 — Combat Arena / Gunfight Arena обход
-- ═══════════════════════════════════════════════════════════
-- Эти игры:
-- 1) Используют кастомные модели НЕ привязанные к Player.Character
-- 2) Модели в папках типа "Characters", "Alive", "InRound" и т.д.
-- 3) Иногда привязка через Attribute, StringValue, ObjectValue
-- 4) Иногда модель названа по UserId, не по Name
-- 5) Humanoid может называться по-другому или быть в подмодели
-- ═══════════════════════════════════════════════════════════

local Res = {}

-- Проверяем является ли модель живым персонажем
local function IsAliveModel(model)
    if not model or not model:IsA("Model") then return false end
    -- Ищем Humanoid
    local hum = model:FindFirstChildOfClass("Humanoid")
    if not hum then
        -- Некоторые игры прячут Humanoid внутрь
        for _, d in ipairs(model:GetDescendants()) do
            if d:IsA("Humanoid") then hum = d; break end
        end
    end
    if not hum or hum.Health <= 0 then return false end
    -- Ищем корневую часть
    local root = model:FindFirstChild("HumanoidRootPart")
        or model:FindFirstChild("Torso")
        or model:FindFirstChild("UpperTorso")
        or model.PrimaryPart
    if not root then
        -- Ищем любую BasePart с именем содержащим root/torso
        for _, p in ipairs(model:GetChildren()) do
            if p:IsA("BasePart") then
                local ln = p.Name:lower()
                if ln:find("root") or ln:find("torso") or ln:find("hrp") then
                    root = p; break
                end
            end
        end
    end
    return root ~= nil, hum, root
end

-- Пытаемся связать модель с игроком
local function ModelMatchesPlayer(model, tp)
    if not model or not tp then return false end
    local names = {tp.Name, tp.DisplayName, tostring(tp.UserId)}

    -- Прямое совпадение имени
    for _, n in ipairs(names) do
        if model.Name == n then return true end
    end

    -- Проверяем атрибуты
    local attrNames = {"Player","player","Owner","owner","UserId","userId","PlayerName","playerName","User"}
    for _, an in ipairs(attrNames) do
        local av = nil
        pcall(function() av = model:GetAttribute(an) end)
        if av then
            if av == tp.Name or av == tp.DisplayName or av == tp.UserId or tostring(av) == tostring(tp.UserId) then
                return true
            end
        end
    end

    -- Проверяем StringValue / ObjectValue внутри модели
    for _, child in ipairs(model:GetChildren()) do
        if child:IsA("StringValue") then
            local ln = child.Name:lower()
            if ln:find("player") or ln:find("owner") or ln:find("user") then
                if child.Value == tp.Name or child.Value == tp.DisplayName then return true end
            end
        elseif child:IsA("IntValue") or child:IsA("NumberValue") then
            local ln = child.Name:lower()
            if ln:find("userid") or ln:find("player") then
                if child.Value == tp.UserId then return true end
            end
        elseif child:IsA("ObjectValue") then
            local ln = child.Name:lower()
            if ln:find("player") or ln:find("owner") then
                pcall(function() if child.Value == tp then return true end end)
            end
        end
    end

    -- Проверяем есть ли Billboard с именем игрока
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BillboardGui") or d:IsA("TextLabel") then
            pcall(function()
                if d:IsA("TextLabel") and (d.Text == tp.Name or d.Text == tp.DisplayName) then
                    return true
                end
            end)
        end
    end

    return false
end

-- Глубокий поиск всех живых моделей в workspace
local function CollectAliveModels()
    local results = {}
    local visited = {}

    local function scan(parent, depth)
        if depth > 6 then return end
        if visited[parent] then return end
        visited[parent] = true

        local ok2, children = pcall(function() return parent:GetChildren() end)
        if not ok2 then return end

        for _, child in ipairs(children) do
            if child:IsA("Model") then
                local alive, hum, root = IsAliveModel(child)
                if alive then
                    table.insert(results, {model = child, hum = hum, root = root})
                end
            end
            -- Рекурсивно ищем в папках, моделях, и других контейнерах
            if child:IsA("Folder") or child:IsA("Model") or child:IsA("Configuration") or child:IsA("WorldModel") then
                scan(child, depth + 1)
            end
        end
    end

    scan(WS, 0)
    return results
end

function Res.Find(tp)
    if not tp then return nil end

    -- 1) Стандартный Character
    local ch = tp.Character
    if ch and ch.Parent then
        local alive = IsAliveModel(ch)
        if alive then return ch end
    end

    if not Cfg.AC.On or not Cfg.AC.AltDetect then return ch end

    -- 2) Поиск по имени в кэше арены
    if Cfg.AC.DeepScan then
        -- Обновляем кэш каждые CacheRate секунд
        if tick() - S.arenaTick > Cfg.AC.CacheRate then
            S.arenaCache = CollectAliveModels()
            S.arenaTick = tick()
        end

        -- Ищем модель принадлежащую этому игроку
        for _, entry in ipairs(S.arenaCache) do
            if entry.model ~= ch and entry.model.Parent then
                if ModelMatchesPlayer(entry.model, tp) then
                    return entry.model
                end
            end
        end

        -- Если не нашли по атрибутам, ищем по близости к камере игрока
        -- (последний резорт — полезно когда имена не совпадают)
    end

    return ch
end

function Res.Scan()
    if tick() - S.charMapTick < Cfg.AC.CacheRate then return end
    S.charMapTick = tick()
    S.charMap = {}
    for _, tp in ipairs(Players:GetPlayers()) do
        if tp == Plr then continue end
        S.charMap[tp] = Res.Find(tp)
    end
end

function Res.Get(tp)
    if Cfg.AC.On and Cfg.AC.AltDetect then
        Res.Scan()
        return S.charMap[tp] or tp.Character
    end
    return tp.Character
end

-- Улучшенная HP функция для арен
function Res.HP(ch)
    if not ch then return 0, 100 end
    -- Стандартный Humanoid
    local h = ch:FindFirstChildOfClass("Humanoid")
    if not h then
        for _, d in ipairs(ch:GetDescendants()) do
            if d:IsA("Humanoid") then h = d; break end
        end
    end
    if h then return h.Health, h.MaxHealth end
    -- NumberValue с именем Health/HP
    for _, d in ipairs(ch:GetDescendants()) do
        if (d:IsA("NumberValue") or d:IsA("IntValue")) then
            local ln = d.Name:lower()
            if ln == "health" or ln == "hp" then
                local max = 100
                local maxV = ch:FindFirstChild("MaxHealth") or ch:FindFirstChild("MaxHP")
                if maxV and (maxV:IsA("NumberValue") or maxV:IsA("IntValue")) then max = maxV.Value end
                return d.Value, max
            end
        end
    end
    -- Attribute
    local aHP = nil
    pcall(function() aHP = ch:GetAttribute("Health") or ch:GetAttribute("HP") end)
    if aHP then return aHP, 100 end
    return 100, 100
end

-- Улучшенный поиск корневой части
function Res.Root(ch)
    if not ch then return nil end
    local r = ch:FindFirstChild("HumanoidRootPart")
        or ch:FindFirstChild("Torso")
        or ch:FindFirstChild("UpperTorso")
    if r then return r end
    if ch.PrimaryPart then return ch.PrimaryPart end
    for _, p in ipairs(ch:GetChildren()) do
        if p:IsA("BasePart") then
            local ln = p.Name:lower()
            if ln:find("root") or ln:find("torso") or ln:find("hrp") then return p end
        end
    end
    -- Последний резорт — первая BasePart
    for _, p in ipairs(ch:GetChildren()) do
        if p:IsA("BasePart") then return p end
    end
    return nil
end

-- ═══════════════════════════════════════
-- CHARACTER SETUP
-- ═══════════════════════════════════════
local function SetupChar()
    local function onC(ch)
        S.me.char=ch;S.me.alive=false;S.tgt.part=nil;S.tgt.plr=nil
        S.tgt.lastPos=nil;S.tgt.sVel=Vector3.zero
        S.me.hum=ch:WaitForChild("Humanoid",10)
        S.me.root=ch:WaitForChild("HumanoidRootPart",10)
        if not S.me.hum or not S.me.root then
            -- Fallback для арен
            for _,d in ipairs(ch:GetDescendants()) do
                if d:IsA("Humanoid") and not S.me.hum then S.me.hum=d end
            end
            S.me.root = Res.Root(ch)
        end
        if not S.me.hum or not S.me.root then return end
        S.me.alive=true
        S.me.hum.Died:Connect(function() S.me.alive=false;S.tgt.part=nil;S.tgt.plr=nil end)
    end
    if Plr.Character then task.spawn(onC,Plr.Character) end
    table.insert(S.conns,Plr.CharacterAdded:Connect(onC))
end

-- ═══════════════════════════════════════
-- TARGETING
-- ═══════════════════════════════════════
local T={}

function T.GetP(ch)
    if not ch then return nil end
    if Cfg.Part=="Nearest" then
        local b,bd=nil,math.huge
        for _,n in ipairs({"Head","UpperTorso","HumanoidRootPart","Torso"}) do
            local p=ch:FindFirstChild(n);if p then local d=SDist(p.Position);if d<bd then bd=d;b=p end end
        end
        if not b then b=Res.Root(ch) end
        return b
    end
    return ch:FindFirstChild(Cfg.Part) or ch:FindFirstChild("Head") or ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Torso") or ch:FindFirstChild("HumanoidRootPart") or Res.Root(ch)
end

function T.Valid(tp)
    if not tp or tp==Plr then return false end
    local ch=Res.Get(tp);if not ch or not ch.Parent then return false end
    local rp=Res.Root(ch);if not rp then return false end
    local hp=Res.HP(ch);if Cfg.Checks.Alive and hp<=0 then return false end
    if Cfg.Checks.Team and TeamEq(Plr,tp) then return false end
    if Cfg.Checks.FF then for _,c in ipairs(ch:GetDescendants()) do if c:IsA("ForceField") then return false end end end
    if Cfg.Checks.Dist and S.me.root then local d=(rp.Position-S.me.root.Position).Magnitude;if d>Cfg.Limits.MaxD or d<Cfg.Limits.MinD then return false end end
    return true
end

function T.Ang(p) if not p or not Cam then return 180 end;local dir=p.Position-Cam.CFrame.Position;if dir.Magnitude<0.001 then return 0 end;return math.deg(math.acos(math.clamp(Cam.CFrame.LookVector:Dot(dir.Unit),-1,1))) end
function T.Score(tp,p) if not p then return-math.huge end;local sd=SDist(p.Position);local wd=(Cam.CFrame.Position-p.Position).Magnitude;if Cfg.Priority=="FOV" then return 10000-sd elseif Cfg.Priority=="Distance" then return 10000-wd elseif Cfg.Priority=="Health" then return 10000-Res.HP(Res.Get(tp)) elseif Cfg.Priority=="Threat" then return(10000-wd)*0.5+(10000-sd)*0.5 end;return 0 end

function T.Find()
    local is360=Cfg.Aim360 or(Cfg.AimMode=="silent" and Cfg.Silent.Use360)
    if Cfg.Sticky and S.tgt.part and S.tgt.plr then
        if not T.Valid(S.tgt.plr) then S.tgt.part=nil;S.tgt.plr=nil;S.tgt.vis=false
        else local ch=Res.Get(S.tgt.plr);local p=T.GetP(ch);if not p then S.tgt.part=nil;S.tgt.plr=nil;S.tgt.vis=false
        else local _,_,on=W2S(p.Position);local inF=not Cfg.FOV.On or SDist(p.Position)<=Cfg.FOV.R*1.5;local vis=not Cfg.Checks.Wall or CanSee(p,S.me.char);if is360 then on=true;inF=true end
            if on and inF and vis then S.tgt.part=p;S.tgt.lastT=tick();S.tgt.vis=true;return p,S.tgt.plr
            elseif not vis then S.tgt.part=nil;S.tgt.plr=nil;S.tgt.vis=false
            elseif tick()-S.tgt.lastT>Cfg.StickyTime then S.tgt.part=nil;S.tgt.plr=nil;S.tgt.vis=false
            else S.tgt.vis=false;return nil,nil end end end
    end
    local bp,bpl,bs=nil,nil,-math.huge
    for _,tp in ipairs(Players:GetPlayers()) do
        if not T.Valid(tp) then continue end;local ch=Res.Get(tp);local p=T.GetP(ch);if not p then continue end
        local _,_,on=W2S(p.Position);if not is360 and not on then continue end
        if Cfg.FOV.On and not is360 and SDist(p.Position)>Cfg.FOV.R then continue end
        if not is360 and T.Ang(p)>Cfg.Limits.MaxA then continue end
        if Cfg.Checks.Wall and not CanSee(p,S.me.char) then continue end
        local sc=is360 and(S.me.root and(10000-(S.me.root.Position-p.Position).Magnitude)or 0) or T.Score(tp,p)
        if sc>bs then bs=sc;bp=p;bpl=tp end
    end
    if bp then S.tgt.vis=true end;return bp,bpl
end

-- ═══════════════════════════════════════
-- AIM / SILENT / FLICK / FIRE / EXPLOITS (compact)
-- ═══════════════════════════════════════
local A={}
function A.Pred(p) if not Cfg.Pred.On or not p then return p and p.Position or Vector3.zero end;local cur=p.Position;if S.tgt.lastPos then S.tgt.sVel=S.tgt.sVel+((cur-S.tgt.lastPos)*60-S.tgt.sVel)*Cfg.Pred.VelSmooth end;S.tgt.lastPos=cur;return p.Position+S.tgt.sVel*Cfg.Pred.Factor end
function A.GetCF(p) if not p or not Cam then return nil end;local t=A.Pred(p);local c=Cam.CFrame.Position;local d=t-c;return d.Magnitude>0.001 and CFrame.lookAt(c,c+d.Unit) or nil end
function A.Smooth(p) if not p or not Cam then return end;local tcf=A.GetCF(p);if not tcf then return end;if Cfg.Smooth.On then local sm=Cfg.Smooth.Amt;if Cfg.Smooth.Dynamic then local t=math.clamp(T.Ang(p)/math.max(Cfg.Limits.MaxA,1),0,1);sm=Cfg.Smooth.Min+(Cfg.Smooth.Max-Cfg.Smooth.Min)*t end;Cam.CFrame=Cam.CFrame:Lerp(tcf,sm) else Cam.CFrame=tcf end end

local Sil={}
function Sil.Should() return Cfg.On and Cfg.Silent.On and Cfg.AimMode=="silent" and S.tgt.part and((Cfg.Silent.Use360 or Cfg.Aim360) or S.tgt.vis) and(Cfg.Silent.Chance>=100 or math.random(1,100)<=Cfg.Silent.Chance) end
function Sil.Pos() if not S.tgt.part then return nil end;local o,p=pcall(function() return A.Pred(S.tgt.part) end);return o and p or nil end
function Sil.CF() local p=Sil.Pos();return p and CFrame.new(p) or nil end
function Sil.Install()
    if S.aim.hooked or not Exec.canSilent then if not Exec.canSilent then Cfg.AimMode="flick";Cfg.Silent.On=false;Cfg.Flick.On=true end;return end
    local wrap=newcclosure or newclosure or function(f) return f end;local hooked=false
    if hasHM and hasNC then pcall(function()
        local old;old=hookmetamethod(game,"__namecall",wrap(function(self,...)
            local m=getnamecallmethod();local args={...}
            if Sil.Should() then local tp=Sil.Pos();if tp then
                if m=="Raycast" and self==WS and #args>=2 and typeof(args[1])=="Vector3" then S.aim.silentPos=tp;local d=(tp-args[1]);if d.Magnitude>0.001 then d=d.Unit*1000 end;return old(self,args[1],d,select(3,...)) end
                if(m=="FindPartOnRay"or m=="FindPartOnRayWithIgnoreList"or m=="FindPartOnRayWithWhitelist")and self==WS and typeof(args[1])=="Ray" then S.aim.silentPos=tp;local d=(tp-args[1].Origin);if d.Magnitude>0.001 then d=d.Unit*1000 end;return old(self,Ray.new(args[1].Origin,d),select(2,...)) end
                if(m=="ScreenPointToRay"or m=="ViewportPointToRay")and self==Cam then local sp=W2S(tp);if sp then S.aim.silentPos=tp;return old(self,sp.X,sp.Y) end end
            end end;return old(self,...) end));hooked=true
    end);pcall(function()
        local old;old=hookmetamethod(game,"__index",wrap(function(self,k)
            if Sil.Should() and self==Mouse then
                if k=="Hit" then local cf=Sil.CF();if cf then S.aim.silentPos=cf.Position;return cf end
                elseif k=="Target" and S.tgt.part then return S.tgt.part
                elseif k=="UnitRay" then local p=Sil.Pos();if p and Cam then local d=p-Cam.CFrame.Position;if d.Magnitude>0.001 then return Ray.new(Cam.CFrame.Position,d.Unit) end end
                elseif(k=="X"or k=="Y")then local p=Sil.Pos();if p then local sp=W2S(p);if sp then return k=="X"and sp.X or sp.Y end end end
            end;return old(self,k) end))
    end) end
    S.aim.hooked=hooked;if not hooked then Cfg.AimMode="flick";Cfg.Silent.On=false;Cfg.Flick.On=true end
end

local Flk={}
function Flk.Down() if IsMobile then return Cfg.Flick.MobileAuto and S.tgt.vis end;local o,r=pcall(function() return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end);return o and r end
function Flk.Update() if Cfg.AimMode~="flick"or not Cfg.Flick.On then if S.aim.flickOn and S.aim.flickCF and Cfg.Flick.Restore then Cam.CFrame=S.aim.flickCF end;S.aim.flickOn=false;S.aim.flickCF=nil;return end;local down=Flk.Down();if down and not S.aim.flickOn and Cfg.On and S.tgt.vis and S.tgt.part then if Cfg.Flick.Chance>=100 or math.random(1,100)<=Cfg.Flick.Chance then S.aim.flickCF=Cam.CFrame;S.aim.flickOn=true end elseif down and S.aim.flickOn then if S.tgt.part and S.tgt.vis then local tcf=A.GetCF(S.tgt.part);if tcf then Cam.CFrame=Cfg.Flick.Speed>=1 and tcf or Cam.CFrame:Lerp(tcf,Cfg.Flick.Speed) end else if S.aim.flickCF and Cfg.Flick.Restore then Cam.CFrame=S.aim.flickCF end;S.aim.flickOn=false;S.aim.flickCF=nil end elseif not down and S.aim.flickOn then if S.aim.flickCF and Cfg.Flick.Restore then Cam.CFrame=S.aim.flickCF end;S.aim.flickOn=false;S.aim.flickCF=nil end end

local Fire={}
function Fire.Init() S.fire.method="none";if typeof(mouse1press)=="function" then S.fire.method="mouse1press";return end;pcall(function() game:GetService("VirtualInputManager");S.fire.method="vim" end) end
function Fire.Click() if S.fire.method=="mouse1press" then return pcall(function() mouse1press();task.delay(0.04,function() pcall(mouse1release) end) end) elseif S.fire.method=="vim" then return pcall(function() local v=game:GetService("VirtualInputManager");v:SendMouseButtonEvent(Mouse.X,Mouse.Y,0,true,game,0);task.delay(0.04,function() pcall(function() v:SendMouseButtonEvent(Mouse.X,Mouse.Y,0,false,game,0) end) end) end) end;return false end
function Fire.Update() if not Cfg.TB.On or not Cfg.On or S.fire.method=="none" then return end;if S.tgt.vis and S.tgt.part and(Cfg.TB.Auto or IsMobile)and tick()-S.fire.last>=Cfg.TB.Delay then if Fire.Click() then S.fire.last=tick() end end end

local Exp={}
function Exp.TP() if not Cfg.TP.On then return end;pcall(function() if Plr.CameraMaxZoomDistance<Cfg.TP.Dist then Plr.CameraMaxZoomDistance=Cfg.TP.Dist end;if Cfg.TP.Unlock and Plr.CameraMode~=Enum.CameraMode.Classic then Plr.CameraMode=Enum.CameraMode.Classic end end) end
function Exp.RTP() pcall(function() Plr.CameraMaxZoomDistance=128;Plr.CameraMinZoomDistance=0.5 end) end
function Exp.Spin(dt) if not Cfg.Spin.On or not S.me.root or not S.me.alive then return end;S.spinAng=(S.spinAng+Cfg.Spin.Spd*dt*60)%360;pcall(function() S.me.root.CFrame=CFrame.new(S.me.root.Position)*CFrame.Angles(0,math.rad(S.spinAng),0) end) end
function Exp.RSpin() S.spinAng=0 end
function Exp.Speed(dt) if not Cfg.Speed.On or not S.me.root or not S.me.alive or not S.me.hum then return end;pcall(function() local md=S.me.hum.MoveDirection;if md.Magnitude<0.1 then return end;S.me.root.CFrame=S.me.root.CFrame+md.Unit*S.me.hum.WalkSpeed*(Cfg.Speed.Mult-1)*dt end) end

-- ═══════════════════════════════════════
-- ESP
-- ═══════════════════════════════════════
local B15={{"Head","UpperTorso"},{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},{"UpperTorso","LowerTorso"},{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"}}
local B6={{"Head","Torso"},{"Torso","Right Arm"},{"Torso","Left Arm"},{"Torso","Right Leg"},{"Torso","Left Leg"}}

local E={}

function E.New(tp)
    if S.espC[tp] then E.Del(tp) end;if not drawOK then return end
    local o={valid=true,curBB=nil,lastUpdate=0,smoothHP=nil,isVis=false,lastVisTick=0,scanY=0,cL={},cO={},glow={},cyber={},grad={},bones={}}
    for i=1,8 do o.cL[i]=ND("Line");o.cO[i]=ND("Line") end
    for i=1,12 do o.glow[i]=ND("Line") end
    for i=1,13 do o.cyber[i]=ND("Line") end
    for i=1,8 do o.grad[i]=ND("Line") end
    o.bI=ND("Square");DS(o.bI,"Filled",false);o.bO=ND("Square");DS(o.bO,"Filled",false)
    o.nT=ND("Text");DS(o.nT,"Outline",true);DS(o.nT,"Size",14)
    o.nSh=ND("Text");DS(o.nSh,"Outline",false);DS(o.nSh,"Size",14)
    o.dT=ND("Text");DS(o.dT,"Outline",true);DS(o.dT,"Size",12)
    o.wT=ND("Text");DS(o.wT,"Outline",true);DS(o.wT,"Size",11)
    o.flT=ND("Text");DS(o.flT,"Outline",true);DS(o.flT,"Size",11)
    o.hBo=ND("Square");DS(o.hBo,"Filled",false);DS(o.hBo,"Color",Color3.new(0,0,0));DS(o.hBo,"Thickness",1)
    o.hBg=ND("Square");DS(o.hBg,"Filled",true);o.hF=ND("Square");DS(o.hF,"Filled",true)
    o.hT=ND("Text");DS(o.hT,"Outline",true);DS(o.hT,"Size",11);DS(o.hT,"Center",true)
    o.tr=ND("Line");o.trO=ND("Line");o.arr=ND("Triangle");DS(o.arr,"Filled",true)
    o.hdot=ND("Circle");DS(o.hdot,"Filled",true);DS(o.hdot,"NumSides",16)
    o.hdotO=ND("Circle");DS(o.hdotO,"Filled",false);DS(o.hdotO,"NumSides",16)
    for i=1,#B15 do o.bones[i]=ND("Line") end
    S.espC[tp]=o
end

function E.HideAll(o)
    if not o then return end
    for i=1,8 do DV(o.cL[i],false);DV(o.cO[i],false) end
    for i=1,12 do DV(o.glow[i],false) end;for i=1,13 do DV(o.cyber[i],false) end;for i=1,8 do DV(o.grad[i],false) end
    DV(o.bI,false);DV(o.bO,false);DV(o.nT,false);DV(o.nSh,false);DV(o.dT,false);DV(o.wT,false);DV(o.flT,false)
    DV(o.hBo,false);DV(o.hBg,false);DV(o.hF,false);DV(o.hT,false)
    DV(o.tr,false);DV(o.trO,false);DV(o.arr,false);DV(o.hdot,false);DV(o.hdotO,false)
    for _,b in ipairs(o.bones) do DV(b,false) end
end

function E.Del(tp) local o=S.espC[tp];if not o then return end;o.valid=false;for i=1,8 do Kill(o.cL[i]);Kill(o.cO[i]) end;for i=1,12 do Kill(o.glow[i]) end;for i=1,13 do Kill(o.cyber[i]) end;for i=1,8 do Kill(o.grad[i]) end;Kill(o.bI);Kill(o.bO);Kill(o.nT);Kill(o.nSh);Kill(o.dT);Kill(o.wT);Kill(o.flT);Kill(o.hBo);Kill(o.hBg);Kill(o.hF);Kill(o.hT);Kill(o.tr);Kill(o.trO);Kill(o.arr);Kill(o.hdot);Kill(o.hdotO);for _,b in ipairs(o.bones) do Kill(b) end;S.espC[tp]=nil end
function E.DelAll() for p in pairs(S.espC) do E.Del(p) end end

function E.BB(ch)
    if not ch then return nil end
    local rp=Res.Root(ch);if not rp then return nil end
    local head=ch:FindFirstChild("Head")
    local topY=head and(head.Position.Y+head.Size.Y/2+0.5)or(rp.Position.Y+3)
    local botY=rp.Position.Y-3
    local topSP,_,topOn=W2S(Vector3.new(rp.Position.X,topY,rp.Position.Z))
    local botSP,_,botOn=W2S(Vector3.new(rp.Position.X,botY,rp.Position.Z))
    if not topOn or not botOn or not topSP or not botSP then return nil end
    local h=math.abs(botSP.Y-topSP.Y);if h<4 then return nil end
    return{x=topSP.X-h*0.3,y=topSP.Y,w=h*0.6,h=h,top=topSP,bot=botSP,rp=rp.Position}
end

function E.FmtN(tp,dist) local dn=tp.DisplayName or tp.Name;if Cfg.ESP.Name.Fmt=="Name+Distance" then return string.format("%s [%.0fm]",dn,dist) end;return dn end
function E.IntBB(o,nb,dt) if not Cfg.ESP.Render.Interp or not o.curBB or not nb then o.curBB=nb;return nb end;local sp=math.clamp(Cfg.ESP.Render.InterpSpeed*dt,0,1);local cb=o.curBB;o.curBB={x=cb.x+(nb.x-cb.x)*sp,y=cb.y+(nb.y-cb.y)*sp,w=cb.w+(nb.w-cb.w)*sp,h=cb.h+(nb.h-cb.h)*sp,top=cb.top:Lerp(nb.top,sp),bot=cb.bot:Lerp(nb.bot,sp),rp=cb.rp:Lerp(nb.rp,sp)};return o.curBB end
function E.ShouldR(o) local R=Cfg.ESP.Render;if R.FPS<=0 then return true end;if tick()-o.lastUpdate<1/R.FPS then return false end;o.lastUpdate=tick();return true end

-- Hide all box drawings
local function HideBox(o) for i=1,8 do DV(o.cL[i],false);DV(o.cO[i],false) end;for i=1,12 do DV(o.glow[i],false) end;for i=1,13 do DV(o.cyber[i],false) end;for i=1,8 do DV(o.grad[i],false) end;DV(o.bI,false);DV(o.bO,false) end

-- STYLE: Corner
local function DrawCorner(o,bx,by,bw,bh,clr,oClr)
    DV(o.bI,false);DV(o.bO,false);for i=1,12 do DV(o.glow[i],false) end;for i=1,13 do DV(o.cyber[i],false) end;for i=1,8 do DV(o.grad[i],false) end
    local cl=math.max(bw,bh)*Cfg.ESP.Box.CL
    local pts={{Vector2.new(bx,by),Vector2.new(bx+cl,by)},{Vector2.new(bx,by),Vector2.new(bx,by+cl)},{Vector2.new(bx+bw,by),Vector2.new(bx+bw-cl,by)},{Vector2.new(bx+bw,by),Vector2.new(bx+bw,by+cl)},{Vector2.new(bx,by+bh),Vector2.new(bx+cl,by+bh)},{Vector2.new(bx,by+bh),Vector2.new(bx,by+bh-cl)},{Vector2.new(bx+bw,by+bh),Vector2.new(bx+bw-cl,by+bh)},{Vector2.new(bx+bw,by+bh),Vector2.new(bx+bw,by+bh-cl)}}
    for i=1,8 do if IV(o.cO[i])and Cfg.ESP.Box.Outline then DS(o.cO[i],"From",pts[i][1]);DS(o.cO[i],"To",pts[i][2]);DS(o.cO[i],"Color",oClr);DS(o.cO[i],"Thickness",Cfg.ESP.Box.W+Cfg.ESP.Box.OW);DV(o.cO[i],true) else DV(o.cO[i],false) end;if IV(o.cL[i]) then DS(o.cL[i],"From",pts[i][1]);DS(o.cL[i],"To",pts[i][2]);DS(o.cL[i],"Color",clr);DS(o.cL[i],"Thickness",Cfg.ESP.Box.W);DV(o.cL[i],true) end end
end

-- STYLE: Full
local function DrawFull(o,bx,by,bw,bh,clr,oClr)
    for i=1,8 do DV(o.cL[i],false);DV(o.cO[i],false) end;for i=1,12 do DV(o.glow[i],false) end;for i=1,13 do DV(o.cyber[i],false) end;for i=1,8 do DV(o.grad[i],false) end
    if IV(o.bO)and Cfg.ESP.Box.Outline then DS(o.bO,"Size",Vector2.new(bw+4,bh+4));DS(o.bO,"Position",Vector2.new(bx-2,by-2));DS(o.bO,"Color",oClr);DS(o.bO,"Thickness",Cfg.ESP.Box.W);DV(o.bO,true) else DV(o.bO,false) end
    if IV(o.bI) then DS(o.bI,"Size",Vector2.new(bw,bh));DS(o.bI,"Position",Vector2.new(bx,by));DS(o.bI,"Color",clr);DS(o.bI,"Thickness",Cfg.ESP.Box.W);DV(o.bI,true) end
end

-- STYLE: Glow
local function DrawGlow(o,bx,by,bw,bh,clr)
    for i=1,8 do DV(o.cL[i],false);DV(o.cO[i],false) end;DV(o.bI,false);DV(o.bO,false);for i=1,13 do DV(o.cyber[i],false) end;for i=1,8 do DV(o.grad[i],false) end
    local G=Cfg.ESP.Glow;local sides={{Vector2.new(bx,by),Vector2.new(bx+bw,by)},{Vector2.new(bx+bw,by),Vector2.new(bx+bw,by+bh)},{Vector2.new(bx,by+bh),Vector2.new(bx+bw,by+bh)},{Vector2.new(bx,by),Vector2.new(bx,by+bh)}};local idx=1
    for layer=1,math.min(G.Layers,3) do local tr=G.BaseTrans+G.FadeStep*(layer-1);local thick=Cfg.ESP.Box.W+G.Spread*layer;for s=1,4 do if idx<=12 and IV(o.glow[idx]) then DS(o.glow[idx],"From",sides[s][1]);DS(o.glow[idx],"To",sides[s][2]);DS(o.glow[idx],"Color",clr);DS(o.glow[idx],"Thickness",thick);DS(o.glow[idx],"Transparency",1-tr);DV(o.glow[idx],true) end;idx=idx+1 end end
    for i=idx,12 do DV(o.glow[i],false) end
end

-- STYLE: Cyber
local function DrawCyber(o,bx,by,bw,bh,clr,accent)
    for i=1,8 do DV(o.cL[i],false);DV(o.cO[i],false) end;DV(o.bI,false);DV(o.bO,false);for i=1,12 do DV(o.glow[i],false) end;for i=1,8 do DV(o.grad[i],false) end
    local CB=Cfg.ESP.Cyber;local cl=math.max(bw,bh)*0.3
    local pts={{Vector2.new(bx,by),Vector2.new(bx+cl,by)},{Vector2.new(bx,by),Vector2.new(bx,by+cl)},{Vector2.new(bx+bw,by),Vector2.new(bx+bw-cl,by)},{Vector2.new(bx+bw,by),Vector2.new(bx+bw,by+cl)},{Vector2.new(bx,by+bh),Vector2.new(bx+cl,by+bh)},{Vector2.new(bx,by+bh),Vector2.new(bx,by+bh-cl)},{Vector2.new(bx+bw,by+bh),Vector2.new(bx+bw-cl,by+bh)},{Vector2.new(bx+bw,by+bh),Vector2.new(bx+bw,by+bh-cl)}}
    for i=1,8 do if IV(o.cyber[i]) then DS(o.cyber[i],"From",pts[i][1]);DS(o.cyber[i],"To",pts[i][2]);DS(o.cyber[i],"Color",clr);DS(o.cyber[i],"Thickness",2);DV(o.cyber[i],true) end end
    if CB.TickMarks then local tl=CB.TickLen;local mx=bx+bw/2;local my=by+bh/2;local ticks={{Vector2.new(mx-tl/2,by),Vector2.new(mx+tl/2,by)},{Vector2.new(mx-tl/2,by+bh),Vector2.new(mx+tl/2,by+bh)},{Vector2.new(bx,my-tl/2),Vector2.new(bx,my+tl/2)},{Vector2.new(bx+bw,my-tl/2),Vector2.new(bx+bw,my+tl/2)}};for i=1,4 do local idx=8+i;if IV(o.cyber[idx]) then DS(o.cyber[idx],"From",ticks[i][1]);DS(o.cyber[idx],"To",ticks[i][2]);DS(o.cyber[idx],"Color",accent);DS(o.cyber[idx],"Thickness",1);DV(o.cyber[idx],true) end end else for i=9,12 do DV(o.cyber[i],false) end end
    if CB.ScanLine then o.scanY=(o.scanY or 0)+CB.ScanSpeed;if o.scanY>bh then o.scanY=0 end;if IV(o.cyber[13]) then DS(o.cyber[13],"From",Vector2.new(bx,by+o.scanY));DS(o.cyber[13],"To",Vector2.new(bx+bw,by+o.scanY));DS(o.cyber[13],"Color",accent);DS(o.cyber[13],"Thickness",1);DS(o.cyber[13],"Transparency",0.5);DV(o.cyber[13],true) end else DV(o.cyber[13],false) end
end

-- STYLE: Gradient
local function DrawGradient(o,bx,by,bw,bh,topC,botC)
    for i=1,8 do DV(o.cO[i],false) end;DV(o.bI,false);DV(o.bO,false);for i=1,12 do DV(o.glow[i],false) end;for i=1,13 do DV(o.cyber[i],false) end
    local steps=math.min(Cfg.ESP.Grad.Steps,4);local segH=bh/steps
    -- Left + Right sides as gradient segments
    for i=1,steps do local t=(i-1)/(steps-1);local clr=Lerp3(topC,botC,t);local y1=by+segH*(i-1);local y2=by+segH*i
        local li=(i-1)*2+1;local ri=li+1
        if li<=8 and IV(o.grad[li]) then DS(o.grad[li],"From",Vector2.new(bx,y1));DS(o.grad[li],"To",Vector2.new(bx,y2));DS(o.grad[li],"Color",clr);DS(o.grad[li],"Thickness",Cfg.ESP.Box.W);DV(o.grad[li],true) end
        if ri<=8 and IV(o.grad[ri]) then DS(o.grad[ri],"From",Vector2.new(bx+bw,y1));DS(o.grad[ri],"To",Vector2.new(bx+bw,y2));DS(o.grad[ri],"Color",clr);DS(o.grad[ri],"Thickness",Cfg.ESP.Box.W);DV(o.grad[ri],true) end
    end
    -- Top/Bottom lines
    if IV(o.cL[1]) then DS(o.cL[1],"From",Vector2.new(bx,by));DS(o.cL[1],"To",Vector2.new(bx+bw,by));DS(o.cL[1],"Color",topC);DS(o.cL[1],"Thickness",Cfg.ESP.Box.W);DV(o.cL[1],true) end
    if IV(o.cL[2]) then DS(o.cL[2],"From",Vector2.new(bx,by+bh));DS(o.cL[2],"To",Vector2.new(bx+bw,by+bh));DS(o.cL[2],"Color",botC);DS(o.cL[2],"Thickness",Cfg.ESP.Box.W);DV(o.cL[2],true) end
    for i=3,8 do DV(o.cL[i],false) end
end

-- ═══ MAIN RENDER — FIX: text positioning ═══
function E.Render(tp,dt)
    local o=S.espC[tp];if not o or not o.valid then return end;dt=dt or 0.016
    local ch=Res.Get(tp);if not ch or not ch.Parent then E.HideAll(o);return end
    local rootP=Res.Root(ch);if not rootP then E.HideAll(o);return end
    local hp,mhp=Res.HP(ch);if hp<=0 then E.HideAll(o);return end
    if not Cfg.ESP.ShowTeam and TeamEq(Plr,tp) then E.HideAll(o);return end
    local dist=S.me.root and(rootP.Position-S.me.root.Position).Magnitude or 0
    if dist>Cfg.ESP.MaxDist then E.HideAll(o);return end
    local now=tick();if now-o.lastVisTick>0.15 then o.isVis=CanSee(rootP,S.me.char);o.lastVisTick=now end
    E.ShouldR(o)
    local rawBB=E.BB(ch)
    if not rawBB then
        E.HideAll(o)
        if Cfg.ESP.OFS.On and S.me.root and IV(o.arr) then local raw=W2SR(rootP.Position);if raw then local sc=SCC();local d2=raw-sc;if d2.Magnitude>5 then d2=d2.Unit;local ap=sc+d2*Cfg.ESP.OFS.Rad;local perp=Vector2.new(-d2.Y,d2.X);local sz=Cfg.ESP.OFS.Sz;DS(o.arr,"PointA",ap+d2*sz);DS(o.arr,"PointB",ap-d2*sz*0.5+perp*sz*0.4);DS(o.arr,"PointC",ap-d2*sz*0.5-perp*sz*0.4);DS(o.arr,"Color",Cfg.ESP.Colors.OFSClr);DV(o.arr,true) else DV(o.arr,false) end else DV(o.arr,false) end end;return
    end;DV(o.arr,false)
    local bb=E.IntBB(o,rawBB,dt);local bx,by,bw,bh=bb.x,bb.y,bb.w,bb.h
    local same=TeamEq(Plr,tp);local CC2=Cfg.ESP.Colors
    local boxClr=same and CC2.TBox or CC2.EBox
    local boxBot=same and CC2.TBoxBot or CC2.EBoxBot
    local nameClr=same and CC2.TName or CC2.EName
    local glowClr=same and CC2.TGlow or CC2.EGlow
    local cyberClr=same and CC2.TCyber or CC2.ECyber
    local cyberAcc=same and CC2.TCyberAccent or CC2.ECyberAccent
    local tracerClr=same and CC2.TTracer or CC2.ETracer
    local skelClr=same and CC2.TSkel or CC2.ESkel
    if Cfg.ESP.Box.VisCheck then boxClr=o.isVis and Cfg.ESP.Box.VisClr or Cfg.ESP.Box.InvisClr end

    -- BOX STYLE
    if Cfg.ESP.Box.On then
        local st=Cfg.ESP.Style
        if st=="Corner" then DrawCorner(o,bx,by,bw,bh,boxClr,CC2.Outline)
        elseif st=="Full" then DrawFull(o,bx,by,bw,bh,boxClr,CC2.Outline)
        elseif st=="Glow" then DrawGlow(o,bx,by,bw,bh,glowClr)
        elseif st=="Cyber" then DrawCyber(o,bx,by,bw,bh,cyberClr,cyberAcc)
        elseif st=="Gradient" then DrawGradient(o,bx,by,bw,bh,boxClr,boxBot)
        else DrawCorner(o,bx,by,bw,bh,boxClr,CC2.Outline) end
    else HideBox(o) end

    -- ═══ FIX: Text positioning relative to bounding box ═══
    local topTY=by
    local botTY=by+bh+2
    local rightTY=by

    -- NAME — always relative to box
    if Cfg.ESP.Name.On and IV(o.nT) then
        local txt=E.FmtN(tp,dist)
        DS(o.nT,"Text",txt);DS(o.nT,"Color",nameClr);DS(o.nT,"Size",Cfg.ESP.Name.Sz);DS(o.nT,"Outline",Cfg.ESP.Name.OL)
        local nPos
        if Cfg.ESP.Name.Pos=="Top" then
            topTY=topTY-Cfg.ESP.Name.Sz-2
            DS(o.nT,"Center",true)
            nPos=Vector2.new(bx+bw/2,topTY)
        elseif Cfg.ESP.Name.Pos=="Bottom" then
            DS(o.nT,"Center",true)
            nPos=Vector2.new(bx+bw/2,botTY)
            botTY=botTY+Cfg.ESP.Name.Sz+2
        else -- Right
            DS(o.nT,"Center",false)
            nPos=Vector2.new(bx+bw+4,rightTY)
            rightTY=rightTY+Cfg.ESP.Name.Sz+2
        end
        DS(o.nT,"Position",nPos);DV(o.nT,true)
        -- Shadow
        if Cfg.ESP.Name.Shadow and IV(o.nSh) then
            DS(o.nSh,"Text",txt);DS(o.nSh,"Color",CC2.NameShadow);DS(o.nSh,"Size",Cfg.ESP.Name.Sz);DS(o.nSh,"Outline",false)
            DS(o.nSh,"Center",Cfg.ESP.Name.Pos=="Top" or Cfg.ESP.Name.Pos=="Bottom")
            DS(o.nSh,"Position",nPos+Vector2.new(1,1));DV(o.nSh,true)
        else DV(o.nSh,false) end
    else DV(o.nT,false);DV(o.nSh,false) end

    -- DISTANCE
    if Cfg.ESP.Dist.On and IV(o.dT) then
        DS(o.dT,"Text",string.format("%.0fm",dist));DS(o.dT,"Color",CC2.DistClr);DS(o.dT,"Size",Cfg.ESP.Dist.Sz);DS(o.dT,"Outline",true)
        DS(o.dT,"Center",true);DS(o.dT,"Position",Vector2.new(bx+bw/2,botTY))
        botTY=botTY+Cfg.ESP.Dist.Sz+2;DV(o.dT,true)
    else DV(o.dT,false) end

    -- WEAPON
    if Cfg.ESP.Weapon.On and IV(o.wT) then
        local tool=GetTool(ch);DS(o.wT,"Text",tool and tool.Name or"None");DS(o.wT,"Color",CC2.WeaponClr);DS(o.wT,"Size",Cfg.ESP.Weapon.Sz);DS(o.wT,"Outline",true)
        DS(o.wT,"Center",true);DS(o.wT,"Position",Vector2.new(bx+bw/2,botTY))
        botTY=botTY+Cfg.ESP.Weapon.Sz+2;DV(o.wT,true)
    else DV(o.wT,false) end

    -- FLAGS
    if Cfg.ESP.Flags.On and IV(o.flT) then
        local ps={};if Cfg.ESP.Flags.ShowTool then local t=GetTool(ch);if t then table.insert(ps,t.Name) end end
        if Cfg.ESP.Flags.ShowDist then table.insert(ps,string.format("%.0fm",dist)) end
        if Cfg.ESP.Flags.ShowVis then table.insert(ps,o.isVis and"VIS"or"INVIS") end
        local str=table.concat(ps," | ")
        if #str>0 then
            DS(o.flT,"Text",str);DS(o.flT,"Color",CC2.FlagsClr);DS(o.flT,"Size",Cfg.ESP.Flags.Sz)
            DS(o.flT,"Center",false);DS(o.flT,"Position",Vector2.new(bx+bw+4,rightTY))
            rightTY=rightTY+Cfg.ESP.Flags.Sz+2;DV(o.flT,true)
        else DV(o.flT,false) end
    else DV(o.flT,false) end

    -- HP BAR
    if Cfg.ESP.HP.On then
        local pct=math.clamp(hp/math.max(mhp,1),0,1)
        if Cfg.ESP.HP.Smooth then if not o.smoothHP then o.smoothHP=pct end;o.smoothHP=o.smoothHP+(pct-o.smoothHP)*math.clamp(Cfg.ESP.HP.SmoothSpd*dt,0,1);pct=o.smoothHP end
        local hc=HPCol(pct);local hP,bW,off=Cfg.ESP.HP.Pos,Cfg.ESP.HP.W,Cfg.ESP.HP.Off
        local bgX,bgY,bgW,bgH,fX,fY,fW,fH
        if hP=="Left" then bgX=bx-off-bW-1;bgY=by-1;bgW=bW+2;bgH=bh+2;fH=math.max(bh*pct,1);fX=bgX+1;fY=by+bh-fH;fW=bW
        elseif hP=="Right" then bgX=bx+bw+off-1;bgY=by-1;bgW=bW+2;bgH=bh+2;fH=math.max(bh*pct,1);fX=bgX+1;fY=by+bh-fH;fW=bW
        else bgX=bx-1;bgY=by+bh+off-1;bgW=bw+2;bgH=bW+2;fX=bgX+1;fY=bgY+1;fW=math.max(bw*pct,1);fH=bW end
        if IV(o.hBg) then DS(o.hBg,"Position",Vector2.new(bgX,bgY));DS(o.hBg,"Size",Vector2.new(math.max(bgW,1),math.max(bgH,1)));DS(o.hBg,"Color",CC2.HPBg);DV(o.hBg,true) end
        if IV(o.hBo)then if Cfg.ESP.HP.OL then DS(o.hBo,"Position",Vector2.new(bgX-1,bgY-1));DS(o.hBo,"Size",Vector2.new(math.max(bgW+2,1),math.max(bgH+2,1)));DV(o.hBo,true) else DV(o.hBo,false) end end
        if IV(o.hF) then DS(o.hF,"Position",Vector2.new(fX,fY));DS(o.hF,"Size",Vector2.new(math.max(fW,1),math.max(fH,1)));DS(o.hF,"Color",hc);DV(o.hF,true) end
        if IV(o.hT) then if Cfg.ESP.HP.Txt and hp<mhp then DS(o.hT,"Text",string.format("%.0f",hp));DS(o.hT,"Color",hc);DS(o.hT,"Center",true);if hP=="Left"or hP=="Right" then DS(o.hT,"Position",Vector2.new(bgX+bgW/2,fY-14)) else DS(o.hT,"Position",Vector2.new(fX+fW+3,fY-2));DS(o.hT,"Center",false) end;DV(o.hT,true) else DV(o.hT,false) end end
    else DV(o.hBg,false);DV(o.hBo,false);DV(o.hF,false);DV(o.hT,false) end

    -- TRACER
    if Cfg.ESP.Tracer.On and IV(o.tr) then
        local from;local orig=Cfg.ESP.Tracer.Origin;if orig=="Center" then from=SCC() elseif orig=="Top" then from=Vector2.new(Cam.ViewportSize.X/2,0) else from=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y) end
        if Cfg.ESP.Tracer.Outline and IV(o.trO) then DS(o.trO,"From",from);DS(o.trO,"To",bb.bot);DS(o.trO,"Color",CC2.Outline);DS(o.trO,"Thickness",Cfg.ESP.Tracer.W+Cfg.ESP.Tracer.OW*2);DV(o.trO,true) else DV(o.trO,false) end
        DS(o.tr,"From",from);DS(o.tr,"To",bb.bot);DS(o.tr,"Color",tracerClr);DS(o.tr,"Thickness",Cfg.ESP.Tracer.W);DV(o.tr,true)
    else DV(o.tr,false);DV(o.trO,false) end

    -- HEAD DOT
    if Cfg.ESP.HeadDot.On then local head=ch:FindFirstChild("Head");if head and IV(o.hdot) then local sp,_,on=W2S(head.Position);if sp and on then DS(o.hdot,"Position",sp);DS(o.hdot,"Radius",Cfg.ESP.HeadDot.Rad);DS(o.hdot,"Color",CC2.HeadDotClr);DS(o.hdot,"Filled",Cfg.ESP.HeadDot.Filled);DV(o.hdot,true);if Cfg.ESP.HeadDot.Outline and IV(o.hdotO) then DS(o.hdotO,"Position",sp);DS(o.hdotO,"Radius",Cfg.ESP.HeadDot.Rad+Cfg.ESP.HeadDot.OW);DS(o.hdotO,"Color",CC2.Outline);DS(o.hdotO,"Thickness",Cfg.ESP.HeadDot.OW);DV(o.hdotO,true) else DV(o.hdotO,false) end else DV(o.hdot,false);DV(o.hdotO,false) end else DV(o.hdot,false);DV(o.hdotO,false) end else DV(o.hdot,false);DV(o.hdotO,false) end

    -- SKELETON
    if Cfg.ESP.Skel.On then local sk=B15;if ch:FindFirstChild("Torso") and not ch:FindFirstChild("UpperTorso") then sk=B6 end;local sClr=Cfg.ESP.Skel.VisCheck and(o.isVis and Cfg.ESP.Box.VisClr or Cfg.ESP.Box.InvisClr) or skelClr;for i,c in ipairs(sk) do local bone=o.bones[i];if not bone or not IV(bone) then continue end;local p1,p2=ch:FindFirstChild(c[1]),ch:FindFirstChild(c[2]);if p1 and p2 then local s1,_,o1=W2S(p1.Position);local s2,_,o2=W2S(p2.Position);if s1 and s2 and o1 and o2 then DS(bone,"From",s1);DS(bone,"To",s2);DS(bone,"Color",sClr);DS(bone,"Thickness",Cfg.ESP.Skel.W);DV(bone,true) else DV(bone,false) end else DV(bone,false) end end;for i=#sk+1,#o.bones do DV(o.bones[i],false) end else for _,b in ipairs(o.bones) do DV(b,false) end end
end

function E.UpdateAll(dt)
    for _,tp in ipairs(Players:GetPlayers()) do if tp~=Plr then if not S.espC[tp] then E.New(tp) end;pcall(E.Render,tp,dt) end end
    local rem={};for p in pairs(S.espC) do if not p or not p.Parent then table.insert(rem,p) end end;for _,p in ipairs(rem) do E.Del(p) end
end

-- ═══════════════════════════════════════
-- WALLHACK — improved for Arena games
-- ═══════════════════════════════════════
local WH={}
function WH.Make(tp)
    if S.whC[tp] then return end;local ch=Res.Get(tp);if not ch or not ch.Parent then return end
    if not Cfg.WH.ShowTeam and TeamEq(Plr,tp) then return end
    local hl=Instance.new("Highlight");hl.Name="XWH";hl.Adornee=ch;hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;hl.Enabled=true
    local same=TeamEq(Plr,tp);if Cfg.WH.UseTC and same then hl.FillColor=Cfg.WH.TFill;hl.OutlineColor=Cfg.WH.TOut else hl.FillColor=Cfg.WH.Fill;hl.OutlineColor=Cfg.WH.Out end;hl.FillTransparency=Cfg.WH.FT;hl.OutlineTransparency=Cfg.WH.OT
    pcall(function() hl.Parent=ch end);S.whC[tp]=hl
end
function WH.Kill(tp) local h=S.whC[tp];if h then pcall(function() h:Destroy() end) end;S.whC[tp]=nil end
function WH.KillAll() for p in pairs(S.whC) do WH.Kill(p) end end
function WH.UpdateAll()
    for _,tp in ipairs(Players:GetPlayers()) do if tp~=Plr then local ch=Res.Get(tp);local same=TeamEq(Plr,tp);local show=Cfg.WH.On and ch and ch.Parent;if show then local h=Res.HP(ch);if h<=0 then show=false end end;if show and same and not Cfg.WH.ShowTeam then show=false end
        if show then if not S.whC[tp] then WH.Make(tp) else local h=S.whC[tp];if h and h.Parent then if h.Adornee~=ch then h.Adornee=ch end else S.whC[tp]=nil;WH.Make(tp) end end else WH.Kill(tp) end
    end end
    local rem={};for p in pairs(S.whC) do if not p or not p.Parent then table.insert(rem,p) end end;for _,p in ipairs(rem) do WH.Kill(p) end
end

-- ═══════════════════════════════════════
-- HUD (compact)
-- ═══════════════════════════════════════
local HUD={}
function HUD.Create() HUD.Destroy();if not drawOK then return end;local d=S.draw;d.fov=ND("Circle");DS(d.fov,"Filled",false);DS(d.fov,"NumSides",64);d.line=ND("Line");d.dot=ND("Circle");DS(d.dot,"Filled",true);DS(d.dot,"NumSides",16);d.st=ND("Text");DS(d.st,"Visible",true);DS(d.st,"Center",false);DS(d.st,"Outline",true);DS(d.st,"Size",SC(14,12));DS(d.st,"Position",Vector2.new(10,SC(10,40)));d.inf=ND("Text");DS(d.inf,"Visible",not IsMobile);DS(d.inf,"Center",false);DS(d.inf,"Outline",true);DS(d.inf,"Size",12);DS(d.inf,"Position",Vector2.new(10,SC(28,56)));DS(d.inf,"Color",Color3.fromRGB(180,180,180)) end
function HUD.Update() if not drawOK then return end;local c=SCC();local d=S.draw;if IV(d.fov) then DS(d.fov,"Position",c);DS(d.fov,"Radius",Cfg.FOV.R);DS(d.fov,"Color",Cfg.FOV.Color);DS(d.fov,"Transparency",Cfg.FOV.Trans);DS(d.fov,"Thickness",Cfg.FOV.Thick);DV(d.fov,Cfg.On and Cfg.FOV.On and Cfg.FOV.Show) end
    if IV(d.st) then local ps={"XENO",Cfg.On and"["..(({normal="AIM",snap="SNAP",flick="FLICK",silent="SILENT"})[Cfg.AimMode] or"?").."]"or"[OFF]"};if Cfg.ESP.On then table.insert(ps,"["..Cfg.ESP.Style.."]") end;if S.tgt.plr and Cfg.On then table.insert(ps,string.format("| %s %.0fHP",S.tgt.name,S.tgt.hp)) end;DS(d.st,"Text",table.concat(ps," "));DS(d.st,"Color",Cfg.On and Color3.fromRGB(100,255,100) or Color3.fromRGB(255,100,100)) end
    if not IsMobile and IV(d.inf) then DS(d.inf,"Text","F1:Aim F2:ESP F3:WH F4:Style | "..Exec.name) end
    if Cfg.On and S.tgt.part and S.tgt.vis then local sp,_,on=W2S(S.tgt.part.Position);if sp and on then if IV(d.line) then DS(d.line,"From",c);DS(d.line,"To",sp);DS(d.line,"Color",Cfg.Vis.LineClr);DS(d.line,"Thickness",Cfg.Vis.LineW);DV(d.line,Cfg.Vis.Line) end;if IV(d.dot) then DS(d.dot,"Position",sp);DS(d.dot,"Color",Cfg.Vis.DotClr);DS(d.dot,"Radius",Cfg.Vis.DotSz);DV(d.dot,Cfg.Vis.Dot) end else DV(d.line,false);DV(d.dot,false) end else DV(d.line,false);DV(d.dot,false) end
end
function HUD.Destroy() for _,dr in pairs(S.draw) do Kill(dr) end;S.draw={} end

-- ═══════════════════════════════════════
-- GUI (simplified for reliability)
-- ═══════════════════════════════════════
local GC={bg=Color3.fromRGB(18,18,28),hdr=Color3.fromRGB(12,12,22),pnl=Color3.fromRGB(25,25,40),acc=Color3.fromRGB(90,130,255),accG=Color3.fromRGB(120,160,255),grn=Color3.fromRGB(80,220,120),red=Color3.fromRGB(255,70,70),org=Color3.fromRGB(255,180,50),txt=Color3.fromRGB(230,230,240),txtD=Color3.fromRGB(140,140,160),brd=Color3.fromRGB(45,45,70),brdA=Color3.fromRGB(90,130,255),tOn=Color3.fromRGB(90,200,130),tOff=Color3.fromRGB(60,60,80),sF=Color3.fromRGB(90,130,255),sB=Color3.fromRGB(40,40,60),ddBg=Color3.fromRGB(20,20,35),tabBg=Color3.fromRGB(18,18,30),tabA=Color3.fromRGB(25,25,45)}
local DDL,DDB=nil,nil
local function CloseDD() if DDL then pcall(function() DDL:Destroy() end);DDL=nil end;if DDB then pcall(function() local s=DDB:FindFirstChildOfClass("UIStroke");if s then s.Color=GC.brd end end);DDB=nil end end
local function CloseSub() if S.subMenu then pcall(function() S.subMenu:Destroy() end);S.subMenu=nil end end

local G={}
function G.Crn(p,r) Instance.new("UICorner",p).CornerRadius=UDim.new(0,r or 8) end
function G.Stk(p,col,t) local s=Instance.new("UIStroke",p);s.Color=col or GC.brd;s.Thickness=t or 1;return s end
function G.Drag(f,h) local dr,ds,sp=false,nil,nil;h.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true;ds=i.Position;sp=f.Position end end);table.insert(S.conns,UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end end));table.insert(S.conns,UIS.InputChanged:Connect(function(i) if dr and(i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then local d=i.Position-ds;f.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d.X,sp.Y.Scale,sp.Y.Offset+d.Y) end end)) end
function G.Sec(p,t,y) Instance.new("Frame",p).Size=UDim2.new(1,-16,0,1);p:GetChildren()[#p:GetChildren()].Position=UDim2.new(0,8,0,y);p:GetChildren()[#p:GetChildren()].BackgroundColor3=GC.brd;p:GetChildren()[#p:GetChildren()].BorderSizePixel=0;local bg=Instance.new("Frame",p);bg.Size=UDim2.new(0,#t*7+16,0,18);bg.Position=UDim2.new(0,8,0,y-9);bg.BackgroundColor3=GC.acc;bg.BorderSizePixel=0;G.Crn(bg,4);local l=Instance.new("TextLabel",bg);l.Text=t:upper();l.Size=UDim2.new(1,0,1,0);l.BackgroundTransparency=1;l.TextColor3=Color3.new(1,1,1);l.TextSize=10;l.Font=Enum.Font.GothamBold;return y+16 end
function G.Tog(p,n,d,y,cb) local h=SC(32,40);local f=Instance.new("Frame",p);f.Size=UDim2.new(1,-16,0,h);f.Position=UDim2.new(0,8,0,y);f.BackgroundColor3=GC.pnl;f.BorderSizePixel=0;G.Crn(f,6);Instance.new("TextLabel",f).Text=n;f:GetChildren()[#f:GetChildren()].Size=UDim2.new(0.7,-10,1,0);f:GetChildren()[#f:GetChildren()].Position=UDim2.new(0,10,0,0);f:GetChildren()[#f:GetChildren()].BackgroundTransparency=1;f:GetChildren()[#f:GetChildren()].TextColor3=GC.txt;f:GetChildren()[#f:GetChildren()].TextSize=SC(12,13);f:GetChildren()[#f:GetChildren()].Font=Enum.Font.Gotham;f:GetChildren()[#f:GetChildren()].TextXAlignment=Enum.TextXAlignment.Left;f:GetChildren()[#f:GetChildren()].TextWrapped=true;local sw,sh=SC(44,52),SC(22,26);local bg=Instance.new("Frame",f);bg.Size=UDim2.new(0,sw,0,sh);bg.Position=UDim2.new(1,-sw-10,0.5,-sh/2);bg.BackgroundColor3=d and GC.tOn or GC.tOff;G.Crn(bg,sh/2);local kw=SC(18,22);local kn=Instance.new("Frame",bg);kn.Size=UDim2.new(0,kw,0,kw);kn.Position=d and UDim2.new(1,-kw-2,0.5,-kw/2) or UDim2.new(0,2,0.5,-kw/2);kn.BackgroundColor3=Color3.new(1,1,1);G.Crn(kn,kw/2);local en=d;Instance.new("TextButton",f).Text="";f:GetChildren()[#f:GetChildren()].Size=UDim2.new(1,0,1,0);f:GetChildren()[#f:GetChildren()].BackgroundTransparency=1;f:GetChildren()[#f:GetChildren()].MouseButton1Click:Connect(function() CloseDD();en=not en;TweenService:Create(bg,TweenInfo.new(0.2),{BackgroundColor3=en and GC.tOn or GC.tOff}):Play();TweenService:Create(kn,TweenInfo.new(0.2),{Position=en and UDim2.new(1,-kw-2,0.5,-kw/2) or UDim2.new(0,2,0.5,-kw/2)}):Play();if cb then cb(en) end end) end
function G.Sld(p,n,mn,mx,d,y,fmt,cb) local h=SC(44,52);local f=Instance.new("Frame",p);f.Size=UDim2.new(1,-16,0,h);f.Position=UDim2.new(0,8,0,y);f.BackgroundColor3=GC.pnl;f.BorderSizePixel=0;G.Crn(f,6);local l=Instance.new("TextLabel",f);l.Text=string.format("%s: "..(fmt or"%.1f"),n,d);l.Size=UDim2.new(1,-16,0,16);l.Position=UDim2.new(0,8,0,4);l.BackgroundTransparency=1;l.TextColor3=GC.txt;l.TextSize=SC(11,12);l.Font=Enum.Font.Gotham;l.TextXAlignment=Enum.TextXAlignment.Left;local tr=Instance.new("Frame",f);tr.Size=UDim2.new(1,-16,0,SC(6,10));tr.Position=UDim2.new(0,8,0,SC(28,30));tr.BackgroundColor3=GC.sB;tr.BorderSizePixel=0;G.Crn(tr,3);local pct=math.clamp((d-mn)/(mx-mn),0,1);local fl=Instance.new("Frame",tr);fl.Size=UDim2.new(pct,0,1,0);fl.BackgroundColor3=GC.sF;fl.BorderSizePixel=0;G.Crn(fl,3);local ks=SC(12,18);local kn=Instance.new("Frame",tr);kn.Size=UDim2.new(0,ks,0,ks);kn.Position=UDim2.new(pct,-ks/2,0.5,-ks/2);kn.BackgroundColor3=Color3.new(1,1,1);kn.ZIndex=5;G.Crn(kn,ks/2);G.Stk(kn,GC.acc,2);local dragging=false;local hb=Instance.new("TextButton",f);hb.Text="";hb.Size=UDim2.new(1,10,0,SC(22,34));hb.Position=UDim2.new(0,-5,0,SC(20,22));hb.BackgroundTransparency=1;hb.ZIndex=6;local function upd(ix) local ap,as=tr.AbsolutePosition.X,tr.AbsoluteSize.X;if as<=0 then return end;local r=math.clamp((ix-ap)/as,0,1);local v=mn+r*(mx-mn);fl.Size=UDim2.new(r,0,1,0);kn.Position=UDim2.new(r,-ks/2,0.5,-ks/2);l.Text=string.format("%s: "..(fmt or"%.1f"),n,v);if cb then cb(v) end end;hb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then CloseDD();dragging=true;upd(i.Position.X) end end);table.insert(S.conns,UIS.InputChanged:Connect(function(i) if dragging and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then upd(i.Position.X) end end));table.insert(S.conns,UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)) end
function G.DD(p,n,opts,d,y,cb) local h=SC(32,40);local ct=Instance.new("Frame",p);ct.Size=UDim2.new(1,-16,0,h);ct.Position=UDim2.new(0,8,0,y);ct.BackgroundColor3=GC.pnl;ct.BorderSizePixel=0;G.Crn(ct,6);Instance.new("TextLabel",ct).Text=n;ct:GetChildren()[#ct:GetChildren()].Size=UDim2.new(0.35,-10,1,0);ct:GetChildren()[#ct:GetChildren()].Position=UDim2.new(0,10,0,0);ct:GetChildren()[#ct:GetChildren()].BackgroundTransparency=1;ct:GetChildren()[#ct:GetChildren()].TextColor3=GC.txt;ct:GetChildren()[#ct:GetChildren()].TextSize=SC(12,13);ct:GetChildren()[#ct:GetChildren()].Font=Enum.Font.Gotham;ct:GetChildren()[#ct:GetChildren()].TextXAlignment=Enum.TextXAlignment.Left;ct:GetChildren()[#ct:GetChildren()].TextWrapped=true;local db=Instance.new("TextButton",ct);db.Text=(d or opts[1]).." v";db.Size=UDim2.new(0.6,0,0,SC(26,32));db.Position=UDim2.new(0.38,0,0.5,-SC(13,16));db.BackgroundColor3=GC.ddBg;db.TextColor3=GC.txt;db.TextSize=SC(11,12);db.Font=Enum.Font.Gotham;db.AutoButtonColor=false;G.Crn(db,5);local bs=G.Stk(db,GC.brd,1);local sel=d or opts[1];db.MouseButton1Click:Connect(function() if DDB==db then CloseDD();return end;CloseDD();bs.Color=GC.brdA;DDB=db;local mf;local cur=p;for _=1,10 do if not cur then break end;if cur.Name=="MainFrame" then mf=cur;break end;cur=cur.Parent end;if not mf then return end;task.defer(function() if DDB~=db then return end;local bp2,bsz=db.AbsolutePosition,db.AbsoluteSize;local mp,ms=mf.AbsolutePosition,mf.AbsoluteSize;local rx,ry=bp2.X-mp.X,bp2.Y-mp.Y+bsz.Y+4;local ih=SC(30,38);local lh=#opts*ih+6;local lw=math.max(bsz.X,SC(130,160));if ry+lh>ms.Y-10 then ry=bp2.Y-mp.Y-lh-4 end;rx=math.clamp(rx,5,ms.X-lw-5);ry=math.clamp(ry,5,ms.Y-lh-5);local grp=Instance.new("Folder",mf);Instance.new("TextButton",grp).Text="";grp:GetChildren()[1].Size=UDim2.new(1,0,1,0);grp:GetChildren()[1].BackgroundTransparency=1;grp:GetChildren()[1].ZIndex=90;grp:GetChildren()[1].AutoButtonColor=false;grp:GetChildren()[1].MouseButton1Click:Connect(CloseDD);local dl=Instance.new("Frame",grp);dl.Size=UDim2.new(0,lw,0,lh);dl.Position=UDim2.new(0,rx,0,ry);dl.BackgroundColor3=Color3.fromRGB(18,18,30);dl.BorderSizePixel=0;dl.ZIndex=100;G.Crn(dl,8);G.Stk(dl,GC.brdA,1);for i,opt in ipairs(opts) do local ob=Instance.new("TextButton",dl);ob.Text=(opt==sel and"> "or"  ")..opt;ob.Size=UDim2.new(1,-8,0,ih-2);ob.Position=UDim2.new(0,4,0,(i-1)*ih+3);ob.BackgroundColor3=opt==sel and Color3.fromRGB(40,50,80) or Color3.fromRGB(22,22,38);ob.TextColor3=opt==sel and GC.acc or GC.txt;ob.TextSize=SC(12,13);ob.Font=Enum.Font.Gotham;ob.TextXAlignment=Enum.TextXAlignment.Left;ob.AutoButtonColor=false;ob.ZIndex=101;G.Crn(ob,5);ob.MouseButton1Click:Connect(function() sel=opt;db.Text=opt.." v";CloseDD();if cb then cb(opt) end end) end;DDL=grp end) end) end
function G.Btn(p,t,y,col,cb) local b=Instance.new("TextButton",p);b.Text=t;b.Size=UDim2.new(1,-16,0,SC(30,38));b.Position=UDim2.new(0,8,0,y);b.BackgroundColor3=col or GC.acc;b.TextColor3=Color3.new(1,1,1);b.TextSize=SC(12,14);b.Font=Enum.Font.GothamBold;b.AutoButtonColor=false;G.Crn(b,6);b.MouseButton1Click:Connect(function() if cb then cb() end end) end

-- Sub-menu builder for gear button
function G.Sub(mf,title,builder)
    CloseSub();CloseDD()
    local ov=Instance.new("Frame",mf);ov.Size=UDim2.new(1,0,1,0);ov.BackgroundColor3=Color3.new(0,0,0);ov.BackgroundTransparency=0.4;ov.ZIndex=50
    local pn=Instance.new("Frame",ov);pn.Size=UDim2.new(0.85,0,0.7,0);pn.Position=UDim2.new(0.075,0,0.15,0);pn.BackgroundColor3=Color3.fromRGB(18,18,32);pn.BorderSizePixel=0;pn.ZIndex=51;pn.ClipsDescendants=true;G.Crn(pn,10);G.Stk(pn,GC.acc,1)
    local hd=Instance.new("Frame",pn);hd.Size=UDim2.new(1,0,0,36);hd.BackgroundColor3=GC.hdr;hd.BorderSizePixel=0;hd.ZIndex=52;G.Crn(hd,10)
    local tl=Instance.new("TextLabel",hd);tl.Text="# "..title;tl.Size=UDim2.new(1,-40,1,0);tl.Position=UDim2.new(0,10,0,0);tl.BackgroundTransparency=1;tl.TextColor3=GC.acc;tl.TextSize=13;tl.Font=Enum.Font.GothamBold;tl.TextXAlignment=Enum.TextXAlignment.Left;tl.ZIndex=53
    local cb=Instance.new("TextButton",hd);cb.Text="X";cb.Size=UDim2.new(0,28,0,28);cb.Position=UDim2.new(1,-32,0.5,-14);cb.BackgroundColor3=GC.red;cb.TextColor3=Color3.new(1,1,1);cb.TextSize=14;cb.Font=Enum.Font.GothamBold;cb.ZIndex=53;cb.AutoButtonColor=false;G.Crn(cb,6);cb.MouseButton1Click:Connect(CloseSub)
    Instance.new("TextButton",ov).Text="";ov:GetChildren()[#ov:GetChildren()].Size=UDim2.new(1,0,1,0);ov:GetChildren()[#ov:GetChildren()].BackgroundTransparency=1;ov:GetChildren()[#ov:GetChildren()].ZIndex=49;ov:GetChildren()[#ov:GetChildren()].AutoButtonColor=false;ov:GetChildren()[#ov:GetChildren()].MouseButton1Click:Connect(CloseSub)
    local sc=Instance.new("ScrollingFrame",pn);sc.Size=UDim2.new(1,0,1,-36);sc.Position=UDim2.new(0,0,0,36);sc.BackgroundTransparency=1;sc.ScrollBarThickness=SC(3,5);sc.ScrollBarImageColor3=GC.acc;sc.CanvasSize=UDim2.new(0,0,0,0);sc.ZIndex=52
    if builder then sc.CanvasSize=UDim2.new(0,0,0,builder(sc)+10) end
    S.subMenu=ov
end

-- Toggle with gear button
function G.TGear(p,n,d,y,cb,gCb)
    local h=SC(32,40);local f=Instance.new("Frame",p);f.Size=UDim2.new(1,-16,0,h);f.Position=UDim2.new(0,8,0,y);f.BackgroundColor3=GC.pnl;f.BorderSizePixel=0;G.Crn(f,6)
    local gs=SC(22,28);local gb=Instance.new("TextButton",f);gb.Text="#";gb.Size=UDim2.new(0,gs,0,gs);gb.Position=UDim2.new(0,6,0.5,-gs/2);gb.BackgroundColor3=GC.ddBg;gb.TextColor3=GC.txtD;gb.TextSize=SC(13,15);gb.Font=Enum.Font.GothamBold;gb.AutoButtonColor=false;G.Crn(gb,4);gb.MouseButton1Click:Connect(function() CloseDD();if gCb then gCb() end end)
    Instance.new("TextLabel",f).Text=n;f:GetChildren()[#f:GetChildren()].Size=UDim2.new(0.55,-10,1,0);f:GetChildren()[#f:GetChildren()].Position=UDim2.new(0,gs+12,0,0);f:GetChildren()[#f:GetChildren()].BackgroundTransparency=1;f:GetChildren()[#f:GetChildren()].TextColor3=GC.txt;f:GetChildren()[#f:GetChildren()].TextSize=SC(12,13);f:GetChildren()[#f:GetChildren()].Font=Enum.Font.Gotham;f:GetChildren()[#f:GetChildren()].TextXAlignment=Enum.TextXAlignment.Left;f:GetChildren()[#f:GetChildren()].TextWrapped=true
    local sw,sh=SC(44,52),SC(22,26);local bg=Instance.new("Frame",f);bg.Size=UDim2.new(0,sw,0,sh);bg.Position=UDim2.new(1,-sw-10,0.5,-sh/2);bg.BackgroundColor3=d and GC.tOn or GC.tOff;G.Crn(bg,sh/2)
    local kw=SC(18,22);local kn=Instance.new("Frame",bg);kn.Size=UDim2.new(0,kw,0,kw);kn.Position=d and UDim2.new(1,-kw-2,0.5,-kw/2) or UDim2.new(0,2,0.5,-kw/2);kn.BackgroundColor3=Color3.new(1,1,1);G.Crn(kn,kw/2)
    local en=d;local hit=Instance.new("TextButton",f);hit.Text="";hit.Size=UDim2.new(0.6,0,1,0);hit.Position=UDim2.new(0.35,0,0,0);hit.BackgroundTransparency=1
    hit.MouseButton1Click:Connect(function() CloseDD();en=not en;TweenService:Create(bg,TweenInfo.new(0.2),{BackgroundColor3=en and GC.tOn or GC.tOff}):Play();TweenService:Create(kn,TweenInfo.new(0.2),{Position=en and UDim2.new(1,-kw-2,0.5,-kw/2) or UDim2.new(0,2,0.5,-kw/2)}):Play();if cb then cb(en) end end)
end

function G.MobBtns()
    if not IsMobile then return end;if S.mobFrame then pcall(function() S.mobFrame:Destroy() end) end
    local gui=S.gui;if not gui then return end
    local bf=Instance.new("Frame",gui);bf.Size=UDim2.new(0,56,0,200);bf.Position=UDim2.new(0,6,0.5,-100);bf.BackgroundTransparency=1;S.mobFrame=bf
    local defs={{t="AIM",y=0,c=GC.grn,fn=function() Cfg.On=not Cfg.On end,gs=function() return Cfg.On end},{t="ESP",y=48,c=GC.acc,fn=function() Cfg.ESP.On=not Cfg.ESP.On;if not Cfg.ESP.On then E.DelAll() end end,gs=function() return Cfg.ESP.On end},{t="WH",y=96,c=GC.org,fn=function() Cfg.WH.On=not Cfg.WH.On;if not Cfg.WH.On then WH.KillAll() end end,gs=function() return Cfg.WH.On end},{t="360",y=144,c=Color3.fromRGB(200,100,255),fn=function() Cfg.Aim360=not Cfg.Aim360;Cfg.Silent.Use360=Cfg.Aim360 end,gs=function() return Cfg.Aim360 end}}
    for _,d in ipairs(defs) do local b=Instance.new("TextButton",bf);b.Size=UDim2.new(0,50,0,40);b.Position=UDim2.new(0,0,0,d.y);b.BackgroundColor3=d.gs()and d.c or Color3.fromRGB(40,40,55);b.TextColor3=Color3.new(1,1,1);b.Text=d.t;b.TextSize=11;b.Font=Enum.Font.GothamBold;b.AutoButtonColor=false;G.Crn(b,8);G.Stk(b,d.c,1);b.MouseButton1Click:Connect(function() d.fn();b.BackgroundColor3=d.gs()and d.c or Color3.fromRGB(40,40,55) end) end
end

function G.Create()
    G.Destroy()
    local gui=Instance.new("ScreenGui");gui.Name="X_"..math.random(100000,999999);gui.ResetOnSpawn=false;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.DisplayOrder=999;Protect(gui);gui.Parent=SafeP();S.gui=gui
    local mW,mH=SC(520,math.min(Cam.ViewportSize.X-20,390)),SC(620,math.min(Cam.ViewportSize.Y-80,520))
    local main=Instance.new("Frame",gui);main.Name="MainFrame";main.Size=UDim2.new(0,mW,0,mH);main.Position=UDim2.new(0.5,-mW/2,0.5,-mH/2);main.BackgroundColor3=GC.bg;main.BorderSizePixel=0;main.Visible=false;main.Active=true;main.ClipsDescendants=true;G.Crn(main,12);G.Stk(main,GC.brd,1)
    local hH=SC(44,38);local hdr=Instance.new("Frame",main);hdr.Size=UDim2.new(1,0,0,hH);hdr.BackgroundColor3=GC.hdr;hdr.BorderSizePixel=0;hdr.ZIndex=5;G.Crn(hdr,12)
    Instance.new("TextLabel",hdr).Text="XENO v9.1";hdr:GetChildren()[#hdr:GetChildren()].Size=UDim2.new(0,80,0,18);hdr:GetChildren()[#hdr:GetChildren()].Position=UDim2.new(0,14,0,SC(6,4));hdr:GetChildren()[#hdr:GetChildren()].BackgroundTransparency=1;hdr:GetChildren()[#hdr:GetChildren()].TextColor3=GC.acc;hdr:GetChildren()[#hdr:GetChildren()].TextSize=SC(16,14);hdr:GetChildren()[#hdr:GetChildren()].Font=Enum.Font.GothamBlack;hdr:GetChildren()[#hdr:GetChildren()].TextXAlignment=Enum.TextXAlignment.Left;hdr:GetChildren()[#hdr:GetChildren()].ZIndex=6
    local xb=Instance.new("TextButton",hdr);xb.Text="X";xb.Size=UDim2.new(0,SC(28,24),0,SC(28,24));xb.Position=UDim2.new(1,-SC(36,30),0.5,-SC(14,12));xb.BackgroundColor3=GC.red;xb.TextColor3=Color3.new(1,1,1);xb.TextSize=SC(12,10);xb.Font=Enum.Font.GothamBold;xb.ZIndex=7;xb.AutoButtonColor=false;G.Crn(xb,6);xb.MouseButton1Click:Connect(function() CloseDD();CloseSub();main.Visible=false end)
    G.Drag(main,hdr)

    local tH=SC(34,30);local tb=Instance.new("Frame",main);tb.Size=UDim2.new(1,0,0,tH);tb.Position=UDim2.new(0,0,0,hH);tb.BackgroundColor3=GC.tabBg;tb.BorderSizePixel=0;tb.ZIndex=4
    local modes=Exec.canSilent and{"normal","snap","silent"}or{"normal","snap","flick"}
    local styles={"Corner","Full","Glow","Cyber","Gradient"}
    local tabs={{"Aim","+"},{"ESP","*"},{"Colors","#"},{"Misc","="}}
    local tabBtns,tabFrames={},{};local tw=1/#tabs
    local ind=Instance.new("Frame",tb);ind.Size=UDim2.new(tw,-8,0,3);ind.Position=UDim2.new(0,4,1,-3);ind.BackgroundColor3=GC.acc;ind.BorderSizePixel=0;ind.ZIndex=6;G.Crn(ind,2)
    local cY=hH+tH;local cf=Instance.new("Frame",main);cf.Size=UDim2.new(1,0,1,-cY);cf.Position=UDim2.new(0,0,0,cY);cf.BackgroundColor3=GC.bg;cf.BorderSizePixel=0;cf.ClipsDescendants=true
    local curTab=tabs[1][1]
    local function swTab(n) CloseDD();CloseSub();curTab=n;for nm,fr in pairs(tabFrames) do fr.Visible=(nm==n) end;for nm,bt in pairs(tabBtns) do TweenService:Create(bt,TweenInfo.new(0.15),{TextColor3=nm==n and GC.acc or GC.txtD,BackgroundColor3=nm==n and GC.tabA or GC.tabBg}):Play() end;for i,td in ipairs(tabs) do if td[1]==n then TweenService:Create(ind,TweenInfo.new(0.2,Enum.EasingStyle.Quart),{Position=UDim2.new(tw*(i-1),4,1,-3)}):Play() end end end
    for i,td in ipairs(tabs) do local bt=Instance.new("TextButton",tb);bt.Text=td[2].." "..td[1];bt.Size=UDim2.new(tw,0,1,-3);bt.Position=UDim2.new(tw*(i-1),0,0,0);bt.BackgroundColor3=td[1]==curTab and GC.tabA or GC.tabBg;bt.TextColor3=td[1]==curTab and GC.acc or GC.txtD;bt.TextSize=SC(10,9);bt.Font=Enum.Font.GothamBold;bt.AutoButtonColor=false;bt.ZIndex=5;bt.BorderSizePixel=0;bt.MouseButton1Click:Connect(function() swTab(td[1]) end);tabBtns[td[1]]=bt;local sf=Instance.new("ScrollingFrame",cf);sf.Size=UDim2.new(1,0,1,0);sf.BackgroundColor3=GC.bg;sf.BackgroundTransparency=0;sf.BorderSizePixel=0;sf.ScrollBarThickness=SC(3,5);sf.ScrollBarImageColor3=GC.acc;sf.CanvasSize=UDim2.new(0,0,0,0);sf.Visible=(td[1]==curTab);sf:GetPropertyChangedSignal("CanvasPosition"):Connect(CloseDD);tabFrames[td[1]]=sf end
    local TH,SH,DH=SC(36,44),SC(50,58),SC(38,46)

    -- ═══ AIM TAB ═══
    local sc=tabFrames["Aim"];local y=8
    y=G.Sec(sc,"AIM",y);y=y+4
    G.Tog(sc,"Aimbot",Cfg.On,y,function(v) Cfg.On=v;if not v then S.tgt.part=nil;S.tgt.plr=nil;S.tgt.vis=false end end);y=y+TH
    G.Tog(sc,"360",Cfg.Aim360,y,function(v) Cfg.Aim360=v;Cfg.Silent.Use360=v end);y=y+TH
    G.DD(sc,"Mode",modes,Cfg.AimMode,y,function(v) Cfg.AimMode=v;Cfg.Silent.On=(v=="silent");Cfg.Flick.On=(v=="flick");if v=="silent" then Sil.Install() end end);y=y+DH
    G.DD(sc,"Part",{"Head","UpperTorso","HumanoidRootPart","Nearest"},Cfg.Part,y,function(v) Cfg.Part=v end);y=y+DH
    G.DD(sc,"Priority",{"FOV","Distance","Health","Threat"},Cfg.Priority,y,function(v) Cfg.Priority=v end);y=y+DH
    G.Tog(sc,"FOV Circle",Cfg.FOV.On,y,function(v) Cfg.FOV.On=v end);y=y+TH
    G.Sld(sc,"FOV Radius",10,500,Cfg.FOV.R,y,"%.0f",function(v) Cfg.FOV.R=v end);y=y+SH
    G.Tog(sc,"Smoothing",Cfg.Smooth.On,y,function(v) Cfg.Smooth.On=v end);y=y+TH
    G.Sld(sc,"Smooth",0.01,1,Cfg.Smooth.Amt,y,"%.2f",function(v) Cfg.Smooth.Amt=v end);y=y+SH
    G.Tog(sc,"Team Check",Cfg.Checks.Team,y,function(v) Cfg.Checks.Team=v end);y=y+TH
    G.Tog(sc,"Wall Check",Cfg.Checks.Wall,y,function(v) Cfg.Checks.Wall=v end);y=y+TH
    G.Sld(sc,"Max Dist",50,2000,Cfg.Limits.MaxD,y,"%.0f",function(v) Cfg.Limits.MaxD=v end);y=y+SH
    G.Tog(sc,"Prediction",Cfg.Pred.On,y,function(v) Cfg.Pred.On=v end);y=y+TH
    G.Tog(sc,"TriggerBot",Cfg.TB.On,y,function(v) Cfg.TB.On=v end);y=y+TH
    G.Tog(sc,"Deep Scan (Arena)",Cfg.AC.DeepScan,y,function(v) Cfg.AC.DeepScan=v end);y=y+TH
    sc.CanvasSize=UDim2.new(0,0,0,y+10)

    -- ═══ ESP TAB ═══
    sc=tabFrames["ESP"];y=8
    y=G.Sec(sc,"ESP",y);y=y+4
    G.Tog(sc,"ESP",Cfg.ESP.On,y,function(v) Cfg.ESP.On=v;if not v then E.DelAll() end end);y=y+TH
    G.Tog(sc,"Show Team",Cfg.ESP.ShowTeam,y,function(v) Cfg.ESP.ShowTeam=v end);y=y+TH
    G.Sld(sc,"Max Dist",100,3000,Cfg.ESP.MaxDist,y,"%.0f",function(v) Cfg.ESP.MaxDist=v end);y=y+SH
    G.DD(sc,"Style",styles,Cfg.ESP.Style,y,function(v) Cfg.ESP.Style=v end);y=y+DH
    G.Sld(sc,"ESP FPS (0=MAX)",0,144,Cfg.ESP.Render.FPS,y,"%.0f",function(v) Cfg.ESP.Render.FPS=math.floor(v) end);y=y+SH
    G.Tog(sc,"Interpolation",Cfg.ESP.Render.Interp,y,function(v) Cfg.ESP.Render.Interp=v end);y=y+TH

    -- Box with gear
    y=G.Sec(sc,"BOX",y+6);y=y+4
    G.TGear(sc,"Box",Cfg.ESP.Box.On,y,function(v) Cfg.ESP.Box.On=v end,function()
        G.Sub(main,"Box Settings",function(sub) local sy=8
            G.Sld(sub,"Width",0.5,5,Cfg.ESP.Box.W,sy,"%.1f",function(v) Cfg.ESP.Box.W=v end);sy=sy+SH
            G.Sld(sub,"Outline W",0,5,Cfg.ESP.Box.OW,sy,"%.0f",function(v) Cfg.ESP.Box.OW=v end);sy=sy+SH
            G.Sld(sub,"Corner Len",0.1,0.5,Cfg.ESP.Box.CL,sy,"%.2f",function(v) Cfg.ESP.Box.CL=v end);sy=sy+SH
            G.Tog(sub,"Outline",Cfg.ESP.Box.Outline,sy,function(v) Cfg.ESP.Box.Outline=v end);sy=sy+TH
            G.Tog(sub,"Vis Color",Cfg.ESP.Box.VisCheck,sy,function(v) Cfg.ESP.Box.VisCheck=v end);sy=sy+TH
            return sy
        end)
    end);y=y+TH

    y=G.Sec(sc,"TEXT",y+6);y=y+4
    G.TGear(sc,"Name",Cfg.ESP.Name.On,y,function(v) Cfg.ESP.Name.On=v end,function()
        G.Sub(main,"Name Settings",function(sub) local sy=8
            G.DD(sub,"Format",{"Name+Distance","Name Only"},Cfg.ESP.Name.Fmt,sy,function(v) Cfg.ESP.Name.Fmt=v end);sy=sy+DH
            G.DD(sub,"Position",{"Top","Bottom","Right"},Cfg.ESP.Name.Pos,sy,function(v) Cfg.ESP.Name.Pos=v end);sy=sy+DH
            G.Sld(sub,"Size",8,24,Cfg.ESP.Name.Sz,sy,"%.0f",function(v) Cfg.ESP.Name.Sz=v end);sy=sy+SH
            G.Tog(sub,"Shadow",Cfg.ESP.Name.Shadow,sy,function(v) Cfg.ESP.Name.Shadow=v end);sy=sy+TH
            return sy
        end)
    end);y=y+TH
    G.Tog(sc,"Distance",Cfg.ESP.Dist.On,y,function(v) Cfg.ESP.Dist.On=v end);y=y+TH
    G.Tog(sc,"Weapon",Cfg.ESP.Weapon.On,y,function(v) Cfg.ESP.Weapon.On=v end);y=y+TH
    G.Tog(sc,"Flags",Cfg.ESP.Flags.On,y,function(v) Cfg.ESP.Flags.On=v end);y=y+TH

    y=G.Sec(sc,"HEALTH",y+6);y=y+4
    G.TGear(sc,"Health Bar",Cfg.ESP.HP.On,y,function(v) Cfg.ESP.HP.On=v end,function()
        G.Sub(main,"HP Settings",function(sub) local sy=8
            G.DD(sub,"Position",{"Left","Right","Bottom"},Cfg.ESP.HP.Pos,sy,function(v) Cfg.ESP.HP.Pos=v end);sy=sy+DH
            G.Sld(sub,"Width",1,10,Cfg.ESP.HP.W,sy,"%.0f",function(v) Cfg.ESP.HP.W=v end);sy=sy+SH
            G.Tog(sub,"HP Text",Cfg.ESP.HP.Txt,sy,function(v) Cfg.ESP.HP.Txt=v end);sy=sy+TH
            G.Tog(sub,"Smooth",Cfg.ESP.HP.Smooth,sy,function(v) Cfg.ESP.HP.Smooth=v end);sy=sy+TH
            G.Sld(sub,"Smooth Spd",1,30,Cfg.ESP.HP.SmoothSpd,sy,"%.0f",function(v) Cfg.ESP.HP.SmoothSpd=v end);sy=sy+SH
            return sy
        end)
    end);y=y+TH

    y=G.Sec(sc,"EXTRA",y+6);y=y+4
    G.TGear(sc,"Tracers",Cfg.ESP.Tracer.On,y,function(v) Cfg.ESP.Tracer.On=v end,function()
        G.Sub(main,"Tracer Settings",function(sub) local sy=8
            G.DD(sub,"Origin",{"Bottom","Top","Center"},Cfg.ESP.Tracer.Origin,sy,function(v) Cfg.ESP.Tracer.Origin=v end);sy=sy+DH
            G.Sld(sub,"Width",0.5,5,Cfg.ESP.Tracer.W,sy,"%.1f",function(v) Cfg.ESP.Tracer.W=v end);sy=sy+SH
            G.Tog(sub,"Outline",Cfg.ESP.Tracer.Outline,sy,function(v) Cfg.ESP.Tracer.Outline=v end);sy=sy+TH
            return sy
        end)
    end);y=y+TH
    G.Tog(sc,"Skeleton",Cfg.ESP.Skel.On,y,function(v) Cfg.ESP.Skel.On=v end);y=y+TH
    G.Tog(sc,"Head Dot",Cfg.ESP.HeadDot.On,y,function(v) Cfg.ESP.HeadDot.On=v end);y=y+TH
    G.Tog(sc,"Off-Screen",Cfg.ESP.OFS.On,y,function(v) Cfg.ESP.OFS.On=v end);y=y+TH

    y=G.Sec(sc,"STYLE SETTINGS",y+6);y=y+4
    G.Sld(sc,"Glow Layers",1,3,Cfg.ESP.Glow.Layers,y,"%.0f",function(v) Cfg.ESP.Glow.Layers=math.floor(v) end);y=y+SH
    G.Sld(sc,"Glow Spread",1,8,Cfg.ESP.Glow.Spread,y,"%.0f",function(v) Cfg.ESP.Glow.Spread=v end);y=y+SH
    G.Tog(sc,"Cyber Scan",Cfg.ESP.Cyber.ScanLine,y,function(v) Cfg.ESP.Cyber.ScanLine=v end);y=y+TH
    G.Sld(sc,"Scan Speed",0.5,8,Cfg.ESP.Cyber.ScanSpeed,y,"%.1f",function(v) Cfg.ESP.Cyber.ScanSpeed=v end);y=y+SH
    G.Sld(sc,"Grad Steps",2,4,Cfg.ESP.Grad.Steps,y,"%.0f",function(v) Cfg.ESP.Grad.Steps=math.floor(v) end);y=y+SH

    y=G.Sec(sc,"WALLHACK",y+6);y=y+4
    G.Tog(sc,"Wallhack",Cfg.WH.On,y,function(v) Cfg.WH.On=v;if not v then WH.KillAll() end end);y=y+TH
    G.Sld(sc,"Fill Trans",0,1,Cfg.WH.FT,y,"%.1f",function(v) Cfg.WH.FT=v end);y=y+SH
    sc.CanvasSize=UDim2.new(0,0,0,y+10)

    -- ═══ COLORS TAB ═══
    sc=tabFrames["Colors"];y=8
    local function CSld(name,key,yy)
        local c=Cfg.ESP.Colors[key]
        local l=Instance.new("TextLabel",sc);l.Text=name;l.Size=UDim2.new(1,-20,0,16);l.Position=UDim2.new(0,10,0,yy);l.BackgroundTransparency=1;l.TextColor3=GC.txt;l.TextSize=SC(11,12);l.Font=Enum.Font.GothamBold;l.TextXAlignment=Enum.TextXAlignment.Left;yy=yy+18
        G.Sld(sc,"R",0,255,math.floor(c.R*255),yy,"%.0f",function(v) local cc=Cfg.ESP.Colors[key];Cfg.ESP.Colors[key]=Color3.fromRGB(v,cc.G*255,cc.B*255) end);yy=yy+SH
        G.Sld(sc,"G",0,255,math.floor(c.G*255),yy,"%.0f",function(v) local cc=Cfg.ESP.Colors[key];Cfg.ESP.Colors[key]=Color3.fromRGB(cc.R*255,v,cc.B*255) end);yy=yy+SH
        G.Sld(sc,"B",0,255,math.floor(c.B*255),yy,"%.0f",function(v) local cc=Cfg.ESP.Colors[key];Cfg.ESP.Colors[key]=Color3.fromRGB(cc.R*255,cc.G*255,v) end);yy=yy+SH
        return yy
    end
    y=G.Sec(sc,"ENEMY",y);y=y+4
    y=CSld("Box","EBox",y);y=CSld("Box Gradient","EBoxBot",y);y=CSld("Glow","EGlow",y);y=CSld("Cyber","ECyber",y);y=CSld("Tracer","ETracer",y)
    y=G.Sec(sc,"TEAM",y+6);y=y+4
    y=CSld("Box","TBox",y);y=CSld("Glow","TGlow",y)
    y=G.Sec(sc,"SHARED",y+6);y=y+4
    y=CSld("Outline","Outline",y);y=CSld("HP Low","HPLo",y);y=CSld("HP High","HPHi",y)
    sc.CanvasSize=UDim2.new(0,0,0,y+10)

    -- ═══ MISC TAB ═══
    sc=tabFrames["Misc"];y=8
    y=G.Sec(sc,"HACKS",y);y=y+4
    G.Tog(sc,"3rd Person",Cfg.TP.On,y,function(v) Cfg.TP.On=v;if not v then Exp.RTP() end end);y=y+TH
    G.Tog(sc,"SpinBot",Cfg.Spin.On,y,function(v) Cfg.Spin.On=v;if not v then Exp.RSpin() end end);y=y+TH
    G.Sld(sc,"Spin Speed",1,50,Cfg.Spin.Spd,y,"%.0f",function(v) Cfg.Spin.Spd=v end);y=y+SH
    G.Tog(sc,"Speed Boost",Cfg.Speed.On,y,function(v) Cfg.Speed.On=v end);y=y+TH
    G.Sld(sc,"Speed Mult",1,3,Cfg.Speed.Mult,y,"%.1fx",function(v) Cfg.Speed.Mult=v end);y=y+SH
    y=G.Sec(sc,"INFO",y+6);y=y+4
    local function Lbl(t,yy,col) Instance.new("TextLabel",sc).Text=t;sc:GetChildren()[#sc:GetChildren()].Size=UDim2.new(1,-20,0,SC(16,20));sc:GetChildren()[#sc:GetChildren()].Position=UDim2.new(0,10,0,yy);sc:GetChildren()[#sc:GetChildren()].BackgroundTransparency=1;sc:GetChildren()[#sc:GetChildren()].TextColor3=col or GC.txtD;sc:GetChildren()[#sc:GetChildren()].TextSize=SC(11,12);sc:GetChildren()[#sc:GetChildren()].Font=Enum.Font.Gotham;sc:GetChildren()[#sc:GetChildren()].TextXAlignment=Enum.TextXAlignment.Left;sc:GetChildren()[#sc:GetChildren()].TextWrapped=true end
    Lbl("Executor: "..Exec.name,y,GC.txt);y=y+SC(20,24)
    Lbl("Drawing: "..(drawOK and"YES"or"NO"),y,drawOK and GC.grn or GC.red);y=y+SC(20,24)
    Lbl("Silent: "..(Exec.canSilent and"YES"or"NO"),y,Exec.canSilent and GC.grn or GC.red);y=y+SC(20,24)
    Lbl("Arena Scan: "..(Cfg.AC.DeepScan and"ON"or"OFF"),y,Cfg.AC.DeepScan and GC.grn or GC.red);y=y+SC(20,24)
    if not IsMobile then Lbl("F1-Aim F2-ESP F3-WH F4-Style RShift-Menu",y,GC.txt);y=y+20 end
    y=y+8;G.Btn(sc,"Unload",y,GC.red,function() Notify("X","Bye",2);task.delay(0.5,Cleanup) end);y=y+SC(38,46)
    sc.CanvasSize=UDim2.new(0,0,0,y+10)

    local obs=SC(36,44);local ob=Instance.new("TextButton",gui);ob.Text="X";ob.Size=UDim2.new(0,obs,0,obs);ob.Position=UDim2.new(1,-obs-10,0,SC(10,50));ob.BackgroundColor3=GC.acc;ob.TextColor3=Color3.new(1,1,1);ob.TextSize=SC(16,18);ob.Font=Enum.Font.GothamBlack;ob.AutoButtonColor=false;G.Crn(ob,obs/2);G.Stk(ob,GC.accG,1)
    ob.MouseButton1Click:Connect(function() CloseDD();CloseSub();main.Visible=not main.Visible end)
    G.MobBtns();swTab(tabs[1][1])
end

function G.Destroy() CloseDD();CloseSub();if S.mobFrame then pcall(function() S.mobFrame:Destroy() end);S.mobFrame=nil end;if S.gui then pcall(function() S.gui:Destroy() end);S.gui=nil end end

-- ═══════════════════════════════════════
-- MAIN LOOP
-- ═══════════════════════════════════════
local styleList={"Corner","Full","Glow","Cyber","Gradient"};local styleIdx=1

local function Loop()
    table.insert(S.conns,RunService.RenderStepped:Connect(function(dt) pcall(function()
        Cam=WS.CurrentCamera;if not S.me.alive then S.tgt.part=nil;S.tgt.plr=nil;S.tgt.vis=false end
        if Cfg.On and S.me.alive then local part,plr=T.Find();if part and plr then S.tgt.part=part;S.tgt.plr=plr;S.tgt.name=plr.Name;S.tgt.dist=(Cam.CFrame.Position-part.Position).Magnitude;S.tgt.vis=true;local ch=Res.Get(plr);local hp,mhp=Res.HP(ch);S.tgt.hp=hp;S.tgt.mhp=mhp;if Cfg.AimMode=="silent"and Cfg.Silent.On then S.aim.silentPos=A.Pred(part) elseif Cfg.AimMode=="normal" then A.Smooth(part) elseif Cfg.AimMode=="snap" then local tcf=A.GetCF(part);if tcf then Cam.CFrame=tcf end end else if not S.tgt.plr then S.tgt.part=nil;S.tgt.name="";S.tgt.lastPos=nil;S.tgt.sVel=Vector3.zero;S.aim.silentPos=nil end;S.tgt.vis=false end else S.aim.silentPos=nil end
        Flk.Update();Fire.Update();HUD.Update()
        if Cfg.ESP.On then E.UpdateAll(dt) else for _,tp in ipairs(Players:GetPlayers()) do local o=S.espC[tp];if o then E.HideAll(o) end end end
        WH.UpdateAll();Exp.TP();Exp.Spin(dt);Exp.Speed(dt)
    end) end))
end

local function Input()
    if not IsMobile then table.insert(S.conns,UIS.InputBegan:Connect(function(i,g) if g then return end
        if i.KeyCode==Enum.KeyCode.F1 then Cfg.On=not Cfg.On;if not Cfg.On then S.tgt.part=nil;S.tgt.plr=nil;S.tgt.vis=false;if S.aim.flickOn and S.aim.flickCF then Cam.CFrame=S.aim.flickCF end;S.aim.flickOn=false;S.aim.flickCF=nil end;Notify("X",Cfg.On and"AIM ON"or"AIM OFF")
        elseif i.KeyCode==Enum.KeyCode.F2 then Cfg.ESP.On=not Cfg.ESP.On;if not Cfg.ESP.On then E.DelAll() end;Notify("X",Cfg.ESP.On and"ESP ON"or"ESP OFF")
        elseif i.KeyCode==Enum.KeyCode.F3 then Cfg.WH.On=not Cfg.WH.On;if not Cfg.WH.On then WH.KillAll() end;Notify("X",Cfg.WH.On and"WH ON"or"WH OFF")
        elseif i.KeyCode==Enum.KeyCode.F4 then styleIdx=styleIdx%#styleList+1;Cfg.ESP.Style=styleList[styleIdx];Notify("X","Style: "..Cfg.ESP.Style)
        elseif i.KeyCode==Enum.KeyCode.RightShift then if S.gui then local mf=S.gui:FindFirstChild("MainFrame");if mf then CloseDD();CloseSub();mf.Visible=not mf.Visible end end end
    end)) end
end

local function Cleanup()
    if S.aim.flickOn and S.aim.flickCF then Cam.CFrame=S.aim.flickCF end;pcall(function() if mouse1release then mouse1release() end end)
    Exp.RSpin();Exp.RTP();for _,c in ipairs(S.conns) do pcall(function() c:Disconnect() end) end;S.conns={}
    E.DelAll();WH.KillAll();HUD.Destroy();G.Destroy();_G.XenoLoaded=false;_G.XenoCleanup=nil
end

_G.XenoCleanup=Cleanup
table.insert(S.conns,Players.PlayerRemoving:Connect(function(p) E.Del(p);WH.Kill(p) end))
SetupChar();task.wait(0.5);Fire.Init();HUD.Create()
if Exec.canSilent and Cfg.Silent.On then Sil.Install() end
G.Create();Input();Loop()
Notify("Xeno v9.1",Cfg.AimMode:upper().." | "..(IsMobile and"Mobile"or"PC").." | "..Cfg.ESP.Style.." | Arena:"..tostring(Cfg.AC.DeepScan),5)

end)
if not ok then pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="XENO ERROR",Text=tostring(err):sub(1,100),Duration=10}) end);warn("[XENO]",err) end
