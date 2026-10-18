--========================================================
-- NOXI'S HUB 1.7.0
-- CYBERPUNK UI REFRESH | PERFORMANCE CENTER
-- MUSIC + THEMES + CONFIG MANAGER | DEVELOPER EDITION
-- LocalScript -> StarterPlayerScripts
--========================================================

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local SoundService = game:GetService("SoundService")
local HttpService = game:GetService("HttpService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local VERSION = "1.7.0"
local DEVELOPER_USERNAME = "Gop_4797"
local DEVELOPER_DISPLAY = "PAKETA"
local IsMainDeveloper = Player.Name == DEVELOPER_USERNAME

local State = {
	Theme = "Purple",
	VisualReconstruction = false,
	VisualQuality = "Medium",
	Notifications = true,
	Animations = true,
	AMOLED = false,
	Debug = false,
	PerformanceProfile = "Balanced",
 MusicVolume = 0.5,
 MusicSoundId = "94919056430713",
}

local Themes = {
	Purple = Color3.fromRGB(168,85,247), Blue = Color3.fromRGB(80,145,255),
	Pink = Color3.fromRGB(244,90,170), Cyan = Color3.fromRGB(45,210,220),
	Red = Color3.fromRGB(255,75,85), Green = Color3.fromRGB(70,220,130),
	Orange = Color3.fromRGB(255,155,60),
}
local Accent = Themes.Purple

local Activity = {}
local VisualObjects = {}
local SavedMaterials = {}
local FPSSamples = {}
local CurrentFPS, CurrentPing, CurrentMemory = 0,0,0
local CurrentInstances, CurrentParts = 0,0
local LastCount = 0
local OriginalLighting = {}

local function SafeDestroy(x)
	if x then pcall(function() x:Destroy() end) end
end

local function New(className, props, parent)
	local x = Instance.new(className)
	for k,v in pairs(props or {}) do pcall(function() x[k] = v end) end
	x.Parent = parent
	return x
end

local function Corner(x,r) return New("UICorner",{CornerRadius=UDim.new(0,r or 10)},x) end
local function Stroke(x,c,t) return New("UIStroke",{Color=c or Color3.fromRGB(45,45,55),Transparency=t or 0,Thickness=1},x) end
local function Padding(x,p) return New("UIPadding",{PaddingLeft=UDim.new(0,p),PaddingRight=UDim.new(0,p),PaddingTop=UDim.new(0,p),PaddingBottom=UDim.new(0,p)},x) end

SafeDestroy(PlayerGui:FindFirstChild("NoxisHub"))
local Gui = New("ScreenGui",{Name="NoxisHub",ResetOnSpawn=false,IgnoreGuiInset=true,DisplayOrder=50},PlayerGui)
local NotificationHolder

local function Log(text)
	table.insert(Activity,1,os.date("%H:%M:%S").."  "..text)
	while #Activity > 30 do table.remove(Activity) end
end

local function Notify(text)
	if not State.Notifications or not NotificationHolder then return end
	local n = New("TextLabel",{Size=UDim2.new(1,0,0,34),BackgroundColor3=Color3.fromRGB(15,15,20),Text=text,TextColor3=Color3.fromRGB(235,235,240),TextSize=12,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=100},NotificationHolder)
	Corner(n,9); Stroke(n,Accent,.25); Padding(n,9)
	task.delay(3,function() SafeDestroy(n) end)
end

--========================================================
-- VISUAL RECONSTRUCTION 3.0
--========================================================

local VisualSettings={
	Low={Brightness=.01,Contrast=.05,Saturation=.02,Bloom=.03,BloomSize=18,Threshold=1,Sun=.01,Atmosphere=.07,Haze=.25,Glare=.02,DOF=.015,Radius=70,Reflect=.02},
	Medium={Brightness=.025,Contrast=.13,Saturation=.055,Bloom=.085,BloomSize=24,Threshold=.88,Sun=.03,Atmosphere=.14,Haze=.55,Glare=.04,DOF=.04,Radius=58,Reflect=.055},
	Ultra={Brightness=.045,Contrast=.25,Saturation=.11,Bloom=.22,BloomSize=30,Threshold=.72,Sun=.085,Atmosphere=.21,Haze=.9,Glare=.105,DOF=.09,Radius=42,Reflect=.12},
}

local function SaveLighting()
	if OriginalLighting.Saved then return end
	OriginalLighting={Saved=true,Brightness=Lighting.Brightness,GlobalShadows=Lighting.GlobalShadows,Diffuse=Lighting.EnvironmentDiffuseScale,Specular=Lighting.EnvironmentSpecularScale}
end

local function ApplyVisualQuality(quality)
	local s=VisualSettings[quality] or VisualSettings.Medium
	SaveLighting(); State.VisualReconstruction=true; State.VisualQuality=quality
	for _,x in ipairs(VisualObjects) do SafeDestroy(x) end
	VisualObjects={}
	Lighting.GlobalShadows=true; Lighting.EnvironmentDiffuseScale=1; Lighting.EnvironmentSpecularScale=1
	local cc=New("ColorCorrectionEffect",{Name="NoxiVisualCC",Brightness=s.Brightness,Contrast=s.Contrast,Saturation=s.Saturation},Lighting)
	local bloom=New("BloomEffect",{Name="NoxiVisualBloom",Intensity=s.Bloom,Size=s.BloomSize,Threshold=s.Threshold},Lighting)
	local rays=New("SunRaysEffect",{Name="NoxiVisualSunRays",Intensity=s.Sun,Spread=.78},Lighting)
	local atm=New("Atmosphere",{Name="NoxiVisualAtmosphere",Density=s.Atmosphere,Offset=.1,Haze=s.Haze,Glare=s.Glare,Color=Color3.fromRGB(190,205,230),Decay=Color3.fromRGB(100,110,135)},Lighting)
	local dof=New("DepthOfFieldEffect",{Name="NoxiVisualDOF",FarIntensity=s.DOF,FocusDistance=25,InFocusRadius=s.Radius,NearIntensity=s.DOF/2},Lighting)
	VisualObjects={cc,bloom,rays,atm,dof}
	for _,obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("BasePart") and not SavedMaterials[obj] then SavedMaterials[obj]={Material=obj.Material,Reflectance=obj.Reflectance,CastShadow=obj.CastShadow} end
	end
	for obj,original in pairs(SavedMaterials) do
		if obj.Parent then obj.Reflectance=math.clamp(s.Reflect,0,.35) end
	end
	Log("Visual Reconstruction: "..quality)
	Notify("🎨 Visual mode: "..quality)
end

local function DisableVisualReconstruction()
	for _,x in ipairs(VisualObjects) do SafeDestroy(x) end
	VisualObjects={}
	for obj,original in pairs(SavedMaterials) do
		if obj.Parent then obj.Material=original.Material; obj.Reflectance=original.Reflectance; obj.CastShadow=original.CastShadow end
	end
	SavedMaterials={}; State.VisualReconstruction=false
	if OriginalLighting.Saved then
		Lighting.Brightness=OriginalLighting.Brightness; Lighting.GlobalShadows=OriginalLighting.GlobalShadows
		Lighting.EnvironmentDiffuseScale=OriginalLighting.Diffuse; Lighting.EnvironmentSpecularScale=OriginalLighting.Specular
	end
	Notify("Visual Reconstruction disabled")
end

--========================================================
-- GUI CORE
--========================================================

local Loading=New("Frame",{Name="Loading",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(300,150),BackgroundColor3=Color3.fromRGB(2,2,4),ZIndex=200,Visible=false},Gui); Corner(Loading,14); Stroke(Loading,Accent,.2)
local LoadTitle=New("TextLabel",{Size=UDim2.new(1,-12,0,35),Position=UDim2.new(0,6,0,12),BackgroundTransparency=1,Text="NOXI'S HUB",TextColor3=Accent,TextSize=24,Font=Enum.Font.GothamBlack,ZIndex=201},Loading)
local LoadSub=New("TextLabel",{Size=UDim2.new(1,-12,0,22),Position=UDim2.new(0,6,0,48),BackgroundTransparency=1,Text=VERSION.." • PERFORMANCE",TextColor3=Color3.fromRGB(180,180,190),TextSize=11,Font=Enum.Font.GothamMedium,ZIndex=201},Loading)
local BarBack=New("Frame",{Size=UDim2.new(1,-36,0,5),Position=UDim2.new(0,18,0,82),BackgroundColor3=Color3.fromRGB(25,25,30),ZIndex=201},Loading); Corner(BarBack,5)
local Bar=New("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=Accent,ZIndex=202},BarBack); Corner(Bar,5)
local LoadStatus=New("TextLabel",{Size=UDim2.new(1,-20,0,22),Position=UDim2.new(0,10,0,96),BackgroundTransparency=1,Text="Starting...",TextColor3=Color3.fromRGB(145,145,155),TextSize=10,Font=Enum.Font.Gotham,ZIndex=201},Loading)

local Main=New("Frame",{Name="Main",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(570,360),BackgroundColor3=Color3.fromRGB(8,10,15),Visible=false,ClipsDescendants=true},Gui)
Corner(Main,14); Stroke(Main,Color3.fromRGB(50,220,190),.18); New("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(13,24,31)),ColorSequenceKeypoint.new(.52,Color3.fromRGB(9,13,21)),ColorSequenceKeypoint.new(1,Color3.fromRGB(17,10,28))}),Rotation=28},Main)
New("UISizeConstraint",{MinSize=Vector2.new(300,300),MaxSize=Vector2.new(570,420)},Main)

-- Compact window: keep the UI centered and inside the viewport on phones and tablets.
local function UpdateWindowSize()
 local camera=workspace.CurrentCamera
 if not camera then return end
 local viewport=camera.ViewportSize
 local width=math.max(300,math.min(570,viewport.X-24))
 local height=math.max(300,math.min(420,viewport.Y-80,360))
 Main.Size=UDim2.fromOffset(width,height)
 Main.AnchorPoint=Vector2.new(.5,.5)
 Main.Position=UDim2.fromScale(.5,.5)
end
UpdateWindowSize()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateWindowSize) end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
 if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(UpdateWindowSize); UpdateWindowSize() end
end)
local Header=New("Frame",{Size=UDim2.new(1,0,0,54),BackgroundColor3=Color3.fromRGB(10,18,25)},Main); Corner(Header,14); New("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(14,43,48)),ColorSequenceKeypoint.new(.65,Color3.fromRGB(12,20,31)),ColorSequenceKeypoint.new(1,Color3.fromRGB(28,15,39))}),Rotation=0},Header)
New("Frame",{Size=UDim2.new(0,4,1,-16),Position=UDim2.fromOffset(10,8),BackgroundColor3=Color3.fromRGB(65,245,205),BorderSizePixel=0},Header)
New("TextLabel",{Size=UDim2.new(1,-115,0,25),Position=UDim2.fromOffset(23,5),BackgroundTransparency=1,Text="NOXI'S HUB",TextColor3=Color3.fromRGB(244,250,255),TextSize=16,TextTruncate=Enum.TextTruncate.AtEnd,Font=Enum.Font.GothamBlack,TextXAlignment=Enum.TextXAlignment.Left},Header)
New("TextLabel",{Size=UDim2.new(1,-115,0,16),Position=UDim2.fromOffset(24,30),BackgroundTransparency=1,Text="SYSTEM CONSOLE  /  1.7.0",TextColor3=Color3.fromRGB(90,224,200),TextSize=9,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left},Header)
local Min=New("TextButton",{Size=UDim2.fromOffset(34,32),Position=UDim2.new(1,-42,0,11),BackgroundColor3=Color3.fromRGB(22,30,39),Text="—",TextColor3=Color3.fromRGB(220,240,245),TextSize=20,Font=Enum.Font.GothamBold,AutoButtonColor=false,Active=true,ZIndex=10},Header); Corner(Min,8); Stroke(Min,Color3.fromRGB(65,245,205),.55)
local Body=New("Frame",{Size=UDim2.new(1,-20,1,-66),Position=UDim2.fromOffset(10,60),BackgroundTransparency=1},Main)
local Sidebar=New("ScrollingFrame",{Size=UDim2.new(0,116,1,0),BackgroundColor3=Color3.fromRGB(11,17,25),BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=2,Active=true},Body); Corner(Sidebar,10); Padding(Sidebar,5)
local SidebarLayout=New("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},Sidebar)
local Content=New("ScrollingFrame",{Size=UDim2.new(1,-126,1,0),Position=UDim2.fromOffset(126,0),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=3,Active=true},Body); Padding(Content,4)
local PageHolder=New("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1},Content); New("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},PageHolder)
NotificationHolder=New("Frame",{Size=UDim2.new(0,250,0,0),AutomaticSize=Enum.AutomaticSize.Y,Position=UDim2.new(1,-265,0,68),BackgroundTransparency=1,ZIndex=100},Gui); New("UIListLayout",{Padding=UDim.new(0,6),HorizontalAlignment=Enum.HorizontalAlignment.Right},NotificationHolder)

local Pages={}; local Nav={}; local OpenPage
local function NewPage(name)
	local p=New("Frame",{Name=name,Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,Visible=false},PageHolder)
	New("UIListLayout",{Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder},p); Pages[name]=p; return p
end
local function Title(parent,title,sub)
	local f=New("Frame",{Size=UDim2.new(1,0,0,58),BackgroundTransparency=1},parent)
	New("TextLabel",{Size=UDim2.new(1,0,0,32),BackgroundTransparency=1,Text=title,TextColor3=Color3.fromRGB(240,240,245),TextSize=23,Font=Enum.Font.GothamBlack,TextXAlignment=Enum.TextXAlignment.Left},f)
	New("TextLabel",{Size=UDim2.new(1,0,0,20),Position=UDim2.fromOffset(0,32),BackgroundTransparency=1,Text=sub or "",TextColor3=Color3.fromRGB(130,130,140),TextSize=11,Font=Enum.Font.Gotham,TextXAlignment=Enum.TextXAlignment.Left},f)
end
local function Card(parent,h)
	local f=New("Frame",{Size=UDim2.new(1,0,0,h or 100),BackgroundColor3=Color3.fromRGB(13,21,29)},parent); Corner(f,11); Stroke(f,Color3.fromRGB(54,100,111),.42); New("UIGradient",{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(18,31,40)),ColorSequenceKeypoint.new(1,Color3.fromRGB(11,15,23))}),Rotation=90},f); Padding(f,12); return f
