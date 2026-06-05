-- src/client/InventoryUI.client.lua  | mobile duck list: tap to equip/unequip your squad
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")

local player     = Players.LocalPlayer
local Shared     = ReplicatedStorage:WaitForChild("Shared")
local DuckSchema = require(Shared:WaitForChild("DuckSchema"))
local Remotes    = ReplicatedStorage:WaitForChild("Remotes")
local InventoryChanged = Remotes:WaitForChild("InventoryChanged")
local EquipDuck        = Remotes:WaitForChild("EquipDuck")

local gui = Instance.new("ScreenGui")
gui.Name = "InventoryUI"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local openBtn = Instance.new("TextButton")
openBtn.AnchorPoint = Vector2.new(1, 1); openBtn.Position = UDim2.new(1, -16, 1, -76)
openBtn.Size = UDim2.new(0, 96, 0, 48); openBtn.BackgroundColor3 = Color3.fromRGB(120, 130, 245)
openBtn.Font = Enum.Font.GothamBlack; openBtn.TextSize = 17; openBtn.TextColor3 = Color3.new(1, 1, 1)
openBtn.Text = "🦆 Ducks"; openBtn.Parent = gui
Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 14)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5); panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.new(0.66, 0, 0.72, 0); panel.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
panel.Visible = false; panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)
Instance.new("UIStroke", panel).Color = Color3.fromRGB(120, 130, 245)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 46); title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack; title.TextSize = 22; title.TextColor3 = Color3.fromRGB(180, 190, 255)
title.Text = "MY DUCKS"; title.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0); closeBtn.Position = UDim2.new(1, -10, 0, 8)
closeBtn.Size = UDim2.new(0, 36, 0, 36); closeBtn.BackgroundColor3 = Color3.fromRGB(200, 70, 70)
closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextSize = 20; closeBtn.TextColor3 = Color3.new(1, 1, 1)
closeBtn.Text = "✕"; closeBtn.Parent = panel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1, 0)

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.new(0, 12, 0, 52); scroll.Size = UDim2.new(1, -24, 1, -64)
scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 5
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = panel
local grid = Instance.new("UIGridLayout", scroll)
grid.CellSize = UDim2.new(0.48, 0, 0, 96); grid.CellPadding = UDim2.new(0.04, 0, 0, 10)

local function render(data)
	for _, c in ipairs(scroll:GetChildren()) do if c:IsA("Frame") then c:Destroy() end end
	local equippedSet = {}; for _, id in ipairs(data.equipped) do equippedSet[id] = true end
	title.Text = ("MY DUCKS  (%d/%d equipped)"):format(#data.equipped, data.max)

	for _, duck in ipairs(data.ducks) do
		local rarity = DuckSchema.getRarity(duck.rarity)
		local rc = rarity and rarity.color or Color3.new(1, 1, 1)
		local on = equippedSet[duck.id]

		local card = Instance.new("Frame")
		card.BackgroundColor3 = Color3.fromRGB(30, 33, 44); card.Parent = scroll
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
		local st = Instance.new("UIStroke", card); st.Color = rc; st.Thickness = on and 3 or 1

		local emoji = Instance.new("TextLabel")
		emoji.Size = UDim2.new(0, 40, 0, 40); emoji.Position = UDim2.new(0, 8, 0, 6)
		emoji.BackgroundTransparency = 1; emoji.TextSize = 32
		emoji.Text = (duck.shiny and "✨" or "🦆"); emoji.Parent = card

		local name = Instance.new("TextLabel")
		name.Position = UDim2.new(0, 52, 0, 8); name.Size = UDim2.new(1, -58, 0, 20)
		name.BackgroundTransparency = 1; name.Font = Enum.Font.GothamBold; name.TextSize = 13
		name.TextXAlignment = Enum.TextXAlignment.Left; name.TextColor3 = rc; name.Text = duck.rarity; name.Parent = card

		local stat = Instance.new("TextLabel")
		stat.Position = UDim2.new(0, 52, 0, 28); stat.Size = UDim2.new(1, -58, 0, 20)
		stat.BackgroundTransparency = 1; stat.Font = Enum.Font.Gotham; stat.TextSize = 12
		stat.TextXAlignment = Enum.TextXAlignment.Left; stat.TextColor3 = Color3.fromRGB(190, 195, 205)
		stat.Text = ("Pow %d • $%d"):format(duck.strength or 0, duck.worth or 0); stat.Parent = card

		local btn = Instance.new("TextButton")
		btn.AnchorPoint = Vector2.new(0.5, 1); btn.Position = UDim2.new(0.5, 0, 1, -8)
		btn.Size = UDim2.new(1, -16, 0, 30); btn.Font = Enum.Font.GothamBold; btn.TextSize = 13
		btn.TextColor3 = Color3.new(1, 1, 1); btn.Parent = card
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		btn.BackgroundColor3 = on and Color3.fromRGB(200, 90, 90) or Color3.fromRGB(70, 200, 110)
		btn.Text = on and "Unequip" or "Equip"
		btn.Activated:Connect(function()
			EquipDuck:FireServer(on and "unequip" or "equip", duck.id)
		end)
	end
end

InventoryChanged.OnClientEvent:Connect(render)
openBtn.Activated:Connect(function() panel.Visible = true; EquipDuck:FireServer("refresh") end)
closeBtn.Activated:Connect(function() panel.Visible = false end)
EquipDuck:FireServer("refresh")
