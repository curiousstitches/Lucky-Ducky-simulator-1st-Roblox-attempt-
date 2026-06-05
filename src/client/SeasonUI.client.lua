-- src/client/SeasonUI.client.lua  | season pass tiers (free/premium) + a live event banner w/ countdown
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local player  = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GetSeason   = Remotes:WaitForChild("GetSeason")
local ClaimSeason = Remotes:WaitForChild("ClaimSeason")
local GetEvent    = Remotes:WaitForChild("GetEvent")

local gui = Instance.new("ScreenGui")
gui.Name = "SeasonUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- ===== live event banner (top, under currency bar) =====
local banner = Instance.new("TextButton")
banner.AnchorPoint = Vector2.new(0.5, 0); banner.Position = UDim2.new(0.5, 0, 0, 52)
banner.Size = UDim2.new(0.86, 0, 0, 34); banner.BackgroundColor3 = Color3.fromRGB(40, 30, 60)
banner.Font = Enum.Font.GothamBold; banner.TextSize = 14; banner.TextColor3 = Color3.fromRGB(255, 220, 130)
banner.Text = "..."; banner.AutoButtonColor = false; banner.Parent = gui
Instance.new("UICorner", banner).CornerRadius = UDim.new(0, 12)
Instance.new("UIStroke", banner).Color = Color3.fromRGB(255, 200, 120)

local eventEndsAt = 0
local eventName = ""
local function fmtCountdown(secs)
	secs = math.max(0, math.floor(secs))
	local d = math.floor(secs / 86400); local h = math.floor((secs % 86400) / 3600); local m = math.floor((secs % 3600) / 60)
	if d > 0 then return ("%dd %dh"):format(d, h) end
	if h > 0 then return ("%dh %dm"):format(h, m) end
	return ("%dm"):format(m)
end

task.spawn(function()
	while true do
		local ok, ev = pcall(function() return GetEvent:InvokeServer() end)
		if ok and ev then eventName = (ev.name or "") .. " — " .. (ev.blurb or ""); eventEndsAt = ev.endsAt or 0 end
		task.wait(60)
	end
end)
task.spawn(function()
	while true do
		if eventEndsAt > 0 then
			banner.Text = ("%s  (ends in %s)"):format(eventName, fmtCountdown(eventEndsAt - os.time()))
		end
		task.wait(1)
	end
end)

-- ===== season pass panel =====
local openBtn = Instance.new("TextButton")
openBtn.AnchorPoint = Vector2.new(0, 1); openBtn.Position = UDim2.new(0, 228, 1, -16)
openBtn.Size = UDim2.new(0, 110, 0, 48); openBtn.BackgroundColor3 = Color3.fromRGB(150, 110, 230)
openBtn.Font = Enum.Font.GothamBlack; openBtn.TextSize = 15; openBtn.TextColor3 = Color3.new(1, 1, 1)
openBtn.Text = "🎟️ Season"; openBtn.Parent = gui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 14)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.66, 0, 0.72, 0); panel.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
panel.Visible = false; panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)
Instance.new("UIStroke", panel).Color = Color3.fromRGB(150, 110, 230)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 0, 40); title.Position = UDim2.new(0, 12, 0, 8)
title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBlack; title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left; title.TextColor3 = Color3.fromRGB(190, 160, 255)
title.Text = "🎟️ SEASON PASS"; title.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0); closeBtn.Position = UDim2.new(1, -10, 0, 8)
closeBtn.Size = UDim2.new(0, 36, 0, 36); closeBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 20; closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "✕"; closeBtn.Parent = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

local head = Instance.new("TextLabel")
head.Position = UDim2.new(0, 12, 0, 48); head.Size = UDim2.new(1, -24, 0, 26)
head.BackgroundTransparency = 1; head.Font = Enum.Font.GothamBold; head.TextSize = 14
head.TextXAlignment = Enum.TextXAlignment.Left; head.TextColor3 = Color3.fromRGB(220, 220, 220)
head.Text = "..."; head.Parent = panel

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.new(0, 12, 0, 78); scroll.Size = UDim2.new(1, -24, 1, -90)
scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 5
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = panel
local list = Instance.new("UIListLayout", scroll); list.Padding = UDim.new(0, 8)
list.HorizontalAlignment = Enum.HorizontalAlignment.Center

local function rewardBtn(parent, text, color, enabled, cb)
	local b = Instance.new("TextButton"); b.Size = UDim2.new(0.46, 0, 0, 38)
	b.Font = Enum.Font.GothamBold; b.TextSize = 12; b.TextColor3 = Color3.new(1, 1, 1)
	b.TextWrapped = true; b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	if enabled then b.BackgroundColor3 = color; b.Activated:Connect(cb)
	else b.BackgroundColor3 = Color3.fromRGB(60, 64, 76); b.AutoButtonColor = false end
	b.Text = text
	return b
end

local function refresh()
	for _, c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local s = GetSeason:InvokeServer() or {}
	head.Text = ("Season %s  •  Tier %d  •  %d/%d XP%s"):format(
		tostring(s.season or 0), s.tier or 0, (s.xp or 0) % (s.xpPerTier or 1), s.xpPerTier or 0,
		s.premium and "  •  ⭐PREMIUM" or "")
	for _, row in ipairs(s.rows or {}) do
		local card = Instance.new("Frame"); card.Size = UDim2.new(1, -6, 0, 72)
		card.BackgroundColor3 = row.unlocked and Color3.fromRGB(34, 38, 50) or Color3.fromRGB(26, 28, 36)
		card.Parent = scroll
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
		local tl = Instance.new("TextLabel"); tl.Position = UDim2.new(0, 10, 0, 6); tl.Size = UDim2.new(1, -20, 0, 18)
		tl.BackgroundTransparency = 1; tl.Font = Enum.Font.GothamBold; tl.TextSize = 13
		tl.TextXAlignment = Enum.TextXAlignment.Left
		tl.TextColor3 = row.unlocked and Color3.fromRGB(150, 230, 160) or Color3.fromRGB(150, 150, 160)
		tl.Text = ("Tier %d %s"):format(row.tier, row.unlocked and "✓" or "🔒"); tl.Parent = card
		local holder = Instance.new("Frame"); holder.Position = UDim2.new(0, 10, 0, 28)
		holder.Size = UDim2.new(1, -20, 0, 38); holder.BackgroundTransparency = 1; holder.Parent = card
		local hl = Instance.new("UIListLayout", holder); hl.FillDirection = Enum.FillDirection.Horizontal
		hl.Padding = UDim.new(0, 8)
		rewardBtn(holder, (row.freeClaimed and "✓ " or "") .. "Free: " .. row.free,
			Color3.fromRGB(70, 200, 110), row.unlocked and not row.freeClaimed, function()
				ClaimSeason:InvokeServer(row.tier, "free"); refresh()
			end)
		rewardBtn(holder, (row.premiumClaimed and "✓ " or "") .. "⭐ " .. row.premium,
			Color3.fromRGB(150, 110, 230), row.unlocked and s.premium and not row.premiumClaimed, function()
				ClaimSeason:InvokeServer(row.tier, "premium"); refresh()
			end)
	end
end

openBtn.Activated:Connect(function() panel.Visible = true; refresh() end)
closeBtn.Activated:Connect(function() panel.Visible = false end)
banner.Activated:Connect(function() panel.Visible = true; refresh() end)