end
local function Label(parent,text,h,color)
	return New("TextLabel",{Size=UDim2.new(1,0,0,h or 25),BackgroundTransparency=1,Text=text,TextColor3=color or Color3.fromRGB(215,215,225),TextSize=13,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center},parent)
end
local function Button(parent,text,callback,h)
	local b=New("TextButton",{Size=UDim2.new(1,0,0,h or 38),BackgroundColor3=Color3.fromRGB(18,30,37),Text=text,TextColor3=Color3.fromRGB(222,244,245),TextSize=12,Font=Enum.Font.GothamBold,AutoButtonColor=false},parent); Corner(b,8); Stroke(b,Color3.fromRGB(57,117,126),.48); b.Activated:Connect(function() pcall(callback) end); return b
end
local function Toggle(parent,text,default,callback)
	local enabled=default
	local b
	b=Button(parent,(enabled and "●  " or "○  ")..text,function() enabled=not enabled; b.Text=(enabled and "●  " or "○  ")..text; pcall(callback,enabled) end)
	return b
end

--========================================================
-- PAGES
--========================================================

local Dashboard=NewPage("Dashboard"); Title(Dashboard,"COMMAND DECK","Live system telemetry  /  1.7.0")
local Greeting=Label(Dashboard,"",25,Color3.fromRGB(88,238,208)); Greeting.Font=Enum.Font.Code; Greeting.TextSize=12
local Hero=Card(Dashboard,92); Hero.BackgroundColor3=Color3.fromRGB(10,32,36); Stroke(Hero,Color3.fromRGB(69,222,193),.2)
local HeroTag=Label(Hero,"NOXI  /  CONTROL INTERFACE",18,Color3.fromRGB(88,238,208)); HeroTag.Font=Enum.Font.Code; HeroTag.TextSize=10
local HeroTitle=Label(Hero,"SYSTEMS ONLINE",30,Color3.fromRGB(244,250,255)); HeroTitle.Font=Enum.Font.GothamBlack; HeroTitle.TextSize=20
local HeroSub=Label(Hero,"Performance • Visuals • Audio",18,Color3.fromRGB(142,178,187)); HeroSub.TextSize=10
local MetricRow=New("Frame",{Size=UDim2.new(1,0,0,66),BackgroundTransparency=1},Dashboard)
local function Metric(parent,x,titleText)
 local box=New("Frame",{Size=UDim2.new(1/3,-6,1,0),Position=UDim2.new(x,0,0,0),BackgroundColor3=Color3.fromRGB(12,20,29)},parent); Corner(box,9); Stroke(box,Color3.fromRGB(53,86,100),.35)
 local t=Label(box,titleText,17,Color3.fromRGB(117,165,174)); t.Position=UDim2.fromOffset(8,4); t.TextSize=9; t.Font=Enum.Font.Code
 local value=Label(box,"--",26,Color3.fromRGB(242,249,252)); value.Position=UDim2.fromOffset(8,27); value.TextSize=17; value.Font=Enum.Font.GothamBlack
 return value
