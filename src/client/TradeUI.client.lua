-- src/client/TradeUI.client.lua  | invite nearby player, build offer, lock to confirm
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local player  = Players.LocalPlayer
local Shared  = ReplicatedStorage:WaitForChild("Shared")
local DuckSchema = require(Shared:WaitForChild("DuckSchema"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Trade   = Remotes:WaitForChild("Trade")
local InventoryChanged = Remotes:WaitForChild("InventoryChanged")
local EquipDuck = Remotes:WaitForChild("EquipDuck")

local myDucks = {}
local offerSet = {}

local gui = Instance.new("ScreenGui")
gui.Name = "TradeUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local openBtn = Instance.new("TextButton")
openBtn.AnchorPoint = Vector2.new(0, 1); openBtn.Position = UDim2.new(0, 122, 1, -16)
openBtn.Size = UDim2.new(0, 96, 0, 48); openBtn.BackgroundColor3 = Color3.fromRGB(90, 200, 170)
openBtn.Font = Enum.Font.GothamBlack; openBtn.TextSize = 16; openBtn.TextColor3 = Color3.new(1, 1, 1)
openBtn.Text = "🔁 Trade"; openBtn.Parent = gui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 14)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.66, 0, 0.72, 0); panel.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
panel.Visible = false; panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)
Instance.new("UIStroke", panel).Color = Color3.fromRGB(90, 200, 170)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -50, 0, 40); title.Position = UDim2.new(0, 12, 0, 8)
title.BackgroundTransparency = 1; title.Font = Enum.Font.GothamBlack; title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left; title.TextColor3 = Color3.fromRGB(120, 220, 190)
title.Text = "🔁 TRADE"; title.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0); closeBtn.Position = UDim2.new(1, -10, 0, 8)
closeBtn.Size = UDim2.new(0, 36, 0, 36); closeBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 20; closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "✕"; closeBtn.Parent = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

-- status line
local status = Instance.new("TextLabel")
status.Position = UDim2.new(0, 12, 0, 48); status.Size = UDim2.new(1, -24, 0, 26)
status.BackgroundTransparency = 1; status.Font = Enum.Font.GothamBold; status.TextSize = 14
status.TextXAlignment = Enum.TextXAlignment.Left; status.TextColor3 = Color3.fromRGB(220, 220, 220)
status.Text = "Pick a player to trade with."; status.Parent = panel

-- container for the two views (player picker OR active trade)
local pickList = Instance.new("ScrollingFrame")
pickList.Position = UDim2.new(0, 12, 0, 80); pickList.Size = UDim2.new(1, -24, 1, -92)
pickList.BackgroundTransparency = 1; pickList.BorderSizePixel = 0; pickList.ScrollBarThickness = 5
pickList.AutomaticCanvasSize = Enum.AutomaticSize.Y; pickList.CanvasSize = UDim2.new(0, 0, 0, 0)
pickList.Parent = panel
local pickLayout = Instance.new("UIListLayout", pickList); pickLayout.Padding = UDim.new(0, 8)

local tradeView = Instance.new("Frame")
tradeView.Position = UDim2.new(0, 12, 0, 80); tradeView.Size = UDim2.new(1, -24, 1, -92)
tradeView.BackgroundTransparency = 1; tradeView.Visible = false; tradeView.Parent = panel

local function showPicker()
	pickList.Visible = true; tradeView.Visible = false
	for _, c in ipairs(pickList:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	status.Text = "Pick a player to trade with."
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local b = Instance.new("TextButton"); b.Size = UDim2.new(1, -6, 0, 44)
			b.BackgroundColor3 = Color3.fromRGB(30, 33, 44); b.Font = Enum.Font.GothamBold
			b.TextSize = 16; b.TextColor3 = Color3.new(1, 1, 1); b.Text = "Invite " .. other.Name; b.Parent = pickList
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
			b.Activated:Connect(function() Trade:FireServer("invite", other.UserId) end)
		end
	end
end

-- active trade view widgets
local theirLabel = Instance.new("TextLabel")
theirLabel.Size = UDim2.new(1, 0, 0, 24); theirLabel.BackgroundTransparency = 1
theirLabel.Font = Enum.Font.GothamBold; theirLabel.TextSize = 14; theirLabel.TextColor3 = Color3.fromRGB(255, 200, 120)
theirLabel.TextXAlignment = Enum.TextXAlignment.Left; theirLabel.Text = "Their offer:"; theirLabel.Parent = tradeView

local theirBox = Instance.new("TextLabel")
theirBox.Position = UDim2.new(0, 0, 0, 26); theirBox.Size = UDim2.new(1, 0, 0, 60)
theirBox.BackgroundColor3 = Color3.fromRGB(30, 33, 44); theirBox.Font = Enum.Font.Gotham
theirBox.TextSize = 13; theirBox.TextColor3 = Color3.fromRGB(220, 220, 220); theirBox.TextWrapped = true
theirBox.Text = "(nothing yet)"; theirBox.Parent = tradeView
Instance.new("UICorner", theirBox).CornerRadius = UDim.new(0, 10)

local mineLabel = Instance.new("TextLabel")
mineLabel.Position = UDim2.new(0, 0, 0, 94); mineLabel.Size = UDim2.new(1, 0, 0, 24)
mineLabel.BackgroundTransparency = 1; mineLabel.Font = Enum.Font.GothamBold; mineLabel.TextSize = 14
mineLabel.TextColor3 = Color3.fromRGB(120, 220, 190); mineLabel.TextXAlignment = Enum.TextXAlignment.Left
mineLabel.Text = "Tap your ducks to add/remove:"; mineLabel.Parent = tradeView

local mineScroll = Instance.new("ScrollingFrame")
mineScroll.Position = UDim2.new(0, 0, 0, 120); mineScroll.Size = UDim2.new(1, 0, 1, -176)
mineScroll.BackgroundTransparency = 1; mineScroll.BorderSizePixel = 0; mineScroll.ScrollBarThickness = 5
mineScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; mineScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
mineScroll.Parent = tradeView
local mineGrid = Instance.new("UIGridLayout", mineScroll)
mineGrid.CellSize = UDim2.new(0.31, 0, 0, 56); mineGrid.CellPadding = UDim2.new(0.025, 0, 0, 8)

local lockBtn = Instance.new("TextButton")
lockBtn.AnchorPoint = Vector2.new(0, 1); lockBtn.Position = UDim2.new(0, 0, 1, 0)
lockBtn.Size = UDim2.new(0.48, 0, 0, 44); lockBtn.BackgroundColor3 = Color3.fromRGB(70, 200, 110)
lockBtn.Font = Enum.Font.GothamBlack; lockBtn.TextSize = 16; lockBtn.TextColor3 = Color3.new(1, 1, 1)
lockBtn.Text = "LOCK ✓"; lockBtn.Parent = tradeView
Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 10)
local locked = false
lockBtn.Activated:Connect(function()
	locked = not locked
	Trade:FireServer(locked and "lock" or "unlock")
end)

