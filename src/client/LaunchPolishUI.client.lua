-- src/client/LaunchPolishUI.client.lua  | loading screen, settings menu, like-prompt, anti-idle,
-- save indicator, and a daily reward button.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

-- ===== LOADING SCREEN (covers the world build, fades after a few seconds) =====
local load = Instance.new("ScreenGui"); load.Name="LoadingUI"; load.IgnoreGuiInset=true; load.DisplayOrder=999; load.ResetOnSpawn=false; load.Parent=pg
local cover=Instance.new("Frame"); cover.Size=UDim2.fromScale(1,1); cover.BackgroundColor3=Color3.fromRGB(20,24,40); cover.Parent=load
local logo=Instance.new("TextLabel"); logo.AnchorPoint=Vector2.new(0.5,0.5); logo.Position=UDim2.fromScale(0.5,0.42)
logo.Size=UDim2.new(0,500,0,80); logo.BackgroundTransparency=1; logo.Font=Enum.Font.FredokaOne; logo.TextScaled=true
logo.TextColor3=Color3.fromRGB(255,220,90); logo.Text="🦆 JEEPERS-GET-DUCKED"; logo.Parent=cover
local tip=Instance.new("TextLabel"); tip.AnchorPoint=Vector2.new(0.5,0.5); tip.Position=UDim2.fromScale(0.5,0.56)
tip.Size=UDim2.new(0,400,0,30); tip.BackgroundTransparency=1; tip.Font=Enum.Font.Gotham; tip.TextScaled=true
tip.TextColor3=Color3.fromRGB(200,210,230); tip.Text="Loading the flock..."; tip.Parent=cover
task.spawn(function()
	for i=1,3 do tip.Text="Loading the flock"..string.rep(".",i); task.wait(0.5) end
	task.wait(2)
	TweenService:Create(cover,TweenInfo.new(1),{BackgroundTransparency=1}):Play()
	TweenService:Create(logo,TweenInfo.new(1),{TextTransparency=1}):Play()
	TweenService:Create(tip,TweenInfo.new(1),{TextTransparency=1}):Play()
	task.wait(1.1); load:Destroy()
end)

-- ===== ANTI-IDLE (stops the 20-min AFK kick so AFK earners keep going) =====
player.Idled:Connect(function()
	VirtualUser:CaptureController()
	VirtualUser:ClickButton2(Vector2.new()) -- harmless input resets idle timer
end)

local gui=Instance.new("ScreenGui"); gui.Name="PolishUI"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true; gui.Parent=pg

-- ===== SAVE INDICATOR =====
local SaveStatus = Remotes:WaitForChild("SaveStatus")
local saveLbl=Instance.new("TextLabel"); saveLbl.AnchorPoint=Vector2.new(1,1); saveLbl.Position=UDim2.new(1,-16,1,-16)
saveLbl.Size=UDim2.new(0,120,0,26); saveLbl.BackgroundTransparency=1; saveLbl.Font=Enum.Font.GothamBold; saveLbl.TextSize=13
saveLbl.TextColor3=Color3.fromRGB(150,230,150); saveLbl.Text=""; saveLbl.TextXAlignment=Enum.TextXAlignment.Right; saveLbl.Parent=gui
SaveStatus.OnClientEvent:Connect(function()
	saveLbl.Text="💾 Saving..."; task.wait(1.2); saveLbl.Text="✓ Saved"; task.wait(1.5); saveLbl.Text=""
end)

-- ===== DAILY REWARD BUTTON =====
local ClaimDaily = Remotes:WaitForChild("ClaimDaily")
local dailyBtn=Instance.new("TextButton"); dailyBtn.AnchorPoint=Vector2.new(0,1); dailyBtn.Position=UDim2.new(0,16,1,-130)
dailyBtn.Size=UDim2.new(0,110,0,48); dailyBtn.BackgroundColor3=Color3.fromRGB(255,200,70); dailyBtn.Font=Enum.Font.FredokaOne
dailyBtn.TextSize=14; dailyBtn.TextColor3=Color3.fromRGB(50,35,10); dailyBtn.Text="🎁 Daily"; dailyBtn.Parent=gui
Instance.new("UICorner",dailyBtn).CornerRadius=UDim.new(0,14)
dailyBtn.Activated:Connect(function() ClaimDaily:InvokeServer() end)