end
local DashFPS=Metric(MetricRow,0,"FPS"); local DashPing=Metric(MetricRow,1/3,"PING"); local DashMemory=Metric(MetricRow,2/3,"MEMORY")
local QuickCard=Card(Dashboard,100); Label(QuickCard,"QUICK LAUNCH",18,Color3.fromRGB(88,238,208)).Font=Enum.Font.Code
local QB2=Button(QuickCard,"OPEN PERFORMANCE CENTER  →",function() OpenPage("Performance") end); QB2.Position=UDim2.new(0,0,0,35); QB2.Size=UDim2.new(1,0,0,34)
local ActivityCard=Card(Dashboard,130); Label(ActivityCard,"EVENT STREAM",18,Color3.fromRGB(88,238,208)).Font=Enum.Font.Code; local ActivityText=Label(ActivityCard,"Waiting for events...",90,Color3.fromRGB(150,178,186)); ActivityText.Position=UDim2.fromOffset(12,32); ActivityText.Font=Enum.Font.Code; ActivityText.TextSize=10

local PlayerPage=NewPage("Player"); Title(PlayerPage,"PLAYER PROFILE","Local session identity")
local PC=Card(PlayerPage,150); Label(PC,"PROFILE",20,Accent); Label(PC,"Username: "..Player.Name,24); Label(PC,"Display Name: "..Player.DisplayName,24); Label(PC,IsMainDeveloper and "👑 NOXI • MAIN DEVELOPER" or "PLAYER",28,IsMainDeveloper and Accent or Color3.fromRGB(160,160,170))

