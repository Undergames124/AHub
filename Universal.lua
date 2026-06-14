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
    local SC = function(p, m) return IsMobile and m or p end

    local Exec = { name = "Unknown", canSilent = false, canCoreGui = false }
    pcall(function() if identifyexecutor then Exec.name = identifyexecutor() elseif getexecutorname then Exec.name = getexecutorname() end end)
    pcall(function() local t = Instance.new("Folder"); t.Parent = CoreGui; t:Destroy(); Exec.canCoreGui = true end)
    local hasHM = typeof(hookmetamethod) == "function"
    local hasNC = typeof(getnamecallmethod) == "function"
    Exec.canSilent = hasHM and hasNC

    local drawOK = false
    pcall(function() local t = Drawing.new("Line"); t.Visible = false; t:Remove(); drawOK = true end)

    local DEAD = false
    local function Notify(t, m, d) pcall(function() StarterGui:SetCore("SendNotification", { Title = t, Text = m or "", Duration = d or 4 }) end) end
    local function SafeP() if Exec.canCoreGui then return CoreGui end; if typeof(gethui) == "function" then local o, r = pcall(gethui); if o and r then return r end end; return Plr:WaitForChild("PlayerGui") end
    local function Protect(g) if typeof(syn) == "table" and syn.protect_gui then pcall(syn.protect_gui, g) end; if typeof(protect_gui) == "function" then pcall(protect_gui, g) end end
    local function Kill(d) if not d then return end; pcall(function() d.Visible = false end); pcall(function() d:Remove() end); pcall(function() d:Destroy() end) end
    local function ND(t) if not drawOK then return nil end; local s, d = pcall(Drawing.new, t); if not s or not d then return nil end; pcall(function() d.Visible = false end); return d end

    Notify("XENO", "Loading v10.2 opt...", 3)

    local Cfg = {
        On = false, AimMode = Exec.canSilent and "silent" or "normal",
        Part = "Head", Priority = "FOV", Sticky = true, StickyTime = 3, Aim360 = false,
        FOV = { On = true, R = SC(120, 200), Show = true, Color = Color3.fromRGB(90, 130, 255), Trans = 0.7, Thick = 1.5 },
        Smooth = { On = true, Amt = SC(0.15, 0.25) },
        Pred = { On = false, Factor = 0.12, VelSmooth = 0.3 },
        Silent = { On = Exec.canSilent, Chance = 100, Use360 = false },
        Flick = { On = not Exec.canSilent, Restore = true, Speed = 1.0, MobileAuto = IsMobile },
        TB = { On = false, Delay = 0.08, TBFOV = 60 },
        ESP = {
            On = false, MaxDist = 1500, ShowTeam = false,
            EBox = Color3.fromRGB(255, 50, 50), TBox = Color3.fromRGB(50, 255, 50),
            EName = Color3.fromRGB(255, 255, 255), TName = Color3.fromRGB(255, 255, 255),
            Outline = Color3.fromRGB(0, 0, 0),
            HPLo = Color3.fromRGB(255, 50, 50), HPMid = Color3.fromRGB(255, 200, 50), HPHi = Color3.fromRGB(80, 220, 120),
            HPBg = Color3.fromRGB(25, 25, 25), TracerClr = Color3.fromRGB(255, 80, 80), HeadDotClr = Color3.fromRGB(255, 255, 255),
            Box = { On = true, Style = "Corner", W = 1, CL = 0.25, Outline = true },
            Name = { On = true, Sz = SC(13, 11), Fmt = "Name+Dist" },
            HP = { On = true, W = 3, Off = 5 },
            Tracer = { On = false, W = 1.5 },
            HeadDot = { On = false, Rad = SC(3, 4) },
        },
        WH = { On = false, Fill = Color3.fromRGB(255, 0, 0), FT = 0.5, Out = Color3.fromRGB(255, 255, 255), OT = 0, ShowTeam = false },
        Checks = { Team = true, Wall = true },
        Limits = { MaxD = 800, MaxA = SC(75, 90), MinD = 5 },
        TP = { On = false, Dist = 30 },
        Spin = { On = false, Spd = 10 },
        Speed = { On = false, Mult = 1.5 },
    }

    local S = {
        tgt = { part = nil, plr = nil, dist = 0, hp = 0, mhp = 0, name = "", lastT = 0, vis = false, lastPos = nil, sVel = Vector3.zero },
        me = { char = nil, hum = nil, root = nil, alive = false },
        aim = { silentPos = nil, hooked = false, flickOn = false, flickCF = nil },
        fire = { last = 0, method = "none" }, draw = {}, espC = {}, whC = {},
        conns = {}, gui = nil, mobFrame = nil, spinAng = 0, frame = 0, espBatch = 0,
        origMaxZoom = nil, origMinZoom = nil, origCamMode = nil,
        teamCache = {}, teamCacheTime = 0
    }

    -- оптимизированный W2S с кэшированием камеры
    local function W2S(pos)
        local cam = Cam
        if not cam then cam = WS.CurrentCamera; Cam = cam end
        if not cam then return nil, false end
        local vp = cam:WorldToViewportPoint(pos)
        if vp.Z <= 0 then return nil, false end
        return Vector2.new(vp.X, vp.Y), true
    end

    local function ScrC()
        local cam = Cam
        if not cam then return Vector2.new(960, 540) end
        local vp = cam.ViewportSize
        return Vector2.new(vp.X / 2, vp.Y / 2)
    end

    local centerCache = Vector2.new(960, 540)
    local lastViewport = Vector2.new(1920, 1080)
    local function UpdateCenter()
        local cam = Cam
        if not cam then return end
        local vp = cam.ViewportSize
        if vp ~= lastViewport then
            lastViewport = vp
            centerCache = Vector2.new(vp.X / 2, vp.Y / 2)
        end
        return centerCache
    end

    local function SDist(wp)
        local sp, on = W2S(wp)
        if not sp or not on then return 9999 end
        return (sp - UpdateCenter()).Magnitude
    end

    -- градиент HP предрасчёт (без аллокаций в кадре)
    local hpGrad = {}
    for i = 0, 100 do
        local pct = i / 100
        if pct > 0.6 then
            local t = (pct - 0.6) / 0.4
            hpGrad[i] = Color3.new(
                Cfg.ESP.HPMid.R + (Cfg.ESP.HPHi.R - Cfg.ESP.HPMid.R) * t,
                Cfg.ESP.HPMid.G + (Cfg.ESP.HPHi.G - Cfg.ESP.HPMid.G) * t,
                Cfg.ESP.HPMid.B + (Cfg.ESP.HPHi.B - Cfg.ESP.HPMid.B) * t
            )
        else
            local t = pct / 0.6
            hpGrad[i] = Color3.new(
                Cfg.ESP.HPLo.R + (Cfg.ESP.HPMid.R - Cfg.ESP.HPLo.R) * t,
                Cfg.ESP.HPLo.G + (Cfg.ESP.HPMid.G - Cfg.ESP.HPLo.G) * t,
                Cfg.ESP.HPLo.B + (Cfg.ESP.HPMid.B - Cfg.ESP.HPLo.B) * t
            )
        end
    end
    local function HPCol(pct) return hpGrad[math.floor(pct * 100)] end

    local function TeamEq(a, b)
        if not a or not b then return false end
        local s, t1 = pcall(function() return a.Team end)
        local s2, t2 = pcall(function() return b.Team end)
        return s and s2 and t1 and t2 and t1 == t2
    end

    local function GetHP(ch)
        if not ch then return 0, 100 end
        local h = ch:FindFirstChildOfClass("Humanoid")
        return h and h.Health or 0, h and h.MaxHealth or 100
    end

    local function GetRoot(ch)
        if not ch then return nil end
        return ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso") or ch.PrimaryPart
    end

    local function CanSee(part, myCh)
        if not part or not myCh then return true end
        local cam = Cam
        if not cam then return true end
        local origin = cam.CFrame.Position
        local tp = part.Position
        local dir = tp - origin
        local dist = dir.Magnitude
        if dist < 3 then return true end
        local par = RaycastParams.new()
        par.FilterType = Enum.RaycastFilterType.Exclude
        local tCh = part.Parent
        par.FilterDescendantsInstances = tCh and { myCh, tCh } or { myCh }
        par.RespectCanCollide = false
        local r = WS:Raycast(origin, dir.Unit * (dist - 1), par)
        if not r then return true end
        return r.Instance.Transparency >= 0.5 or not r.Instance.CanCollide
    end

    local function SetupChar()
        local function onC(ch)
            if DEAD then return end
            S.me.char = ch; S.me.alive = false; S.tgt.part = nil; S.tgt.plr = nil
            S.me.hum = ch:WaitForChild("Humanoid", 10)
            S.me.root = ch:WaitForChild("HumanoidRootPart", 10)
            if not S.me.hum or not S.me.root then return end
            S.me.alive = true
            S.me.hum.Died:Connect(function() S.me.alive = false; S.tgt.part = nil; S.tgt.plr = nil end)
        end
        if Plr.Character then task.spawn(onC, Plr.Character) end
        table.insert(S.conns, Plr.CharacterAdded:Connect(onC))
    end

    local function GetBone(ch)
        if not ch then return nil end
        return ch:FindFirstChild(Cfg.Part) or ch:FindFirstChild("Head") or GetRoot(ch)
    end

    local function IsValid(ch, tp)
        if not ch or not ch.Parent then return false end
        local rp = GetRoot(ch); if not rp then return false end
        if GetHP(ch) <= 0 then return false end
        if Cfg.Checks.Team and tp and TeamEq(Plr, tp) then return false end
        if S.me.root then
            local d = (rp.Position - S.me.root.Position).Magnitude
            if d > Cfg.Limits.MaxD or d < Cfg.Limits.MinD then return false end
        end
        return true
    end

    local function UpdateTeamCache()
        if tick() - S.teamCacheTime > 0.5 then
            S.teamCacheTime = tick()
            for _, p in ipairs(Players:GetPlayers()) do
                S.teamCache[p.UserId] = TeamEq(Plr, p)
            end
        end
    end

    -- единый FindTarget с минимальным кол-вом W2S
    local function FindTarget()
        if not S.me.alive or not Cam then return nil, nil end
        local is360 = Cfg.Aim360 or (Cfg.AimMode == "silent" and Cfg.Silent.Use360)
        local center = UpdateCenter()
        local camPos = Cam.CFrame.Position
        local myChar = S.me.char
        local maxAng = Cfg.Limits.MaxA
        local fovOn = Cfg.FOV.On
        local fovR = Cfg.FOV.R
        local wallCheck = Cfg.Checks.Wall
        local sticky = Cfg.Sticky
        local stickyTime = Cfg.StickyTime

        -- Sticky логика без лишних вызовов
        if sticky and S.tgt.part and S.tgt.plr then
            local ch = S.tgt.plr.Character
            if ch and ch.Parent and GetHP(ch) > 0 then
                local p = GetBone(ch)
                if p then
                    local sp, on = W2S(p.Position)
                    local inFOV = true
                    if fovOn and not is360 and sp then
                        local distToCenter = (sp - center).Magnitude
                        inFOV = distToCenter <= fovR * 1.5
                    end
                    local vis = not wallCheck or CanSee(p, myChar)
                    if (is360 or (on and inFOV)) and vis then
                        S.tgt.part = p; S.tgt.lastT = tick(); S.tgt.vis = true; return p, S.tgt.plr
                    elseif not vis then
                        S.tgt.part = nil; S.tgt.plr = nil; S.tgt.vis = false
                    elseif tick() - S.tgt.lastT > stickyTime then
                        S.tgt.part = nil; S.tgt.plr = nil; S.tgt.vis = false
                    else
                        S.tgt.vis = false; return nil, nil
                    end
                else
                    S.tgt.part = nil; S.tgt.plr = nil; S.tgt.vis = false
                end
            else
                S.tgt.part = nil; S.tgt.plr = nil; S.tgt.vis = false
            end
        end

        local bestPart, bestPlr, bestScore = nil, nil, -9999
        for _, tp in ipairs(Players:GetPlayers()) do
            if tp == Plr then continue end
            local ch = tp.Character
            if not IsValid(ch, tp) then continue end
            local p = GetBone(ch); if not p then continue end
            local sp, on = W2S(p.Position)
            if not is360 and not on then continue end
            local screenDist = (sp - center).Magnitude
            if fovOn and not is360 and screenDist > fovR then continue end
            if not is360 then
                local dir = p.Position - camPos
                if dir.Magnitude > 0.001 then
                    local ang = math.deg(math.acos(math.clamp(Cam.CFrame.LookVector:Dot(dir.Unit), -1, 1)))
                    if ang > maxAng then continue end
                end
            end
            if wallCheck and not CanSee(p, myChar) then continue end
            local score = 10000 - screenDist
            if score > bestScore then
                bestScore = score
                bestPart = p
                bestPlr = tp
            end
        end
        if bestPart then S.tgt.vis = true else S.tgt.vis = false end
        return bestPart, bestPlr
    end

    local function PredPos(p)
        if not Cfg.Pred.On or not p then return p and p.Position or Vector3.zero end
        local cur = p.Position
        if S.tgt.lastPos then
            S.tgt.sVel = S.tgt.sVel + ((cur - S.tgt.lastPos) * 60 - S.tgt.sVel) * Cfg.Pred.VelSmooth
        end
        S.tgt.lastPos = cur
        return cur + S.tgt.sVel * Cfg.Pred.Factor
    end

    local function MakeCF(p)
        if not p or not Cam then return nil end
        local t = PredPos(p)
        local c = Cam.CFrame.Position
        local d = t - c
        if d.Magnitude < 0.001 then return nil end
        return CFrame.lookAt(c, c + d.Unit)
    end

    local function ApplyAim(p)
        if not p or not Cam then return end
        local tcf = MakeCF(p)
        if not tcf then return end
        if Cfg.AimMode == "snap" then
            Cam.CFrame = tcf
        elseif Cfg.AimMode == "normal" then
            if Cfg.Smooth.On then
                Cam.CFrame = Cam.CFrame:Lerp(tcf, math.clamp(Cfg.Smooth.Amt, 0.01, 1))
            else
                Cam.CFrame = tcf
            end
        end
    end

    local Sil = {}
    function Sil.Should() return not DEAD and Cfg.On and Cfg.Silent.On and Cfg.AimMode == "silent" and S.tgt.part and (S.tgt.vis or Cfg.Silent.Use360 or Cfg.Aim360) end
    function Sil.Pos() return S.tgt.part and PredPos(S.tgt.part) or nil end
    function Sil.Install()
        if S.aim.hooked or not Exec.canSilent then return end
        local wrap = newcclosure or function(f) return f end
        pcall(function()
            local old; old = hookmetamethod(game, "__namecall", wrap(function(self, ...)
                if DEAD then return old(self, ...) end
                local m = getnamecallmethod()
                if Sil.Should() then
                    local tp = Sil.Pos()
                    if tp then
                        if m == "Raycast" and self == WS then
                            local args = { ... }
                            if #args >= 2 and typeof(args[1]) == "Vector3" then
                                local d = tp - args[1]; if d.Magnitude > 0.001 then d = d.Unit * 1000 end
                                return old(self, args[1], d, select(3, ...))
                            end
                        end
                        if (m == "FindPartOnRay" or m == "FindPartOnRayWithIgnoreList" or m == "FindPartOnRayWithWhitelist") and self == WS then
                            local args = { ... }
                            if typeof(args[1]) == "Ray" then
                                local d = tp - args[1].Origin; if d.Magnitude > 0.001 then d = d.Unit * 1000 end
                                return old(self, Ray.new(args[1].Origin, d), select(2, ...))
                            end
                        end
                    end
                end
                return old(self, ...)
            end))
            S.aim.hooked = true
        end)
        pcall(function()
            local old; old = hookmetamethod(game, "__index", wrap(function(self, k)
                if DEAD then return old(self, k) end
                if Sil.Should() and self == Mouse then
                    local tp = Sil.Pos()
                    if tp then
                        if k == "Hit" then return CFrame.new(tp) end
                        if k == "Target" and S.tgt.part then return S.tgt.part end
                        if k == "UnitRay" then local d = tp - Cam.CFrame.Position; if d.Magnitude > 0.001 then return Ray.new(Cam.CFrame.Position, d.Unit) end end
                    end
                end
                return old(self, k)
            end))
        end)
    end

    local function FlickUpdate()
        if DEAD or Cfg.AimMode ~= "flick" or not Cfg.Flick.On then
            if S.aim.flickOn and S.aim.flickCF and Cfg.Flick.Restore and Cam then Cam.CFrame = S.aim.flickCF end
            S.aim.flickOn = false; return
        end
        local down = IsMobile and (Cfg.Flick.MobileAuto and S.tgt.vis) or (pcall(function() return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end))
        if type(down) ~= "boolean" then local _, r = pcall(function() return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end); down = r end
        if down and not S.aim.flickOn and Cfg.On and S.tgt.vis and S.tgt.part then
            S.aim.flickCF = Cam.CFrame; S.aim.flickOn = true
        elseif down and S.aim.flickOn then
            if S.tgt.part and S.tgt.vis then
                local tcf = MakeCF(S.tgt.part)
                if tcf then Cam.CFrame = Cfg.Flick.Speed >= 1 and tcf or Cam.CFrame:Lerp(tcf, Cfg.Flick.Speed) end
            else if S.aim.flickCF and Cfg.Flick.Restore then Cam.CFrame = S.aim.flickCF end; S.aim.flickOn = false end
        elseif not down and S.aim.flickOn then
            if S.aim.flickCF and Cfg.Flick.Restore then Cam.CFrame = S.aim.flickCF end; S.aim.flickOn = false
        end
    end

    local function FireInit()
        S.fire.method = "none"
        if typeof(mouse1press) == "function" then S.fire.method = "m1"; return end
        pcall(function() game:GetService("VirtualInputManager"); S.fire.method = "vim" end)
    end
    local function FireClick()
        if S.fire.method == "m1" then
            pcall(function() mouse1press(); task.delay(0.05, function() pcall(mouse1release) end) end)
            return true
        elseif S.fire.method == "vim" then
            pcall(function()
                local v = game:GetService("VirtualInputManager")
                v:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, true, game, 0)
                task.delay(0.05, function() pcall(function() v:SendMouseButtonEvent(Mouse.X, Mouse.Y, 0, false, game, 0) end) end)
            end)
            return true
        end
        return false
    end
    local function FireUpdate()
        if DEAD or not Cfg.TB.On or not Cfg.On or S.fire.method == "none" then return end
        if tick() - S.fire.last < Cfg.TB.Delay then return end
        local center = UpdateCenter()
        for _, tp in ipairs(Players:GetPlayers()) do
            if tp == Plr then continue end
            local ch = tp.Character; if not ch or not ch.Parent then continue end
            if Cfg.Checks.Team and TeamEq(Plr, tp) then continue end
            if GetHP(ch) <= 0 then continue end
            local head = ch:FindFirstChild("Head"); if not head then continue end
            local sp, on = W2S(head.Position)
            if on and (sp - center).Magnitude <= Cfg.TB.TBFOV then
                if not Cfg.Checks.Wall or CanSee(head, S.me.char) then
                    if FireClick() then S.fire.last = tick() end
                    return
                end
            end
        end
    end

    local function TPUpdate() if Cfg.TP.On then pcall(function() Plr.CameraMaxZoomDistance = Cfg.TP.Dist; Plr.CameraMinZoomDistance = 0.5 end) else pcall(function() Plr.CameraMaxZoomDistance = 10; Plr.CameraMinZoomDistance = 0.5 end) end end

    local function SpinUpdate(dt)
        if DEAD or not Cfg.Spin.On or not S.me.alive or not S.me.root then return end
        S.spinAng = (S.spinAng + Cfg.Spin.Spd * dt * 60) % 360
        pcall(function() S.me.root.CFrame = CFrame.new(S.me.root.Position) * CFrame.Angles(0, math.rad(S.spinAng), 0) end)
    end

    local function SpeedUpdate(dt)
        if DEAD or not Cfg.Speed.On or not S.me.root or not S.me.alive or not S.me.hum then return end
        pcall(function()
            local md = S.me.hum.MoveDirection
            if md.Magnitude < 0.1 then return end
            S.me.root.CFrame = S.me.root.CFrame + md.Unit * S.me.hum.WalkSpeed * (Cfg.Speed.Mult - 1) * dt
        end)
    end

    -- оптимизированный ESP рендер с минимальным количеством операций
    local E = {}
    function E.New(uid)
        if DEAD or S.espC[uid] or not drawOK then return end
        local o = {}
        o.box = ND("Square"); if o.box then pcall(function() o.box.Filled = false end) end
        o.boxO = ND("Square"); if o.boxO then pcall(function() o.boxO.Filled = false; o.boxO.Color = Cfg.ESP.Outline end) end
        o.cL = {}; o.cO = {}
        for i = 1, 8 do o.cL[i] = ND("Line"); o.cO[i] = ND("Line") end
        o.name = ND("Text"); if o.name then pcall(function() o.name.Center = true; o.name.Outline = true; o.name.Size = Cfg.ESP.Name.Sz end) end
        o.hpBg = ND("Square"); if o.hpBg then pcall(function() o.hpBg.Filled = true end) end
        o.hpFill = ND("Square"); if o.hpFill then pcall(function() o.hpFill.Filled = true end) end
        o.tracer = ND("Line")
        o.hdot = ND("Circle"); if o.hdot then pcall(function() o.hdot.Filled = true; o.hdot.NumSides = 10 end) end
        S.espC[uid] = o
    end
    function E.Hide(o)
        if not o then return end
        for _, k in ipairs({ "box", "boxO", "name", "hpBg", "hpFill", "tracer", "hdot" }) do if o[k] then pcall(function() o[k].Visible = false end) end end
        if o.cL then for i = 1, 8 do if o.cL[i] then pcall(function() o.cL[i].Visible = false end) end; if o.cO[i] then pcall(function() o.cO[i].Visible = false end) end end end
    end
    function E.Del(uid)
        local o = S.espC[uid]; if not o then return end; E.Hide(o)
        for _, k in ipairs({ "box", "boxO", "name", "hpBg", "hpFill", "tracer", "hdot" }) do Kill(o[k]) end
        if o.cL then for i = 1, 8 do Kill(o.cL[i]); Kill(o.cO[i]) end end
        S.espC[uid] = nil
    end
    function E.DelAll() for uid in pairs(S.espC) do E.Del(uid) end end
    function E.Render(uid, ch, dname, isTeam)
        local o = S.espC[uid]; if not o then return end
        if not ch or not ch.Parent then E.Hide(o); return end
        local rp = GetRoot(ch); if not rp then E.Hide(o); return end
        local hp, mhp = GetHP(ch); if hp <= 0 then E.Hide(o); return end
        if isTeam and not Cfg.ESP.ShowTeam then E.Hide(o); return end
        local dist = S.me.root and (rp.Position - S.me.root.Position).Magnitude or 0
        if dist > Cfg.ESP.MaxDist then E.Hide(o); return end
        local head = ch:FindFirstChild("Head")
        local topY = head and (head.Position.Y + 1) or (rp.Position.Y + 3)
        local botY = rp.Position.Y - 3
        local topSP, topOn = W2S(Vector3.new(rp.Position.X, topY, rp.Position.Z))
        if not topOn or not topSP then E.Hide(o); return end
        local botSP, botOn = W2S(Vector3.new(rp.Position.X, botY, rp.Position.Z))
        if not botOn or not botSP then E.Hide(o); return end
        local h = math.abs(botSP.Y - topSP.Y)
        if h < 3 then E.Hide(o); return end
        local w = h * 0.6; local bx = topSP.X - w / 2; local by = topSP.Y
        local vp = Cam.ViewportSize
        if bx < -200 or bx > vp.X + 200 or by < -200 or by > vp.Y + 200 then E.Hide(o); return end
        local boxClr = isTeam and Cfg.ESP.TBox or Cfg.ESP.EBox
        local nameClr = isTeam and Cfg.ESP.TName or Cfg.ESP.EName
        local distI = math.floor(dist)
        if Cfg.ESP.Box.On then
            if Cfg.ESP.Box.Style == "Full" then
                for i = 1, 8 do pcall(function() o.cL[i].Visible = false end); pcall(function() o.cO[i].Visible = false end) end
                pcall(function() o.box.Size = Vector2.new(w, h); o.box.Position = Vector2.new(bx, by); o.box.Color = boxClr; o.box.Thickness = Cfg.ESP.Box.W; o.box.Visible = true end)
                if Cfg.ESP.Box.Outline then
                    pcall(function() o.boxO.Size = Vector2.new(w + 4, h + 4); o.boxO.Position = Vector2.new(bx - 2, by - 2); o.boxO.Color = Cfg.ESP.Outline; o.boxO.Thickness = Cfg.ESP.Box.W + 2; o.boxO.Visible = true end)
                else pcall(function() o.boxO.Visible = false end) end
            else
                pcall(function() o.box.Visible = false end); pcall(function() o.boxO.Visible = false end)
                local cl = math.max(w, h) * Cfg.ESP.Box.CL
                local pts = {
                    { bx, by, bx + cl, by }, { bx, by, bx, by + cl },
                    { bx + w, by, bx + w - cl, by }, { bx + w, by, bx + w, by + cl },
                    { bx, by + h, bx + cl, by + h }, { bx, by + h, bx, by + h - cl },
                    { bx + w, by + h, bx + w - cl, by + h }, { bx + w, by + h, bx + w, by + h - cl }
                }
                for i = 1, 8 do
                    pcall(function()
                        o.cL[i].From = Vector2.new(pts[i][1], pts[i][2]); o.cL[i].To = Vector2.new(pts[i][3], pts[i][4])
                        o.cL[i].Color = boxClr; o.cL[i].Thickness = Cfg.ESP.Box.W; o.cL[i].Visible = true
                    end)
                    if Cfg.ESP.Box.Outline then
                        pcall(function()
                            o.cO[i].From = o.cL[i].From; o.cO[i].To = o.cL[i].To
                            o.cO[i].Color = Cfg.ESP.Outline; o.cO[i].Thickness = Cfg.ESP.Box.W + 2; o.cO[i].Visible = true
                        end)
                    else pcall(function() o.cO[i].Visible = false end) end
                end
            end
        else
            pcall(function() o.box.Visible = false end); pcall(function() o.boxO.Visible = false end)
            for i = 1, 8 do pcall(function() o.cL[i].Visible = false end); pcall(function() o.cO[i].Visible = false end) end
        end
        if Cfg.ESP.Name.On and o.name then
            local txt = Cfg.ESP.Name.Fmt == "Name+Dist" and (dname .. " [" .. distI .. "m]") or dname
            pcall(function() o.name.Text = txt; o.name.Color = nameClr; o.name.Size = Cfg.ESP.Name.Sz; o.name.Position = Vector2.new(bx + w / 2, by - Cfg.ESP.Name.Sz - 2); o.name.Visible = true end)
        else pcall(function() o.name.Visible = false end) end
        if Cfg.ESP.HP.On then
            local pct = math.clamp(hp / math.max(mhp, 1), 0, 1)
            local hc = HPCol(pct); local bW = Cfg.ESP.HP.W; local off = Cfg.ESP.HP.Off
            local bgX = bx - off - bW - 1; local fH = math.max(h * pct, 1)
            pcall(function() o.hpBg.Position = Vector2.new(bgX, by - 1); o.hpBg.Size = Vector2.new(bW + 2, h + 2); o.hpBg.Color = Cfg.ESP.HPBg; o.hpBg.Visible = true end)
            pcall(function() o.hpFill.Position = Vector2.new(bgX + 1, by + h - fH); o.hpFill.Size = Vector2.new(bW, fH); o.hpFill.Color = hc; o.hpFill.Visible = true end)
        else pcall(function() o.hpBg.Visible = false end); pcall(function() o.hpFill.Visible = false end) end
        if Cfg.ESP.Tracer.On and o.tracer then
            pcall(function() o.tracer.From = Vector2.new(vp.X / 2, vp.Y); o.tracer.To = botSP; o.tracer.Color = Cfg.ESP.TracerClr; o.tracer.Thickness = Cfg.ESP.Tracer.W; o.tracer.Visible = true end)
        else pcall(function() o.tracer.Visible = false end) end
        if Cfg.ESP.HeadDot.On and head and o.hdot then
            local sp, on = W2S(head.Position)
            if sp and on then pcall(function() o.hdot.Position = sp; o.hdot.Radius = Cfg.ESP.HeadDot.Rad; o.hdot.Color = Cfg.ESP.HeadDotClr; o.hdot.Visible = true end)
            else pcall(function() o.hdot.Visible = false end) end
        else pcall(function() o.hdot.Visible = false end) end
    end

    local playerList = {}
    local plTick = 0
    local function RefreshPL() if tick() - plTick < 0.5 then return end; plTick = tick(); playerList = Players:GetPlayers(); UpdateTeamCache() end

    function E.UpdateBatch(dt)
        if DEAD then return end; RefreshPL()
        local count = #playerList; if count <= 1 then return end
        local perFrame = math.max(math.ceil((count - 1) / 3), 1)
        local start = S.espBatch; local done = 0
        for i = 1, count do
            if done >= perFrame then break end
            local idx = ((start + i - 2) % count) + 1
            local tp = playerList[idx]; if not tp or tp == Plr then continue end
            done = done + 1
            local uid = tp.UserId; local ch = tp.Character
            if not ch or not ch.Parent or GetHP(ch) <= 0 then
                if S.espC[uid] then E.Hide(S.espC[uid]) end
                continue
            end
            if not S.espC[uid] then E.New(uid) end
            E.Render(uid, ch, tp.DisplayName or tp.Name, S.teamCache[uid] or TeamEq(Plr, tp))
        end
        S.espBatch = (start + done) % math.max(count - 1, 1)
        if S.frame % 30 == 0 then
            for uid in pairs(S.espC) do
                local found = false
                for _, tp in ipairs(playerList) do if tp.UserId == uid then found = true; break end end
                if not found then E.Del(uid) end
            end
        end
    end

    local WH = {}
    function WH.Make(uid, ch, isTeam)
        if DEAD or S.whC[uid] or not ch then return end
        local hl = Instance.new("Highlight")
        hl.Adornee = ch
        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        hl.FillColor = isTeam and Color3.fromRGB(0, 255, 0) or Cfg.WH.Fill
        hl.OutlineColor = Cfg.WH.Out
        hl.FillTransparency = Cfg.WH.FT
        hl.OutlineTransparency = Cfg.WH.OT
        pcall(function() hl.Parent = ch end)
        S.whC[uid] = hl
    end
    function WH.Kill(uid) if S.whC[uid] then pcall(function() S.whC[uid]:Destroy() end) end; S.whC[uid] = nil end
    function WH.KillAll() for k in pairs(S.whC) do pcall(function() S.whC[k]:Destroy() end) end; S.whC = {} end
    function WH.Update()
        if DEAD or not Cfg.WH.On then WH.KillAll(); return end
        local active = {}
        for _, tp in ipairs(playerList) do
            if tp == Plr then continue end
            local uid = tp.UserId; local ch = tp.Character; local isTeam = S.teamCache[uid] or TeamEq(Plr, tp)
            local show = ch and ch.Parent and GetHP(ch) > 0
            if show and isTeam and not Cfg.WH.ShowTeam then show = false end
            if show then active[uid] = true; if not S.whC[uid] then WH.Make(uid, ch, isTeam) end else WH.Kill(uid) end
        end
        for k in pairs(S.whC) do if not active[k] then WH.Kill(k) end end
    end

    local HUD = {}
    function HUD.Create()
        HUD.Destroy(); if not drawOK then return end
        S.draw.fov = ND("Circle"); pcall(function() S.draw.fov.Filled = false; S.draw.fov.NumSides = 40 end)
        S.draw.line = ND("Line")
        S.draw.dot = ND("Circle"); pcall(function() S.draw.dot.Filled = true; S.draw.dot.NumSides = 10 end)
        S.draw.st = ND("Text"); pcall(function() S.draw.st.Center = false; S.draw.st.Outline = true; S.draw.st.Size = SC(14, 12); S.draw.st.Position = Vector2.new(10, SC(10, 40)); S.draw.st.Visible = true end)
    end
    function HUD.Update()
        if DEAD or not drawOK then return end
        local c = UpdateCenter(); local d = S.draw
        if d.fov then pcall(function() d.fov.Position = c; d.fov.Radius = Cfg.FOV.R; d.fov.Color = Cfg.FOV.Color; d.fov.Transparency = Cfg.FOV.Trans; d.fov.Thickness = Cfg.FOV.Thick; d.fov.Visible = Cfg.On and Cfg.FOV.On and Cfg.FOV.Show end) end
        if d.st then
            local m = ({ normal = "AIM", snap = "SNAP", flick = "FLICK", silent = "SILENT" })[Cfg.AimMode] or "?"
            local t = "XENO " .. (Cfg.On and "[" .. m .. "]" or "[OFF]")
            if S.tgt.part and Cfg.On then t = t .. string.format(" | %s %.0fHP", S.tgt.name, S.tgt.hp) end
            pcall(function() d.st.Text = t; d.st.Color = Cfg.On and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100) end)
        end
        if Cfg.On and S.tgt.part and S.tgt.vis then
            local sp, on = W2S(S.tgt.part.Position)
            if sp and on then
                pcall(function() d.line.From = c; d.line.To = sp; d.line.Color = Color3.new(1, 1, 1); d.line.Thickness = 1.5; d.line.Visible = true end)
                pcall(function() d.dot.Position = sp; d.dot.Color = Color3.fromRGB(255, 50, 50); d.dot.Radius = SC(5, 8); d.dot.Visible = true end)
            else pcall(function() d.line.Visible = false end); pcall(function() d.dot.Visible = false end) end
        else pcall(function() d.line.Visible = false end); pcall(function() d.dot.Visible = false end) end
    end
    function HUD.Destroy() for _, dr in pairs(S.draw) do Kill(dr) end; S.draw = {} end

    local function Cleanup()
        DEAD = true; task.wait(0.05)
        pcall(function() if S.aim.flickOn and S.aim.flickCF and Cam then Cam.CFrame = S.aim.flickCF end end)
        for _, c in ipairs(S.conns) do pcall(function() c:Disconnect() end) end; S.conns = {}
        pcall(E.DelAll); pcall(WH.KillAll); pcall(HUD.Destroy)
        pcall(function() if S.mobFrame then S.mobFrame:Destroy() end; if S.gui then S.gui:Destroy() end end)
        _G.XenoLoaded = false; _G.XenoCleanup = nil
    end

    local MC = Color3.fromRGB(90, 130, 255)
    local BG = Color3.fromRGB(20, 20, 28)
    local PNL = Color3.fromRGB(30, 30, 38)
    local TXT = Color3.fromRGB(220, 220, 230)
    local TXTD = Color3.fromRGB(140, 140, 155)
    local TOFF = Color3.fromRGB(50, 50, 55)

    local function BuildGUI()
        pcall(function() if S.mobFrame then S.mobFrame:Destroy() end; if S.gui then S.gui:Destroy() end end)
        local gui = Instance.new("ScreenGui"); gui.Name = "X_" .. math.random(1e5, 9e5); gui.ResetOnSpawn = false; gui.DisplayOrder = 999; Protect(gui); gui.Parent = SafeP(); S.gui = gui
        Cam = WS.CurrentCamera
        local mW = SC(440, 360); local mH = SC(360, 300)
        local main = Instance.new("Frame", gui); main.Name = "MainFrame"; main.Size = UDim2.new(0, mW, 0, mH); main.Position = UDim2.new(0.5, -mW / 2, 0.5, -mH / 2); main.BackgroundColor3 = BG; main.BorderSizePixel = 0; main.Visible = false; main.Active = true; main.ClipsDescendants = true
        Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)
        Instance.new("UIStroke", main).Color = Color3.fromRGB(40, 40, 60)
        local tl = Instance.new("TextLabel", main); tl.Text = "XENO v10.2 opt"; tl.Size = UDim2.new(1, -50, 0, 28); tl.Position = UDim2.new(0, 10, 0, 4); tl.BackgroundTransparency = 1; tl.TextColor3 = MC; tl.Font = Enum.Font.GothamBold; tl.TextSize = SC(15, 13); tl.TextXAlignment = Enum.TextXAlignment.Left
        local xb = Instance.new("TextButton", main); xb.Text = "X"; xb.Size = UDim2.new(0, 24, 0, 24); xb.Position = UDim2.new(1, -30, 0, 4); xb.BackgroundColor3 = Color3.fromRGB(200, 50, 50); xb.TextColor3 = Color3.new(1, 1, 1); xb.TextSize = 11; xb.Font = Enum.Font.GothamBold; xb.AutoButtonColor = false; Instance.new("UICorner", xb).CornerRadius = UDim.new(0, 5)
        xb.MouseButton1Click:Connect(function() main.Visible = false end)
        local dragS, startP; main.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragS = i.Position; startP = main.Position; i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then dragS = nil end end) end end)
        table.insert(S.conns, UIS.InputChanged:Connect(function(i) if dragS and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then local d = i.Position - dragS; main.Position = UDim2.new(startP.X.Scale, startP.X.Offset + d.X, startP.Y.Scale, startP.Y.Offset + d.Y) end end))
        local tabBar = Instance.new("Frame", main); tabBar.Size = UDim2.new(1, 0, 0, 26); tabBar.Position = UDim2.new(0, 0, 0, 32); tabBar.BackgroundTransparency = 1
        local body = Instance.new("Frame", main); body.Size = UDim2.new(1, -12, 1, -65); body.Position = UDim2.new(0, 6, 0, 62); body.BackgroundTransparency = 1; body.ClipsDescendants = true
        local curTab, tabBtns = nil, {}
        local function mkTab(name, idx, tot)
            local btn = Instance.new("TextButton", tabBar); btn.Text = name; btn.Size = UDim2.new(1 / tot, 0, 1, 0); btn.Position = UDim2.new((idx - 1) / tot, 0, 0, 0); btn.BackgroundTransparency = 1; btn.TextColor3 = TXTD; btn.Font = Enum.Font.GothamBold; btn.TextSize = SC(10, 9); btn.AutoButtonColor = false
            local sf = Instance.new("ScrollingFrame", body); sf.Size = UDim2.new(1, 0, 1, 0); sf.BackgroundTransparency = 1; sf.ScrollBarThickness = 2; sf.ScrollBarImageColor3 = MC; sf.BorderSizePixel = 0; sf.Visible = false; sf.CanvasSize = UDim2.new(0, 0, 0, 0)
            local lay = Instance.new("UIListLayout", sf); lay.Padding = UDim.new(0, 4); lay.SortOrder = Enum.SortOrder.LayoutOrder
            lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sf.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 8) end)
            btn.MouseButton1Click:Connect(function() if curTab then curTab.Visible = false end; sf.Visible = true; curTab = sf; for _, b in pairs(tabBtns) do b.TextColor3 = TXTD end; btn.TextColor3 = MC end)
            tabBtns[name] = btn; return sf
        end
        local ord = 0
        local function nOrd() ord = ord + 1; return ord end
        local function mkTog(p, txt, t, k)
            local n = nOrd(); local f = Instance.new("Frame", p); f.Size = UDim2.new(1, 0, 0, SC(28, 34)); f.BackgroundColor3 = PNL; f.BorderSizePixel = 0; f.LayoutOrder = n; Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)
            local l = Instance.new("TextLabel", f); l.Text = txt; l.Size = UDim2.new(0.75, 0, 1, 0); l.Position = UDim2.new(0, 8, 0, 0); l.BackgroundTransparency = 1; l.TextColor3 = TXT; l.Font = Enum.Font.Gotham; l.TextSize = SC(10, 11); l.TextXAlignment = Enum.TextXAlignment.Left
            local sw = SC(18, 22); local dot = Instance.new("Frame", f); dot.Size = UDim2.new(0, sw, 0, sw); dot.Position = UDim2.new(1, -sw - 6, 0.5, -sw / 2); dot.BackgroundColor3 = t[k] and MC or TOFF; Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 4)
            local btn = Instance.new("TextButton", f); btn.Text = ""; btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1
            btn.MouseButton1Click:Connect(function() t[k] = not t[k]; dot.BackgroundColor3 = t[k] and MC or TOFF end)
        end
        local function mkSld(p, txt, mn, mx, t, k, fmt)
            local n = nOrd(); local f = Instance.new("Frame", p); f.Size = UDim2.new(1, 0, 0, SC(38, 44)); f.BackgroundColor3 = PNL; f.BorderSizePixel = 0; f.LayoutOrder = n; Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)
            local l = Instance.new("TextLabel", f); l.Text = string.format("%s: " .. (fmt or "%.1f"), txt, t[k]); l.Size = UDim2.new(1, -10, 0, 14); l.Position = UDim2.new(0, 6, 0, 2); l.BackgroundTransparency = 1; l.TextColor3 = TXT; l.TextSize = SC(9, 10); l.Font = Enum.Font.Gotham; l.TextXAlignment = Enum.TextXAlignment.Left
            local tr = Instance.new("Frame", f); tr.Size = UDim2.new(1, -12, 0, SC(5, 7)); tr.Position = UDim2.new(0, 6, 0, SC(22, 24)); tr.BackgroundColor3 = Color3.fromRGB(40, 40, 50); tr.BorderSizePixel = 0; Instance.new("UICorner", tr).CornerRadius = UDim.new(0, 3)
            local pct = math.clamp((t[k] - mn) / (mx - mn), 0, 1); local fl = Instance.new("Frame", tr); fl.Size = UDim2.new(pct, 0, 1, 0); fl.BackgroundColor3 = MC; fl.BorderSizePixel = 0; Instance.new("UICorner", fl).CornerRadius = UDim.new(0, 3)
            local dragging = false; local hb = Instance.new("TextButton", f); hb.Text = ""; hb.Size = UDim2.new(1, 4, 0, SC(18, 24)); hb.Position = UDim2.new(0, -2, 0, SC(16, 18)); hb.BackgroundTransparency = 1; hb.ZIndex = 5
            local function upd(ix) local ap, as = tr.AbsolutePosition.X, tr.AbsoluteSize.X; if as <= 0 then return end; local r = math.clamp((ix - ap) / as, 0, 1); t[k] = mn + r * (mx - mn); fl.Size = UDim2.new(r, 0, 1, 0); l.Text = string.format("%s: " .. (fmt or "%.1f"), txt, t[k]) end
            hb.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; upd(i.Position.X) end end)
            table.insert(S.conns, UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then upd(i.Position.X) end end))
            table.insert(S.conns, UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end))
        end
        local function mkDD(p, txt, opts, t, k)
            local n = nOrd(); local f = Instance.new("Frame", p); f.Size = UDim2.new(1, 0, 0, SC(28, 34)); f.BackgroundColor3 = PNL; f.BorderSizePixel = 0; f.LayoutOrder = n; Instance.new("UICorner", f).CornerRadius = UDim.new(0, 5)
            local l = Instance.new("TextLabel", f); l.Text = txt; l.Size = UDim2.new(0.45, 0, 1, 0); l.Position = UDim2.new(0, 8, 0, 0); l.BackgroundTransparency = 1; l.TextColor3 = TXT; l.TextSize = SC(10, 11); l.Font = Enum.Font.Gotham; l.TextXAlignment = Enum.TextXAlignment.Left
            local btn = Instance.new("TextButton", f); btn.Text = tostring(t[k]); btn.Size = UDim2.new(0.5, -6, 0.75, 0); btn.Position = UDim2.new(0.48, 0, 0.125, 0); btn.BackgroundColor3 = Color3.fromRGB(35, 35, 45); btn.TextColor3 = MC; btn.Font = Enum.Font.GothamBold; btn.TextSize = SC(10, 11); btn.AutoButtonColor = false; Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
            btn.MouseButton1Click:Connect(function() local idx = table.find(opts, t[k]) or 0; idx = idx % #opts + 1; t[k] = opts[idx]; btn.Text = tostring(opts[idx]) end)
        end
        local function mkSep(p, txt) local n = nOrd(); local f = Instance.new("Frame", p); f.Size = UDim2.new(1, 0, 0, 16); f.BackgroundTransparency = 1; f.LayoutOrder = n; local l = Instance.new("TextLabel", f); l.Text = "— " .. txt .. " —"; l.Size = UDim2.new(1, 0, 1, 0); l.BackgroundTransparency = 1; l.TextColor3 = MC; l.Font = Enum.Font.GothamBold; l.TextSize = 9 end

        local tA = mkTab("Aim", 1, 4); local tE = mkTab("ESP", 2, 4); local tW = mkTab("WH", 3, 4); local tM = mkTab("Misc", 4, 4)
        tabBtns["Aim"].TextColor3 = MC; tA.Visible = true; curTab = tA

        ord = 0; mkSep(tA, "AIMBOT"); mkTog(tA, "Enabled", Cfg, "On"); mkTog(tA, "360", Cfg, "Aim360")
        mkDD(tA, "Mode", Exec.canSilent and { "normal", "snap", "silent" } or { "normal", "snap", "flick" }, Cfg, "AimMode")
        mkDD(tA, "Bone", { "Head", "UpperTorso", "HumanoidRootPart" }, Cfg, "Part")
        mkTog(tA, "FOV Circle", Cfg.FOV, "On"); mkSld(tA, "FOV", 10, 500, Cfg.FOV, "R", "%.0f")
        mkTog(tA, "Smooth", Cfg.Smooth, "On"); mkSld(tA, "Amount", 0.01, 1, Cfg.Smooth, "Amt", "%.2f")
        mkTog(tA, "Prediction", Cfg.Pred, "On"); mkTog(tA, "Team Check", Cfg.Checks, "Team"); mkTog(tA, "Wall Check", Cfg.Checks, "Wall")
        mkSld(tA, "Max Dist", 50, 2000, Cfg.Limits, "MaxD", "%.0f")
        mkSep(tA, "TRIGGERBOT"); mkTog(tA, "TriggerBot", Cfg.TB, "On"); mkSld(tA, "TB FOV", 10, 200, Cfg.TB, "TBFOV", "%.0f"); mkSld(tA, "TB Delay", 0.01, 0.5, Cfg.TB, "Delay", "%.2fs")

        ord = 0; mkSep(tE, "ESP"); mkTog(tE, "Enabled", Cfg.ESP, "On"); mkTog(tE, "Show Team", Cfg.ESP, "ShowTeam"); mkSld(tE, "Max Dist", 100, 3000, Cfg.ESP, "MaxDist", "%.0f")
        mkSep(tE, "BOX"); mkTog(tE, "Box", Cfg.ESP.Box, "On"); mkDD(tE, "Style", { "Corner", "Full" }, Cfg.ESP.Box, "Style"); mkTog(tE, "Outline", Cfg.ESP.Box, "Outline")
        mkSep(tE, "INFO"); mkTog(tE, "Name", Cfg.ESP.Name, "On"); mkDD(tE, "Format", { "Name+Dist", "Name" }, Cfg.ESP.Name, "Fmt")
        mkTog(tE, "Health Bar", Cfg.ESP.HP, "On"); mkTog(tE, "Tracers", Cfg.ESP.Tracer, "On"); mkTog(tE, "Head Dot", Cfg.ESP.HeadDot, "On")

        ord = 0; mkSep(tW, "WALLHACK"); mkTog(tW, "Enabled", Cfg.WH, "On"); mkTog(tW, "Show Team", Cfg.WH, "ShowTeam"); mkSld(tW, "Fill Trans", 0, 1, Cfg.WH, "FT", "%.1f")

        ord = 0; mkSep(tM, "CAMERA"); mkTog(tM, "3rd Person", Cfg.TP, "On"); mkSld(tM, "Distance", 5, 100, Cfg.TP, "Dist", "%.0f")
        mkSep(tM, "MOVEMENT"); mkTog(tM, "SpinBot", Cfg.Spin, "On"); mkSld(tM, "Spin Speed", 1, 50, Cfg.Spin, "Spd", "%.0f")
        mkTog(tM, "Speed Boost", Cfg.Speed, "On"); mkSld(tM, "Speed", 1, 3, Cfg.Speed, "Mult", "%.1fx")
        mkSep(tM, "SYSTEM")
        local il = Instance.new("TextLabel", tM); il.Text = Exec.name .. " | Silent:" .. (Exec.canSilent and "Y" or "N"); il.Size = UDim2.new(1, 0, 0, 18); il.BackgroundTransparency = 1; il.TextColor3 = TXTD; il.TextSize = 9; il.Font = Enum.Font.Gotham; il.LayoutOrder = nOrd()
        local ub = Instance.new("TextButton", tM); ub.Text = "Unload"; ub.Size = UDim2.new(1, 0, 0, SC(26, 32)); ub.BackgroundColor3 = Color3.fromRGB(200, 50, 50); ub.TextColor3 = Color3.new(1, 1, 1); ub.TextSize = SC(11, 12); ub.Font = Enum.Font.GothamBold; ub.AutoButtonColor = false; ub.LayoutOrder = nOrd(); Instance.new("UICorner", ub).CornerRadius = UDim.new(0, 5)
        ub.MouseButton1Click:Connect(function() Notify("X", "Bye", 2); task.delay(0.3, Cleanup) end)

        local obs = SC(32, 40); local ob = Instance.new("TextButton", gui); ob.Text = "X"; ob.Size = UDim2.new(0, obs, 0, obs); ob.Position = UDim2.new(1, -obs - 6, 0, SC(6, 44)); ob.BackgroundColor3 = MC; ob.TextColor3 = Color3.new(1, 1, 1); ob.TextSize = SC(14, 16); ob.Font = Enum.Font.GothamBlack; ob.AutoButtonColor = false; Instance.new("UICorner", ob).CornerRadius = UDim.new(0, obs / 2)
        ob.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

        if IsMobile then
            local bf = Instance.new("Frame", gui); bf.Size = UDim2.new(0, 48, 0, 130); bf.Position = UDim2.new(0, 4, 0.5, -65); bf.BackgroundTransparency = 1; S.mobFrame = bf
            for i, d in ipairs({ { "AIM", 0, Color3.fromRGB(80, 220, 120), function() Cfg.On = not Cfg.On end, function() return Cfg.On end }, { "ESP", 44, MC, function() Cfg.ESP.On = not Cfg.ESP.On; if not Cfg.ESP.On then E.DelAll() end end, function() return Cfg.ESP.On end }, { "WH", 88, Color3.fromRGB(255, 180, 50), function() Cfg.WH.On = not Cfg.WH.On; if not Cfg.WH.On then WH.KillAll() end end, function() return Cfg.WH.On end } }) do
                local b = Instance.new("TextButton", bf); b.Size = UDim2.new(0, 44, 0, 36); b.Position = UDim2.new(0, 0, 0, d[2]); b.BackgroundColor3 = d[5]() and d[3] or TOFF; b.TextColor3 = Color3.new(1, 1, 1); b.Text = d[1]; b.TextSize = 9; b.Font = Enum.Font.GothamBold; b.AutoButtonColor = false; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
                b.MouseButton1Click:Connect(function() d[4](); b.BackgroundColor3 = d[5]() and d[3] or TOFF end)
            end
        end
    end

    local function MainLoop()
        table.insert(S.conns, RunService.RenderStepped:Connect(function(dt)
            if DEAD then return end
            S.frame = S.frame + 1
            Cam = WS.CurrentCamera
            if not S.me.alive then S.tgt.part = nil; S.tgt.plr = nil; S.tgt.vis = false end
            if Cfg.On and S.me.alive then
                local part, plr = FindTarget()
                if part then
                    S.tgt.part = part; S.tgt.plr = plr; S.tgt.name = plr and plr.Name or "?"
                    S.tgt.dist = (Cam.CFrame.Position - part.Position).Magnitude; S.tgt.vis = true
                    local ch = plr and plr.Character; local hp, mhp = GetHP(ch); S.tgt.hp = hp; S.tgt.mhp = mhp
                    if not (Cfg.AimMode == "silent" and Cfg.Silent.On) and Cfg.AimMode ~= "flick" then
                        ApplyAim(part)
                    end
                else
                    if not S.tgt.plr then S.tgt.part = nil; S.tgt.name = ""; S.tgt.lastPos = nil; S.tgt.sVel = Vector3.zero end
                    S.tgt.vis = false
                end
            end
            FlickUpdate(); FireUpdate()
            if S.frame % 2 == 0 then HUD.Update() end
            if Cfg.ESP.On then E.UpdateBatch(dt) end
            if S.frame % 5 == 0 then RefreshPL(); WH.Update() end
            TPUpdate(); SpinUpdate(dt); SpeedUpdate(dt)
        end))
    end

    local function InputSetup()
        if not IsMobile then
            table.insert(S.conns, UIS.InputBegan:Connect(function(i, g)
                if DEAD or g then return end
                if i.KeyCode == Enum.KeyCode.F1 then Cfg.On = not Cfg.On; Notify("X", Cfg.On and "AIM ON" or "AIM OFF")
                elseif i.KeyCode == Enum.KeyCode.F2 then Cfg.ESP.On = not Cfg.ESP.On; if not Cfg.ESP.On then E.DelAll() end; Notify("X", Cfg.ESP.On and "ESP ON" or "ESP OFF")
                elseif i.KeyCode == Enum.KeyCode.F3 then Cfg.WH.On = not Cfg.WH.On; if not Cfg.WH.On then WH.KillAll() end; Notify("X", Cfg.WH.On and "WH ON" or "WH OFF")
                elseif i.KeyCode == Enum.KeyCode.RightShift then if S.gui then local mf = S.gui:FindFirstChild("MainFrame"); if mf then mf.Visible = not mf.Visible end end end
            end))
        end
    end

    _G.XenoCleanup = Cleanup
    table.insert(S.conns, Players.PlayerRemoving:Connect(function(p) if DEAD then return end; E.Del(p.UserId); WH.Kill(p.UserId) end))
    SetupChar(); task.wait(0.5); FireInit(); HUD.Create()
    if Exec.canSilent and Cfg.Silent.On then Sil.Install() end
    BuildGUI(); InputSetup(); MainLoop()
    Notify("Xeno v10.2 opt", "Loaded | " .. Cfg.AimMode:upper(), 5)
end)
if not ok then warn("[XENO]", err); pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "XENO ERROR", Text = tostring(err):sub(1, 100), Duration = 10 }) end) end
