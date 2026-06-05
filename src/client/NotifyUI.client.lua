-- src/client/NotifyUI.client.lua  | global toast feed, fed by the server "Notify" remote
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")

local player  = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Notify  = Remotes:WaitForChild("Notify")

local gui = Instance.new("ScreenGui")
gui.Name = "NotifyUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local holder = Instance.new("Frame")
holder.AnchorPoint = Vector2.new(0.5, 0); holder.Position = UDim2.new(0.5, 0, 0.16, 0)
holder.Size = UDim2.new(0.92, 0, 0.5, 0); holder.BackgroundTransparency = 1; holder.Parent = gui
local layout = Instance.new("UIListLayout", holder)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Top
layout.Padding = UDim.new(0, 8); layout.SortOrder = Enum.SortOrder.LayoutOrder

local order = 0
Notify.OnClientEvent:Connect(function(data)
	if not data or not data.text then return end
	order += 1
	local f = Instance.new("Frame")
	f.Size = UDim2.new(1, 0, 0, 0); f.AutomaticSize = Enum.AutomaticSize.Y
	f.BackgroundColor3 = Color3.fromRGB(25, 27, 36); f.BackgroundTransparency = 0.05
	f.LayoutOrder = order; f.Parent = holder
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
	local s = Instance.new("UIStroke", f); s.Color = data.color or Color3.fromRGB(120, 210, 255); s.Thickness = 2
	local pad = Instance.new("UIPadding", f)
	pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)
	pad.PaddingLeft = UDim.new(0, 14); pad.PaddingRight = UDim.new(0, 14)
	local t = Instance.new("TextLabel")
	t.Size = UDim2.new(1, 0, 0, 0); t.AutomaticSize = Enum.AutomaticSize.Y
	t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold; t.TextSize = 16
	t.TextColor3 = Color3.new(1, 1, 1); t.TextWrapped = true; t.Text = data.text; t.Parent = f

	f.BackgroundTransparency = 1; t.TextTransparency = 1; s.Transparency = 1
	TweenService:Create(f, TweenInfo.new(0.25), { BackgroundTransparency = 0.05 }):Play()
	TweenService:Create(t, TweenInfo.new(0.25), { TextTransparency = 0 }):Play()
	TweenService:Create(s, TweenInfo.new(0.25), { Transparency = 0 }):Play()
	task.delay(4, function()
		TweenService:Create(f, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(t, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		TweenService:Create(s, TweenInfo.new(0.4), { Transparency = 1 }):Play()
		task.wait(0.45); f:Destroy()
	end)
end)
