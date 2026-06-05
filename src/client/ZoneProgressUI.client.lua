-- src/client/ZoneProgressUI.client.lua  | a slim top bar showing current World, Zone, and progress
-- through the 100-zone line. Updates as you walk; hides while in the sky lobby.
local Players  = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local ZoneConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ZoneConfig"))
local ZONE_LEN = ZoneConfig.ZoneLength
local LOBBY_Y = 250

local gui=Instance.new("ScreenGui"); gui.Name="ZoneProgressUI"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
gui.Parent=player:WaitForChild("PlayerGui")

local bar=Instance.new("Frame"); bar.AnchorPoint=Vector2.new(0.5,0); bar.Position=UDim2.new(0.5,0,0,92)
bar.Size=UDim2.new(0,300,0,42); bar.BackgroundColor3=Color3.fromRGB(25,28,40); bar.BackgroundTransparency=0.1
bar.Visible=false; bar.Parent=gui
Instance.new("UICorner",bar).CornerRadius=UDim.new(0,14)
local st=Instance.new("UIStroke",bar); st.Color=Color3.fromRGB(255,210,80); st.Thickness=2

local title=Instance.new("TextLabel"); title.Size=UDim2.new(1,-16,0,20); title.Position=UDim2.new(0,8,0,3)
title.BackgroundTransparency=1; title.Font=Enum.Font.FredokaOne; title.TextSize=15; title.TextColor3=Color3.fromRGB(255,225,120)
title.TextXAlignment=Enum.TextXAlignment.Left; title.Text="World 1"; title.Parent=bar

local track=Instance.new("Frame"); track.Position=UDim2.new(0,8,0,26); track.Size=UDim2.new(1,-16,0,10)
track.BackgroundColor3=Color3.fromRGB(50,54,68); track.Parent=bar
Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
local fill=Instance.new("Frame"); fill.Size=UDim2.new(0,0,1,0); fill.BackgroundColor3=Color3.fromRGB(80,220,120); fill.Parent=track
Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

local acc=0
RunService.Heartbeat:Connect(function(dt)
	acc = acc + dt; if acc < 0.25 then return end; acc = 0
	local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then bar.Visible=false; return end
	if math.abs(root.Position.Y-LOBBY_Y)<60 and root.Position.Z>60 then
		bar.Visible=true
		local zone=math.clamp(math.floor(root.Position.Z/ZONE_LEN)+1,1,ZoneConfig.TotalZones)
		local w=ZoneConfig.worldForZone(zone)
		local zoneInWorld=((zone-1)%10)+1
		title.Text=("World %d: %s  •  Zone %d/100"):format(w.n, w.name, zone)
		fill.Size=UDim2.new(zone/100,0,1,0)
	else
		bar.Visible=false
	end
end)
