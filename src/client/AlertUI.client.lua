-- src/client/AlertUI.client.lua  | big splashy center alert for server-wide random events
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")

local player  = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Alert   = Remotes:WaitForChild("Alert")

local gui = Instance.new("ScreenGui")
gui.Name = "AlertUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

Alert.OnClientEvent:Connect(function(data)
	if not data or not data.text then return end
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5); f.Position = UDim2.fromScale(0.5, 0.32)
	f.Size = UDim2.new(0, 0, 0, 70); f.BackgroundColor3 = Color3.fromRGB(35, 20, 50)
	f.BackgroundTransparency = 0.05; f.Parent = gui
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 16)
	local s = Instance.new("UIStroke", f); s.Color = Color3.fromRGB(255, 200, 70); s.Thickness = 3
	local pad = Instance.new("UIPadding", f)
	pad.PaddingLeft = UDim.new(0, 20); pad.PaddingRight = UDim.new(0, 20)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 1, 0); t.AutomaticSize = Enum.AutomaticSize.X
	t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBlack; t.TextSize = 22
	t.TextColor3 = Color3.fromRGB(255, 230, 130); t.Text = data.text; t.Parent = f

	f.Size = UDim2.new(0.9, 0, 0, 0)
	TweenService:Create(f, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0.9, 0, 0, 70) }):Play()
	-- pulse the stroke
	task.spawn(function()
		for i = 1, 6 do
			TweenService:Create(s, TweenInfo.new(0.3), { Thickness = 6 }):Play(); task.wait(0.3)
			TweenService:Create(s, TweenInfo.new(0.3), { Thickness = 3 }):Play(); task.wait(0.3)
		end
	end)
	task.delay(4.5, function()
		TweenService:Create(f, TweenInfo.new(0.3), { Size = UDim2.new(0.9, 0, 0, 0) }):Play()
		task.wait(0.35); f:Destroy()
	end)
end)
