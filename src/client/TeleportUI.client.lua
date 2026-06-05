-- src/client/TeleportUI.client.lua  | fast-travel menu: on-screen button + opened by the lobby pad.
-- Lists worlds; unlocked ones are tappable to jump to that world's first zone.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player  = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetMenu = Remotes:WaitForChild("GetTeleportMenu")
local TeleportWorld = Remotes:WaitForChild("TeleportWorld")

local gui=Instance.new("ScreenGui"); gui.Name="TeleportUI"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=player:WaitForChild("PlayerGui")

local openBtn=Instance.new("TextButton"); openBtn.AnchorPoint=Vector2.new(1,1); openBtn.Position=UDim2.new(1,-16,1,-126)
openBtn.Size=UDim2.new(0,110,0,48); openBtn.BackgroundColor3=Color3.fromRGB(120,180,255); openBtn.Font=Enum.Font.GothamBlack
openBtn.TextSize=14; openBtn.TextColor3=Color3.new(1,1,1); openBtn.Text="🌀 Travel"; openBtn.Parent=gui
Instance.new("UICorner",openBtn).CornerRadius=UDim.new(0,14)

local panel=Instance.new("Frame"); panel.AnchorPoint=Vector2.new(0.5,0.5); panel.Position=UDim2.fromScale(0.5,0.5)
panel.Size=UDim2.new(0,440,0,420); panel.BackgroundColor3=Color3.fromRGB(20,22,30); panel.Visible=false; panel.Parent=gui
Instance.new("UICorner",panel).CornerRadius=UDim.new(0,18)
Instance.new("UIStroke",panel).Color=Color3.fromRGB(120,180,255)
local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,-50,0,40); title.Position=UDim2.new(0,12,0,8)
title.BackgroundTransparency=1; title.Font=Enum.Font.GothamBlack; title.TextSize=18; title.TextXAlignment=Enum.TextXAlignment.Left
title.TextColor3=Color3.fromRGB(150,210,255); title.Text="🌀 FAST TRAVEL"; title.Parent=panel
local close=Instance.new("TextButton"); close.AnchorPoint=Vector2.new(1,0); close.Position=UDim2.new(1,-10,0,8)
close.Size=UDim2.new(0,36,0,36); close.BackgroundColor3=Color3.fromRGB(200,70,70); close.Font=Enum.Font.GothamBold
close.TextSize=20; close.TextColor3=Color3.new(1,1,1); close.Text="✕"; close.Parent=panel
Instance.new("UICorner",close).CornerRadius=UDim.new(1,0)
local scroll=Instance.new("ScrollingFrame"); scroll.Position=UDim2.new(0,12,0,54); scroll.Size=UDim2.new(1,-24,1,-66)
scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0; scroll.ScrollBarThickness=5; scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.Parent=panel
local list=Instance.new("UIListLayout",scroll); list.Padding=UDim.new(0,8); list.HorizontalAlignment=Enum.HorizontalAlignment.Center

local function refresh()
	for _,c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local m=GetMenu:InvokeServer() or {}
	for _,w in ipairs(m.worlds or {}) do
		local card=Instance.new("Frame"); card.Size=UDim2.new(1,-6,0,54); card.BackgroundColor3=w.unlocked and Color3.fromRGB(32,38,52) or Color3.fromRGB(26,28,34); card.Parent=scroll
		Instance.new("UICorner",card).CornerRadius=UDim.new(0,12)
		local t=Instance.new("TextLabel"); t.Position=UDim2.new(0,12,0,0); t.Size=UDim2.new(0.6,0,1,0); t.BackgroundTransparency=1
		t.Font=Enum.Font.GothamBold; t.TextSize=15; t.TextXAlignment=Enum.TextXAlignment.Left
		t.TextColor3=w.unlocked and Color3.new(1,1,1) or Color3.fromRGB(130,130,140)
		t.Text=("World %d — %s"):format(w.n, w.name); t.Parent=card
		local b=Instance.new("TextButton"); b.AnchorPoint=Vector2.new(1,0.5); b.Position=UDim2.new(1,-10,0.5,0); b.Size=UDim2.new(0,96,0,40)
		b.Font=Enum.Font.GothamBold; b.TextSize=13; b.TextColor3=Color3.new(1,1,1); b.Parent=card
		Instance.new("UICorner",b).CornerRadius=UDim.new(0,9)
		if w.unlocked then b.BackgroundColor3=Color3.fromRGB(70,200,110); b.Text="Travel"
			b.Activated:Connect(function() TeleportWorld:InvokeServer(w.n); panel.Visible=false end)
		else b.BackgroundColor3=Color3.fromRGB(60,64,76); b.Text="🔒 Locked"; b.AutoButtonColor=false end
	end
end

openBtn.Activated:Connect(function() panel.Visible=true; refresh() end)
close.Activated:Connect(function() panel.Visible=false end)
-- the lobby Fast Travel pad also opens it
ProximityPromptService.PromptTriggered:Connect(function(prompt)
	if prompt:GetAttribute("TeleportMenu") then panel.Visible=true; refresh() end
end)
