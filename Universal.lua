

```lua
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

local DEAD = false

local function Notify(t,m,d) pcall(function() StarterGui:SetCore("SendNotification",{Title=t,Text=m or"",Duration=d or 4}) end) end
local function SafeP() if Exec.canCoreGui then return CoreGui end;if typeof(gethui)=="function" then local o,r=pcall(gethui);if o and r then return r end end;return Plr:WaitForChild("PlayerGui") end
local function Protect(g) if typeof(syn)=="table" and syn.protect_gui then pcall(syn.protect_gui,g) end;if typeof(protect_gui)=="function" then pcall(protect_gui,g) end end
local function Kill(d) if not d then return end;pcall(function() d.Visible=false end);pcall(function() d:Remove() end);pcall(function() d:Destroy() end) end
local function ND(t) if not drawOK then return nil end;local o,d=pcall(Drawing.new,t);if not o or not d then return nil end;d.Visible=false;return d end

Notify("XENO","Loading v10...",3)

local Cfg={
    On=false,AimMode=Exec.canSilent and"silent"or"normal",
    Part="Head",Priority="FOV",Sticky=true,StickyTime=3,Aim360=false,
    FOV={On=true,R=SC(120,200),Show=true,Color=Color3.fromRGB(90,130,255),Trans=0.7,Thick=1.5},
    Smooth={On=true,Amt=SC(0.15,0.25),Dynamic=true,Max=0.5,Min=0.05},
    Pred={On=false,Factor=0.12,VelSmooth=0.3},
    Silent={On=Exec.canSilent,Chance=100,Use360=false},
    Flick={On=not Exec.canSilent,Restore=true,Chance=100,Speed=1.0,MobileAuto=IsMobile},
    TB={On=false,Auto=true,Delay=0.08,FOVCheck=true,TBFOV=60},
    Vis={Dot=true,DotClr=Color3.fromRGB(255,50,50),DotSz=SC(5,8),Line=not IsMobile,LineClr=Color3.fromRGB(255,255,255),LineW=1.5},
    ESP={
        On=false,MaxDist=1500,ShowTeam=false,
        Colors={
            EBox=Color3.fromRGB(255,50,50),EName=Color3.fromRGB(255,255,255),
            TBox=Color3.fromRGB(50,255,50),TName=Color3.fromRGB(255,255,255),
            Outline=Color3.fromRGB(0,0,0),
            HPLo=Color3.fromRGB(255,50,50),HPMid=Color3.fromRGB(255,200,50),HPHi=Color3.fromRGB(80,220,120),
            HPBg=Color3.fromRGB(25,25,25),HeadDotClr=Color3.fromRGB(255,255,255),
            TracerClr=Color3.fromRGB(255,80,80),DistClr=Color3.fromRGB(180,180,200),
            ArmorClr=Color3.fromRGB(100,150,255),WeaponClr=Color3.fromRGB(200,180,140),
            FlagClr=Color3.fromRGB(180,180,255),
        },
        Box={On=true,Style="Corner",W=1,CL=0.25,Outline=true,OW=2,
            VisCheck=false,VisClr=Color3.fromRGB(50,255,50),InvisClr=Color3.fromRGB(255,50,50)},
        Name={On=true,Sz=SC(13,11),Pos="Top",Fmt="Name+Dist",Shadow=true},
        HP={On=true,W=3,Off=5,Pos="Left",ShowText=true,Outline=true,Smooth=true},
        Tracer={On=false,W=1.5,Origin="Bottom",Outline=false},
        HeadDot={On=false,Rad=SC(3,4),Outline=true},
        Dist={On=false,Sz=11},
        Weapon={On=false,Sz=11},
        Flags={On=false,Sz=11},
        OFS={On=false,Sz=14,Rad=200},
    },
    WH={On=false,Fill=Color3.fromRGB(255,0,0),FT=0.5,Out=Color3.fromRGB(255,255,255),OT=0,
        TFill=Color3.fromRGB(0,255,0),TOut=Color3.fromRGB(200,255,200),ShowTeam=false},
    Wall={Thresh=0.5,MaxPierce=3},
    Checks={Team=true,Alive=true,Wall=true,FF=true,Dist=true},
    Limits={MaxD=800,MaxA=SC(75,90),MinD=5},
    TP={On=false,Dist=30},
    Spin={On=false,Spd=15},
    Speed={On=false,Mult=1.5},
    Menu={Color=Color3.fromRGB(90,130,255),BgColor=Color3.fromRGB(20,20,28)},
}

local S={
    tgt={part=nil,plr=nil,dist=0,hp=0,mhp=0,name="",lastT=0,vis=false,lastPos=nil,sVel=Vector3.zero},
    me={char=nil,hum=nil,root=nil,alive=false},
    aim={silentPos=nil,hooked=false,flickOn=false,flickCF=nil},
    fire={last=0,method="none"},draw={},espC={},whC={},
    conns={},gui=nil,mobFrame=nil,spinAng=0,frame=0,espBatch=0,
    origMaxZoom=nil,origMinZoom=nil,
}

local vpX,vpY=1920,1080
local camPos=Vector3.zero
local scrCenter=Vector2.new(960,540)

local function RefreshCam()
    Cam=WS.CurrentCamera;if not Cam then return end
    vpX=Cam.ViewportSize.X;vpY=Cam.ViewportSize.Y
    scrCenter=Vector2.new(vpX*0.5,vpY*0.5)
    camPos=Cam.CFrame.Position
end

local function W2S(pos)
    if not Cam then return nil,false end
    local v,on=Cam:WorldToViewportPoint(pos)
    if on then return Vector2.new(v.X,v.Y),true end
    return nil,false
end

local function SDist(wp)
    local sp,on=W2S(wp)
    return(sp and on)and(sp-scrCenter).Magnitude or 9999
end

local function HPCol(pct)
    pct=math.clamp(pct,0,1);local C=Cfg.ESP.Colors
    if pct>0.6 then return C.HPMid:Lerp(C.HPHi,(pct-0.6)/0.4) end
    return C.HPLo:Lerp(C.HPMid,pct/0.6)
end

local function TeamEq(p1,p2)
    if not p1 or not p2 then return false end
    local t1,t2;pcall(function() t1=p1.Team end);pcall(function() t2=p2.Team end)
    return t1 and t2 and t1==t2
end

local function CanSee(part,myCh)
    if not part or not myCh or not Cam then return true end
    local tp=part.Position;local dir=tp-camPos;local dist=dir.Magnitude
    if dist<3 then return true end
    local par=RaycastParams.new();par.FilterType=Enum.RaycastFilterType.Exclude
    local tCh=part.Parent
    par.FilterDescendantsInstances=tCh and{myCh,tCh}or{myCh}
    par.RespectCanCollide=false
    local r=WS:Raycast(camPos,dir.Unit*(dist-1),par)
    if not r then return true end
    if r.Instance.Transparency>=Cfg.Wall.Thresh or not r.Instance.CanCollide then return true end
    return false
end

local function GetTool(ch)
    if not ch then return nil end
    for _,c in ipairs(ch:GetChildren()) do if c:IsA("Tool") then return c end end
    return nil
end

local Res={}
function Res.HP(ch) if not ch then return 0,100 end;local h=ch:FindFirstChildOfClass("Humanoid");if h then return h.Health,h.MaxHealth end;return 100,100 end
function Res.Root(ch) if not ch then return nil end;return ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso") or ch.PrimaryPart end

local function SetupChar()
    local function onC(ch)
        if DEAD then return end
        S.me.char=ch;S.me.alive=false;S.tgt.part=nil;S.tgt.plr=nil
        S.me.hum=ch:WaitForChild("Humanoid",10);S.me.root=ch:WaitForChild("HumanoidRootPart",10)
        if not S.me.hum or not S.me.root then return end
        S.me.alive=true
        S.me.hum.Died:Connect(function() S.me.alive=false;S.tgt.part=nil;S.tgt.plr=nil end)
    end
    if Plr.Character then task.spawn(onC,Plr.Character) end
    table.insert(S.conns,Plr.CharacterAdded:Connect(onC))
end

local T={}
function T.GetP(ch)
    if not ch then return nil end
    local p=ch:FindFirstChild(Cfg.Part)
    if not p then p=ch:FindFirstChild("Head") end
    if not p then p=Res.Root(ch) end
    return p
end

function T.Valid(ch,tp)
    if not ch or not ch.Parent then return false end
    local rp=Res.Root(ch);if not rp then return false end
    local hp=Res.HP(ch);if hp<=0 then return false end
    if tp and Cfg.Checks.Team and TeamEq(Plr,tp) then return false end
    if Cfg.Checks.Dist and S.me.root then
        local d=(rp.Position-S.me.root.Position).Magnitude
        if d>Cfg.Limits.MaxD or d<Cfg.Limits.MinD then return false end
    end
    return true
end

function T.Ang(p)
    if not p or not Cam then return 180 end
    local dir=p.Position-camPos
    if dir.Magnitude<0.001 then return 0 end
    return math.deg(math.acos(math.clamp(Cam.CFrame.LookVector:Dot(dir.Unit),-1,1)))
end

function T.Find()
    if not S.me.alive or not Cam then return nil,nil end
    local is360=Cfg.Aim360 or(Cfg.AimMode=="silent" and Cfg.Silent.Use360)
    if Cfg.Sticky and S.tgt.part and S.tgt.plr then
        local ch=S.tgt.plr.Character
        if ch and ch.Parent and Res.HP(ch)>0 then
            local p=T.GetP(ch)
            if p then
                local _,on=W2S(p.Position)
                local inF=not Cfg.FOV.On or SDist(p.Position)<=Cfg.FOV.R*1.5
                local vis=not Cfg.Checks.Wall or CanSee(p,S.me.char)
                if is360 then on=true;inF=true end
                if on and inF and vis then
                    S.tgt.part=p;S.tgt.lastT=tick();S.tgt.vis=true
                    return p,S.tgt.plr
                elseif not vis then
                    S.tgt.part=nil;S.tgt.plr=nil;S.tgt.vis=false
                elseif tick()-S.tgt.lastT>Cfg.StickyTime then
                    S.tgt.part=nil;S.tgt.plr=nil;S.tgt.vis=false
                else
                    S.tgt.vis=false;return nil,nil
                end
            else S.tgt.part=nil;S.tgt.plr=nil;S.tgt.vis=false end
        else S.tgt.part=nil;S.tgt.plr=nil;S.tgt.vis=false end
    end
    local bp,bpl,bs=nil,nil,-9999
    for _,tp in ipairs(Players:GetPlayers()) do
        if tp==Plr then continue end
        local ch=tp.Character;if not T.Valid(ch,tp) then continue end
        local p=T.GetP(ch);if not p then continue end
        local _,on=W2S(p.Position);if not is360 and not on then continue end
        local sd=SDist(p.Position)
        if Cfg.FOV.On and not is360 and sd>Cfg.FOV.R then continue end
        if not is360 and T.Ang(p)>Cfg.Limits.MaxA then continue end
        if Cfg.Checks.Wall and not CanSee(p,S.me.char) then continue end
        local sc
        if Cfg.Priority=="FOV" then sc=10000-sd
        elseif Cfg.Priority=="Distance" then sc=10000-(camPos-p.Position).Magnitude
        elseif Cfg.Priority=="Health" then sc=10000-Res.HP(ch)
        else sc=10000-sd end
        if sc>bs then bs=sc;bp=p;bpl=tp end
    end
    if bp then S.tgt.vis=true end
    return bp,bpl
end

local A={}
function A.Pred(p)
    if not Cfg.Pred.On or not p then return p and p.Position or Vector3.zero end
    local cur=p.Position
    if S.tgt.lastPos then
        S.tgt.sVel=S.tgt.sVel+((cur-S.tgt.lastPos)*60-S.tgt.sVel)*Cfg.Pred.VelSmooth
    end
    S.tgt.lastPos=cur
    return cur+S.tgt.sVel*Cfg.Pred.Factor
end

function A.GetCF(p)
    if not p or not Cam then return nil end
    local t=A.Pred(p);local d=t-camPos
    return d.Magnitude>0.001 and CFrame.lookAt(camPos,camPos+d.Unit) or nil
end

function A.Apply(p)
    if not p or not Cam then return end
    local tcf=A.GetCF(p);if not tcf then return end
    if Cfg.AimMode=="snap" then
        Cam.CFrame=tcf
    elseif Cfg.AimMode=="normal" then
        if Cfg.Smooth.On then
            local sm=Cfg.Smooth.Amt
            if Cfg.Smooth.Dynamic then
                local t=math.clamp(T.Ang(p)/math.max(Cfg.Limits.MaxA,1),0,1)
                sm=Cfg.Smooth.Min+(Cfg.Smooth.Max-Cfg.Smooth.Min)*t
            end
            local curLook=Cam.CFrame.LookVector
            local tgtLook=tcf.LookVector
            local newLook=curLook:Lerp(tgtLook,sm)
            if newLook.Magnitude>0.001 then
                Cam.CFrame=CFrame.lookAt(camPos,camPos+newLook)
            end
        else
            Cam.CFrame=tcf
        end
    end
end

local Sil={}
function Sil.Should() return not DEAD and Cfg.On and Cfg.Silent.On and Cfg.AimMode=="silent" and S.tgt.part and((Cfg.Silent.Use360 or Cfg.Aim360)or S.tgt.vis)and(Cfg.Silent.Chance>=100 or math.random(1,100)<=Cfg.Silent.Chance) end
function Sil.Pos() if not S.tgt.part then return nil end;return A.Pred(S.tgt.part) end
function Sil.CF() local p=Sil.Pos();return p and CFrame.new(p)or nil end
function Sil.Install()
    if S.aim.hooked or not Exec.canSilent then if not Exec.canSilent then Cfg.AimMode="flick";Cfg.Silent.On=false;Cfg.Flick.On=true end;return end
    local wrap=newcclosure or newclosure or function(f) return f end;local hooked=false
    if hasHM and hasNC then pcall(function()
        local old;old=hookmetamethod(game,"__namecall",wrap(function(self,...)
            if DEAD then return old(self,...) end
            local m=getnamecallmethod();local args={...}
            if Sil.Should() then
                local tp=Sil.Pos()
                if tp then
                    if m=="Raycast" and self==WS and #args>=2 and typeof(args[1])=="Vector3" then
                        S.aim.silentPos=tp;local d=(tp-args[1]);if d.Magnitude>0.001 then d=d.Unit*1000 end
                        return old(self,args[1],d,select(3,...))
                    end
                    if(m=="FindPartOnRay"or m=="FindPartOnRayWithIgnoreList"or m=="FindPartOnRayWithWhitelist")and self==WS and typeof(args[1])=="Ray" then
                        S.aim.silentPos=tp;local d=(tp-args[1].Origin);if d.Magnitude>0.001 then d=d.Unit*1000 end
                        return old(self,Ray.new(args[1].Origin,d),select(2,...))
                    end
                end
            end
            return old(self,...)
        end));hooked=true
    end);pcall(function()
        local old;old=hookmetamethod(game,"__index",wrap(function(self,k)
            if DEAD then return old(self,k) end
            if Sil.Should() and self==Mouse then
                if k=="Hit" then local cf=Sil.CF();if cf then S.aim.silentPos=cf.Position;return cf end
                elseif k=="Target" and S.tgt.part then return S.tgt.part
                elseif k=="UnitRay" then local p=Sil.Pos();if p then local d=p-camPos;if d.Magnitude>0.001 then return Ray.new(camPos,d.Unit) end end
                end
            end
            return old(self,k)
        end))
    end) end
    S.aim.hooked=hooked;if not hooked then Cfg.AimMode="flick";Cfg.Silent.On=false;Cfg.Flick.On=true end
end

local Flk={}
function Flk.Down() if IsMobile then return Cfg.Flick.MobileAuto and S.tgt.vis end;local o,r=pcall(function() return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end);return o and r end
function Flk.Update()
    if DEAD or Cfg.AimMode~="flick" or not Cfg.Flick.On then
        if S.aim.flickOn and S.aim.flickCF and Cfg.Flick.Restore then Cam.CFrame=S.aim.flickCF end
        S.aim.flickOn=false;S.aim.flickCF=nil;return
    end
    local down=Flk.Down()
    if down and not S.aim.flickOn and Cfg.On and S.tgt.vis and S.tgt.part then
        S.aim.flickCF=Cam.CFrame;S.aim.flickOn=true
    elseif down and S.aim.flickOn then
        if S.tgt.part and S.tgt.vis then
            local tcf=A.GetCF(S.tgt.part)
            if tcf then Cam.CFrame=Cfg.Flick.Speed>=1 and tcf or Cam.CFrame:Lerp(tcf,Cfg.Flick.Speed) end
        else
            if S.aim.flickCF and Cfg.Flick.Restore then Cam.CFrame=S.aim.flickCF end
            S.aim.flickOn=false
        end
    elseif not down and S.aim.flickOn then
        if S.aim.flickCF and Cfg.Flick.Restore then Cam.CFrame=S.aim.flickCF end
        S.aim.flickOn=false
    end
end

local Fire={}
function Fire.Init()
    S.fire.method="none"
    if typeof(mouse1press)=="function" then S.fire.method="mouse1press";return end
    pcall(function() game:GetService("VirtualInputManager");S.fire.method="vim" end)
end
function Fire.Click()
    if S.fire.method=="mouse1press" then
        pcall(function() mouse1press();task.delay(0.05,function() pcall(mouse1release) end) end)
        return true
    elseif S.fire.method=="vim" then
        pcall(function()
            local v=game:GetService("VirtualInputManager")
            v:SendMouseButtonEvent(Mouse.X,Mouse.Y,0,true,game,0)
            task.delay(0.05,function() pcall(function() v:SendMouseButtonEvent(Mouse.X,Mouse.Y,0,false,game,0) end) end)
        end)
        return true
    end
    return false
end
function Fire.Update()
    if DEAD or not Cfg.TB.On or not Cfg.On then return end
    if S.fire.method=="none" then return end
    if tick()-S.fire.last<Cfg.TB.Delay then return end
    local hasTgt=false
    if Cfg.TB.FOVCheck then
        for _,tp in ipairs(Players:GetPlayers()) do
            if tp==Plr then continue end
            local ch=tp.Character;if not ch or not ch.Parent then continue end
            if Cfg.Checks.Team and TeamEq(Plr,tp) then continue end
            local hp=Res.HP(ch);if hp<=0 then continue end
            local head=ch:FindFirstChild("Head");if not head then continue end
            local sd=SDist(head.Position)
            if sd<=Cfg.TB.TBFOV then
                if not Cfg.Checks.Wall or CanSee(head,S.me.char) then
                    hasTgt=true;break
                end
            end
        end
    else
        hasTgt=S.tgt.vis and S.tgt.part~=nil
    end
    if hasTgt then
        if Fire.Click() then S.fire.last=tick() end
    end
end

local Exp={}
function Exp.TP()
    if DEAD then return end
    if Cfg.TP.On then
        if not S.origMaxZoom then
            S.origMaxZoom=Plr.CameraMaxZoomDistance
            S.origMinZoom=Plr.CameraMinZoomDistance
        end
        Plr.CameraMaxZoomDistance=Cfg.TP.Dist
        if Plr.CameraMinZoomDistance>Cfg.TP.Dist then
            Plr.CameraMinZoomDistance=0.5
        end
    end
end
function Exp.RTP()
    if S.origMaxZoom then
        pcall(function() Plr.CameraMaxZoomDistance=S.origMaxZoom end)
        pcall(function() Plr.CameraMinZoomDistance=S.origMinZoom end)
        S.origMaxZoom=nil;S.origMinZoom=nil
    end
end
function Exp.Spin(dt)
    if DEAD or not Cfg.Spin.On or not S.me.alive then return end
    local ch=S.me.char;if not ch then return end
    local hum=S.me.hum;if not hum then return end
    local root=S.me.root;if not root then return end
    S.spinAng=(S.spinAng+Cfg.Spin.Spd*dt*60)%360
    local moveDir=hum.MoveDirection
    local pos=root.Position
    local spinCF=CFrame.new(pos)*CFrame.Angles(0,math.rad(S.spinAng),0)
    if moveDir.Magnitude>0.1 then
        local vel=root.AssemblyLinearVelocity
        root.CFrame=spinCF
        root.AssemblyLinearVelocity=vel
    else
        root.CFrame=spinCF
    end
end
function Exp.RSpin() S.spinAng=0 end
function Exp.Speed(dt)
    if DEAD or not Cfg.Speed.On or not S.me.root or not S.me.alive or not S.me.hum then return end
    local md=S.me.hum.MoveDirection
    if md.Magnitude<0.1 then return end
    S.me.root.CFrame=S.me.root.CFrame+md.Unit*S.me.hum.WalkSpeed*(Cfg.Speed.Mult-1)*dt
end

local E={}
function E.New(uid)
    if DEAD or S.espC[uid] or not drawOK then return end
    local o={}
    o.box=ND("Square");o.box.Filled=false;o.box.Thickness=Cfg.ESP.Box.W
    o.boxO=ND("Square");o.boxO.Filled=false;o.boxO.Color=Cfg.ESP.Colors.Outline
    o.cL={};o.cO={}
    for i=1,8 do o.cL[i]=ND("Line");o.cO[i]=ND("Line") end
    o.name=ND("Text");o.name.Center=true;o.name.Outline=true;o.name.Size=Cfg.ESP.Name.Sz
    o.nameSh=ND("Text");o.nameSh.Center=true;o.nameSh.Outline=false;o.nameSh.Size=Cfg.ESP.Name.Sz
    o.hpBg=ND("Square");o.hpBg.Filled=true
    o.hpOL=ND("Square");o.hpOL.Filled=false;o.hpOL.Color=Color3.new(0,0,0);o.hpOL.Thickness=1
    o.hpFill=ND("Square");o.hpFill.Filled=true
    o.hpTxt=ND("Text");o.hpTxt.Outline=true;o.hpTxt.Size=11;o.hpTxt.Center=true
    o.tracer=ND("Line")
    o.tracerO=ND("Line")
    o.hdot=ND("Circle");o.hdot.Filled=true;o.hdot.NumSides=10
    o.hdotO=ND("Circle");o.hdotO.Filled=false;o.hdotO.NumSides=10;o.hdotO.Color=Color3.new(0,0,0)
    o.dist=ND("Text");o.dist.Center=true;o.dist.Outline=true;o.dist.Size=11
    o.weapon=ND("Text");o.weapon.Center=true;o.weapon.Outline=true;o.weapon.Size=11
    o.flags=ND("Text");o.flags.Outline=true;o.flags.Size=11
    o.arrow=ND("Triangle");o.arrow.Filled=true
    o.smoothHP=nil
    S.espC[uid]=o
end

function E.Hide(o)
    if not o then return end
    if o.box then o.box.Visible=false end
    if o.boxO then o.boxO.Visible=false end
    for i=1,8 do if o.cL[i] then o.cL[i].Visible=false end;if o.cO[i] then o.cO[i].Visible=false end end
    if o.name then o.name.Visible=false end
    if o.nameSh then o.nameSh.Visible=false end
    if o.hpBg then o.hpBg.Visible=false end
    if o.hpOL then o.hpOL.Visible=false end
    if o.hpFill then o.hpFill.Visible=false end
    if o.hpTxt then o.hpTxt.Visible=false end
    if o.tracer then o.tracer.Visible=false end
    if o.tracerO then o.tracerO.Visible=false end
    if o.hdot then o.hdot.Visible=false end
    if o.hdotO then o.hdotO.Visible=false end
    if o.dist then o.dist.Visible=false end
    if o.weapon then o.weapon.Visible=false end
    if o.flags then o.flags.Visible=false end
    if o.arrow then o.arrow.Visible=false end
end

function E.Del(uid)
    local o=S.espC[uid];if not o then return end;E.Hide(o)
    Kill(o.box);Kill(o.boxO)
    for i=1,8 do Kill(o.cL[i]);Kill(o.cO[i]) end
    Kill(o.name);Kill(o.nameSh);Kill(o.hpBg);Kill(o.hpOL);Kill(o.hpFill);Kill(o.hpTxt)
    Kill(o.tracer);Kill(o.tracerO);Kill(o.hdot);Kill(o.hdotO)
    Kill(o.dist);Kill(o.weapon);Kill(o.flags);Kill(o.arrow)
    S.espC[uid]=nil
end

function E.DelAll() local k={};for uid in pairs(S.espC) do k[#k+1]=uid end;for _,uid in ipairs(k) do E.Del(uid) end end

function E.Render(uid,ch,dname,isTeam,dt)
    local o=S.espC[uid];if not o then return end
    if not ch or not ch.Parent then E.Hide(o);return end
    local rp=Res.Root(ch);if not rp then E.Hide(o);return end
    local hp,mhp=Res.HP(ch);if hp<=0 then E.Hide(o);return end
    if isTeam and not Cfg.ESP.ShowTeam then E.Hide(o);return end
    local rpPos=rp.Position
    local dist=S.me.root and(rpPos-S.me.root.Position).Magnitude or 0
    if dist>Cfg.ESP.MaxDist then E.Hide(o);return end

    local head=ch:FindFirstChild("Head")
    local topY=head and(head.Position.Y+1)or(rpPos.Y+3)
    local botY=rpPos.Y-3
    local topSP,topOn=W2S(Vector3.new(rpPos.X,topY,rpPos.Z))
    if not topOn then
        E.Hide(o)
        if Cfg.ESP.OFS.On and o.arrow then
            local raw,_=W2S(rpPos)
            if raw then
                local d2=(raw or scrCenter)-scrCenter
                if d2.Magnitude>5 then
                    d2=d2.Unit;local ap=scrCenter+d2*Cfg.ESP.OFS.Rad
                    local perp=Vector2.new(-d2.Y,d2.X);local sz=Cfg.ESP.OFS.Sz
                    o.arrow.PointA=ap+d2*sz;o.arrow.PointB=ap-d2*sz*0.5+perp*sz*0.4;o.arrow.PointC=ap-d2*sz*0.5-perp*sz*0.4
                    o.arrow.Color=isTeam and Cfg.ESP.Colors.TBox or Cfg.ESP.Colors.EBox;o.arrow.Visible=true
                else o.arrow.Visible=false end
            else o.arrow.Visible=false end
        end
        return
    end
    if o.arrow then o.arrow.Visible=false end
    local botSP,botOn=W2S(Vector3.new(rpPos.X,botY,rpPos.Z))
    if not botOn then E.Hide(o);return end

    local h=math.abs(botSP.Y-topSP.Y)
    if h<3 then E.Hide(o);return end
    local w=h*0.6;local bx=topSP.X-w*0.5;local by=topSP.Y
    if bx<-200 or bx>vpX+200 or by<-200 or by>vpY+200 then E.Hide(o);return end

    local CC=Cfg.ESP.Colors
    local boxClr=isTeam and CC.TBox or CC.EBox
    local nameClr=isTeam and CC.TName or CC.EName
    if Cfg.ESP.Box.VisCheck then
        local vis=CanSee(rp,S.me.char)
        boxClr=vis and Cfg.ESP.Box.VisClr or Cfg.ESP.Box.InvisClr
    end
    local distInt=math.floor(dist)

    if Cfg.ESP.Box.On then
        local style=Cfg.ESP.Box.Style
        if style=="Full" then
            for i=1,8 do if o.cL[i] then o.cL[i].Visible=false end;if o.cO[i] then o.cO[i].Visible=false end end
            o.box.Size=Vector2.new(w,h);o.box.Position=Vector2.new(bx,by);o.box.Color=boxClr;o.box.Thickness=Cfg.ESP.Box.W;o.box.Visible=true
            if Cfg.ESP.Box.Outline then
                o.boxO.Size=Vector2.new(w+4,h+4);o.boxO.Position=Vector2.new(bx-2,by-2);o.boxO.Color=CC.Outline;o.boxO.Thickness=Cfg.ESP.Box.W+Cfg.ESP.Box.OW;o.boxO.Visible=true
            else o.boxO.Visible=false end
        else
            o.box.Visible=false;o.boxO.Visible=false
            local cl=math.max(w,h)*Cfg.ESP.Box.CL
            local pts={{bx,by,bx+cl,by},{bx,by,bx,by+cl},{bx+w,by,bx+w-cl,by},{bx+w,by,bx+w,by+cl},{bx,by+h,bx+cl,by+h},{bx,by+h,bx,by+h-cl},{bx+w,by+h,bx+w-cl,by+h},{bx+w,by+h,bx+w,by+h-cl}}
            for i=1,8 do
                local d=o.cL[i];if not d then continue end
                d.From=Vector2.new(pts[i][1],pts[i][2]);d.To=Vector2.new(pts[i][3],pts[i][4])
                d.Color=boxClr;d.Thickness=Cfg.ESP.Box.W;d.Visible=true
                if Cfg.ESP.Box.Outline then
                    local od=o.cO[i];if od then od.From=d.From;od.To=d.To;od.Color=CC.Outline;od.Thickness=Cfg.ESP.Box.W+Cfg.ESP.Box.OW;od.Visible=true end
                else if o.cO[i] then o.cO[i].Visible=false end end
            end
        end
    else
        o.box.Visible=false;o.boxO.Visible=false
        for i=1,8 do if o.cL[i] then o.cL[i].Visible=false end;if o.cO[i] then o.cO[i].Visible=false end end
    end

    local topTY=by;local botTY=by+h+2
    if Cfg.ESP.Name.On and o.name then
        local txt
        if Cfg.ESP.Name.Fmt=="Name+Dist" then txt=dname.." ["..distInt.."m]"
        elseif Cfg.ESP.Name.Fmt=="Name" then txt=dname
        else txt=dname.." ["..distInt.."m]" end
        local nPos
        if Cfg.ESP.Name.Pos=="Top" then topTY=topTY-Cfg.ESP.Name.Sz-2;nPos=Vector2.new(bx+w*0.5,topTY)
        else nPos=Vector2.new(bx+w*0.5,botTY);botTY=botTY+Cfg.ESP.Name.Sz+2 end
        o.name.Text=txt;o.name.Color=nameClr;o.name.Size=Cfg.ESP.Name.Sz;o.name.Position=nPos;o.name.Visible=true
        if Cfg.ESP.Name.Shadow and o.nameSh then
            o.nameSh.Text=txt;o.nameSh.Color=Color3.new(0,0,0);o.nameSh.Size=Cfg.ESP.Name.Sz;o.nameSh.Position=nPos+Vector2.new(1,1);o.nameSh.Visible=true
        elseif o.nameSh then o.nameSh.Visible=false end
    else if o.name then o.name.Visible=false end;if o.nameSh then o.nameSh.Visible=false end end

    if Cfg.ESP.HP.On then
        local pct=math.clamp(hp/math.max(mhp,1),0,1)
        if Cfg.ESP.HP.Smooth then
            if not o.smoothHP then o.smoothHP=pct end
            o.smoothHP=o.smoothHP+(pct-o.smoothHP)*math.clamp(10*(dt or 0.016),0,1)
            pct=o.smoothHP
        end
        local hc=HPCol(pct);local bW=Cfg.ESP.HP.W;local off=Cfg.ESP.HP.Off
        local bgX,bgY,bgW,bgH,fX,fY,fW,fH
        if Cfg.ESP.HP.Pos=="Left" then
            bgX=bx-off-bW-1;bgY=by-1;bgW=bW+2;bgH=h+2;fH=math.max(h*pct,1);fX=bgX+1;fY=by+h-fH;fW=bW
        elseif Cfg.ESP.HP.Pos=="Right" then
            bgX=bx+w+off-1;bgY=by-1;bgW=bW+2;bgH=h+2;fH=math.max(h*pct,1);fX=bgX+1;fY=by+h-fH;fW=bW
        else
            bgX=bx-1;bgY=by+h+off-1;bgW=w+2;bgH=bW+2;fX=bgX+1;fY=bgY+1;fW=math.max(w*pct,1);fH=bW
        end
        o.hpBg.Position=Vector2.new(bgX,bgY);o.hpBg.Size=Vector2.new(bgW,bgH);o.hpBg.Color=CC.HPBg;o.hpBg.Visible=true
        o.hpFill.Position=Vector2.new(fX,fY);o.hpFill.Size=Vector2.new(fW,math.max(fH,1));o.hpFill.Color=hc;o.hpFill.Visible=true
        if Cfg.ESP.HP.Outline and o.hpOL then
            o.hpOL.Position=Vector2.new(bgX-1,bgY-1);o.hpOL.Size=Vector2.new(bgW+2,bgH+2);o.hpOL.Visible=true
        elseif o.hpOL then o.hpOL.Visible=false end
        if Cfg.ESP.HP.ShowText and hp<mhp and o.hpTxt then
            o.hpTxt.Text=math.floor(hp).."";o.hpTxt.Color=hc
            if Cfg.ESP.HP.Pos=="Left" or Cfg.ESP.HP.Pos=="Right" then
                o.hpTxt.Position=Vector2.new(bgX+bgW/2,fY-14)
            else o.hpTxt.Position=Vector2.new(fX+fW+3,fY-2) end
            o.hpTxt.Visible=true
        elseif o.hpTxt then o.hpTxt.Visible=false end
    else
        if o.hpBg then o.hpBg.Visible=false end;if o.hpFill then o.hpFill.Visible=false end
        if o.hpOL then o.hpOL.Visible=false end;if o.hpTxt then o.hpTxt.Visible=false end
    end

    if Cfg.ESP.Tracer.On and o.tracer then
        local from
        if Cfg.ESP.Tracer.Origin=="Center" then from=scrCenter
        elseif Cfg.ESP.Tracer.Origin=="Top" then from=Vector2.new(vpX/2,0)
        else from=Vector2.new(vpX/2,vpY) end
        if Cfg.ESP.Tracer.Outline and o.tracerO then
            o.tracerO.From=from;o.tracerO.To=botSP;o.tracerO.Color=CC.Outline;o.tracerO.Thickness=Cfg.ESP.Tracer.W+2;o.tracerO.Visible=true
        elseif o.tracerO then o.tracerO.Visible=false end
        o.tracer.From=from;o.tracer.To=botSP;o.tracer.Color=CC.TracerClr;o.tracer.Thickness=Cfg.ESP.Tracer.W;o.tracer.Visible=true
    else if o.tracer then o.tracer.Visible=false end;if o.tracerO then o.tracerO.Visible=false end end

    if Cfg.ESP.HeadDot.On and head and o.hdot then
        local sp,on=W2S(head.Position)
        if sp and on then
            o.hdot.Position=sp;o.hdot.Radius=Cfg.ESP.HeadDot.Rad;o.hdot.Color=CC.HeadDotClr;o.hdot.Visible=true
            if Cfg.ESP.HeadDot.Outline and o.hdotO then
                o.hdotO.Position=sp;o.hdotO.Radius=Cfg.ESP.HeadDot.Rad+1;o.hdotO.Thickness=1;o.hdotO.Visible=true
            elseif o.hdotO then o.hdotO.Visible=false end
        else o.hdot.Visible=false;if o.hdotO then o.hdotO.Visible=false end end
    else if o.hdot then o.hdot.Visible=false end;if o.hdotO then o.hdotO.Visible=false end end

    if Cfg.ESP.Dist.On and o.dist then
        o.dist.Text=distInt.."m";o.dist.Color=CC.DistClr;o.dist.Position=Vector2.new(bx+w/2,botTY);o.dist.Visible=true
        botTY=botTY+12
    elseif o.dist then o.dist.Visible=false end

    if Cfg.ESP.Weapon.On and o.weapon then
        local tool=GetTool(ch)
        o.weapon.Text=tool and tool.Name or"";o.weapon.Color=CC.WeaponClr;o.weapon.Position=Vector2.new(bx+w/2,botTY)
        o.weapon.Visible=tool~=nil
        if tool then botTY=botTY+12 end
    elseif o.weapon then o.weapon.Visible=false end

    if Cfg.ESP.Flags.On and o.flags then
        local f={};if dist<50 then table.insert(f,"CLOSE") end
        local tool=GetTool(ch);if tool then table.insert(f,tool.Name) end
        local str=table.concat(f," | ")
        if #str>0 then o.flags.Text=str;o.flags.Color=CC.FlagClr;o.flags.Position=Vector2.new(bx+w+4,by);o.flags.Visible=true
        else o.flags.Visible=false end
    elseif o.flags then o.flags.Visible=false end
end

local playerList={}
local plTick=0
local function RefreshPL() if tick()-plTick<0.5 then return end;plTick=tick();playerList=Players:GetPlayers() end

function E.UpdateBatch(dt)
    if DEAD then return end
    RefreshPL()
    local count=#playerList;if count<=1 then return end
    local perFrame=math.max(math.ceil((count-1)/3),1)
    local startIdx=S.espBatch;local processed=0
    for i=1,count do
        if processed>=perFrame then break end
        local idx=((startIdx+i-2)%count)+1
        local tp=playerList[idx];if not tp or tp==Plr then continue end
        processed=processed+1
        local uid=tp.UserId;local ch=tp.Character
        if not ch or not ch.Parent or Res.HP(ch)<=0 then
            if S.espC[uid] then E.Hide(S.espC[uid]) end;continue
        end
        if not S.espC[uid] then E.New(uid) end
        E.Render(uid,ch,tp.DisplayName or tp.Name,TeamEq(Plr,tp),dt)
    end
    S.espBatch=(startIdx+processed)%math.max(count-1,1)
    if S.frame%30==0 then
        for uid in pairs(S.espC) do
            local found=false
            for _,tp in ipairs(playerList) do if tp.UserId==uid then found=true;break end end
            if not found then E.Del(uid) end
        end
    end
end

local WH={}
function WH.Make(uid,ch,isTeam) if DEAD or S.whC[uid] or not ch then return end;local hl=Instance.new("Highlight");hl.Name="XWH";hl.Adornee=ch;hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;hl.Enabled=true;hl.FillColor=isTeam and Cfg.WH.TFill or Cfg.WH.Fill;hl.OutlineColor=isTeam and Cfg.WH.TOut or Cfg.WH.Out;hl.FillTransparency=Cfg.WH.FT;hl.OutlineTransparency=Cfg.WH.OT;pcall(function() hl.Parent=ch end);S.whC[uid]=hl end
function WH.Kill(uid) local h=S.whC[uid];if h then pcall(function() h:Destroy() end) end;S.whC[uid]=nil end
function WH.KillAll() for k in pairs(S.whC) do pcall(function() S.whC[k]:Destroy() end) end;S.whC={} end
function WH.UpdateAll()
    if DEAD or not Cfg.WH.On then WH.KillAll();return end
    local active={}
    for _,tp in ipairs(playerList) do
        if tp==Plr then continue end
        local uid=tp.UserId;local ch=tp.Character;local isTeam=TeamEq(Plr,tp)
        local show=ch and ch.Parent and Res.HP(ch)>0
        if show and isTeam and not Cfg.WH.ShowTeam then show=false end
        if show then active[uid]=true;if not S.whC[uid] then WH.Make(uid,ch,isTeam) end
        elseif S.whC[uid] then WH.Kill(uid) end
    end
    for k in pairs(S.whC) do if not active[k] then WH.Kill(k) end end
end

local HUD={}
function HUD.Create()
    HUD.Destroy();if not drawOK then return end
    local d=S.draw
    d.fov=ND("Circle");d.fov.Filled=false;d.fov.NumSides=40
    d.line=ND("Line");d.dot=ND("Circle");d.dot.Filled=true;d.dot.NumSides=10
    d.st=ND("Text");d.st.Center=false;d.st.Outline=true;d.st.Size=SC(14,12);d.st.Position=Vector2.new(10,SC(10,40));d.st.Visible=true
end
function HUD.Update()
    if DEAD or not drawOK then return end;local d=S.draw
    if d.fov then d.fov.Position=scrCenter;d.fov.Radius=Cfg.FOV.R;d.fov.Color=Cfg.FOV.Color;d.fov.Transparency=Cfg.FOV.Trans;d.fov.Thickness=Cfg.FOV.Thick;d.fov.Visible=(Cfg.On and Cfg.FOV.On and Cfg.FOV.Show) end
    if d.st then
        local m=({normal="AIM",snap="SNAP",flick="FLICK",silent="SILENT"})[Cfg.AimMode] or"?"
        local t="XENO "..(Cfg.On and"["..m.."]"or"[OFF]")
        if S.tgt.part and Cfg.On then t=t..string.format(" | %s %.0fHP",S.tgt.name,S.tgt.hp) end
        d.st.Text=t;d.st.Color=Cfg.On and Color3.fromRGB(100,255,100)or Color3.fromRGB(255,100,100)
    end
    if Cfg.On and S.tgt.part and S.tgt.vis then
        local sp,on=W2S(S.tgt.part.Position)
        if sp and on then
            if d.line then d.line.From=scrCenter;d.line.To=sp;d.line.Color=Cfg.Vis.LineClr;d.line.Thickness=Cfg.Vis.LineW;d.line.Visible=Cfg.Vis.Line end
            if d.dot then d.dot.Position=sp;d.dot.Color=Cfg.Vis.DotClr;d.dot.Radius=Cfg.Vis.DotSz;d.dot.Visible=Cfg.Vis.Dot end
        else if d.line then d.line.Visible=false end;if d.dot then d.dot.Visible=false end end
    else if d.line then d.line.Visible=false end;if d.dot then d.dot.Visible=false end end
end
function HUD.Destroy() for _,dr in pairs(S.draw) do Kill(dr) end;S.draw={} end

local MC=Cfg.Menu.Color
local BG=Cfg.Menu.BgColor
local PNL=Color3.fromRGB(30,30,38)
local TXT=Color3.fromRGB(220,220,230)
local TXTD=Color3.fromRGB(140,140,155)
local TON=Color3.fromRGB(90,200,130)
local TOFF=Color3.fromRGB(50,50,55)

local G={}
function G.Crn(p,r) Instance.new("UICorner",p).CornerRadius=UDim.new(0,r or 6) end
function G.Stk(p,c,t) local s=Instance.new("UIStroke",p);s.Color=c or Color3.fromRGB(40,40,55);s.Thickness=t or 1;return s end

local function Cleanup()
    DEAD=true;task.wait(0.05)
    pcall(function() if S.aim.flickOn and S.aim.flickCF and Cam then Cam.CFrame=S.aim.flickCF end end)
    for _,c in ipairs(S.conns) do pcall(function() c:Disconnect() end) end;S.conns={}
    pcall(E.DelAll);pcall(WH.KillAll);pcall(HUD.Destroy);pcall(Exp.RTP);pcall(Exp.RSpin)
    pcall(function() if S.mobFrame then S.mobFrame:Destroy() end;if S.gui then S.gui:Destroy() end end)
    _G.XenoLoaded=false;_G.XenoCleanup=nil
end

function G.Create()
    pcall(function() if S.mobFrame then S.mobFrame:Destroy();S.mobFrame=nil end;if S.gui then S.gui:Destroy();S.gui=nil end end)
    local gui=Instance.new("ScreenGui");gui.Name="X_"..math.random(1e5,9e5);gui.ResetOnSpawn=false;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.DisplayOrder=999;Protect(gui);gui.Parent=SafeP();S.gui=gui

    local mW,mH=SC(460,math.min(Cam.ViewportSize.X-20,380)),SC(380,math.min(Cam.ViewportSize.Y-80,340))
    local main=Instance.new("Frame",gui);main.Name="MainFrame";main.Size=UDim2.new(0,mW,0,mH);main.Position=UDim2.new(0.5,-mW/2,0.5,-mH/2);main.BackgroundColor3=BG;main.BorderSizePixel=0;main.Visible=false;main.Active=true;main.ClipsDescendants=true;G.Crn(main,10);G.Stk(main,Color3.fromRGB(40,40,60),1)

    local title=Instance.new("TextLabel",main);title.Text="XENO v10 ☠";title.Size=UDim2.new(1,-60,0,30);title.Position=UDim2.new(0,12,0,5);title.BackgroundTransparency=1;title.TextColor3=MC;title.Font=Enum.Font.GothamBold;title.TextSize=SC(16,14);title.TextXAlignment=Enum.TextXAlignment.Left

    local xb=Instance.new("TextButton",main);xb.Text="✕";xb.Size=UDim2.new(0,28,0,28);xb.Position=UDim2.new(1,-36,0,4);xb.BackgroundColor3=Color3.fromRGB(255,60,60);xb.TextColor3=Color3.new(1,1,1);xb.TextSize=12;xb.Font=Enum.Font.GothamBold;xb.AutoButtonColor=false;G.Crn(xb,6);xb.MouseButton1Click:Connect(function() main.Visible=false end)

    local dragStart,startPos
    main.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
            dragStart=i.Position;startPos=main.Position
            i.Changed:Connect(function() if i.UserInputState==Enum.UserInputState.End then dragStart=nil end end)
        end
    end)
    table.insert(S.conns,UIS.InputChanged:Connect(function(i)
        if dragStart and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then
            local d=i.Position-dragStart;main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end))

    local tabH=Instance.new("Frame",main);tabH.Size=UDim2.new(1,0,0,28);tabH.Position=UDim2.new(0,0,0,38);tabH.BackgroundTransparency=1

    local content=Instance.new("Frame",main);content.Size=UDim2.new(1,-16,1,-75);content.Position=UDim2.new(0,8,0,70);content.BackgroundTransparency=1;content.ClipsDescendants=true

    local curTab=nil
    local tabBtns={}

    local function makeTab(name,icon,idx,total)
        local btn=Instance.new("TextButton",tabH)
        btn.Text=icon.." "..name;btn.Size=UDim2.new(1/total,0,1,0);btn.Position=UDim2.new((idx-1)/total,0,0,0)
        btn.BackgroundTransparency=1;btn.TextColor3=TXTD;btn.Font=Enum.Font.GothamBold;btn.TextSize=SC(11,10);btn.AutoButtonColor=false

        local sf=Instance.new("ScrollingFrame",content);sf.Size=UDim2.new(1,0,1,0);sf.BackgroundTransparency=1;sf.ScrollBarThickness=2;sf.ScrollBarImageColor3=MC;sf.BorderSizePixel=0;sf.Visible=false;sf.CanvasSize=UDim2.new(0,0,0,0)
        local lay=Instance.new("UIListLayout",sf);lay.Padding=UDim.new(0,5);lay.SortOrder=Enum.SortOrder.LayoutOrder
        lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() sf.CanvasSize=UDim2.new(0,0,0,lay.AbsoluteContentSize.Y+10) end)

        btn.MouseButton1Click:Connect(function()
            if curTab then curTab.Visible=false end;sf.Visible=true;curTab=sf
            for _,b in pairs(tabBtns) do b.TextColor3=TXTD end;btn.TextColor3=MC
        end)
        tabBtns[name]=btn
        return sf
    end

    local function makeToggle(parent,text,tbl,key,order)
        local f=Instance.new("Frame",parent);f.Size=UDim2.new(1,-4,0,SC(30,36));f.BackgroundColor3=PNL;f.BorderSizePixel=0;f.LayoutOrder=order or 0;G.Crn(f,5)
        local l=Instance.new("TextLabel",f);l.Text=text;l.Size=UDim2.new(0.75,-10,1,0);l.Position=UDim2.new(0,10,0,0);l.BackgroundTransparency=1;l.TextColor3=TXT;l.Font=Enum.Font.Gotham;l.TextSize=SC(11,12);l.TextXAlignment=Enum.TextXAlignment.Left;l.TextWrapped=true
        local sw=SC(20,24)
        local dot=Instance.new("Frame",f);dot.Size=UDim2.new(0,sw,0,sw);dot.Position=UDim2.new(1,-sw-8,0.5,-sw/2);dot.BackgroundColor3=tbl[key] and MC or TOFF;G.Crn(dot,4)
        local btn=Instance.new("TextButton",f);btn.Text="";btn.Size=UDim2.new(1,0,1,0);btn.BackgroundTransparency=1
        btn.MouseButton1Click:Connect(function()
            tbl[key]=not tbl[key]
            TweenService:Create(dot,TweenInfo.new(0.15),{BackgroundColor3=tbl[key] and MC or TOFF}):Play()
        end)
        return f
    end

    local function makeSlider(parent,text,mn,mx,tbl,key,fmt,order)
        local f=Instance.new("Frame",parent);f.Size=UDim2.new(1,-4,0,SC(42,48));f.BackgroundColor3=PNL;f.BorderSizePixel=0;f.LayoutOrder=order or 0;G.Crn(f,5)
        local l=Instance.new("TextLabel",f);l.Text=string.format("%s: "..(fmt or"%.1f"),text,tbl[key]);l.Size=UDim2.new(1,-12,0,16);l.Position=UDim2.new(0,8,0,3);l.BackgroundTransparency=1;l.TextColor3=TXT;l.TextSize=SC(10,11);l.Font=Enum.Font.Gotham;l.TextXAlignment=Enum.TextXAlignment.Left
        local tr=Instance.new("Frame",f);tr.Size=UDim2.new(1,-16,0,SC(6,8));tr.Position=UDim2.new(0,8,0,SC(26,28));tr.BackgroundColor3=Color3.fromRGB(40,40,50);tr.BorderSizePixel=0;G.Crn(tr,3)
        local pct=math.clamp((tbl[key]-mn)/(mx-mn),0,1)
        local fl=Instance.new("Frame",tr);fl.Size=UDim2.new(pct,0,1,0);fl.BackgroundColor3=MC;fl.BorderSizePixel=0;G.Crn(fl,3)
        local dragging=false
        local hb=Instance.new("TextButton",f);hb.Text="";hb.Size=UDim2.new(1,6,0,SC(20,28));hb.Position=UDim2.new(0,-3,0,SC(18,20));hb.BackgroundTransparency=1;hb.ZIndex=5
        local function upd(ix)
            local ap,as=tr.AbsolutePosition.X,tr.AbsoluteSize.X;if as<=0 then return end
            local r=math.clamp((ix-ap)/as,0,1);local v=mn+r*(mx-mn);tbl[key]=v
            fl.Size=UDim2.new(r,0,1,0);l.Text=string.format("%s: "..(fmt or"%.1f"),text,v)
        end
        hb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true;upd(i.Position.X) end end)
        table.insert(S.conns,UIS.InputChanged:Connect(function(i) if dragging and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then upd(i.Position.X) end end))
        table.insert(S.conns,UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end))
    end

    local function makeDD(parent,text,opts,tbl,key,order)
        local f=Instance.new("Frame",parent);f.Size=UDim2.new(1,-4,0,SC(30,36));f.BackgroundColor3=PNL;f.BorderSizePixel=0;f.LayoutOrder=order or 0;G.Crn(f,5)
        local l=Instance.new("TextLabel",f);l.Text=text;l.Size=UDim2.new(0.45,-5,1,0);l.Position=UDim2.new(0,10,0,0);l.BackgroundTransparency=1;l.TextColor3=TXT;l.TextSize=SC(11,12);l.Font=Enum.Font.Gotham;l.TextXAlignment=Enum.TextXAlignment.Left
        local btn=Instance.new("TextButton",f);btn.Text=tostring(tbl[key]);btn.Size=UDim2.new(0.5,-8,0.8,0);btn.Position=UDim2.new(0.48,0,0.1,0);btn.BackgroundColor3=Color3.fromRGB(35,35,45);btn.TextColor3=MC;btn.Font=Enum.Font.GothamBold;btn.TextSize=SC(11,12);btn.AutoButtonColor=false;G.Crn(btn,4)
        btn.MouseButton1Click:Connect(function()
            local idx=table.find(opts,tbl[key]) or 0;idx=idx+1;if idx>#opts then idx=1 end
            tbl[key]=opts[idx];btn.Text=tostring(opts[idx])
        end)
    end

    local function makeSep(parent,text,order)
        local f=Instance.new("Frame",parent);f.Size=UDim2.new(1,-4,0,18);f.BackgroundTransparency=1;f.LayoutOrder=order or 0
        local l=Instance.new("TextLabel",f);l.Text="— "..text.." —";l.Size=UDim2.new(1,0,1,0);l.BackgroundTransparency=1;l.TextColor3=MC;l.Font=Enum.Font.GothamBold;l.TextSize=10;l.TextXAlignment=Enum.TextXAlignment.Center
    end

    local tabAim=makeTab("Legit","⚔",1,4)
    local tabVis=makeTab("Visuals","👁",2,4)
    local tabWH=makeTab("Chams","◈",3,4)
    local tabMisc=makeTab("Misc","⚙",4,4)

    tabBtns["Legit"].TextColor3=MC;tabAim.Visible=true;curTab=tabAim

    local n=0
    makeSep(tabAim,"AIMBOT",n);n=n+1
    makeToggle(tabAim,"Enabled",Cfg,"On",n);n=n+1
    makeToggle(tabAim,"360° Mode",Cfg,"Aim360",n);n=n+1
    makeDD(tabAim,"Mode",Exec.canSilent and{"normal","snap","silent"}or{"normal","snap","flick"},Cfg,"AimMode",n);n=n+1
    makeDD(tabAim,"Bone",{"Head","UpperTorso","HumanoidRootPart"},Cfg,"Part",n);n=n+1
    makeDD(tabAim,"Priority",{"FOV","Distance","Health"},Cfg,"Priority",n);n=n+1
    makeToggle(tabAim,"FOV Circle",Cfg.FOV,"On",n);n=n+1
    makeSlider(tabAim,"FOV Radius",10,500,Cfg.FOV,"R","%.0f",n);n=n+1
    makeToggle(tabAim,"Smoothing",Cfg.Smooth,"On",n);n=n+1
    makeSlider(tabAim,"Smooth",0.01,1,Cfg.Smooth,"Amt","%.2f",n);n=n+1
    makeToggle(tabAim,"Prediction",Cfg.Pred,"On",n);n=n+1
    makeSep(tabAim,"CHECKS",n);n=n+1
    makeToggle(tabAim,"Team Check",Cfg.Checks,"Team",n);n=n+1
    makeToggle(tabAim,"Wall Check",Cfg.Checks,"Wall",n);n=n+1
    makeSlider(tabAim,"Max Distance",50,2000,Cfg.Limits,"MaxD","%.0f",n);n=n+1
    makeSep(tabAim,"TRIGGERBOT",n);n=n+1
    makeToggle(tabAim,"TriggerBot",Cfg.TB,"On",n);n=n+1
    makeToggle(tabAim,"FOV Check",Cfg.TB,"FOVCheck",n);n=n+1
    makeSlider(tabAim,"TB FOV",10,200,Cfg.TB,"TBFOV","%.0f",n);n=n+1
    makeSlider(tabAim,"TB Delay",0.01,0.5,Cfg.TB,"Delay","%.2fs",n);n=n+1

    n=0
    makeSep(tabVis,"ESP",n);n=n+1
    makeToggle(tabVis,"ESP Enabled",Cfg.ESP,"On",n);n=n+1
    makeToggle(tabVis,"Show Team",Cfg.ESP,"ShowTeam",n);n=n+1
    makeSlider(tabVis,"Max Distance",100,3000,Cfg.ESP,"MaxDist","%.0f",n);n=n+1
    makeSep(tabVis,"BOX",n);n=n+1
    makeToggle(tabVis,"Box",Cfg.ESP.Box,"On",n);n=n+1
    makeDD(tabVis,"Box Style",{"Corner","Full"},Cfg.ESP.Box,"Style",n);n=n+1
    makeToggle(tabVis,"Box Outline",Cfg.ESP.Box,"Outline",n);n=n+1
    makeToggle(tabVis,"Vis Check Color",Cfg.ESP.Box,"VisCheck",n);n=n+1
    makeSep(tabVis,"NAME",n);n=n+1
    makeToggle(tabVis,"Name",Cfg.ESP.Name,"On",n);n=n+1
    makeDD(tabVis,"Name Pos",{"Top","Bottom"},Cfg.ESP.Name,"Pos",n);n=n+1
    makeDD(tabVis,"Name Fmt",{"Name+Dist","Name"},Cfg.ESP.Name,"Fmt",n);n=n+1
    makeToggle(tabVis,"Name Shadow",Cfg.ESP.Name,"Shadow",n);n=n+1
    makeSep(tabVis,"HEALTH",n);n=n+1
    makeToggle(tabVis,"Health Bar",Cfg.ESP.HP,"On",n);n=n+1
    makeDD(tabVis,"HP Position",{"Left","Right","Bottom"},Cfg.ESP.HP,"Pos",n);n=n+1
    makeToggle(tabVis,"HP Text",Cfg.ESP.HP,"ShowText",n);n=n+1
    makeToggle(tabVis,"HP Outline",Cfg.ESP.HP,"Outline",n);n=n+1
    makeToggle(tabVis,"HP Smooth",Cfg.ESP.HP,"Smooth",n);n=n+1
    makeSep(tabVis,"EXTRAS",n);n=n+1
    makeToggle(tabVis,"Tracers",Cfg.ESP.Tracer,"On",n);n=n+1
    makeDD(tabVis,"Tracer Origin",{"Bottom","Center","Top"},Cfg.ESP.Tracer,"Origin",n);n=n+1
    makeToggle(tabVis,"Tracer Outline",Cfg.ESP.Tracer,"Outline",n);n=n+1
    makeToggle(tabVis,"Head Dot",Cfg.ESP.HeadDot,"On",n);n=n+1
    makeToggle(tabVis,"Distance Text",Cfg.ESP.Dist,"On",n);n=n+1
    makeToggle(tabVis,"Weapon Text",Cfg.ESP.Weapon,"On",n);n=n+1
    makeToggle(tabVis,"Flags",Cfg.ESP.Flags,"On",n);n=n+1
    makeToggle(tabVis,"OFS Arrows",Cfg.ESP.OFS,"On",n);n=n+1

    n=0
    makeSep(tabWH,"WALLHACK",n);n=n+1
    makeToggle(tabWH,"Wallhack",Cfg.WH,"On",n);n=n+1
    makeToggle(tabWH,"Show Team",Cfg.WH,"ShowTeam",n);n=n+1
    makeSlider(tabWH,"Fill Trans",0,1,Cfg.WH,"FT","%.1f",n);n=n+1

    n=0
    makeSep(tabMisc,"MOVEMENT",n);n=n+1
    makeToggle(tabMisc,"3rd Person Cam",Cfg.TP,"On",n);n=n+1
    makeSlider(tabMisc,"Cam Distance",5,100,Cfg.TP,"Dist","%.0f",n);n=n+1
    makeToggle(tabMisc,"SpinBot",Cfg.Spin,"On",n);n=n+1
    makeSlider(tabMisc,"Spin Speed",1,50,Cfg.Spin,"Spd","%.0f",n);n=n+1
    makeToggle(tabMisc,"Speed Boost",Cfg.Speed,"On",n);n=n+1
    makeSlider(tabMisc,"Speed Mult",1,3,Cfg.Speed,"Mult","%.1fx",n);n=n+1
    makeSep(tabMisc,"SYSTEM",n);n=n+1
    local inf=Instance.new("TextLabel",tabMisc);inf.Text="Executor: "..Exec.name.." | Silent: "..(Exec.canSilent and"YES"or"NO");inf.Size=UDim2.new(1,-4,0,20);inf.BackgroundTransparency=1;inf.TextColor3=TXTD;inf.TextSize=10;inf.Font=Enum.Font.Gotham;inf.LayoutOrder=n;n=n+1
    local ub=Instance.new("TextButton",tabMisc);ub.Text="Unload";ub.Size=UDim2.new(1,-4,0,SC(28,34));ub.BackgroundColor3=Color3.fromRGB(200,50,50);ub.TextColor3=Color3.new(1,1,1);ub.TextSize=SC(12,13);ub.Font=Enum.Font.GothamBold;ub.AutoButtonColor=false;ub.LayoutOrder=n;G.Crn(ub,5)
    ub.MouseButton1Click:Connect(function() Notify("X","Bye",2);task.delay(0.3,Cleanup) end)

    local obs=SC(34,42);local ob=Instance.new("TextButton",gui);ob.Text="☠";ob.Size=UDim2.new(0,obs,0,obs);ob.Position=UDim2.new(1,-obs-8,0,SC(8,46));ob.BackgroundColor3=MC;ob.TextColor3=Color3.new(1,1,1);ob.TextSize=SC(16,18);ob.Font=Enum.Font.GothamBlack;ob.AutoButtonColor=false;G.Crn(ob,obs/2);G.Stk(ob,Color3.fromRGB(120,160,255),1)
    ob.MouseButton1Click:Connect(function() main.Visible=not main.Visible end)

    if IsMobile then
        local bf=Instance.new("Frame",gui);bf.Size=UDim2.new(0,50,0,140);bf.Position=UDim2.new(0,4,0.5,-70);bf.BackgroundTransparency=1;S.mobFrame=bf
        local mb={{"AIM",0,Color3.fromRGB(80,220,120),function() Cfg.On=not Cfg.On end,function() return Cfg.On end},{"ESP",44,MC,function() Cfg.ESP.On=not Cfg.ESP.On;if not Cfg.ESP.On then E.DelAll() end end,function() return Cfg.ESP.On end},{"WH",88,Color3.fromRGB(255,180,50),function() Cfg.WH.On=not Cfg.WH.On;if not Cfg.WH.On then WH.KillAll() end end,function() return Cfg.WH.On end}}
        for _,d in ipairs(mb) do
            local b=Instance.new("TextButton",bf);b.Size=UDim2.new(0,46,0,38);b.Position=UDim2.new(0,0,0,d[2]);b.BackgroundColor3=d[5]()and d[3]or Color3.fromRGB(40,40,50);b.TextColor3=Color3.new(1,1,1);b.Text=d[1];b.TextSize=10;b.Font=Enum.Font.GothamBold;b.AutoButtonColor=false;G.Crn(b,6);G.Stk(b,d[3],1)
            b.MouseButton1Click:Connect(function() d[4]();b.BackgroundColor3=d[5]()and d[3]or Color3.fromRGB(40,40,50) end)
        end
    end
end

local function Loop()
    table.insert(S.conns,RunService.RenderStepped:Connect(function(dt)
        if DEAD then return end
        S.frame=S.frame+1
        RefreshCam()
        if not S.me.alive then S.tgt.part=nil;S.tgt.plr=nil;S.tgt.vis=false end
        if Cfg.On and S.me.alive then
            local part,plr=T.Find()
            if part then
                S.tgt.part=part;S.tgt.plr=plr;S.tgt.name=plr and plr.Name or"?"
                S.tgt.dist=(camPos-part.Position).Magnitude;S.tgt.vis=true
                local ch=plr and plr.Character;local hp,mhp=Res.HP(ch);S.tgt.hp=hp;S.tgt.mhp=mhp
                if Cfg.AimMode=="silent" and Cfg.Silent.On then S.aim.silentPos=A.Pred(part)
                else A.Apply(part) end
            else
                if not S.tgt.plr then S.tgt.part=nil;S.tgt.name="";S.tgt.lastPos=nil;S.tgt.sVel=Vector3.zero;S.aim.silentPos=nil end
                S.tgt.vis=false
            end
        else S.aim.silentPos=nil end
        Flk.Update();Fire.Update()
        if S.frame%2==0 then HUD.Update() end
        if Cfg.ESP.On then E.UpdateBatch(dt) end
        if S.frame%5==0 then RefreshPL();WH.UpdateAll() end
        Exp.TP();Exp.Spin(dt);Exp.Speed(dt)
    end))
end

local function Input()
    if not IsMobile then table.insert(S.conns,UIS.InputBegan:Connect(function(i,g)
        if DEAD or g then return end
        if i.KeyCode==Enum.KeyCode.F1 then Cfg.On=not Cfg.On;Notify("X",Cfg.On and"AIM ON"or"AIM OFF")
        elseif i.KeyCode==Enum.KeyCode.F2 then Cfg.ESP.On=not Cfg.ESP.On;if not Cfg.ESP.On then E.DelAll() end;Notify("X",Cfg.ESP.On and"ESP ON"or"ESP OFF")
        elseif i.KeyCode==Enum.KeyCode.F3 then Cfg.WH.On=not Cfg.WH.On;if not Cfg.WH.On then WH.KillAll() end;Notify("X",Cfg.WH.On and"WH ON"or"WH OFF")
        elseif i.KeyCode==Enum.KeyCode.RightShift then if S.gui then local mf=S.gui:FindFirstChild("MainFrame");if mf then mf.Visible=not mf.Visible end end end
    end)) end
end

_G.XenoCleanup=Cleanup
table.insert(S.conns,Players.PlayerRemoving:Connect(function(p) if DEAD then return end;E.Del(p.UserId);WH.Kill(p.UserId) end))
SetupChar();task.wait(0.5);Fire.Init();HUD.Create()
if Exec.canSilent and Cfg.Silent.On then Sil.Install() end
G.Create();Input();Loop()
Notify("Xeno v10","Loaded | "..Cfg.AimMode:upper(),5)

end)
if not ok then pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="XENO ERROR",Text=tostring(err):sub(1,100),Duration=10}) end);warn("[XENO]",err) end
```