local PerformancePage=NewPage("Performance"); Title(PerformancePage,"PERFORMANCE","Live telemetry  /  FPS • PING • MEMORY")
local PerfCard=Card(PerformancePage,190); Label(PerfCard,"LIVE METRICS",20,Accent); local PerfInfo=Label(PerfCard,"Loading...",150); PerfInfo.Position=UDim2.fromOffset(12,38)
local Prof=Card(PerformancePage,160); Label(Prof,"PROFILE",20,Accent)
for i,name in ipairs({"Balanced","Performance","Ultra"}) do local b=Button(Prof,string.upper(name),function() State.PerformanceProfile=name; Notify("Performance profile: "..name) end); b.Position=UDim2.fromOffset(12,38+(i-1)*42) end

local VisualsPage=NewPage("Visuals"); Title(VisualsPage,"VISUAL LAB","Lighting and atmosphere controls")
local VC=Card(VisualsPage,225); Label(VC,"VISUAL RECONSTRUCTION",22,Accent); Label(VC,"Lighting, atmosphere, bloom, depth and material response.",30,Color3.fromRGB(145,145,155))
local VL=Button(VC,"LOW",function() ApplyVisualQuality("Low") end); VL.Position=UDim2.new(0,0,0,70); VL.Size=UDim2.new(.32,-5,0,44)
local VM=Button(VC,"MEDIUM",function() ApplyVisualQuality("Medium") end); VM.Position=UDim2.new(.34,0,0,70); VM.Size=UDim2.new(.32,-5,0,44)
local VU=Button(VC,"🔥  ULTRA",function() ApplyVisualQuality("Ultra") end); VU.Position=UDim2.new(.68,0,0,70); VU.Size=UDim2.new(.32,0,0,44)
local VD=Button(VC,"DISABLE RECONSTRUCTION",DisableVisualReconstruction); VD.Position=UDim2.new(0,0,0,122)
local VS=Label(VC,"Current: MEDIUM • Reconstruction OFF",25,Accent); VS.Position=UDim2.fromOffset(0,165)