-- ===== SETTINGS MENU (music/sfx/low-graphics) =====
local SoundService=game:GetService("SoundService")
local Lighting=game:GetService("Lighting")
local setBtn=Instance.new("TextButton"); setBtn.AnchorPoint=Vector2.new(1,0); setBtn.Position=UDim2.new(1,-16,0,140)
setBtn.Size=UDim2.new(0,48,0,48); setBtn.BackgroundColor3=Color3.fromRGB(60,64,80); setBtn.Font=Enum.Font.GothamBold
setBtn.TextSize=22; setBtn.TextColor3=Color3.new(1,1,1); setBtn.Text="⚙️"; setBtn.Parent=gui
Instance.new("UICorner",setBtn).CornerRadius=UDim.new(1,0)
local setPanel=Instance.new("Frame"); setPanel.AnchorPoint=Vector2.new(0.5,0.5); setPanel.Position=UDim2.fromScale(0.5,0.5)
setPanel.Size=UDim2.new(0,280,0,220); setPanel.BackgroundColor3=Color3.fromRGB(24,28,40); setPanel.Visible=false; setPanel.Parent=gui
Instance.new("UICorner",setPanel).CornerRadius=UDim.new(0,16); Instance.new("UIStroke",setPanel).Color=Color3.fromRGB(120,180,255)
local sTitle=Instance.new("TextLabel"); sTitle.Size=UDim2.new(1,0,0,40); sTitle.BackgroundTransparency=1; sTitle.Font=Enum.Font.FredokaOne
sTitle.TextSize=20; sTitle.TextColor3=Color3.fromRGB(150,210,255); sTitle.Text="⚙️ Settings"; sTitle.Parent=setPanel
local function toggle(y, label, default, cb)
	local on=default
	local b=Instance.new("TextButton"); b.Position=UDim2.new(0.5,-110,0,y); b.Size=UDim2.new(0,220,0,42)
	b.BackgroundColor3=Color3.fromRGB(40,44,58); b.Font=Enum.Font.GothamBold; b.TextSize=15; b.TextColor3=Color3.new(1,1,1); b.Parent=setPanel
	Instance.new("UICorner",b).CornerRadius=UDim.new(0,10)
	local function upd() b.Text=label..": "..(on and "ON" or "OFF") end; upd()
	b.Activated:Connect(function() on=not on; upd(); cb(on) end)
end
toggle(50,"Music",true,function(on) SoundService.AmbientReverb=on and Enum.ReverbType.NoReverb or Enum.ReverbType.NoReverb; local a=SoundService:FindFirstChild("ThemeAmbient"); if a then a.Volume=on and 0.3 or 0 end end)
toggle(100,"Low Graphics",false,function(on)
	-- low graphics: drop atmosphere + particle load
	local at=Lighting:FindFirstChildOfClass("Atmosphere"); if at then at.Density=on and 0.1 or 0.3 end
end)
local closeS=Instance.new("TextButton"); closeS.AnchorPoint=Vector2.new(0.5,1); closeS.Position=UDim2.new(0.5,0,1,-12)
closeS.Size=UDim2.new(0,120,0,40); closeS.BackgroundColor3=Color3.fromRGB(200,80,80); closeS.Font=Enum.Font.GothamBold
closeS.TextSize=15; closeS.TextColor3=Color3.new(1,1,1); closeS.Text="Close"; closeS.Parent=setPanel
Instance.new("UICorner",closeS).CornerRadius=UDim.new(0,10)
setBtn.Activated:Connect(function() setPanel.Visible=not setPanel.Visible end)
closeS.Activated:Connect(function() setPanel.Visible=false end)

-- ===== LIKE NUDGE (once, after 3 min of play) =====
task.delay(180, function()
	local n=Instance.new("TextLabel"); n.AnchorPoint=Vector2.new(0.5,0); n.Position=UDim2.new(0.5,0,0,150)
	n.Size=UDim2.new(0,360,0,40); n.BackgroundColor3=Color3.fromRGB(40,44,60); n.Font=Enum.Font.GothamBold
	n.TextSize=15; n.TextColor3=Color3.fromRGB(255,225,120); n.Text="👍 Enjoying it? Tap the Like button up top — it helps a ton!"; n.Parent=gui
	Instance.new("UICorner",n).CornerRadius=UDim.new(0,12)
	task.wait(8); n:Destroy()
end)
