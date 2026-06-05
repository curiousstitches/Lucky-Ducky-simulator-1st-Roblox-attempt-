-- src/client/OfflineUI.client.lua  | "welcome back" banner for Premium offline earnings
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")

local player  = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OfflineEarnings = Remotes:WaitForChild("OfflineEarnings")

local gui = Instance.new("ScreenGui")
gui.Name = "OfflineUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

local function fmtTime(s)
	local h = math.floor(s / 3600); local m = math.floor((s % 3600) / 60)
	if h > 0 then return ("%dh %dm"):format(h, m) end
	return ("%dm"):format(m)
end

OfflineEarnings.OnClientEvent:Connect(function(data)
	if not data or (data.amount or 0) <= 0 then return end
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0); f.Position = UDim2.new(0.5, 0, -0.2, 0)
	f.Size = UDim2.new(0.86, 0, 0, 64); f.BackgroundColor3 = Color3.fromRGB(25, 27, 36); f.Parent = gui
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 14)
	local s = Instance.new("UIStroke", f); s.Color = Color3.fromRGB(120, 210, 255); s.Thickness = 2

	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold
	t.TextSize = 16; t.TextColor3 = Color3.new(1, 1, 1); t.TextWrapped = true
	t.Text = ("🦆 Welcome back! Your ducks earned %d Duck Droppings while you were away (%s)")
		:format(data.amount, fmtTime(data.seconds or 0))
	t.Parent = f

	TweenService:Create(f, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0.08, 0) }):Play()
	task.delay(5, function()
		TweenService:Create(f, TweenInfo.new(0.4), { Position = UDim2.new(0.5, 0, -0.2, 0) }):Play()
		task.wait(0.45); f:Destroy()
	end)
end)
