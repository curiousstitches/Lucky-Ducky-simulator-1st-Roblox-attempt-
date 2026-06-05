-- src/client/CurrencyHud.client.lua  | mobile balance pills, top-center; biome pills appear when earned
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local player     = Players.LocalPlayer
local Shared     = ReplicatedStorage:WaitForChild("Shared")
local Currencies = require(Shared:WaitForChild("Currencies"))
local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local BalanceChanged = Remotes:WaitForChild("BalanceChanged")
local RequestBalance = Remotes:WaitForChild("RequestBalance")

local gui = Instance.new("ScreenGui")
gui.Name = "CurrencyHud"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 0); bar.Position = UDim2.new(0.5, 0, 0, 10)
bar.Size = UDim2.new(0, 0, 0, 36); bar.AutomaticSize = Enum.AutomaticSize.X
bar.BackgroundTransparency = 1; bar.Parent = gui
local layout = Instance.new("UIListLayout", bar)
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 6); layout.SortOrder = Enum.SortOrder.LayoutOrder

local pills = {}
local function makePill(cur, order)
	local pill = Instance.new("Frame"); pill.Size = UDim2.new(0, 0, 0, 36)
	pill.AutomaticSize = Enum.AutomaticSize.X; pill.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
	pill.BackgroundTransparency = 0.1; pill.LayoutOrder = order; pill.Parent = bar
	Instance.new("UICorner", pill).CornerRadius = UDim.new(0, 18)
	local stroke = Instance.new("UIStroke", pill); stroke.Color = cur.color; stroke.Thickness = 3
	local padg = Instance.new("UIPadding", pill)
	padg.PaddingLeft = UDim.new(0, 12); padg.PaddingRight = UDim.new(0, 12)
	local lbl = Instance.new("TextLabel"); lbl.AutomaticSize = Enum.AutomaticSize.X
	lbl.Size = UDim2.new(0, 0, 1, 0); lbl.BackgroundTransparency = 1; lbl.Font = Enum.Font.FredokaOne
	lbl.TextSize = 16; lbl.TextColor3 = Color3.fromRGB(245, 245, 245)
	lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = (cur.icon and (cur.icon .. " ") or "") .. cur.name .. ": 0"; lbl.Parent = pill
	return { frame = pill, label = lbl, cfg = cur }
end

-- soft + premium always shown
local order = 0
for _, cur in ipairs(Currencies.List) do
	if cur.kind == "soft" or cur.kind == "premium" then
		order += 1; pills[cur.id] = makePill(cur, order)
	end
end

local BigNum = require(Shared:WaitForChild("BigNum"))
local function fmt(n) return BigNum.format(n) end

BalanceChanged.OnClientEvent:Connect(function(wallet)
	-- biome + local pills appear once you've earned any of that currency
	for _, cur in ipairs(Currencies.List) do
		local amt = wallet[cur.id]
		if (cur.kind == "biome" or cur.kind == "local") and not pills[cur.id] and amt and amt > 0 then
			order += 1; pills[cur.id] = makePill(cur, order)
		end
	end
	for id, entry in pairs(pills) do
		entry.label.Text = (entry.cfg.icon and (entry.cfg.icon .. " ") or "") .. entry.cfg.name .. ": " .. fmt(wallet[id] or 0)
	end
end)

RequestBalance:FireServer()