local MusicPage=NewPage("Music"); Title(MusicPage,"AUDIO DECK","Track selector and volume")
local MusicCard=Card(MusicPage,220); Label(MusicCard,"NOW PLAYING",20,Accent)
local MusicLabel=Label(MusicCard,"Choose a track",28); MusicLabel.Position=UDim2.fromOffset(12,32)
local Music=SoundService:FindFirstChild("NoxiHubMusic") or New("Sound",{Name="NoxiHubMusic",Volume=State.MusicVolume,Looped=true},SoundService)
local Tracks={{Name="Track 1",Id="94919056430713"},{Name="Track 2",Id="102616343336371"},{Name="Track 3",Id="71681070025173"}}
local TrackIndex=1
local function PlayTrack(i) TrackIndex=((i-1)%#Tracks)+1; local t=Tracks[TrackIndex]; State.MusicSoundId=t.Id; Music:Stop(); Music.SoundId="rbxassetid://"..t.Id; Music.Volume=State.MusicVolume; MusicLabel.Text=t.Name.." • "..t.Id; pcall(function() Music:Play() end) end
local Prev=Button(MusicCard,"◀ PREVIOUS",function() PlayTrack(TrackIndex-1) end); Prev.Position=UDim2.new(0,0,0,68); Prev.Size=UDim2.new(.32,-5,0,38)
local Play=Button(MusicCard,"▶ PLAY / PAUSE",function() if Music.IsPlaying then Music:Pause() else if Music.SoundId=="" then PlayTrack(TrackIndex) else pcall(function() Music:Resume() end) end end end); Play.Position=UDim2.new(.34,0,0,68); Play.Size=UDim2.new(.32,-5,0,38)
local Next=Button(MusicCard,"NEXT ▶",function() PlayTrack(TrackIndex+1) end); Next.Position=UDim2.new(.68,0,0,68); Next.Size=UDim2.new(.32,0,0,38)
local Stop=Button(MusicCard,"■ STOP",function() Music:Stop() end); Stop.Position=UDim2.new(0,0,0,112)
local VolLabel=Label(MusicCard,"Volume: 50%",24,Accent); VolLabel.Position=UDim2.fromOffset(0,154)
local VolBar=New("TextButton",{Size=UDim2.new(1,0,0,12),Position=UDim2.fromOffset(0,184),BackgroundColor3=Color3.fromRGB(35,35,45),Text=""},MusicCard); Corner(VolBar,6)
local VolFill=New("Frame",{Size=UDim2.new(State.MusicVolume,0,1,0),BackgroundColor3=Accent},VolBar); Corner(VolFill,6)
local function SetVol(x) State.MusicVolume=math.clamp((x-VolBar.AbsolutePosition.X)/math.max(1,VolBar.AbsoluteSize.X),0,1); Music.Volume=State.MusicVolume; VolFill.Size=UDim2.new(State.MusicVolume,0,1,0); VolLabel.Text="Volume: "..math.floor(State.MusicVolume*100).."%" end
VolBar.Activated:Connect(function() SetVol(UserInputService:GetMouseLocation().X) end)
local volDrag=false
VolBar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then volDrag=true; SetVol(i.Position.X) end end)
UserInputService.InputChanged:Connect(function(i) if volDrag and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then SetVol(i.Position.X) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then volDrag=false end end)

