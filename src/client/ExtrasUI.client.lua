-- src/client/ExtrasUI.client.lua  | Level & Enchant ducks, Achievements/Titles, Cosmetics, Settings
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local player     = Players.LocalPlayer
local Shared     = ReplicatedStorage:WaitForChild("Shared")
local DuckSchema = require(Shared:WaitForChild("DuckSchema"))
local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local InventoryChanged = Remotes:WaitForChild("InventoryChanged")
local EquipDuck  = Remotes:WaitForChild("EquipDuck")
local LevelDuck  = Remotes:WaitForChild("LevelDuck")
local EnchantDuck= Remotes:WaitForChild("EnchantDuck")
local GetAchievements = Remotes:WaitForChild("GetAchievements")
local SetTitle   = Remotes:WaitForChild("SetTitle")
local GetCosmetics = Remotes:WaitForChild("GetCosmetics")
local BuyCosmetic  = Remotes:WaitForChild("BuyCosmetic")
local EquipCosmetic= Remotes:WaitForChild("EquipCosmetic")
local GetSettings  = Remotes:WaitForChild("GetSettings")
local SetSetting   = Remotes:WaitForChild("SetSetting")

local myDucks = {}
InventoryChanged.OnClientEvent:Connect(function(d) myDucks = d.ducks or {} end)

local gui = Instance.new("ScreenGui")
gui.Name = "ExtrasUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local openBtn = Instance.new("TextButton")
openBtn.AnchorPoint = Vector2.new(0, 1); openBtn.Position = UDim2.new(0, 16, 1, -76)
openBtn.Size = UDim2.new(0, 110, 0, 48); openBtn.BackgroundColor3 = Color3.fromRGB(180, 140, 255)
openBtn.Font = Enum.Font.GothamBlack; openBtn.TextSize = 15; openBtn.TextColor3 = Color3.new(1, 1, 1)
openBtn.Text = "⭐ Extras"; openBtn.Parent = gui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 14)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.66, 0, 0.72, 0); panel.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
panel.Visible = false; panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)
Instance.new("UIStroke", panel).Color = Color3.fromRGB(180, 140, 255)

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
body.Position = UDim2.new(0, 12, 0, 52); body.Size = UDim2.new(1, -24, 1, -62); body.BackgroundTransparency = 1; body.Parent = panel

local pages, refreshers = {}, {}
local function page(n)
	local pg = Instance.new("ScrollingFrame"); pg.Size = UDim2.fromScale(1, 1); pg.BackgroundTransparency = 1
	pg.BorderSizePixel = 0; pg.ScrollBarThickness = 5; pg.AutomaticCanvasSize = Enum.AutomaticSize.Y
	pg.CanvasSize = UDim2.new(0, 0, 0, 0); pg.Visible = false; pg.Parent = body
	local l = Instance.new("UIListLayout", pg); l.Padding = UDim.new(0, 8); l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	pages[n] = pg; return pg
end
local function show(n) for k, pg in pairs(pages) do pg.Visible = (k == n) end if refreshers[n] then refreshers[n]() end end
local function tab(n, lbl)
	local b = Instance.new("TextButton"); b.Size = UDim2.new(0, 78, 1, 0); b.BackgroundColor3 = Color3.fromRGB(35, 38, 48)
	b.Font = Enum.Font.GothamBold; b.TextSize = 12; b.TextColor3 = Color3.new(1, 1, 1); b.Text = lbl; b.Parent = tabbar
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10); b.Activated:Connect(function() show(n) end)
end
local function card(parent, h) local c = Instance.new("Frame"); c.Size = UDim2.new(1, -6, 0, h or 64)
	c.BackgroundColor3 = Color3.fromRGB(30, 33, 44); c.Parent = parent; Instance.new("UICorner", c).CornerRadius = UDim.new(0, 12); return c end
local function lbl(parent, txt, x, y, w, h, color, sz, align)
	local t = Instance.new("TextLabel"); t.Position = UDim2.new(0, x, 0, y); t.Size = UDim2.new(w, 0, 0, h)
	t.BackgroundTransparency = 1; t.Font = Enum.Font.GothamBold; t.TextSize = sz or 14; t.TextWrapped = true
	t.TextXAlignment = align or Enum.TextXAlignment.Left; t.TextColor3 = color or Color3.new(1, 1, 1); t.Text = txt; t.Parent = parent; return t end
local function btn(parent, txt, color, x, w, cb)
	local b = Instance.new("TextButton"); b.AnchorPoint = Vector2.new(1, 0.5); b.Position = UDim2.new(1, x, 0.5, 0)
	b.Size = UDim2.new(0, w, 0, 40); b.BackgroundColor3 = color; b.Font = Enum.Font.GothamBold; b.TextSize = 12
	b.TextColor3 = Color3.new(1, 1, 1); b.Text = txt; b.Parent = parent; Instance.new("UICorner", b).CornerRadius = UDim.new(0, 9)
	b.Activated:Connect(cb); return b end

