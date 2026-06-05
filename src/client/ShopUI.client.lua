-- src/client/ShopUI.client.lua  | mobile Robux shop: products, passes, subscription
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local player     = Players.LocalPlayer
local Shared     = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(Shared:WaitForChild("ShopConfig"))
local Remotes    = ReplicatedStorage:WaitForChild("Remotes")

local gui = Instance.new("ScreenGui")
gui.Name = "ShopUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- floating open button (bottom-right, thumb-reachable)
local openBtn = Instance.new("TextButton")
openBtn.AnchorPoint = Vector2.new(1, 1); openBtn.Position = UDim2.new(1, -16, 1, -16)
openBtn.Size = UDim2.new(0, 96, 0, 48); openBtn.BackgroundColor3 = Color3.fromRGB(70, 200, 110)
openBtn.Font = Enum.Font.GothamBlack; openBtn.TextSize = 18; openBtn.TextColor3 = Color3.new(1, 1, 1)
openBtn.Text = "🛒 Shop"; openBtn.Parent = gui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 14)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.66, 0, 0.72, 0); panel.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
panel.Visible = false; panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)
local pstroke = Instance.new("UIStroke", panel); pstroke.Color = Color3.fromRGB(70, 200, 110); pstroke.Thickness = 2

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 46); title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack; title.TextSize = 24; title.TextColor3 = Color3.fromRGB(255, 221, 51)
title.Text = "🦆 DUCK SHOP"; title.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0); closeBtn.Position = UDim2.new(1, -10, 0, 8)
closeBtn.Size = UDim2.new(0, 36, 0, 36); closeBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 20; closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "✕"; closeBtn.Parent = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.new(0, 12, 0, 52); scroll.Size = UDim2.new(1, -24, 1, -64)
scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 5
scroll.CanvasSize = UDim2.new(0, 0, 0, 0); scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel
local list = Instance.new("UIListLayout", scroll); list.Padding = UDim.new(0, 10)
list.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function row(name, blurb, robux, enabled, onBuy)
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, -6, 0, 76); card.BackgroundColor3 = Color3.fromRGB(30, 33, 44); card.Parent = scroll
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)

	local n = Instance.new("TextLabel")
	n.Position = UDim2.new(0, 12, 0, 8); n.Size = UDim2.new(0.62, 0, 0, 24)
	n.BackgroundTransparency = 1; n.Font = Enum.Font.GothamBold; n.TextSize = 17
	n.TextXAlignment = Enum.TextXAlignment.Left; n.TextColor3 = Color3.new(1, 1, 1); n.Text = name; n.Parent = card

	local b = Instance.new("TextLabel")
	b.Position = UDim2.new(0, 12, 0, 36); b.Size = UDim2.new(0.62, 0, 0, 32)
	b.BackgroundTransparency = 1; b.Font = Enum.Font.Gotham; b.TextSize = 13; b.TextWrapped = true
	b.TextXAlignment = Enum.TextXAlignment.Left; b.TextYAlignment = Enum.TextYAlignment.Top
	b.TextColor3 = Color3.fromRGB(190, 195, 205); b.Text = blurb; b.Parent = card

	local buy = Instance.new("TextButton")
	buy.AnchorPoint = Vector2.new(1, 0.5); buy.Position = UDim2.new(1, -12, 0.5, 0)
	buy.Size = UDim2.new(0, 96, 0, 44); buy.Font = Enum.Font.GothamBold; buy.TextSize = 15
	buy.TextColor3 = Color3.new(1, 1, 1); buy.Parent = card
	Instance.new("UICorner", buy).CornerRadius = UDim.new(0, 10)
	if enabled then
		buy.BackgroundColor3 = Color3.fromRGB(70, 200, 110); buy.Text = "R$ " .. tostring(robux)
		buy.Activated:Connect(onBuy)
	else
		buy.BackgroundColor3 = Color3.fromRGB(70, 74, 86); buy.Text = "Soon"; buy.AutoButtonColor = false
	end
end

local function section(text)
	local h = Instance.new("TextLabel")
	h.Size = UDim2.new(1, -6, 0, 26); h.BackgroundTransparency = 1; h.Font = Enum.Font.GothamBlack
	h.TextSize = 15; h.TextColor3 = Color3.fromRGB(120, 210, 255); h.TextXAlignment = Enum.TextXAlignment.Left
	h.Text = text; h.Parent = scroll
end

section("💩 Currency & Boosts")
for _, p in ipairs(ShopConfig.DeveloperProducts) do
	local live = p.id ~= 0
	row(p.name, p.blurb, p.robux, live, function()
		MarketplaceService:PromptProductPurchase(player, p.id)
	end)
end

section("⭐ Permanent Perks")
for _, g in ipairs(ShopConfig.GamePasses) do
	local live = g.id ~= 0
	row(g.name, g.blurb, g.robux, live, function()
		MarketplaceService:PromptGamePassPurchase(player, g.id)
	end)
end

section("🦆 Membership")
do
	local sub = ShopConfig.Subscription
	local live = sub.id ~= "EXP-REPLACE"
	row(sub.name, sub.blurb, "Sub", live, function()
		MarketplaceService:PromptSubscriptionPurchase(player, sub.id)
	end)
end

openBtn.Activated:Connect(function() panel.Visible = true end)
closeBtn.Activated:Connect(function() panel.Visible = false end)