local ConfigPage=NewPage("Config"); Title(ConfigPage,"CONFIG VAULT","JSON import and export")
local ConfigCard=Card(ConfigPage,310); Label(ConfigCard,"CONFIGURATION JSON",20,Accent)
local ConfigBox=New("TextBox",{Size=UDim2.new(1,0,0,150),Position=UDim2.fromOffset(0,34),BackgroundColor3=Color3.fromRGB(5,5,8),TextColor3=Color3.fromRGB(220,220,230),PlaceholderText="Export settings or paste JSON here",Text="",TextSize=11,Font=Enum.Font.Code,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,ClearTextOnFocus=false,MultiLine=true},ConfigCard); Corner(ConfigBox,8); Padding(ConfigBox,8)
local function ConfigData() return {version=VERSION,theme=State.Theme,visualReconstruction=State.VisualReconstruction,visualQuality=State.VisualQuality,notifications=State.Notifications,animations=State.Animations,amoled=State.AMOLED,performanceProfile=State.PerformanceProfile,musicVolume=State.MusicVolume,musicSoundId=State.MusicSoundId} end
local Export=Button(ConfigCard,"EXPORT JSON",function() local ok,out=pcall(function() return HttpService:JSONEncode(ConfigData()) end); if ok then ConfigBox.Text=out; Notify("JSON exported") else Notify("Export failed") end end); Export.Position=UDim2.new(0,0,0,194)
local Import=Button(ConfigCard,"IMPORT JSON",function() local ok,c=pcall(function() return HttpService:JSONDecode(ConfigBox.Text) end); if not ok or type(c)~="table" then Notify("Invalid JSON"); return end
 if type(c.notifications)=="boolean" then State.Notifications=c.notifications end
 if type(c.animations)=="boolean" then State.Animations=c.animations end
 if type(c.amoled)=="boolean" then State.AMOLED=c.amoled; Main.BackgroundColor3=c.amoled and Color3.new(0,0,0) or Color3.fromRGB(7,7,10) end
 if type(c.musicVolume)=="number" then State.MusicVolume=math.clamp(c.musicVolume,0,1); Music.Volume=State.MusicVolume; VolFill.Size=UDim2.new(State.MusicVolume,0,1,0); VolLabel.Text="Volume: "..math.floor(State.MusicVolume*100).."%" end
 if type(c.visualQuality)=="string" and VisualSettings[c.visualQuality] then State.VisualQuality=c.visualQuality end
 if c.visualReconstruction==true then ApplyVisualQuality(State.VisualQuality) elseif c.visualReconstruction==false and State.VisualReconstruction then DisableVisualReconstruction() end
 Notify("Config imported"); Log("Config imported")
end); Import.Position=UDim2.new(0,0,0,238)
local Note=Label(ConfigCard,"Copy exported JSON somewhere safe to keep it; import applies supported settings.",34,Color3.fromRGB(145,145,155)); Note.Position=UDim2.fromOffset(0,278)

local ServerPage=NewPage("Server"); Title(ServerPage,"Server","Live server information")
local SC=Card(ServerPage,145); Label(SC,"SERVER",20,Accent); local SI=Label(SC,"Players: --\nJobId: "..game.JobId.."\nPlaceId: "..tostring(game.PlaceId),100); SI.Position=UDim2.fromOffset(12,38)

local DebugPage=NewPage("Debug"); Title(DebugPage,"Debug","Developer diagnostics")
local DC=Card(DebugPage,130); Label(DC,"DEBUG TOOLS",20,Accent); local DT=Toggle(DC,"Debug Logging",false,function(v) State.Debug=v end); DT.Position=UDim2.fromOffset(12,38)
local DB=Button(DC,"REFRESH DIAGNOSTICS",function() Log("Diagnostics refreshed"); Notify("Diagnostics refreshed") end); DB.Position=UDim2.fromOffset(12,80)

