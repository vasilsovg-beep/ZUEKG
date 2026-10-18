--========================================================
-- NOXI'S HUB 1.3.0
-- DASHBOARD 3.0 | VISUAL RECONSTRUCTION 3.0
-- PERFORMANCE 3.0 | DEVELOPER EDITION
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

local VERSION = "1.7.0-dev"
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

local Loading=New("Frame",{Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(2,2,4),ZIndex=200},Gui)
local LoadTitle=New("TextLabel",{Size=UDim2.new(1,0,0,55),Position=UDim2.new(0,0,.40,0),BackgroundTransparency=1,Text="NOXI'S HUB",TextColor3=Accent,TextSize=34,Font=Enum.Font.GothamBlack,ZIndex=201},Loading)
local LoadSub=New("TextLabel",{Size=UDim2.new(1,0,0,30),Position=UDim2.new(0,0,.49,0),BackgroundTransparency=1,Text="1.3.0  •  PERFORMANCE & VISUALS",TextColor3=Color3.fromRGB(180,180,190),TextSize=13,Font=Enum.Font.GothamMedium,ZIndex=201},Loading)
local BarBack=New("Frame",{Size=UDim2.new(0,300,0,5),Position=UDim2.new(.5,-150,.55,0),BackgroundColor3=Color3.fromRGB(25,25,30),ZIndex=201},Loading); Corner(BarBack,5)
local Bar=New("Frame",{Size=UDim2.new(0,0,1,0),BackgroundColor3=Accent,ZIndex=202},BarBack); Corner(Bar,5)
local LoadStatus=New("TextLabel",{Size=UDim2.new(1,0,0,25),Position=UDim2.new(0,0,.58,0),BackgroundTransparency=1,Text="Starting...",TextColor3=Color3.fromRGB(145,145,155),TextSize=12,Font=Enum.Font.Gotham,ZIndex=201},Loading)

local Main=New("Frame",{Name="Main",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.new(0,720,0,520),BackgroundColor3=Color3.fromRGB(7,7,10),Visible=false},Gui)
Corner(Main,16); Stroke(Main,Color3.fromRGB(45,45,55),.15)
New("UISizeConstraint",{MinSize=Vector2.new(320,330),MaxSize=Vector2.new(900,620)},Main)
local Header=New("Frame",{Size=UDim2.new(1,0,0,58),BackgroundColor3=Color3.fromRGB(10,10,14)},Main); Corner(Header,16)
New("TextLabel",{Size=UDim2.new(0,320,1,0),Position=UDim2.fromOffset(18,0),BackgroundTransparency=1,Text="NOXI'S HUB  •  1.3.0",TextColor3=Color3.fromRGB(240,240,245),TextSize=17,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Left},Header)
New("TextLabel",{Size=UDim2.new(0,190,1,0),Position=UDim2.new(1,-245,0,0),BackgroundTransparency=1,Text=IsMainDeveloper and "👑 NOXI  •  DEV" or "DEVELOPER EDITION",TextColor3=Accent,TextSize=11,Font=Enum.Font.GothamBold,TextXAlignment=Enum.TextXAlignment.Right},Header)
local Min=New("TextButton",{Size=UDim2.fromOffset(38,32),Position=UDim2.new(1,-45,0,13),BackgroundColor3=Color3.fromRGB(20,20,25),Text="—",TextColor3=Color3.fromRGB(220,220,225),TextSize=17,Font=Enum.Font.GothamBold,AutoButtonColor=false},Header); Corner(Min,9)
local Body=New("Frame",{Size=UDim2.new(1,-18,1,-68),Position=UDim2.fromOffset(9,62),BackgroundTransparency=1},Main)
local Sidebar=New("ScrollingFrame",{Size=UDim2.new(0,150,1,0),BackgroundColor3=Color3.fromRGB(10,10,14),BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=3,Active=true},Body); Corner(Sidebar,12); Padding(Sidebar,8)
New("UIListLayout",{Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder},Sidebar)
local Content=New("ScrollingFrame",{Size=UDim2.new(1,-160,1,0),Position=UDim2.fromOffset(160,0),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=4,Active=true},Body); Padding(Content,4)
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
	local f=New("Frame",{Size=UDim2.new(1,0,0,h or 100),BackgroundColor3=Color3.fromRGB(12,12,17)},parent); Corner(f,12); Stroke(f,Color3.fromRGB(40,40,50),.25); Padding(f,12); return f