local cancelBtn = Instance.new("TextButton")
cancelBtn.AnchorPoint = Vector2.new(1, 1); cancelBtn.Position = UDim2.new(1, 0, 1, 0)
cancelBtn.Size = UDim2.new(0.48, 0, 0, 44); cancelBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
cancelBtn.Font = Enum.Font.GothamBlack; cancelBtn.TextSize = 16; cancelBtn.TextColor3 = Color3.new(1, 1, 1)
cancelBtn.Text = "CANCEL"; cancelBtn.Parent = tradeView
Instance.new("UICorner", cancelBtn).CornerRadius = UDim.new(0, 10)
cancelBtn.Activated:Connect(function() Trade:FireServer("cancel") end)

local function sendOffer()
	local ids = {}; for id in pairs(offerSet) do table.insert(ids, id) end
	Trade:FireServer("offer", ids)
end

local function renderMine()
	for _, c in ipairs(mineScroll:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	for _, duck in ipairs(myDucks) do
		local rarity = DuckSchema.getRarity(duck.rarity)
		local rc = rarity and rarity.color or Color3.new(1, 1, 1)
		local b = Instance.new("TextButton"); b.BackgroundColor3 = Color3.fromRGB(30, 33, 44); b.Parent = mineScroll
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
		local st = Instance.new("UIStroke", b); st.Color = rc; st.Thickness = offerSet[duck.id] and 4 or 1
		b.Font = Enum.Font.GothamBold; b.TextSize = 11; b.TextColor3 = rc
		b.Text = (duck.shiny and "✨ " or "") .. duck.rarity .. "\n$" .. tostring(duck.worth or 0)
		b.Activated:Connect(function()
			if offerSet[duck.id] then offerSet[duck.id] = nil else offerSet[duck.id] = true end
			st.Thickness = offerSet[duck.id] and 4 or 1
			if locked then locked = false end
			sendOffer()
		end)
	end
end

InventoryChanged.OnClientEvent:Connect(function(data)
	myDucks = data.ducks or {}
	if tradeView.Visible then
		local own = {}; for _, d in ipairs(myDucks) do own[d.id] = true end
		for id in pairs(offerSet) do if not own[id] then offerSet[id] = nil end end
		renderMine()
	end
end)

Trade.OnClientEvent:Connect(function(kind, payload)
	if kind == "update" then
		pickList.Visible = false; tradeView.Visible = true; panel.Visible = true
		status.Text = ("Trading with %s — %s")
			:format(payload.otherName or "?", payload.theyLocked and "they LOCKED ✓" or "they're choosing...")
		theirLabel.Text = "Their offer:" .. (payload.theyLocked and "  (LOCKED ✓)" or "")
		local lines = {}
		local byId = {}; for _, d in ipairs(myDucks) do byId[d.id] = d end
		for _, id in ipairs(payload.theirOffer or {}) do table.insert(lines, id:sub(1, 6)) end
		theirBox.Text = (#(payload.theirOffer or {}) > 0) and (#payload.theirOffer .. " duck(s) offered") or "(nothing yet)"
		locked = payload.youLocked or false
		lockBtn.Text = locked and "LOCKED ✓ (tap to undo)" or "LOCK ✓"
		lockBtn.BackgroundColor3 = locked and Color3.fromRGB(60, 150, 90) or Color3.fromRGB(70, 200, 110)
		renderMine()
	elseif kind == "closed" then
		offerSet = {}; locked = false
		status.Text = payload.reason or "Trade closed"
		task.wait(0.1)
		showPicker()
	end
end)

openBtn.Activated:Connect(function() panel.Visible = true; showPicker(); EquipDuck:FireServer("refresh") end)
closeBtn.Activated:Connect(function()
	if tradeView.Visible then Trade:FireServer("cancel") end
	panel.Visible = false
end)
