-- src/client/LobbyUI.client.lua  | tabbed: Eggs(Jeeps) / Abilities / Potions / Gifts / Shop(Robux)
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local player     = Players.LocalPlayer
local Shared     = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig = require(Shared:WaitForChild("ShopConfig"))
local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local GetEggs    = Remotes:WaitForChild("GetEggs")
local UnlockEgg  = Remotes:WaitForChild("UnlockEgg")
local OpenEgg    = Remotes:WaitForChild("OpenEgg")
local GetUnlocks = Remotes:WaitForChild("GetUnlocks")
local BuyAbility = Remotes:WaitForChild("BuyAbility")
local BuyPotion  = Remotes:WaitForChild("BuyPotion")
local GetGifts   = Remotes:WaitForChild("GetGifts")
local OpenGift   = Remotes:WaitForChild("OpenGift")
local SellGift   = Remotes:WaitForChild("SellGift")

local gui = Instance.new("ScreenGui")
gui.Name = "LobbyUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local openBtn = Instance.new("TextButton")
openBtn.AnchorPoint = Vector2.new(1, 1); openBtn.Position = UDim2.new(1, -16, 1, -196)
openBtn.Size = UDim2.new(0, 110, 0, 48); openBtn.BackgroundColor3 = Color3.fromRGB(255, 170, 60)
openBtn.Font = Enum.Font.GothamBlack; openBtn.TextSize = 15; openBtn.TextColor3 = Color3.new(1, 1, 1)
openBtn.Text = "🥚 Lobby"; openBtn.Parent = gui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 14)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.66, 0, 0.72, 0); panel.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
panel.Visible = false; panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)
Instance.new("UIStroke", panel).Color = Color3.fromRGB(255, 170, 60)

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0); closeBtn.Position = UDim2.new(1, -10, 0, 8)
closeBtn.Size = UDim2.new(0, 36, 0, 36); closeBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 20; closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "✕"; closeBtn.Parent = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

local tabbar = Instance.new("Frame")
tabbar.Position = UDim2.new(0, 12, 0, 8); tabbar.Size = UDim2.new(1, -56, 0, 38)
tabbar.BackgroundTransparency = 1; tabbar.Parent = panel
local tl = Instance.new("UIListLayout", tabbar); tl.FillDirection = Enum.FillDirection.Horizontal; tl.Padding = UDim.new(0, 5)

local body = Instance.new("Frame")
body.Position = UDim2.new(0, 12, 0, 52); body.Size = UDim2.new(1, -24, 1, -62)
body.BackgroundTransparency = 1; body.Parent = panel

local pages, refreshers = {}, {}
local function page(name)
	local pg = Instance.new("ScrollingFrame"); pg.Size = UDim2.fromScale(1, 1)
	pg.BackgroundTransparency = 1; pg.BorderSizePixel = 0; pg.ScrollBarThickness = 5
	pg.AutomaticCanvasSize = Enum.AutomaticSize.Y; pg.CanvasSize = UDim2.new(0, 0, 0, 0)
	pg.Visible = false; pg.Parent = body
	local l = Instance.new("UIListLayout", pg); l.Padding = UDim.new(0, 8); l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	pages[name] = pg; return pg
end
local function show(name)
	for n, pg in pairs(pages) do pg.Visible = (n == name) end
	if refreshers[name] then refreshers[name]() end
end
local function tab(name, label)
	local b = Instance.new("TextButton"); b.Size = UDim2.new(0, 70, 1, 0)
	b.BackgroundColor3 = Color3.fromRGB(35, 38, 48); b.Font = Enum.Font.GothamBold; b.TextSize = 12
	b.TextColor3 = Color3.new(1, 1, 1); b.Text = label; b.Parent = tabbar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	b.Activated:Connect(function() show(name) end)
end

