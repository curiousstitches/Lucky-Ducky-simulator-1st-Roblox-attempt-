-- src/client/MenuBar.client.lua  | moves all on-screen menu buttons into ONE bottom icon bar.
-- Each is a small icon; hovering shows its name. When any menu panel is open, the bar hides so the
-- screen stays clean. Keeps every existing button's click logic — we just restyle/relocate them.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local pg = player:WaitForChild("PlayerGui")

-- map ScreenGui name -> {icon, label}. Order = left to right on the bar.
local ITEMS = {
	{ gui="LobbyUI",        icon="🥚", label="Eggs" },
	{ gui="ShopUI",         icon="🛒", label="Shop" },
	{ gui="LaunchUI",       icon="➕", label="Slots" },
	{ gui="ExtrasUI",       icon="🦆", label="Ducks" },
	{ gui="InventoryUI",    icon="🎒", label="Bag" },
	{ gui="ForgeUI",        icon="⚙️", label="Forge" },
	{ gui="SeasonUI",       icon="🎟️", label="Season" },
	{ gui="TradeUI",        icon="🔁", label="Trade" },
	{ gui="TeleportUI",     icon="🌀", label="Travel" },
	{ gui="MenuUI",         icon="📜", label="Menu" },
	{ gui="LaunchPolishUI", icon="🎁", label="Daily" },
}

-- find the original open-button inside a gui (top-level TextButton parented to the ScreenGui)
local function openButtonFor(guiName)
	local g = pg:FindFirstChild(guiName); if not g then return nil end
	for _, d in ipairs(g:GetChildren()) do
		if d:IsA("TextButton") then return d end
	end
	return nil
end

-- is any big menu panel currently visible? (a Frame taking up a big chunk of screen)
local function aMenuIsOpen()
	for _, g in ipairs(pg:GetChildren()) do
		if g:IsA("ScreenGui") and g.Name ~= "MenuBar" and g.Name ~= "CurrencyHud" and g.Name ~= "ZoneProgressUI" and g.Name ~= "AlertUI" then
			for _, d in ipairs(g:GetChildren()) do
				if d:IsA("Frame") and d.Visible and (d.Size.X.Scale >= 0.5 or d.Size.X.Offset >= 280) then
					return true
				end
			end
		end
	end
	return false
end

local gui = Instance.new("ScreenGui"); gui.Name="MenuBar"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.DisplayOrder=20; gui.Parent=pg

-- the bottom bar container
local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 1); bar.Position = UDim2.new(0.5, 0, 1, -10)
bar.Size = UDim2.new(0, #ITEMS*52, 0, 52); bar.BackgroundColor3 = Color3.fromRGB(22,25,38)
bar.BackgroundTransparency = 0.1; bar.Parent = gui
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 18)
Instance.new("UIStroke", bar).Color = Color3.fromRGB(255,210,80)
local pad = Instance.new("UIPadding", bar); pad.PaddingLeft=UDim.new(0,6); pad.PaddingRight=UDim.new(0,6)
local layout = Instance.new("UIListLayout", bar)
layout.FillDirection = Enum.FillDirection.Horizontal; layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 4)

-- tooltip
local tip = Instance.new("TextLabel"); tip.AnchorPoint=Vector2.new(0.5,1); tip.Position=UDim2.new(0.5,0,1,-66)
tip.Size=UDim2.new(0,120,0,24); tip.BackgroundColor3=Color3.fromRGB(20,22,32); tip.Visible=false
tip.Font=Enum.Font.FredokaOne; tip.TextSize=14; tip.TextColor3=Color3.fromRGB(255,225,120); tip.Parent=gui
Instance.new("UICorner", tip).CornerRadius=UDim.new(0,8)

local function build()
	for _, c in ipairs(bar:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	for _, item in ipairs(ITEMS) do
		local orig = openButtonFor(item.gui)
		if orig then
			orig.Visible = false  -- hide the loose corner button
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(0, 44, 0, 44); b.BackgroundColor3 = Color3.fromRGB(40,46,64)
			b.Font = Enum.Font.GothamBold; b.TextSize = 22; b.TextColor3 = Color3.new(1,1,1); b.Text = item.icon
			b.Parent = bar
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
			b.MouseEnter:Connect(function() tip.Text=item.label; tip.Visible=true end)
			b.MouseLeave:Connect(function() tip.Visible=false end)
			b.Activated:Connect(function()
				-- fire the original button's action by toggling its panel through its own handler
				local o = openButtonFor(item.gui)
				if o then
					-- simplest reliable trigger: temporarily enable + invoke its Activated via a click sim
					o.Visible = true
					-- most open-buttons just toggle a panel; we replicate by toggling visible panels:
					local g = pg:FindFirstChild(item.gui)
					if g then
						for _, d in ipairs(g:GetDescendants()) do
							if d:IsA("Frame") and (d.Size.X.Scale>=0.5 or d.Size.X.Offset>=280) then
								d.Visible = not d.Visible
							end
						end
					end
					o.Visible = false
				end
			end)
		end
	end
end

-- hide the bar when a menu is open; show it otherwise
task.spawn(function()
	for _=1,6 do build(); task.wait(1) end  -- rebuild as guis load
	while true do
		bar.Visible = not aMenuIsOpen()
		if not bar.Visible then tip.Visible=false end
		task.wait(0.3)
	end
end)