-- ===== LEVEL & ENCHANT (equipped ducks) =====
local lvlPage = page("level")
refreshers.level = function()
	for _, c in ipairs(lvlPage:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	EquipDuck:FireServer("refresh"); task.wait(0.1)
	local equippedSet = {} -- show equipped first
	for _, duck in ipairs(myDucks) do
		local rar = DuckSchema.getRarity(duck.rarity); local rc = rar and rar.color or Color3.new(1,1,1)
		local c = card(lvlPage, 84)
		lbl(c, ("%s%s  Lv%d"):format(duck.shiny and "✨ " or "", duck.rarity, duck.level or 0), 12, 8, 0.6, 20, rc, 14)
		lbl(c, ("Pow %d • enchants %d/3"):format(duck.strength or 0, #(duck.enchants or {})), 12, 30, 0.6, 18, Color3.fromRGB(190,195,205), 12)
		btn(c, "Level Up", Color3.fromRGB(70,200,110), -10, 86, function() LevelDuck:InvokeServer(duck.id); task.wait(0.15); refreshers.level() end)
		-- enchant row
		local er = Instance.new("Frame"); er.Position = UDim2.new(0, 12, 1, -32); er.Size = UDim2.new(1, -110, 0, 26)
		er.BackgroundTransparency = 1; er.Parent = c
		local el = Instance.new("UIListLayout", er); el.FillDirection = Enum.FillDirection.Horizontal; el.Padding = UDim.new(0, 5)
		for _, et in ipairs({ "power", "luck", "earn" }) do
			local eb = Instance.new("TextButton"); eb.Size = UDim2.new(0, 70, 1, 0); eb.BackgroundColor3 = Color3.fromRGB(120, 90, 200)
			eb.Font = Enum.Font.GothamBold; eb.TextSize = 11; eb.TextColor3 = Color3.new(1,1,1); eb.Text = "+" .. et; eb.Parent = er
			Instance.new("UICorner", eb).CornerRadius = UDim.new(0, 7)
			eb.Activated:Connect(function() EnchantDuck:InvokeServer(duck.id, et); task.wait(0.15); refreshers.level() end)
		end
	end
	if #myDucks == 0 then lbl(lvlPage, "Hatch some ducks first!", 0, 0, 1, 30, Color3.fromRGB(200,200,200), 15, Enum.TextXAlignment.Center) end
end

-- ===== ACHIEVEMENTS + TITLES =====
local achPage = page("ach")
refreshers.ach = function()
	for _, c in ipairs(achPage:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local s = GetAchievements:InvokeServer() or {}
	-- title picker
	local tcard = card(achPage, 50)
	lbl(tcard, "Active title: " .. (s.active or "none"), 12, 6, 0.95, 18, Color3.fromRGB(255,215,60), 13)
	local trow = Instance.new("Frame"); trow.Position = UDim2.new(0, 12, 0, 26); trow.Size = UDim2.new(1, -20, 0, 20); trow.BackgroundTransparency = 1; trow.Parent = tcard
	-- (titles equip from the list below)
	for _, row in ipairs(s.rows or {}) do
		local c = card(achPage, 56)
		lbl(c, (row.done and "🏆 " or "▫️ ") .. row.name, 12, 8, 0.6, 18, row.done and Color3.fromRGB(150,230,160) or Color3.fromRGB(200,200,210), 14)
		lbl(c, ("%d/%d • title: %s"):format(row.progress, row.target, row.title), 12, 30, 0.6, 18, Color3.fromRGB(180,185,195), 11)
		if row.done then
			btn(c, "Wear Title", Color3.fromRGB(180,140,255), -10, 92, function() SetTitle:InvokeServer(row.title); task.wait(0.1); refreshers.ach() end)
		end
	end
end

-- ===== COSMETICS =====
local cosPage = page("cos")
refreshers.cos = function()
	for _, c in ipairs(cosPage:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local s = GetCosmetics:InvokeServer() or {}
	for _, item in ipairs(s.items or {}) do
		local owned = (s.owned or {})[item.id]
		local equipped = (item.kind == "trail" and s.trail == item.id) or (item.kind == "aura" and s.aura == item.id)
		local c = card(cosPage, 56)
		lbl(c, ((item.kind == "trail") and "🌈 " or "🔆 ") .. item.name, 12, 8, 0.55, 18, Color3.fromRGB(220,200,255), 14)
		lbl(c, owned and (equipped and "Equipped ✓" or "Owned") or (item.cost .. " Splats"), 12, 30, 0.55, 18, Color3.fromRGB(180,185,195), 12)
		if not owned then
			btn(c, "Buy", Color3.fromRGB(120,180,255), -10, 80, function() BuyCosmetic:InvokeServer(item.id); task.wait(0.15); refreshers.cos() end)
		else
			btn(c, equipped and "Unequip" or "Equip", equipped and Color3.fromRGB(200,90,90) or Color3.fromRGB(70,200,110), -10, 86, function()
				EquipCosmetic:FireServer(equipped and nil or item.id); task.wait(0.15); refreshers.cos() end)
		end
	end
end

-- ===== SETTINGS =====
local setPage = page("set")
refreshers.set = function()
	for _, c in ipairs(setPage:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local s = GetSettings:InvokeServer() or { autoCollect = true, music = true }
	for _, key in ipairs({ "autoCollect", "music" }) do
		local c = card(setPage, 50)
		lbl(c, (key == "autoCollect") and "Auto-Collect nearby" or "Music & Ambiance", 12, 14, 0.6, 22, Color3.new(1,1,1), 15)
		local on = s[key]
		btn(c, on and "ON" or "OFF", on and Color3.fromRGB(70,200,110) or Color3.fromRGB(120,124,136), -10, 70, function()
			SetSetting:FireServer(key, not on); task.wait(0.1); refreshers.set() end)
	end
end

tab("level", "🦆 Level"); tab("ach", "🏆 Goals"); tab("cos", "🌈 Style"); tab("set", "⚙️ Settings")
openBtn.Activated:Connect(function() panel.Visible = true; show("level") end)
closeBtn.Activated:Connect(function() panel.Visible = false end)