local function rowCard(parent, title, sub, btnText, btnColor, enabled, cb)
	local card = Instance.new("Frame"); card.Size = UDim2.new(1, -6, 0, 64)
	card.BackgroundColor3 = Color3.fromRGB(30, 33, 44); card.Parent = parent
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
	local n = Instance.new("TextLabel"); n.Position = UDim2.new(0, 12, 0, 8); n.Size = UDim2.new(0.58, 0, 0, 22)
	n.BackgroundTransparency = 1; n.Font = Enum.Font.GothamBold; n.TextSize = 15; n.TextXAlignment = Enum.TextXAlignment.Left
	n.TextColor3 = Color3.new(1, 1, 1); n.Text = title; n.Parent = card
	local s = Instance.new("TextLabel"); s.Position = UDim2.new(0, 12, 0, 32); s.Size = UDim2.new(0.58, 0, 0, 24)
	s.BackgroundTransparency = 1; s.Font = Enum.Font.Gotham; s.TextSize = 12; s.TextWrapped = true
	s.TextXAlignment = Enum.TextXAlignment.Left; s.TextYAlignment = Enum.TextYAlignment.Top
	s.TextColor3 = Color3.fromRGB(190, 195, 205); s.Text = sub; s.Parent = card
	local b = Instance.new("TextButton"); b.AnchorPoint = Vector2.new(1, 0.5); b.Position = UDim2.new(1, -10, 0.5, 0)
	b.Size = UDim2.new(0, 100, 0, 42); b.Font = Enum.Font.GothamBold; b.TextSize = 13; b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = btnText; b.Parent = card
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	if enabled then b.BackgroundColor3 = btnColor; b.Activated:Connect(cb)
	else b.BackgroundColor3 = Color3.fromRGB(64, 68, 80); b.AutoButtonColor = false end
	return card
end

-- ===== EGGS =====
local eggsPage = page("eggs")
local batchChoice = 1
refreshers.eggs = function()
	for _, c in ipairs(eggsPage:GetChildren()) do if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end end
	local data = GetEggs:InvokeServer() or { eggs = {}, maxBatch = 3 }
	-- batch selector
	local sel = Instance.new("Frame"); sel.Size = UDim2.new(1, -6, 0, 40); sel.BackgroundTransparency = 1; sel.Parent = eggsPage
	local sl = Instance.new("UIListLayout", sel); sl.FillDirection = Enum.FillDirection.Horizontal; sl.Padding = UDim.new(0, 6)
	sl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	for _, n in ipairs({ 1, 3, 5, 10 }) do
		local b = Instance.new("TextButton"); b.Size = UDim2.new(0, 56, 1, 0); b.Font = Enum.Font.GothamBold
		b.TextSize = 14; b.TextColor3 = Color3.new(1, 1, 1); b.Text = "x" .. n
		local allowed = n <= (data.maxBatch or 3)
		b.BackgroundColor3 = (batchChoice == n) and Color3.fromRGB(255, 170, 60) or (allowed and Color3.fromRGB(45, 48, 60) or Color3.fromRGB(60, 40, 40))
		b.Parent = sel; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		b.Activated:Connect(function()
			if allowed then batchChoice = n; refreshers.eggs() else
				b.Text = "🔒"; task.wait(0.6); refreshers.eggs() end
		end)
	end
	for _, e in ipairs(data.eggs) do
		local sub = e.robux and "Robux Jeep" or (e.owned and ("Open x" .. batchChoice) or ("Unlock: " .. e.cost .. " " .. e.currency))
		if e.vip then sub = "👑 " .. sub end
		local btn = e.owned and ("Open x" .. batchChoice) or (e.robux and "Get (shop)" or "Unlock")
		rowCard(eggsPage, "🚙 " .. e.name, sub, btn, e.owned and Color3.fromRGB(70, 200, 110) or Color3.fromRGB(120, 180, 255),
			not e.robux, function()
				if e.owned then OpenEgg:FireServer(e.id, batchChoice)
				else UnlockEgg:InvokeServer(e.id); task.wait(0.15); refreshers.eggs() end
			end)
	end
end