local SettingsPage=NewPage("Settings"); Title(SettingsPage,"Settings","Noxi's Hub preferences")
local SetC=Card(SettingsPage,310); Label(SetC,"GENERAL",20,Accent)
local NT=Toggle(SetC,"Notifications",true,function(v) State.Notifications=v end); NT.Position=UDim2.fromOffset(12,38)
local AT=Toggle(SetC,"Animations",true,function(v) State.Animations=v end); AT.Position=UDim2.fromOffset(12,80)
local AO=Toggle(SetC,"AMOLED",false,function(v) State.AMOLED=v; Main.BackgroundColor3=v and Color3.fromRGB(0,0,0) or Color3.fromRGB(7,7,10) end); AO.Position=UDim2.fromOffset(12,122)
Label(SetC,"ACCENT THEME",22,Accent).Position=UDim2.fromOffset(0,164)
local ThemeNames={"Purple","Blue","Pink","Cyan","Red","Green","Orange"}
for i,themeName in ipairs(ThemeNames) do
 local b=Button(SetC,themeName,function()
  State.Theme=themeName; Accent=Themes[themeName]; VolFill.BackgroundColor3=Accent
  for _,obj in ipairs(Gui:GetDescendants()) do
   if obj:IsA("TextLabel") and (obj.TextColor3==Themes.Purple or obj.TextColor3==Themes.Blue or obj.TextColor3==Themes.Pink or obj.TextColor3==Themes.Cyan or obj.TextColor3==Themes.Red or obj.TextColor3==Themes.Green or obj.TextColor3==Themes.Orange) then obj.TextColor3=Accent end
  end
  Log("Theme changed: "..themeName); Notify("Theme: "..themeName)
 end,30)
 local col=(i-1)%4; local row=math.floor((i-1)/4)
 b.Position=UDim2.new(col*.25,0,0,194+row*34); b.Size=UDim2.new(.23,0,0,28)
end

local WhatsNew=NewPage("What's New"); Title(WhatsNew,"What's New","NOXI'S HUB 1.7.0")
local WC=Card(WhatsNew,245); Label(WC,"VERSION 1.7.0  /  REDESIGN",22,Color3.fromRGB(88,238,208)); local WT=Label(WC,"▸ Command Deck dashboard\n▸ Live FPS / ping / memory tiles\n▸ New teal graphite interface\n▸ Mobile touch navigation\n▸ Music, themes and JSON config kept\n▸ Visual lab and diagnostics\n▸ Minimize, restore and drag controls",190); WT.Position=UDim2.fromOffset(12,38)

--========================================================
-- NAVIGATION / EVENTS
--========================================================

local order={"Dashboard","Player","Performance","Music","Config","Visuals","Server","Debug","Settings","What's New"}
for i,name in ipairs(order) do local b=Button(Sidebar,name,function() OpenPage(name) end,36); b.LayoutOrder=i; Nav[name]=b end

-- Responsive layout: desktop uses a side rail; phones use a horizontal touch navigation strip.
local function ApplyResponsiveLayout()
 local camera=workspace.CurrentCamera
 local view=camera and camera.ViewportSize or Vector2.new(390,844)
 local mobile=view.X<600
 if mobile then
  Sidebar.Size=UDim2.new(1,0,0,40); Sidebar.Position=UDim2.fromOffset(0,0)
  Sidebar.AutomaticCanvasSize=Enum.AutomaticSize.X; Sidebar.ScrollingDirection=Enum.ScrollingDirection.X
  SidebarLayout.FillDirection=Enum.FillDirection.Horizontal; SidebarLayout.VerticalAlignment=Enum.VerticalAlignment.Center
  SidebarLayout.HorizontalAlignment=Enum.HorizontalAlignment.Left; SidebarLayout.Padding=UDim.new(0,5)
  for _,b in pairs(Nav) do b.Size=UDim2.fromOffset(91,30); b.TextSize=10 end
  Content.Size=UDim2.new(1,0,1,-46); Content.Position=UDim2.fromOffset(0,46); Content.ScrollBarThickness=2
 else
  Sidebar.Size=UDim2.new(0,116,1,0); Sidebar.Position=UDim2.fromOffset(0,0)
  Sidebar.AutomaticCanvasSize=Enum.AutomaticSize.Y; Sidebar.ScrollingDirection=Enum.ScrollingDirection.Y
  SidebarLayout.FillDirection=Enum.FillDirection.Vertical; SidebarLayout.VerticalAlignment=Enum.VerticalAlignment.Top
  SidebarLayout.HorizontalAlignment=Enum.HorizontalAlignment.Left; SidebarLayout.Padding=UDim.new(0,5)
  for _,b in pairs(Nav) do b.Size=UDim2.new(1,0,0,34); b.TextSize=10 end
  Content.Size=UDim2.new(1,-126,1,0); Content.Position=UDim2.fromOffset(126,0); Content.ScrollBarThickness=3
 end