end
local function Label(parent,text,h,color)
	return New("TextLabel",{Size=UDim2.new(1,0,0,h or 25),BackgroundTransparency=1,Text=text,TextColor3=color or Color3.fromRGB(215,215,225),TextSize=13,Font=Enum.Font.GothamMedium,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center},parent)
end
local function Button(parent,text,callback,h)
	local b=New("TextButton",{Size=UDim2.new(1,0,0,h or 38),BackgroundColor3=Color3.fromRGB(18,18,24),Text=text,TextColor3=Color3.fromRGB(220,220,228),TextSize=12,Font=Enum.Font.GothamBold,AutoButtonColor=false},parent); Corner(b,9); Stroke(b,Color3.fromRGB(50,50,60),.35); b.Activated:Connect(function() pcall(callback) end); return b
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

local Dashboard=NewPage("Dashboard"); Title(Dashboard,"Dashboard 3.0","Live developer overview")
local Greeting=Label(Dashboard,"",28,Accent)
local SystemCard=Card(Dashboard,120); Label(SystemCard,"SYSTEM STATUS",20,Accent); local SystemInfo=Label(SystemCard,"Loading...",70); SystemInfo.Position=UDim2.fromOffset(12,35)
local ActivityCard=Card(Dashboard,170); Label(ActivityCard,"LIVE ACTIVITY",20,Accent); local ActivityText=Label(ActivityCard,"No events yet.",125,Color3.fromRGB(150,150,160)); ActivityText.Position=UDim2.fromOffset(12,35)
local QuickCard=Card(Dashboard,95); Label(QuickCard,"QUICK ACTIONS",20,Accent)
local QB2=Button(QuickCard,"⚡  OPEN PERFORMANCE CENTER",function() OpenPage("Performance") end); QB2.Position=UDim2.new(0,0,0,38); QB2.Size=UDim2.new(1,0,0,38)

local PlayerPage=NewPage("Player"); Title(PlayerPage,"Player","Current player profile")
local PC=Card(PlayerPage,150); Label(PC,"PROFILE",20,Accent); Label(PC,"Username: "..Player.Name,24); Label(PC,"Display Name: "..Player.DisplayName,24); Label(PC,IsMainDeveloper and "👑 NOXI • MAIN DEVELOPER" or "PLAYER",28,IsMainDeveloper and Accent or Color3.fromRGB(160,160,170))

local PerformancePage=NewPage("Performance"); Title(PerformancePage,"Performance 3.0","Live FPS, 1% low, ping and memory")
local PerfCard=Card(PerformancePage,190); Label(PerfCard,"LIVE METRICS",20,Accent); local PerfInfo=Label(PerfCard,"Loading...",150); PerfInfo.Position=UDim2.fromOffset(12,38)
local Prof=Card(PerformancePage,160); Label(Prof,"PROFILE",20,Accent)
for i,name in ipairs({"Balanced","Performance","Ultra"}) do local b=Button(Prof,string.upper(name),function() State.PerformanceProfile=name; Notify("Performance profile: "..name) end); b.Position=UDim2.fromOffset(12,38+(i-1)*42) end

local VisualsPage=NewPage("Visuals"); Title(VisualsPage,"Visuals 3.0","Visual Reconstruction • Low / Medium / Ultra")
local VC=Card(VisualsPage,225); Label(VC,"VISUAL RECONSTRUCTION",22,Accent); Label(VC,"Lighting, atmosphere, bloom, depth and material response.",30,Color3.fromRGB(145,145,155))
local VL=Button(VC,"LOW",function() ApplyVisualQuality("Low") end); VL.Position=UDim2.new(0,0,0,70); VL.Size=UDim2.new(.32,-5,0,44)
local VM=Button(VC,"MEDIUM",function() ApplyVisualQuality("Medium") end); VM.Position=UDim2.new(.34,0,0,70); VM.Size=UDim2.new(.32,-5,0,44)
local VU=Button(VC,"🔥  ULTRA",function() ApplyVisualQuality("Ultra") end); VU.Position=UDim2.new(.68,0,0,70); VU.Size=UDim2.new(.32,0,0,44)
local VD=Button(VC,"DISABLE RECONSTRUCTION",DisableVisualReconstruction); VD.Position=UDim2.new(0,0,0,122)
local VS=Label(VC,"Current: MEDIUM • Reconstruction OFF",25,Accent); VS.Position=UDim2.fromOffset(0,165)


