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

Notify("XENO","Loading v9.8...",3)

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
        Colors={
            EBox=Color3.fromRGB(255,50,50),EName=Color3.fromRGB(255,255,255),
            TBox=Color3.fromRGB(50,255,50),TName=Color3.fromRGB(255,255,255),
            Outline=Color3.fromRGB(0,0,0),
            HPLo=Color3.fromRGB(255,50,50),HPMid=Color3.fromRGB(255,200,50),HPHi=Color3.fromRGB(80,220,120),
            HPBg=Color3.fromRGB(25,25,25),HeadDotClr=Color3.fromRGB(255,255,255),
        },
        Box={On=true,W=1,CL=0.25,Outline=true},
        Name={On=true,Sz=SC(13,11)},
        HP={On=true,W=3,Off=5},
        Tracer={On=false,W=1},
        HeadDot={On=false,Rad=SC(3,4)},
    },
    WH={On=false,Fill=Color3.fromRGB(255,0,0),FT=0.5,Out=Color3.fromRGB(255,255,255),OT=0,
        TFill=Color3.fromRGB(0,255,0),TOut=Color3.fromRGB(200,255,200),ShowTeam=false},
    Wall={Thresh=0.5,MaxPierce=3},
    Checks={Team=true,Alive=true,Wall=true,FF=true,Dist=true},
    Limits={MaxD=800,MaxA=SC(75,90),MinD=5},
    TP={On=false,Dist=12},Spin={On=false,Spd=15},Speed={On=false,Mult=1.5},
}

local S={
    tgt={part=nil,plr=nil,dist=0,hp=0,mhp=0,name="",lastT=0,vis=false,lastPos=nil,sVel=Vector3.zero,isBot=false,botModel=nil},
    me={char=nil,hum=nil,root=nil,alive=false},
    aim={silentPos=nil,hooked=false,flickOn=false,flickCF=nil},
    fire={last=0,method="none"},draw={},espC={},whC={},
    conns={},gui=nil,mobFrame=nil,subMenu=nil,spinAng=0,
    frame=0,espBatch=0,
}

local vpX,vpY=1920,1080
local camPos=Vector3.zero
local camLook=Vector3.new(0,0,-1)
local scrCenter=Vector2.new(960,540)

local function RefreshCam()
    if not Cam then Cam=WS.CurrentCamera;if not Cam then return end end
    vpX=Cam.ViewportSize.X;vpY=Cam.ViewportSize.Y
    scrCenter=Vector2.new(vpX*0.5,vpY*0.5)
    camPos=Cam.CFrame.Position
    camLook=Cam.CFrame.LookVector
end

local function W2S(pos)
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
    return ch:FindFirstChild(Cfg.Part) or ch:FindFirstChild("Head") or Res.Root(ch)
end

function T.Valid(ch,tp)
    if not ch or not ch.Parent then return false end
    local rp=Res.Root(ch);if not rp then return false end
    local hp=Res.HP(ch);if hp<=0 then return false end
    if tp and Cfg.Checks.Team and TeamEq(Plr,tp) then return false end
    if Cfg.Checks.Dist and S.me.root then local d=(rp.Position-S.me.root.Position).Magnitude;if d>Cfg.Limits.MaxD or d<Cfg.Limits.MinD then return false end end
    return true
end

function T.Ang(p) if not p then return 180 end;local dir=p.Position-camPos;if dir.Magnitude<0.001 then return 0 end;return math.deg(math.acos(math.clamp(camLook:Dot(dir.Unit),-1,1))) end

function T.Find()
    local is360=Cfg.Aim360 or(Cfg.AimMode=="silent" and Cfg.Silent.Use360)
    if Cfg.Sticky and S.tgt.part and S.tgt.plr then
        local ch=S.tgt.plr.Character
        if not ch or not ch.Parent or Res.HP(ch)<=0 then S.tgt.part=nil;S.tgt.plr=nil;S.tgt.vis=false
        else local p=T.GetP(ch);if not p then S.tgt.part=nil;S.tgt.plr=nil;S.tgt.vis=false
        else local _,on=W2S(p.Position);local inF=not Cfg.FOV.On or SDist(p.Position)<=Cfg.FOV.R*1.5;local vis=not Cfg.Checks.Wall or CanSee(p,S.me.char);if is360 then on=true;inF=true end
            if on and inF and vis then S.tgt.part=p;S.tgt.lastT=tick();S.tgt.vis=true;return p,S.tgt.plr
            elseif not vis then S.tgt.part=nil;S.tgt.plr=nil;S.tgt.vis=false
            elseif tick()-S.tgt.lastT>Cfg.StickyTime then S.tgt.part=nil;S.tgt.plr=nil;S.tgt.vis=false
            else S.tgt.vis=false;return nil,nil end end end
    end
    local bp,bpl,bs=nil,nil,-9999
    for _,tp in ipairs(Players:GetPlayers()) do
        if tp==Plr then continue end
        local ch=tp.Character;if not T.Valid(ch,tp) then continue end
        local p=T.GetP(ch);if not p then continue end
        local _,on=W2S(p.Position);if not is360 and not on then continue end
        if Cfg.FOV.On and not is360 and SDist(p.Position)>Cfg.FOV.R then continue end
        if not is360 and T.Ang(p)>Cfg.Limits.MaxA then continue end
        if Cfg.Checks.Wall and not CanSee(p,S.me.char) then continue end
        local sd=SDist(p.Position);local sc=10000-sd
        if sc>bs then bs=sc;bp=p;bpl=tp end
    end
    if bp then S.tgt.vis=true end
    return bp,bpl
end

local A={}
function A.Pred(p) if not Cfg.Pred.On or not p then return p and p.Position or Vector3.zero end;local cur=p.Position;if S.tgt.lastPos then S.tgt.sVel=S.tgt.sVel+((cur-S.tgt.lastPos)*60-S.tgt.sVel)*Cfg.Pred.VelSmooth end;S.tgt.lastPos=cur;return cur+S.tgt.sVel*Cfg.Pred.Factor end
function A.GetCF(p) if not p then return nil end;local t=A.Pred(p);local d=t-camPos;return d.Magnitude>0.001 and CFrame.lookAt(camPos,camPos+d.Unit)or nil end
function A.Smooth(p) if not p then return end;local tcf=A.GetCF(p);if not tcf then return end;if Cfg.Smooth.On then local sm=Cfg.Smooth.Amt;if Cfg.Smooth.Dynamic then local t=math.clamp(T.Ang(p)/math.max(Cfg.Limits.MaxA,1),0,1);sm=Cfg.Smooth.Min+(Cfg.Smooth.Max-Cfg.Smooth.Min)*t end;Cam.CFrame=Cam.CFrame:Lerp(tcf,sm) else Cam.CFrame=tcf end end