-- ===== ABILITIES =====
local abPage = page("abilities")
refreshers.abilities = function()
	for _, c in ipairs(abPage:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local data = GetUnlocks:InvokeServer() or {}
	for _, a in ipairs(data.abilities or {}) do
		local own = data.owned and data.owned[a.id]
		local sub = own and "Owned ✓" or (a.currency == "Robux" and "Robux" or (a.cost .. " " .. a.currency))
		rowCard(abPage, "✨ " .. a.name, sub, own and "Owned" or "Buy",
			Color3.fromRGB(120, 180, 255), not own and a.currency ~= "Robux", function()
				BuyAbility:InvokeServer(a.id); task.wait(0.15); refreshers.abilities()
			end)
	end
end

-- ===== POTIONS =====
local potPage = page("potions")
refreshers.potions = function()
	for _, c in ipairs(potPage:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local data = GetUnlocks:InvokeServer() or {}
	for _, pot in ipairs(data.potions or {}) do
		local sub = ("%s x%.1f, %ds (stacks)"):format(pot.effect, pot.power, pot.seconds)
		rowCard(potPage, "🧪 " .. pot.name, sub, pot.currency == "Robux" and "Robux" or "Buy",
			Color3.fromRGB(150, 230, 160), pot.currency ~= "Robux", function()
				BuyPotion:InvokeServer(pot.id); task.wait(0.15); refreshers.potions()
			end)
	end
end

-- ===== GIFTS =====
local giftPage = page("gifts")
refreshers.gifts = function()
	for _, c in ipairs(giftPage:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local data = GetGifts:InvokeServer() or { gifts = {}, tiers = {} }
	for _, tier in ipairs(data.tiers) do
		local n = (data.gifts and data.gifts[tier.id]) or 0
		local card = rowCard(giftPage, "🎁 " .. tier.name, ("You have: %d  •  sell: %s"):format(n, tier.sell > 0 and tostring(tier.sell) or "—"),
			"Open", Color3.fromRGB(255, 200, 90), n > 0, function()
				OpenGift:InvokeServer(tier.id); task.wait(0.15); refreshers.gifts()
			end)
		if tier.sell > 0 and n > 0 then
			local sb = Instance.new("TextButton"); sb.AnchorPoint = Vector2.new(1, 0.5)
			sb.Position = UDim2.new(1, -116, 0.5, 0); sb.Size = UDim2.new(0, 72, 0, 42)
			sb.BackgroundColor3 = Color3.fromRGB(120, 160, 90); sb.Font = Enum.Font.GothamBold
			sb.TextSize = 12; sb.TextColor3 = Color3.new(1, 1, 1); sb.Text = "Sell"; sb.Parent = card
			Instance.new("UICorner", sb).CornerRadius = UDim.new(0, 10)
			sb.Activated:Connect(function() SellGift:InvokeServer(tier.id); task.wait(0.15); refreshers.gifts() end)
		end
	end
end

-- ===== SHOP (Robux: products, extra products, passes, subscription) =====
local shopPage = page("shop")
refreshers.shop = function()
	for _, c in ipairs(shopPage:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for _, p in ipairs(ShopConfig.DeveloperProducts) do
		rowCard(shopPage, "💩 " .. p.name, p.blurb, p.id ~= 0 and ("R$ " .. p.robux) or "Soon",
			Color3.fromRGB(70, 200, 110), p.id ~= 0, function() MarketplaceService:PromptProductPurchase(player, p.id) end)
	end
	for _, p in ipairs(ShopConfig.ExtraProducts or {}) do
		rowCard(shopPage, "⭐ " .. p.name, p.blurb, p.id ~= 0 and ("R$ " .. p.robux) or "Soon",
			Color3.fromRGB(120, 180, 255), p.id ~= 0, function() MarketplaceService:PromptProductPurchase(player, p.id) end)
	end
	for _, g in ipairs(ShopConfig.GamePasses) do
		rowCard(shopPage, "🎫 " .. g.name, g.blurb, g.id ~= 0 and ("R$ " .. g.robux) or "Soon",
			Color3.fromRGB(255, 180, 80), g.id ~= 0, function() MarketplaceService:PromptGamePassPurchase(player, g.id) end)
	end
	local sub = ShopConfig.Subscription
	rowCard(shopPage, "🦆 " .. sub.name, sub.blurb, sub.id ~= "EXP-REPLACE" and "Subscribe" or "Soon",
		Color3.fromRGB(150, 110, 230), sub.id ~= "EXP-REPLACE", function() MarketplaceService:PromptSubscriptionPurchase(player, sub.id) end)
end

tab("eggs", "🥚 Eggs"); tab("abilities", "✨ Powers"); tab("potions", "🧪 Potions"); tab("gifts", "🎁 Gifts"); tab("shop", "🛒 Shop")

openBtn.Activated:Connect(function() panel.Visible = true; show("eggs") end)
closeBtn.Activated:Connect(function() panel.Visible = false end)