local MusicPage=NewPage("Music"); Title(MusicPage,"Music Player","Track selector and volume")
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

local ConfigPage=NewPage("Config"); Title(ConfigPage,"Config Manager","JSON import and export")
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
local SetC=Card(SettingsPage,175); Label(SetC,"GENERAL",20,Accent)
local NT=Toggle(SetC,"Notifications",true,function(v) State.Notifications=v end); NT.Position=UDim2.fromOffset(12,38)
local AT=Toggle(SetC,"Animations",true,function(v) State.Animations=v end); AT.Position=UDim2.fromOffset(12,80)
local AO=Toggle(SetC,"AMOLED",false,function(v) State.AMOLED=v; Main.BackgroundColor3=v and Color3.fromRGB(0,0,0) or Color3.fromRGB(7,7,10) end); AO.Position=UDim2.fromOffset(12,122)

local WhatsNew=NewPage("What's New"); Title(WhatsNew,"What's New","NOXI'S HUB 1.3.0")
local WC=Card(WhatsNew,245); Label(WC,"1.3.0 RESTORE BASE",22,Accent); local WT=Label(WC,"🏠 Dashboard 3.0\n⚡ Performance metrics\n🎨 Visual Reconstruction: Low / Medium / Ultra\n🛠 Developer diagnostics\n📱 Mobile scrolling preserved\n🖤 AMOLED appearance\n🪟 Minimize, restore and drag controls",190); WT.Position=UDim2.fromOffset(12,38)

--========================================================
-- NAVIGATION / EVENTS
--========================================================

local order={"Dashboard","Player","Performance","Music","Config","Visuals","Server","Debug","Settings","What's New"}
for i,name in ipairs(order) do local b=Button(Sidebar,name,function() OpenPage(name) end,36); b.LayoutOrder=i; Nav[name]=b end
OpenPage=function(name)
	for n,p in pairs(Pages) do p.Visible=(n==name) end
	for n,b in pairs(Nav) do b.BackgroundColor3=(n==name) and Accent or Color3.fromRGB(18,18,24); b.TextColor3=(n==name) and Color3.new(1,1,1) or Color3.fromRGB(190,190,200) end
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
	PerfInfo.Text=string.format("FPS: %d\n1%% Low: %d\nPing: %d ms\nMemory: %d MB\nInstances: %d\nParts: %d",CurrentFPS,low,CurrentPing,CurrentMemory,CurrentInstances,CurrentParts)
	UpdateLive()
end)

--========================================================
-- MINIMIZE / DRAG / LOADING
--========================================================

local Restore=New("TextButton",{Size=UDim2.fromOffset(34,34),Position=UDim2.new(0,5,.5,-17),BackgroundColor3=Color3.fromRGB(8,8,12),Text="N",TextColor3=Accent,TextSize=15,Font=Enum.Font.GothamBlack,Visible=false,AutoButtonColor=false,ZIndex=80},Gui); Corner(Restore,10); Stroke(Restore,Accent,.25)
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
task.spawn(function()
	local steps={"Initializing core","Loading Dashboard 2.0","Preparing Performance Center","Initializing Music Player","Preparing JSON Config Manager","Preparing diagnostics","Finalizing interface"}
	for i,s in ipairs(steps) do
		LoadStatus.Text=s
		TweenService:Create(Bar,TweenInfo.new(.22),{Size=UDim2.new(i/#steps,0,1,0)}):Play()
		task.wait(.23)
	end
	Main.Visible=true; OpenPage("Dashboard"); task.wait(.25)
	TweenService:Create(Loading,TweenInfo.new(.35),{BackgroundTransparency=1}):Play(); task.wait(.4); Loading.Visible=false
	Log("NOXI'S HUB 1.3.0 online"); Notify("NOXI'S HUB 1.3.0 ready")
end)

print("[NOXI'S HUB] 1.3.0 loaded | NOXI / "..DEVELOPER_USERNAME.." ("..DEVELOPER_DISPLAY..")")