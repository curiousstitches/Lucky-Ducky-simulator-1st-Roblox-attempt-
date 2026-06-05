-- src/client/DuckRevealUI.client.lua  | splashy reveal card when a dispenser pops a duck
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")

local player     = Players.LocalPlayer
local Shared     = ReplicatedStorage:WaitForChild("Shared")
local DuckSchema = require(Shared:WaitForChild("DuckSchema"))
local DuckModelBuilder = require(Shared:WaitForChild("DuckModelBuilder"))
local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local RevealDuck = Remotes:WaitForChild("RevealDuck")

local gui = Instance.new("ScreenGui")
gui.Name = "DuckRevealUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local function toast(text, color)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0); f.Position = UDim2.new(0.5, 0, 0.12, 0)
	f.Size = UDim2.new(0.9, 0, 0, 44); f.BackgroundColor3 = Color3.fromRGB(25, 27, 36)
	f.BackgroundTransparency = 0.05; f.Parent = gui
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 12)
	local s = Instance.new("UIStroke", f); s.Color = color or Color3.fromRGB(255, 90, 90); s.Thickness = 2
	local t = Instance.new("TextLabel")
	t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold
	t.TextSize = 18; t.TextColor3 = Color3.new(1, 1, 1); t.Text = text; t.Parent = f
	task.delay(2, function()
		TweenService:Create(f, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
		TweenService:Create(t, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		task.wait(0.35); f:Destroy()
	end)
end

local function showDuck(duck, dispenserName)
	local rarity = DuckSchema.getRarity(duck.rarity)
	local rc = rarity and rarity.color or Color3.new(1, 1, 1)

	local card = Instance.new("Frame")
	card.AnchorPoint = Vector2.new(0.5, 0.5); card.Position = UDim2.fromScale(0.5, 0.5)
	card.Size = UDim2.new(0, 300, 0, 360); card.BackgroundColor3 = Color3.fromRGB(22, 24, 32)
	card.Parent = gui
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 20)
	local stroke = Instance.new("UIStroke", card); stroke.Color = rc; stroke.Thickness = 4

	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 40); header.Position = UDim2.new(0, 0, 0, 14)
	header.BackgroundTransparency = 1; header.Font = Enum.Font.GothamBlack; header.TextSize = 24
	header.TextColor3 = rc; header.Text = (duck.shiny and "✨ " or "") .. duck.rarity
	header.Parent = card

	local big = Instance.new("ViewportFrame")
	big.Size = UDim2.new(1, -40, 0, 150); big.Position = UDim2.new(0, 20, 0, 60)
	big.BackgroundColor3 = Color3.fromRGB(14, 15, 20); big.BackgroundTransparency = 0.2
	big.Parent = card
	Instance.new("UICorner", big).CornerRadius = UDim.new(0, 14)
	local cam = Instance.new("Camera"); big.CurrentCamera = cam; cam.Parent = big
	local okm, model = pcall(function() return DuckModelBuilder.build(duck) end)
	if okm and model then
		model.Parent = big
		local cf, size = model:GetBoundingBox()
		local dist = size.Magnitude * 1.1
		task.spawn(function()
			local a = 0
			while big.Parent do
				a += 0.04
				local pos = cf.Position + Vector3.new(math.sin(a) * dist, dist * 0.3, math.cos(a) * dist)
				cam.CFrame = CFrame.new(pos, cf.Position)
				task.wait(0.03)
			end
		end)
	else
		local fallback = Instance.new("TextLabel"); fallback.Size = UDim2.fromScale(1, 1)
		fallback.BackgroundTransparency = 1; fallback.TextScaled = true; fallback.Text = "🦆"; fallback.Parent = big
	end

	local info = Instance.new("TextLabel")
	info.Size = UDim2.new(1, -24, 0, 110); info.Position = UDim2.new(0, 12, 0, 218)
	info.BackgroundTransparency = 1; info.Font = Enum.Font.GothamMedium; info.TextSize = 15
	info.TextColor3 = Color3.fromRGB(225, 225, 225); info.TextYAlignment = Enum.TextYAlignment.Top
	info.TextWrapped = true
	info.Text = ("%s\nBody: %s  •  Head: %s\nFace: %s  •  Shimmer: %s\nParticle: %s\nWorth: %d  •  Power: %d")
		:format(dispenserName or "", duck.parts.Body, duck.parts.Head, duck.parts.Face,
			duck.parts.Shimmer, duck.parts.Particle, duck.worth or 0, duck.strength or 0)
	info.Parent = card

	-- pop in
	card.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(card, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.new(0, 300, 0, 360) }):Play()

	-- rarity-scaled flash: rarer = wilder pulse
	local tier = rarity and rarity.tier or 1
	local pulses = math.clamp(tier * 2, 2, 14)
	task.spawn(function()
		for i = 1, pulses do
			TweenService:Create(stroke, TweenInfo.new(0.18), { Thickness = 8 }):Play(); task.wait(0.18)
			TweenService:Create(stroke, TweenInfo.new(0.18), { Thickness = 4 }):Play(); task.wait(0.18)
		end
	end)

	task.delay(2.6, function()
		TweenService:Create(card, TweenInfo.new(0.25), { Size = UDim2.new(0, 0, 0, 0) }):Play()
		task.wait(0.3); card:Destroy()
	end)
end

RevealDuck.OnClientEvent:Connect(function(payload)
	if not payload then return end
	if payload.ok then showDuck(payload.duck, payload.dispenser)
	else toast(payload.reason or "Couldn't pull a duck", Color3.fromRGB(255, 90, 90)) end
end)
