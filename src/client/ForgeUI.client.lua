-- src/client/ForgeUI.client.lua  | select up to 100 ducks, see projected tier, pick edits, forge
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local player     = Players.LocalPlayer
local Shared     = ReplicatedStorage:WaitForChild("Shared")
local DuckSchema = require(Shared:WaitForChild("DuckSchema"))
local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local InventoryChanged = Remotes:WaitForChild("InventoryChanged")
local ForgeDucks       = Remotes:WaitForChild("ForgeDucks")

local MAX = 100
local selected = {}   -- [duckId] = true
local latestDucks = {}
local editChoices = {} -- [Dim] = optionName

local gui = Instance.new("ScreenGui")
gui.Name = "ForgeUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local openBtn = Instance.new("TextButton")
openBtn.AnchorPoint = Vector2.new(1, 1); openBtn.Position = UDim2.new(1, -16, 1, -136)
openBtn.Size = UDim2.new(0, 96, 0, 48); openBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 60)
openBtn.Font = Enum.Font.GothamBlack; openBtn.TextSize = 16; openBtn.TextColor3 = Color3.new(1, 1, 1)
openBtn.Text = "🔥 Forge"; openBtn.Parent = gui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 14)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.66, 0, 0.72, 0); panel.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
panel.Visible = false; panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)
Instance.new("UIStroke", panel).Color = Color3.fromRGB(255, 140, 60)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 0, 40); title.Position = UDim2.new(0, 12, 0, 8)
title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBlack; title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left; title.TextColor3 = Color3.fromRGB(255, 160, 80)
title.Text = "🔥 DUCK FORGE"; title.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0); closeBtn.Position = UDim2.new(1, -10, 0, 8)
closeBtn.Size = UDim2.new(0, 36, 0, 36); closeBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 20; closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "✕"; closeBtn.Parent = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

-- projected tier readout
local readout = Instance.new("TextLabel")
readout.Position = UDim2.new(0, 12, 0, 50); readout.Size = UDim2.new(1, -24, 0, 52)
readout.BackgroundTransparency = 1; readout.Font = Enum.Font.GothamMedium; readout.TextSize = 14
readout.TextWrapped = true; readout.TextYAlignment = Enum.TextYAlignment.Top
readout.TextXAlignment = Enum.TextXAlignment.Left; readout.TextColor3 = Color3.fromRGB(220, 220, 220)
readout.Text = "Select ducks to fuse."; readout.Parent = panel

-- duck picker
local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.new(0, 12, 0, 108); scroll.Size = UDim2.new(1, -24, 1, -210)
scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 5
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = panel
local grid = Instance.new("UIGridLayout", scroll)
grid.CellSize = UDim2.new(0.31, 0, 0, 70); grid.CellPadding = UDim2.new(0.025, 0, 0, 8)

-- edits row
local editsHolder = Instance.new("ScrollingFrame")
editsHolder.Position = UDim2.new(0, 12, 1, -96); editsHolder.Size = UDim2.new(1, -24, 0, 44)
editsHolder.BackgroundTransparency = 1; editsHolder.BorderSizePixel = 0
editsHolder.ScrollBarThickness = 4; editsHolder.ScrollingDirection = Enum.ScrollingDirection.X
editsHolder.AutomaticCanvasSize = Enum.AutomaticSize.X; editsHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
editsHolder.Parent = panel
local editsLayout = Instance.new("UIListLayout", editsHolder)
editsLayout.FillDirection = Enum.FillDirection.Horizontal; editsLayout.Padding = UDim.new(0, 6)

local forgeBtn = Instance.new("TextButton")
forgeBtn.AnchorPoint = Vector2.new(0.5, 1); forgeBtn.Position = UDim2.new(0.5, 0, 1, -10)
forgeBtn.Size = UDim2.new(1, -24, 0, 40); forgeBtn.BackgroundColor3 = Color3.fromRGB(255, 140, 60)
forgeBtn.Font = Enum.Font.GothamBlack; forgeBtn.TextSize = 18; forgeBtn.TextColor3 = Color3.new(1, 1, 1)
forgeBtn.Text = "FORGE"; forgeBtn.Parent = panel
Instance.new("UICorner", forgeBtn).CornerRadius = UDim.new(0, 12)

-- mirror server's point math for a live preview
local function previewPoints()
	local pts = 0
	local byId = {}; for _, d in ipairs(latestDucks) do byId[d.id] = d end
	for id in pairs(selected) do
		local d = byId[id]
		if d then
			local rarity = DuckSchema.getRarity(d.rarity)
			local tw = rarity and (1 + (rarity.tier - 1) * 0.35) or 1
			pts += (d.worth or 0) * tw
		end
	end
	return math.floor(pts)