end
ApplyResponsiveLayout()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ApplyResponsiveLayout) end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
 if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(ApplyResponsiveLayout); ApplyResponsiveLayout() end
end)
OpenPage=function(name)
	for n,p in pairs(Pages) do p.Visible=(n==name) end
	for n,b in pairs(Nav) do b.BackgroundColor3=(n==name) and Color3.fromRGB(22,66,69) or Color3.fromRGB(18,27,36); b.TextColor3=(n==name) and Color3.fromRGB(103,255,215) or Color3.fromRGB(164,190,199) end
	Content.CanvasPosition=Vector2.new(0,0)
end

local function UpdateLive()
	local act={}; for i=1,math.min(#Activity,6) do act[i]=Activity[i] end; ActivityText.Text=#act>0 and table.concat(act,"\n") or "No events yet."
	local hour=tonumber(os.date("%H")) or 12; Greeting.Text=(hour>=6 and hour<18) and "GOOD DAY ☀️" or "GOOD NIGHT 🌙"
	VS.Text="Current: "..string.upper(State.VisualQuality)..(State.VisualReconstruction and " • Reconstruction ON" or " • Reconstruction OFF")
	SI.Text="Players: "..#Players:GetPlayers().."\nJobId: "..game.JobId.."\nPlaceId: "..tostring(game.PlaceId)
end

RunService.RenderStepped:Connect(function(dt)
	CurrentFPS=math.floor(1/math.max(dt,.0001)); table.insert(FPSSamples,CurrentFPS); while #FPSSamples>120 do table.remove(FPSSamples,1) end
	local ok,ping=pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end); CurrentPing=ok and math.floor(ping) or 0
	local ok2,mem=pcall(function() return Stats:GetTotalMemoryUsageMb() end); CurrentMemory=ok2 and math.floor(mem) or 0
	if os.clock()-LastCount>2 then
		CurrentInstances=0; CurrentParts=0
		for _,obj in ipairs(workspace:GetDescendants()) do CurrentInstances+=1; if obj:IsA("BasePart") then CurrentParts+=1 end end
		LastCount=os.clock()
	end
	local sorted=table.clone(FPSSamples); table.sort(sorted); local low=sorted[math.max(1,math.floor(#sorted*.01))] or CurrentFPS
	SystemInfo.Text=string.format("FPS: %d     Ping: %d ms     Memory: %d MB\nPlayers: %d     Instances: %d     Parts: %d",CurrentFPS,CurrentPing,CurrentMemory,#Players:GetPlayers(),CurrentInstances,CurrentParts)
	DashFPS.Text=tostring(CurrentFPS); DashPing.Text=tostring(CurrentPing).." ms"; DashMemory.Text=tostring(CurrentMemory).." MB"
	PerfInfo.Text=string.format("FPS: %d\n1%% Low: %d\nPing: %d ms\nMemory: %d MB\nInstances: %d\nParts: %d",CurrentFPS,low,CurrentPing,CurrentMemory,CurrentInstances,CurrentParts)
	UpdateLive()
end)

--========================================================
-- MINIMIZE / DRAG / LOADING
--========================================================

local Restore=New("TextButton",{Size=UDim2.fromOffset(34,34),Position=UDim2.new(0,5,.5,-17),BackgroundColor3=Color3.fromRGB(8,18,24),Text="N",TextColor3=Color3.fromRGB(85,245,205),TextSize=15,Font=Enum.Font.GothamBlack,Visible=false,AutoButtonColor=false,ZIndex=80},Gui); Corner(Restore,9); Stroke(Restore,Color3.fromRGB(85,245,205),.25)
Min.Activated:Connect(function() Main.Visible=false; Restore.Visible=true end)
Restore.Activated:Connect(function() Main.Visible=true; Restore.Visible=false end)

local dragging=false; local dragStart; local startPos
Header.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
		dragging=true; dragStart=input.Position; startPos=Main.Position
		input.Changed:Connect(function() if input.UserInputState==Enum.UserInputState.End then dragging=false end end)
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
		local d=input.Position-dragStart
		Main.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
	end
end)

OpenPage("Dashboard")
-- NOXI'S HUB 1.7.0: redesigned cyberpunk interface; compact UI appears immediately.
Main.Visible=true
Loading.Visible=false
Log("NOXI HUB ready")
Notify("NOXI HUB ready")

print("[NOXI'S HUB] "..VERSION.." loaded | NOXI / "..DEVELOPER_USERNAME.." ("..DEVELOPER_DISPLAY..")")