local Sil={}
function Sil.Should() return not DEAD and Cfg.On and Cfg.Silent.On and Cfg.AimMode=="silent" and S.tgt.part and((Cfg.Silent.Use360 or Cfg.Aim360)or S.tgt.vis)and(Cfg.Silent.Chance>=100 or math.random(1,100)<=Cfg.Silent.Chance) end
function Sil.Pos() if not S.tgt.part then return nil end;return A.Pred(S.tgt.part) end
function Sil.CF() local p=Sil.Pos();return p and CFrame.new(p)or nil end
function Sil.Install()
    if S.aim.hooked or not Exec.canSilent then if not Exec.canSilent then Cfg.AimMode="flick";Cfg.Silent.On=false;Cfg.Flick.On=true end;return end
    local wrap=newcclosure or newclosure or function(f) return f end;local hooked=false
    if hasHM and hasNC then pcall(function()
        local old;old=hookmetamethod(game,"__namecall",wrap(function(self,...) if DEAD then return old(self,...) end;local m=getnamecallmethod();local args={...};if Sil.Should() then local tp=Sil.Pos();if tp then if m=="Raycast" and self==WS and #args>=2 and typeof(args[1])=="Vector3" then S.aim.silentPos=tp;local d=(tp-args[1]);if d.Magnitude>0.001 then d=d.Unit*1000 end;return old(self,args[1],d,select(3,...)) end;if(m=="FindPartOnRay"or m=="FindPartOnRayWithIgnoreList"or m=="FindPartOnRayWithWhitelist")and self==WS and typeof(args[1])=="Ray" then S.aim.silentPos=tp;local d=(tp-args[1].Origin);if d.Magnitude>0.001 then d=d.Unit*1000 end;return old(self,Ray.new(args[1].Origin,d),select(2,...)) end end end;return old(self,...) end));hooked=true
    end);pcall(function()
        local old;old=hookmetamethod(game,"__index",wrap(function(self,k) if DEAD then return old(self,k) end;if Sil.Should() and self==Mouse then if k=="Hit" then local cf=Sil.CF();if cf then S.aim.silentPos=cf.Position;return cf end elseif k=="Target" and S.tgt.part then return S.tgt.part elseif k=="UnitRay" then local p=Sil.Pos();if p then local d=p-camPos;if d.Magnitude>0.001 then return Ray.new(camPos,d.Unit) end end end end;return old(self,k) end))
    end) end
    S.aim.hooked=hooked;if not hooked then Cfg.AimMode="flick";Cfg.Silent.On=false;Cfg.Flick.On=true end
end

local Flk={}
function Flk.Down() if IsMobile then return Cfg.Flick.MobileAuto and S.tgt.vis end;local o,r=pcall(function() return UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) end);return o and r end
function Flk.Update() if DEAD or Cfg.AimMode~="flick" or not Cfg.Flick.On then if S.aim.flickOn and S.aim.flickCF and Cfg.Flick.Restore then Cam.CFrame=S.aim.flickCF end;S.aim.flickOn=false;S.aim.flickCF=nil;return end;local down=Flk.Down();if down and not S.aim.flickOn and Cfg.On and S.tgt.vis and S.tgt.part then S.aim.flickCF=Cam.CFrame;S.aim.flickOn=true elseif down and S.aim.flickOn then if S.tgt.part and S.tgt.vis then local tcf=A.GetCF(S.tgt.part);if tcf then Cam.CFrame=Cfg.Flick.Speed>=1 and tcf or Cam.CFrame:Lerp(tcf,Cfg.Flick.Speed) end else if S.aim.flickCF and Cfg.Flick.Restore then Cam.CFrame=S.aim.flickCF end;S.aim.flickOn=false end elseif not down and S.aim.flickOn then if S.aim.flickCF and Cfg.Flick.Restore then Cam.CFrame=S.aim.flickCF end;S.aim.flickOn=false end end

local Fire={};function Fire.Init() S.fire.method="none";if typeof(mouse1press)=="function" then S.fire.method="mouse1press";return end;pcall(function() game:GetService("VirtualInputManager");S.fire.method="vim" end) end;function Fire.Click() if S.fire.method=="mouse1press" then pcall(function() mouse1press();task.delay(0.04,function() pcall(mouse1release) end) end);return true elseif S.fire.method=="vim" then pcall(function() local v=game:GetService("VirtualInputManager");v:SendMouseButtonEvent(Mouse.X,Mouse.Y,0,true,game,0);task.delay(0.04,function() pcall(function() v:SendMouseButtonEvent(Mouse.X,Mouse.Y,0,false,game,0) end) end) end);return true end;return false end;function Fire.Update() if DEAD or not Cfg.TB.On or not Cfg.On or S.fire.method=="none" then return end;if S.tgt.vis and S.tgt.part and(Cfg.TB.Auto or IsMobile)and tick()-S.fire.last>=Cfg.TB.Delay then if Fire.Click() then S.fire.last=tick() end end end

local Exp={}
function Exp.TP() if DEAD or not Cfg.TP.On then return end;pcall(function() if Plr.CameraMaxZoomDistance<Cfg.TP.Dist then Plr.CameraMaxZoomDistance=Cfg.TP.Dist end end) end
function Exp.RTP() pcall(function() Plr.CameraMaxZoomDistance=128 end) end
function Exp.Spin(dt) if DEAD or not Cfg.Spin.On or not S.me.root or not S.me.alive then return end;S.spinAng=(S.spinAng+Cfg.Spin.Spd*dt*60)%360;pcall(function() S.me.root.CFrame=CFrame.new(S.me.root.Position)*CFrame.Angles(0,math.rad(S.spinAng),0) end) end
function Exp.RSpin() S.spinAng=0 end
function Exp.Speed(dt) if DEAD or not Cfg.Speed.On or not S.me.root or not S.me.alive or not S.me.hum then return end;pcall(function() local md=S.me.hum.MoveDirection;if md.Magnitude<0.1 then return end;S.me.root.CFrame=S.me.root.CFrame+md.Unit*S.me.hum.WalkSpeed*(Cfg.Speed.Mult-1)*dt end) end

local E={}

function E.New(uid)
    if DEAD or S.espC[uid] or not drawOK then return end
    local o={}
    o.box=ND("Square");o.box.Filled=false;o.box.Thickness=Cfg.ESP.Box.W
    o.boxO=ND("Square");o.boxO.Filled=false;o.boxO.Thickness=Cfg.ESP.Box.W+2;o.boxO.Color=Cfg.ESP.Colors.Outline
    o.name=ND("Text");o.name.Center=true;o.name.Outline=true;o.name.Size=Cfg.ESP.Name.Sz
    o.hpBg=ND("Square");o.hpBg.Filled=true
    o.hpFill=ND("Square");o.hpFill.Filled=true
    o.tracer=ND("Line")
    o.hdot=ND("Circle");o.hdot.Filled=true;o.hdot.NumSides=10
    S.espC[uid]=o
end

function E.Hide(o)
    if not o then return end
    if o.box then o.box.Visible=false end
    if o.boxO then o.boxO.Visible=false end
    if o.name then o.name.Visible=false end
    if o.hpBg then o.hpBg.Visible=false end
    if o.hpFill then o.hpFill.Visible=false end
    if o.tracer then o.tracer.Visible=false end
    if o.hdot then o.hdot.Visible=false end
end

function E.Del(uid)
    local o=S.espC[uid];if not o then return end
    E.Hide(o)
    Kill(o.box);Kill(o.boxO);Kill(o.name);Kill(o.hpBg);Kill(o.hpFill);Kill(o.tracer);Kill(o.hdot)
    S.espC[uid]=nil
end

function E.DelAll() local k={};for uid in pairs(S.espC) do k[#k+1]=uid end;for _,uid in ipairs(k) do E.Del(uid) end end

function E.Render(uid,ch,dname,isTeam)
    local o=S.espC[uid]
    if not o then return end
    if not ch or not ch.Parent then E.Hide(o);return end
    local rp=Res.Root(ch);if not rp then E.Hide(o);return end
    local hp,mhp=Res.HP(ch);if hp<=0 then E.Hide(o);return end
    if isTeam and not Cfg.ESP.ShowTeam then E.Hide(o);return end
    local rpPos=rp.Position
    if S.me.root then
        local d=(rpPos-S.me.root.Position).Magnitude
        if d>Cfg.ESP.MaxDist then E.Hide(o);return end
    end

    local head=ch:FindFirstChild("Head")
    local topY=head and(head.Position.Y+1)or(rpPos.Y+3)
    local botY=rpPos.Y-3

    local topSP,topOn=W2S(Vector3.new(rpPos.X,topY,rpPos.Z))
    if not topOn then E.Hide(o);return end
    local botSP,botOn=W2S(Vector3.new(rpPos.X,botY,rpPos.Z))
    if not botOn then E.Hide(o);return end

    local h=math.abs(botSP.Y-topSP.Y)
    if h<3 then E.Hide(o);return end
    local w=h*0.6
    local bx=topSP.X-w*0.5
    local by=topSP.Y

    if bx<-200 or bx>vpX+200 or by<-200 or by>vpY+200 then E.Hide(o);return end

    local CC=Cfg.ESP.Colors
    local boxClr=isTeam and CC.TBox or CC.EBox
    local nameClr=isTeam and CC.TName or CC.EName
    local dist=S.me.root and math.floor((rpPos-S.me.root.Position).Magnitude) or 0

    if Cfg.ESP.Box.On and o.box then
        local sz=Vector2.new(w,h);local pos=Vector2.new(bx,by)
        o.box.Size=sz;o.box.Position=pos;o.box.Color=boxClr;o.box.Thickness=Cfg.ESP.Box.W;o.box.Visible=true
        if Cfg.ESP.Box.Outline and o.boxO then
            o.boxO.Size=Vector2.new(w+4,h+4);o.boxO.Position=Vector2.new(bx-2,by-2);o.boxO.Color=CC.Outline;o.boxO.Visible=true
        elseif o.boxO then o.boxO.Visible=false end
    else
        if o.box then o.box.Visible=false end
        if o.boxO then o.boxO.Visible=false end
    end

    if Cfg.ESP.Name.On and o.name then
        o.name.Text=dname.." ["..dist.."m]"
        o.name.Color=nameClr;o.name.Size=Cfg.ESP.Name.Sz
        o.name.Position=Vector2.new(bx+w*0.5,by-Cfg.ESP.Name.Sz-2);o.name.Visible=true
    elseif o.name then o.name.Visible=false end

    if Cfg.ESP.HP.On then
        local pct=math.clamp(hp/math.max(mhp,1),0,1)
        local bW=Cfg.ESP.HP.W;local off=Cfg.ESP.HP.Off
        local bgX=bx-off-bW-1;local fH=math.max(h*pct,1)
        if o.hpBg then o.hpBg.Position=Vector2.new(bgX,by-1);o.hpBg.Size=Vector2.new(bW+2,h+2);o.hpBg.Color=CC.HPBg;o.hpBg.Visible=true end
        if o.hpFill then o.hpFill.Position=Vector2.new(bgX+1,by+h-fH);o.hpFill.Size=Vector2.new(bW,fH);o.hpFill.Color=HPCol(pct);o.hpFill.Visible=true end
    else
        if o.hpBg then o.hpBg.Visible=false end
        if o.hpFill then o.hpFill.Visible=false end
    end

    if Cfg.ESP.Tracer.On and o.tracer then
        o.tracer.From=Vector2.new(vpX*0.5,vpY);o.tracer.To=botSP;o.tracer.Color=boxClr;o.tracer.Thickness=Cfg.ESP.Tracer.W;o.tracer.Visible=true
    elseif o.tracer then o.tracer.Visible=false end

    if Cfg.ESP.HeadDot.On and head and o.hdot then
        local sp,on=W2S(head.Position)
        if sp and on then o.hdot.Position=sp;o.hdot.Radius=Cfg.ESP.HeadDot.Rad;o.hdot.Color=CC.HeadDotClr;o.hdot.Visible=true
        else o.hdot.Visible=false end
    elseif o.hdot then o.hdot.Visible=false end
end

local playerList={}
local playerListTick=0

local function RefreshPlayerList()
    if tick()-playerListTick<0.5 then return end
    playerListTick=tick()
    playerList=Players:GetPlayers()
end

function E.UpdateBatch()
    if DEAD then return end
    RefreshPlayerList()
    local count=#playerList
    if count<=1 then return end

    local perFrame=math.max(math.ceil((count-1)/3),1)
    local startIdx=S.espBatch
    local activeKeys={}
    local processed=0

    for i=1,count do
        if processed>=perFrame then break end
        local idx=((startIdx+i-2)%(count))+1
        local tp=playerList[idx]
        if not tp or tp==Plr then continue end
        processed=processed+1
        local uid=tp.UserId
        local ch=tp.Character
        if not ch or not ch.Parent or Res.HP(ch)<=0 then
            if S.espC[uid] then E.Hide(S.espC[uid]) end
            continue
        end
        activeKeys[uid]=true
        if not S.espC[uid] then E.New(uid) end
        E.Render(uid,ch,tp.DisplayName or tp.Name,TeamEq(Plr,tp))
    end
    S.espBatch=(startIdx+processed)%(math.max(count-1,1))

    if S.frame%30==0 then
        for uid in pairs(S.espC) do
            local found=false
            for _,tp in ipairs(playerList) do
                if tp.UserId==uid then found=true;break end
            end
            if not found then E.Del(uid) end
        end
    end
end

local WH={}
function WH.Make(uid,ch,isTeam) if DEAD or S.whC[uid] or not ch or not ch.Parent then return end;local hl=Instance.new("Highlight");hl.Name="XWH";hl.Adornee=ch;hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop;hl.Enabled=true;hl.FillColor=isTeam and Cfg.WH.TFill or Cfg.WH.Fill;hl.OutlineColor=isTeam and Cfg.WH.TOut or Cfg.WH.Out;hl.FillTransparency=Cfg.WH.FT;hl.OutlineTransparency=Cfg.WH.OT;pcall(function() hl.Parent=ch end);S.whC[uid]=hl end
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
    d.line=ND("Line")
    d.dot=ND("Circle");d.dot.Filled=true;d.dot.NumSides=10
    d.st=ND("Text");d.st.Center=false;d.st.Outline=true;d.st.Size=SC(14,12);d.st.Position=Vector2.new(10,SC(10,40));d.st.Visible=true
end
function HUD.Update()
    if DEAD or not drawOK then return end
    local d=S.draw
    if d.fov then d.fov.Position=scrCenter;d.fov.Radius=Cfg.FOV.R;d.fov.Color=Cfg.FOV.Color;d.fov.Transparency=Cfg.FOV.Trans;d.fov.Thickness=Cfg.FOV.Thick;d.fov.Visible=(Cfg.On and Cfg.FOV.On and Cfg.FOV.Show) end
    if d.st then
        local t="XENO "..(Cfg.On and"[ON]"or"[OFF]")
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

local GC={bg=Color3.fromRGB(18,18,28),hdr=Color3.fromRGB(12,12,22),pnl=Color3.fromRGB(25,25,40),acc=Color3.fromRGB(90,130,255),accG=Color3.fromRGB(120,160,255),grn=Color3.fromRGB(80,220,120),red=Color3.fromRGB(255,70,70),org=Color3.fromRGB(255,180,50),txt=Color3.fromRGB(230,230,240),txtD=Color3.fromRGB(140,140,160),brd=Color3.fromRGB(45,45,70),brdA=Color3.fromRGB(90,130,255),tOn=Color3.fromRGB(90,200,130),tOff=Color3.fromRGB(60,60,80),sF=Color3.fromRGB(90,130,255),sB=Color3.fromRGB(40,40,60),ddBg=Color3.fromRGB(20,20,35),tabBg=Color3.fromRGB(18,18,30),tabA=Color3.fromRGB(25,25,45)}
local DDL,DDB=nil,nil
local function CloseDD() if DDL then pcall(function() DDL:Destroy() end);DDL=nil end;if DDB then pcall(function() DDB:FindFirstChildOfClass("UIStroke").Color=GC.brd end);DDB=nil end end
local function CloseSub() if S.subMenu then pcall(function() S.subMenu:Destroy() end);S.subMenu=nil end end
local G={}
function G.Crn(p,r) Instance.new("UICorner",p).CornerRadius=UDim.new(0,r or 8) end
function G.Stk(p,col,t) local s=Instance.new("UIStroke",p);s.Color=col or GC.brd;s.Thickness=t or 1;return s end
function G.Drag(f,h) local dr,ds,sp=false,nil,nil;h.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dr=true;ds=i.Position;sp=f.Position end end);table.insert(S.conns,UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then dr=false end end));table.insert(S.conns,UIS.InputChanged:Connect(function(i) if dr and(i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseMovement) then local d2=i.Position-ds;f.Position=UDim2.new(sp.X.Scale,sp.X.Offset+d2.X,sp.Y.Scale,sp.Y.Offset+d2.Y) end end)) end
function G.Sec(p,t,y) local ln=Instance.new("Frame",p);ln.Size=UDim2.new(1,-16,0,1);ln.Position=UDim2.new(0,8,0,y);ln.BackgroundColor3=GC.brd;ln.BorderSizePixel=0;local bg=Instance.new("Frame",p);bg.Size=UDim2.new(0,#t*7+16,0,18);bg.Position=UDim2.new(0,8,0,y-9);bg.BackgroundColor3=GC.acc;bg.BorderSizePixel=0;G.Crn(bg,4);local l=Instance.new("TextLabel",bg);l.Text=t:upper();l.Size=UDim2.new(1,0,1,0);l.BackgroundTransparency=1;l.TextColor3=Color3.new(1,1,1);l.TextSize=10;l.Font=Enum.Font.GothamBold;return y+16 end
function G.Tog(p,n,d,y,cb) local h=SC(32,40);local f=Instance.new("Frame",p);f.Size=UDim2.new(1,-16,0,h);f.Position=UDim2.new(0,8,0,y);f.BackgroundColor3=GC.pnl;f.BorderSizePixel=0;G.Crn(f,6);local l=Instance.new("TextLabel",f);l.Text=n;l.Size=UDim2.new(0.7,-10,1,0);l.Position=UDim2.new(0,10,0,0);l.BackgroundTransparency=1;l.TextColor3=GC.txt;l.TextSize=SC(12,13);l.Font=Enum.Font.Gotham;l.TextXAlignment=Enum.TextXAlignment.Left;l.TextWrapped=true;local sw,sh=SC(44,52),SC(22,26);local bg=Instance.new("Frame",f);bg.Size=UDim2.new(0,sw,0,sh);bg.Position=UDim2.new(1,-sw-10,0.5,-sh/2);bg.BackgroundColor3=d and GC.tOn or GC.tOff;G.Crn(bg,sh/2);local kw=SC(18,22);local kn=Instance.new("Frame",bg);kn.Size=UDim2.new(0,kw,0,kw);kn.Position=d and UDim2.new(1,-kw-2,0.5,-kw/2)or UDim2.new(0,2,0.5,-kw/2);kn.BackgroundColor3=Color3.new(1,1,1);G.Crn(kn,kw/2);local en=d;local btn=Instance.new("TextButton",f);btn.Text="";btn.Size=UDim2.new(1,0,1,0);btn.BackgroundTransparency=1;btn.MouseButton1Click:Connect(function() CloseDD();en=not en;TweenService:Create(bg,TweenInfo.new(0.2),{BackgroundColor3=en and GC.tOn or GC.tOff}):Play();TweenService:Create(kn,TweenInfo.new(0.2),{Position=en and UDim2.new(1,-kw-2,0.5,-kw/2)or UDim2.new(0,2,0.5,-kw/2)}):Play();if cb then cb(en) end end) end
function G.Sld(p,n,mn,mx,d,y,fmt,cb) local h=SC(44,52);local f=Instance.new("Frame",p);f.Size=UDim2.new(1,-16,0,h);f.Position=UDim2.new(0,8,0,y);f.BackgroundColor3=GC.pnl;f.BorderSizePixel=0;G.Crn(f,6);local l=Instance.new("TextLabel",f);l.Text=string.format("%s: "..(fmt or"%.1f"),n,d);l.Size=UDim2.new(1,-16,0,16);l.Position=UDim2.new(0,8,0,4);l.BackgroundTransparency=1;l.TextColor3=GC.txt;l.TextSize=SC(11,12);l.Font=Enum.Font.Gotham;l.TextXAlignment=Enum.TextXAlignment.Left;local tr=Instance.new("Frame",f);tr.Size=UDim2.new(1,-16,0,SC(6,10));tr.Position=UDim2.new(0,8,0,SC(28,30));tr.BackgroundColor3=GC.sB;tr.BorderSizePixel=0;G.Crn(tr,3);local pct=math.clamp((d-mn)/(mx-mn),0,1);local fl=Instance.new("Frame",tr);fl.Size=UDim2.new(pct,0,1,0);fl.BackgroundColor3=GC.sF;fl.BorderSizePixel=0;G.Crn(fl,3);local ks=SC(12,18);local kn=Instance.new("Frame",tr);kn.Size=UDim2.new(0,ks,0,ks);kn.Position=UDim2.new(pct,-ks/2,0.5,-ks/2);kn.BackgroundColor3=Color3.new(1,1,1);kn.ZIndex=5;G.Crn(kn,ks/2);G.Stk(kn,GC.acc,2);local dragging=false;local hb=Instance.new("TextButton",f);hb.Text="";hb.Size=UDim2.new(1,10,0,SC(22,34));hb.Position=UDim2.new(0,-5,0,SC(20,22));hb.BackgroundTransparency=1;hb.ZIndex=6;local function upd(ix) local ap,as=tr.AbsolutePosition.X,tr.AbsoluteSize.X;if as<=0 then return end;local r=math.clamp((ix-ap)/as,0,1);local v=mn+r*(mx-mn);fl.Size=UDim2.new(r,0,1,0);kn.Position=UDim2.new(r,-ks/2,0.5,-ks/2);l.Text=string.format("%s: "..(fmt or"%.1f"),n,v);if cb then cb(v) end end;hb.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then CloseDD();dragging=true;upd(i.Position.X) end end);table.insert(S.conns,UIS.InputChanged:Connect(function(i) if dragging and(i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then upd(i.Position.X) end end));table.insert(S.conns,UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)) end
function G.DD(p,n,opts,d,y,cb) local h=SC(32,40);local ct=Instance.new("Frame",p);ct.Size=UDim2.new(1,-16,0,h);ct.Position=UDim2.new(0,8,0,y);ct.BackgroundColor3=GC.pnl;ct.BorderSizePixel=0;G.Crn(ct,6);local ll=Instance.new("TextLabel",ct);ll.Text=n;ll.Size=UDim2.new(0.35,-10,1,0);ll.Position=UDim2.new(0,10,0,0);ll.BackgroundTransparency=1;ll.TextColor3=GC.txt;ll.TextSize=SC(12,13);ll.Font=Enum.Font.Gotham;ll.TextXAlignment=Enum.TextXAlignment.Left;local db=Instance.new("TextButton",ct);db.Text=(d or opts[1]).." v";db.Size=UDim2.new(0.6,0,0,SC(26,32));db.Position=UDim2.new(0.38,0,0.5,-SC(13,16));db.BackgroundColor3=GC.ddBg;db.TextColor3=GC.txt;db.TextSize=SC(11,12);db.Font=Enum.Font.Gotham;db.AutoButtonColor=false;G.Crn(db,5);local bs=G.Stk(db,GC.brd,1);local sel=d or opts[1];db.MouseButton1Click:Connect(function() if DDB==db then CloseDD();return end;CloseDD();bs.Color=GC.brdA;DDB=db;local mf;local cur=p;for _=1,10 do if not cur then break end;if cur.Name=="MainFrame" then mf=cur;break end;cur=cur.Parent end;if not mf then return end;task.defer(function() if DDB~=db then return end;local bp2,bsz=db.AbsolutePosition,db.AbsoluteSize;local mp,ms=mf.AbsolutePosition,mf.AbsoluteSize;local rx,ry=bp2.X-mp.X,bp2.Y-mp.Y+bsz.Y+4;local ih=SC(30,38);local lh=#opts*ih+6;local lw=math.max(bsz.X,SC(130,160));if ry+lh>ms.Y-10 then ry=bp2.Y-mp.Y-lh-4 end;rx=math.clamp(rx,5,ms.X-lw-5);ry=math.clamp(ry,5,ms.Y-lh-5);local grp=Instance.new("Folder",mf);local bgb=Instance.new("TextButton",grp);bgb.Text="";bgb.Size=UDim2.new(1,0,1,0);bgb.BackgroundTransparency=1;bgb.ZIndex=90;bgb.AutoButtonColor=false;bgb.MouseButton1Click:Connect(CloseDD);local dl=Instance.new("Frame",grp);dl.Size=UDim2.new(0,lw,0,lh);dl.Position=UDim2.new(0,rx,0,ry);dl.BackgroundColor3=Color3.fromRGB(18,18,30);dl.BorderSizePixel=0;dl.ZIndex=100;G.Crn(dl,8);G.Stk(dl,GC.brdA,1);for i,opt in ipairs(opts) do local ob=Instance.new("TextButton",dl);ob.Text=(opt==sel and"> "or"  ")..opt;ob.Size=UDim2.new(1,-8,0,ih-2);ob.Position=UDim2.new(0,4,0,(i-1)*ih+3);ob.BackgroundColor3=opt==sel and Color3.fromRGB(40,50,80)or Color3.fromRGB(22,22,38);ob.TextColor3=opt==sel and GC.acc or GC.txt;ob.TextSize=SC(12,13);ob.Font=Enum.Font.Gotham;ob.TextXAlignment=Enum.TextXAlignment.Left;ob.AutoButtonColor=false;ob.ZIndex=101;G.Crn(ob,5);ob.MouseButton1Click:Connect(function() sel=opt;db.Text=opt.." v";CloseDD();if cb then cb(opt) end end) end;DDL=grp end) end) end
function G.Btn(p,t,y,col,cb) local b=Instance.new("TextButton",p);b.Text=t;b.Size=UDim2.new(1,-16,0,SC(30,38));b.Position=UDim2.new(0,8,0,y);b.BackgroundColor3=col or GC.acc;b.TextColor3=Color3.new(1,1,1);b.TextSize=SC(12,14);b.Font=Enum.Font.GothamBold;b.AutoButtonColor=false;G.Crn(b,6);b.MouseButton1Click:Connect(function() if cb then cb() end end) end
function G.MobBtns() if not IsMobile then return end;if S.mobFrame then pcall(function() S.mobFrame:Destroy() end) end;local gui=S.gui;if not gui then return end;local bf=Instance.new("Frame",gui);bf.Size=UDim2.new(0,56,0,150);bf.Position=UDim2.new(0,6,0.5,-75);bf.BackgroundTransparency=1;S.mobFrame=bf;local defs={{t="AIM",y=0,c=GC.grn,fn=function() Cfg.On=not Cfg.On end,gs=function() return Cfg.On end},{t="ESP",y=48,c=GC.acc,fn=function() Cfg.ESP.On=not Cfg.ESP.On;if not Cfg.ESP.On then E.DelAll() end end,gs=function() return Cfg.ESP.On end},{t="WH",y=96,c=GC.org,fn=function() Cfg.WH.On=not Cfg.WH.On;if not Cfg.WH.On then WH.KillAll() end end,gs=function() return Cfg.WH.On end}};for _,d in ipairs(defs) do local b=Instance.new("TextButton",bf);b.Size=UDim2.new(0,50,0,40);b.Position=UDim2.new(0,0,0,d.y);b.BackgroundColor3=d.gs()and d.c or Color3.fromRGB(40,40,55);b.TextColor3=Color3.new(1,1,1);b.Text=d.t;b.TextSize=11;b.Font=Enum.Font.GothamBold;b.AutoButtonColor=false;G.Crn(b,8);G.Stk(b,d.c,1);b.MouseButton1Click:Connect(function() d.fn();b.BackgroundColor3=d.gs()and d.c or Color3.fromRGB(40,40,55) end) end end

local function Cleanup() DEAD=true;task.wait(0.05);pcall(function() if S.aim.flickOn and S.aim.flickCF and Cam then Cam.CFrame=S.aim.flickCF end end);for _,c in ipairs(S.conns) do pcall(function() c:Disconnect() end) end;S.conns={};pcall(E.DelAll);pcall(WH.KillAll);pcall(HUD.Destroy);pcall(function() CloseDD();CloseSub();if S.mobFrame then S.mobFrame:Destroy() end;if S.gui then S.gui:Destroy() end end);pcall(Exp.RSpin);pcall(Exp.RTP);_G.XenoLoaded=false;_G.XenoCleanup=nil end

function G.Create()
    pcall(function() CloseDD();CloseSub();if S.mobFrame then S.mobFrame:Destroy();S.mobFrame=nil end;if S.gui then S.gui:Destroy();S.gui=nil end end)
    local gui=Instance.new("ScreenGui");gui.Name="X_"..math.random(100000,999999);gui.ResetOnSpawn=false;gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling;gui.DisplayOrder=999;Protect(gui);gui.Parent=SafeP();S.gui=gui
    local mW,mH=SC(520,math.min(Cam.ViewportSize.X-20,390)),SC(580,math.min(Cam.ViewportSize.Y-80,480))
    local main=Instance.new("Frame",gui);main.Name="MainFrame";main.Size=UDim2.new(0,mW,0,mH);main.Position=UDim2.new(0.5,-mW/2,0.5,-mH/2);main.BackgroundColor3=GC.bg;main.BorderSizePixel=0;main.Visible=false;main.Active=true;main.ClipsDescendants=true;G.Crn(main,12);G.Stk(main,GC.brd,1)
    local hH=SC(44,38);local hdr=Instance.new("Frame",main);hdr.Size=UDim2.new(1,0,0,hH);hdr.BackgroundColor3=GC.hdr;hdr.BorderSizePixel=0;hdr.ZIndex=5;G.Crn(hdr,12);local tl=Instance.new("TextLabel",hdr);tl.Text="XENO v9.8";tl.Size=UDim2.new(0,80,0,18);tl.Position=UDim2.new(0,14,0,SC(6,4));tl.BackgroundTransparency=1;tl.TextColor3=GC.acc;tl.TextSize=SC(16,14);tl.Font=Enum.Font.GothamBlack;tl.TextXAlignment=Enum.TextXAlignment.Left;tl.ZIndex=6;local xb=Instance.new("TextButton",hdr);xb.Text="X";xb.Size=UDim2.new(0,SC(28,24),0,SC(28,24));xb.Position=UDim2.new(1,-SC(36,30),0.5,-SC(14,12));xb.BackgroundColor3=GC.red;xb.TextColor3=Color3.new(1,1,1);xb.TextSize=SC(12,10);xb.Font=Enum.Font.GothamBold;xb.ZIndex=7;xb.AutoButtonColor=false;G.Crn(xb,6);xb.MouseButton1Click:Connect(function() main.Visible=false end);G.Drag(main,hdr)
    local tH=SC(34,30);local tb=Instance.new("Frame",main);tb.Size=UDim2.new(1,0,0,tH);tb.Position=UDim2.new(0,0,0,hH);tb.BackgroundColor3=GC.tabBg;tb.BorderSizePixel=0;tb.ZIndex=4
    local modes=Exec.canSilent and{"normal","snap","silent"}or{"normal","snap","flick"}
    local tabs={{"Aim","+"},{"ESP","*"},{"Misc","="}};local tabBtns,tabFrames={},{};local tw=1/#tabs
    local ind=Instance.new("Frame",tb);ind.Size=UDim2.new(tw,-8,0,3);ind.Position=UDim2.new(0,4,1,-3);ind.BackgroundColor3=GC.acc;ind.BorderSizePixel=0;ind.ZIndex=6;G.Crn(ind,2)
    local cY=hH+tH;local cf=Instance.new("Frame",main);cf.Size=UDim2.new(1,0,1,-cY);cf.Position=UDim2.new(0,0,0,cY);cf.BackgroundColor3=GC.bg;cf.BorderSizePixel=0;cf.ClipsDescendants=true;local curTab=tabs[1][1]
    local function swTab(n) CloseDD();curTab=n;for nm,fr in pairs(tabFrames) do fr.Visible=(nm==n) end;for nm,bt in pairs(tabBtns) do bt.TextColor3=nm==n and GC.acc or GC.txtD;bt.BackgroundColor3=nm==n and GC.tabA or GC.tabBg end;for i,td in ipairs(tabs) do if td[1]==n then ind.Position=UDim2.new(tw*(i-1),4,1,-3) end end end
    for i,td in ipairs(tabs) do local bt=Instance.new("TextButton",tb);bt.Text=td[2].." "..td[1];bt.Size=UDim2.new(tw,0,1,-3);bt.Position=UDim2.new(tw*(i-1),0,0,0);bt.BackgroundColor3=td[1]==curTab and GC.tabA or GC.tabBg;bt.TextColor3=td[1]==curTab and GC.acc or GC.txtD;bt.TextSize=SC(10,9);bt.Font=Enum.Font.GothamBold;bt.AutoButtonColor=false;bt.ZIndex=5;bt.BorderSizePixel=0;bt.MouseButton1Click:Connect(function() swTab(td[1]) end);tabBtns[td[1]]=bt;local sf=Instance.new("ScrollingFrame",cf);sf.Size=UDim2.new(1,0,1,0);sf.BackgroundColor3=GC.bg;sf.BorderSizePixel=0;sf.ScrollBarThickness=SC(3,5);sf.ScrollBarImageColor3=GC.acc;sf.CanvasSize=UDim2.new(0,0,0,0);sf.Visible=(td[1]==curTab);tabFrames[td[1]]=sf end
    local TH,SH,DH=SC(36,44),SC(50,58),SC(38,46)

    local sc=tabFrames["Aim"];local y=8
    y=G.Sec(sc,"AIM",y);y=y+4
    G.Tog(sc,"Aimbot",Cfg.On,y,function(v) Cfg.On=v end);y=y+TH
    G.Tog(sc,"360",Cfg.Aim360,y,function(v) Cfg.Aim360=v;Cfg.Silent.Use360=v end);y=y+TH
    G.DD(sc,"Mode",modes,Cfg.AimMode,y,function(v) Cfg.AimMode=v;Cfg.Silent.On=(v=="silent");Cfg.Flick.On=(v=="flick");if v=="silent" then Sil.Install() end end);y=y+DH
    G.DD(sc,"Part",{"Head","UpperTorso","HumanoidRootPart"},Cfg.Part,y,function(v) Cfg.Part=v end);y=y+DH
    G.Tog(sc,"FOV Circle",Cfg.FOV.On,y,function(v) Cfg.FOV.On=v end);y=y+TH
    G.Sld(sc,"FOV Radius",10,500,Cfg.FOV.R,y,"%.0f",function(v) Cfg.FOV.R=v end);y=y+SH
    G.Tog(sc,"Smoothing",Cfg.Smooth.On,y,function(v) Cfg.Smooth.On=v end);y=y+TH
    G.Sld(sc,"Smooth",0.01,1,Cfg.Smooth.Amt,y,"%.2f",function(v) Cfg.Smooth.Amt=v end);y=y+SH
    G.Tog(sc,"Team Check",Cfg.Checks.Team,y,function(v) Cfg.Checks.Team=v end);y=y+TH
    G.Tog(sc,"Wall Check",Cfg.Checks.Wall,y,function(v) Cfg.Checks.Wall=v end);y=y+TH
    G.Sld(sc,"Max Dist",50,2000,Cfg.Limits.MaxD,y,"%.0f",function(v) Cfg.Limits.MaxD=v end);y=y+SH
    G.Tog(sc,"Prediction",Cfg.Pred.On,y,function(v) Cfg.Pred.On=v end);y=y+TH
    G.Tog(sc,"TriggerBot",Cfg.TB.On,y,function(v) Cfg.TB.On=v end);y=y+TH
    sc.CanvasSize=UDim2.new(0,0,0,y+10)

    sc=tabFrames["ESP"];y=8
    y=G.Sec(sc,"ESP",y);y=y+4
    G.Tog(sc,"ESP",Cfg.ESP.On,y,function(v) Cfg.ESP.On=v;if not v then E.DelAll() end end);y=y+TH
    G.Tog(sc,"Show Team",Cfg.ESP.ShowTeam,y,function(v) Cfg.ESP.ShowTeam=v end);y=y+TH
    G.Sld(sc,"Max Dist",100,3000,Cfg.ESP.MaxDist,y,"%.0f",function(v) Cfg.ESP.MaxDist=v end);y=y+SH
    G.Tog(sc,"Box",Cfg.ESP.Box.On,y,function(v) Cfg.ESP.Box.On=v end);y=y+TH
    G.Tog(sc,"Name",Cfg.ESP.Name.On,y,function(v) Cfg.ESP.Name.On=v end);y=y+TH
    G.Tog(sc,"Health Bar",Cfg.ESP.HP.On,y,function(v) Cfg.ESP.HP.On=v end);y=y+TH
    G.Tog(sc,"Tracers",Cfg.ESP.Tracer.On,y,function(v) Cfg.ESP.Tracer.On=v end);y=y+TH
    G.Tog(sc,"Head Dot",Cfg.ESP.HeadDot.On,y,function(v) Cfg.ESP.HeadDot.On=v end);y=y+TH
    y=G.Sec(sc,"WALLHACK",y+6);y=y+4
    G.Tog(sc,"Wallhack",Cfg.WH.On,y,function(v) Cfg.WH.On=v;if not v then WH.KillAll() end end);y=y+TH
    G.Sld(sc,"Fill Trans",0,1,Cfg.WH.FT,y,"%.1f",function(v) Cfg.WH.FT=v end);y=y+SH
    sc.CanvasSize=UDim2.new(0,0,0,y+10)

    sc=tabFrames["Misc"];y=8
    y=G.Sec(sc,"HACKS",y);y=y+4
    G.Tog(sc,"3rd Person",Cfg.TP.On,y,function(v) Cfg.TP.On=v;if not v then Exp.RTP() end end);y=y+TH
    G.Tog(sc,"SpinBot",Cfg.Spin.On,y,function(v) Cfg.Spin.On=v;if not v then Exp.RSpin() end end);y=y+TH
    G.Sld(sc,"Spin Speed",1,50,Cfg.Spin.Spd,y,"%.0f",function(v) Cfg.Spin.Spd=v end);y=y+SH
    G.Tog(sc,"Speed Boost",Cfg.Speed.On,y,function(v) Cfg.Speed.On=v end);y=y+TH
    G.Sld(sc,"Speed Mult",1,3,Cfg.Speed.Mult,y,"%.1fx",function(v) Cfg.Speed.Mult=v end);y=y+SH
    y=y+8;G.Btn(sc,"Unload",y,GC.red,function() Notify("X","Bye",2);task.delay(0.3,Cleanup) end);y=y+SC(38,46)
    sc.CanvasSize=UDim2.new(0,0,0,y+10)

    local obs=SC(36,44);local ob=Instance.new("TextButton",gui);ob.Text="X";ob.Size=UDim2.new(0,obs,0,obs);ob.Position=UDim2.new(1,-obs-10,0,SC(10,50));ob.BackgroundColor3=GC.acc;ob.TextColor3=Color3.new(1,1,1);ob.TextSize=SC(16,18);ob.Font=Enum.Font.GothamBlack;ob.AutoButtonColor=false;G.Crn(ob,obs/2);G.Stk(ob,GC.accG,1);ob.MouseButton1Click:Connect(function() main.Visible=not main.Visible end)
    G.MobBtns();swTab(tabs[1][1])
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
                S.tgt.part=part;S.tgt.plr=plr;S.tgt.isBot=false;S.tgt.botModel=plr and plr.Character
                S.tgt.name=plr and plr.Name or"?"
                S.tgt.dist=(camPos-part.Position).Magnitude;S.tgt.vis=true
                local ch=plr and plr.Character
                local hp,mhp=Res.HP(ch);S.tgt.hp=hp;S.tgt.mhp=mhp
                if Cfg.AimMode=="silent" and Cfg.Silent.On then S.aim.silentPos=A.Pred(part)
                elseif Cfg.AimMode=="normal" then A.Smooth(part)
                elseif Cfg.AimMode=="snap" then local tcf=A.GetCF(part);if tcf then Cam.CFrame=tcf end end
            else
                if not S.tgt.plr then S.tgt.part=nil;S.tgt.name="";S.tgt.lastPos=nil;S.tgt.sVel=Vector3.zero;S.aim.silentPos=nil end
                S.tgt.vis=false
            end
        else S.aim.silentPos=nil end
        Flk.Update();Fire.Update()
        if S.frame%2==0 then HUD.Update() end
        if Cfg.ESP.On then E.UpdateBatch() end
        if S.frame%5==0 then WH.UpdateAll() end
        Exp.TP();Exp.Spin(dt);Exp.Speed(dt)
    end))
end

local function Input()
    if not IsMobile then table.insert(S.conns,UIS.InputBegan:Connect(function(i,g)
        if DEAD or g then return end
        if i.KeyCode==Enum.KeyCode.F1 then Cfg.On=not Cfg.On;if not Cfg.On then S.tgt.part=nil;S.tgt.plr=nil;S.tgt.vis=false end;Notify("X",Cfg.On and"AIM ON"or"AIM OFF")
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
Notify("Xeno v9.8","Loaded | "..Cfg.AimMode:upper(),5)

end)
if not ok then pcall(function() game:GetService("StarterGui"):SetCore("SendNotification",{Title="XENO ERROR",Text=tostring(err):sub(1,100),Duration=10}) end);warn("[XENO]",err) end