end

local function count(t) local n = 0; for _ in pairs(t) do n += 1 end; return n end

local function rebuildEdits(tier)
	for _, c in ipairs(editsHolder:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for _, dim in ipairs(tier.edits) do
		local f = Instance.new("Frame"); f.Size = UDim2.new(0, 120, 1, 0)
		f.BackgroundColor3 = Color3.fromRGB(30, 33, 44); f.Parent = editsHolder
		Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
		local b = Instance.new("TextButton"); b.Size = UDim2.fromScale(1, 1); b.BackgroundTransparency = 1
		b.Font = Enum.Font.GothamBold; b.TextSize = 12; b.TextColor3 = Color3.fromRGB(255, 200, 150)
		b.Text = dim .. ":\n" .. (editChoices[dim] or "random"); b.Parent = f
		b.Activated:Connect(function()
			local opts = DuckSchema.Dimensions[dim]
			-- cycle through options the tier allows (forge-only only if tier unlocks it)
			local names = {}
			for _, o in ipairs(opts) do
				if (not o.forgeOnly) or tier.forgeExclusive then table.insert(names, o.name) end
			end
			table.insert(names, 1, "random")
			local cur = editChoices[dim] or "random"
			local idx = 1
			for i, n in ipairs(names) do if n == cur then idx = i end end
			local nextName = names[(idx % #names) + 1]
			editChoices[dim] = (nextName == "random") and nil or nextName
			b.Text = dim .. ":\n" .. (editChoices[dim] or "random")
		end)
	end
end

local function refreshReadout()
	local pts = previewPoints()
	local tier = DuckSchema.forgeTierForPoints(pts)
	readout.Text = ("Selected: %d/%d ducks  •  Forge points: %d\nProjected output: %s  •  Editable: %s")
		:format(count(selected), MAX, pts, tier.outRarity, table.concat(tier.edits, ", "))
	-- drop edit choices that the tier no longer allows
	local allowed = {}; for _, e in ipairs(tier.edits) do allowed[e] = true end
	for dim in pairs(editChoices) do if not allowed[dim] then editChoices[dim] = nil end end
	rebuildEdits(tier)
end

local function renderPicker(data)
	latestDucks = data.ducks or {}
	for _, c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	for _, duck in ipairs(latestDucks) do
		local rarity = DuckSchema.getRarity(duck.rarity)
		local rc = rarity and rarity.color or Color3.new(1, 1, 1)
		local card = Instance.new("Frame"); card.BackgroundColor3 = Color3.fromRGB(30, 33, 44); card.Parent = scroll
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)
		local st = Instance.new("UIStroke", card); st.Color = rc; st.Thickness = selected[duck.id] and 4 or 1
		local btn = Instance.new("TextButton"); btn.Size = UDim2.fromScale(1, 1); btn.BackgroundTransparency = 1
		btn.Font = Enum.Font.GothamBold; btn.TextSize = 12; btn.TextColor3 = rc
		btn.Text = (duck.shiny and "✨\n" or "🦆\n") .. duck.rarity .. "\n$" .. tostring(duck.worth or 0); btn.Parent = card
		btn.Activated:Connect(function()
			if selected[duck.id] then selected[duck.id] = nil
			elseif count(selected) < MAX then selected[duck.id] = true end
			st.Thickness = selected[duck.id] and 4 or 1
			refreshReadout()
		end)
	end
	refreshReadout()
end

InventoryChanged.OnClientEvent:Connect(function(data)
	if panel.Visible then
		-- keep only still-owned selections
		local own = {}; for _, d in ipairs(data.ducks) do own[d.id] = true end
		for id in pairs(selected) do if not own[id] then selected[id] = nil end end
		renderPicker(data)
	else
		latestDucks = data.ducks or {}
	end
end)

forgeBtn.Activated:Connect(function()
	local ids = {}; for id in pairs(selected) do table.insert(ids, id) end
	if #ids == 0 then return end
	forgeBtn.Text = "FORGING..."
	local res = ForgeDucks:InvokeServer({ ids = ids, edits = editChoices })
	forgeBtn.Text = "FORGE"
	if res and res.ok then
		selected = {}; editChoices = {}
	end
end)

openBtn.Activated:Connect(function() panel.Visible = true; renderPicker({ ducks = latestDucks }) end)
closeBtn.Activated:Connect(function() panel.Visible = false end)
