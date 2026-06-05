-- src/server/WorldBuilder.lua  | builds 300 procedural levels across 3 worlds with gates,
-- breakable fields, scattered shops/clan/secret/boss/egglab features, plus the VIP zone.
local Workspace         = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared       = ReplicatedStorage:WaitForChild("Shared")
local WorldConfig  = require(Shared:WaitForChild("WorldConfig"))
local UnlockConfig = require(Shared:WaitForChild("UnlockConfig"))

local WorldBuilder = {}

local function part(props)
	local p = Instance.new("Part"); p.Anchored = true; p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do p[k] = v end
	return p
end

local function label(parent, text, color, size)
	local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(0, size or 240, 0, 56)
	bb.StudsOffset = Vector3.new(0, 5, 0); bb.AlwaysOnTop = true; bb.Parent = parent
	local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold; t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.3; t.TextScaled = true; t.Text = text; t.Parent = bb
end

local function breakable(pos, parent, currency, reward, hp, color)
	local b = part({ Size = Vector3.new(4, 4, 4), Position = pos + Vector3.new(0, 2, 0),
		Color = color or Color3.fromRGB(120, 90, 55), Material = Enum.Material.Slate, Parent = parent })
	b:SetAttribute("MaxHP", hp); b:SetAttribute("Reward", reward); b:SetAttribute("Currency", currency)
	CollectionService:AddTag(b, "Breakable")
end

local function gate(pos, parent, level, cost)
	local g = part({ Name = "Gate_" .. level, Size = Vector3.new(40, 16, 2), Position = pos + Vector3.new(0, 8, 0),
		Color = Color3.fromRGB(60, 60, 80), Material = Enum.Material.ForceField, Transparency = 0.35, Parent = parent })
	g:SetAttribute("GateLevel", level); g:SetAttribute("GateCost", cost)
	CollectionService:AddTag(g, "LevelGate")
	label(g, ("⛩️ LEVEL %d GATE\n%d to pass"):format(level, cost), Color3.fromRGB(255, 200, 90))
	return g
end

local function featureMarker(pos, parent, kind, level)
	local colors = { shop = Color3.fromRGB(90, 200, 120), clan = Color3.fromRGB(150, 120, 255),
		boss = Color3.fromRGB(255, 80, 80), secret = Color3.fromRGB(255, 215, 40), egglab = Color3.fromRGB(120, 200, 255),
		worldgate = Color3.fromRGB(255, 255, 255) }
	local m = part({ Name = kind .. "_" .. level, Size = Vector3.new(8, 10, 8), Position = pos + Vector3.new(0, 5, 0),
		Color = colors[kind] or Color3.fromRGB(200, 200, 200), Material = Enum.Material.Neon, Parent = parent })
	m:SetAttribute("Feature", kind); m:SetAttribute("FeatureLevel", level)
	CollectionService:AddTag(m, "Feature")
	local names = { shop = "🏪 SHOP", clan = "🛡️ CLAN HALL", boss = "💀 BOSS ARENA",
		secret = "❓ SECRET", egglab = "🥚 EGG LAB", worldgate = "🌍 WORLD ENTRANCE" }
	-- shops pull a scattered, level-scaled name (low->advanced)
	local shopName = ""
	if kind == "shop" then
		local idx = ((level // 10) % #UnlockConfig.Shops) + 1
		shopName = "\n" .. UnlockConfig.Shops[idx]
	end
	label(m, (names[kind] or kind) .. shopName, colors[kind])
	return m
end

function WorldBuilder.Build()
	local world = Workspace:FindFirstChild("World") or Instance.new("Folder")
	world.Name = "World"; world.Parent = Workspace
	local levelsFolder = Instance.new("Folder"); levelsFolder.Name = "Levels"; levelsFolder.Parent = world

	for lvl = 1, WorldConfig.TotalLevels do
		local def = WorldConfig.levelDef(lvl)
		local origin = WorldConfig.levelOrigin(lvl)
		-- only physically build a sampled set up-front to stay light: build every level's floor + gate,
		-- but only spawn breakables/features for the first 60 levels + every 10th beyond (perf).
		local heavy = (lvl <= 60) or (lvl % 10 == 0)

		local floor = part({ Name = "L" .. lvl, Size = Vector3.new(80, 2, 100),
			Position = origin + Vector3.new(0, -1, 0), Color = def.color, Parent = levelsFolder })

		-- entry gate (skip level 1 of world 1 = free spawn)
		if not (lvl == 1) then
			gate(origin + Vector3.new(0, 0, -48), levelsFolder, lvl, def.gateCost)
		end

		if heavy then
			local count = math.clamp(6 + math.floor(lvl / 8), 6, 18)
			for i = 1, count do
				local ang = (i / count) * math.pi * 2
				breakable(origin + Vector3.new(math.cos(ang) * 26, 0, math.sin(ang) * 26),
					levelsFolder, def.currency, def.reward, def.hp, def.color:Lerp(Color3.new(0,0,0), 0.25))
			end
			if def.feature then
				featureMarker(origin + Vector3.new(0, 0, 30), levelsFolder, def.feature, lvl)
				if def.feature == "boss" then CollectionService:AddTag(levelsFolder, "HasBoss") end
			end
		end
	end

	-- VIP ZONE (walled off; entry validated by VIP pass at the pad)
	local vip = Instance.new("Folder"); vip.Name = "VIPZone"; vip.Parent = world
	local vipOrigin = Vector3.new(-600, 0, 0)
	part({ Name = "VIPFloor", Size = Vector3.new(160, 2, 160), Position = vipOrigin + Vector3.new(0, -1, 0),
		Color = Color3.fromRGB(60, 50, 20), Material = Enum.Material.Foil, Parent = vip })
	local vsign = part({ Name = "VIPSign", Size = Vector3.new(60, 14, 1), Position = vipOrigin + Vector3.new(0, 9, -70),
		Color = Color3.fromRGB(40, 34, 10), Parent = vip })
	label(vsign, "👑 VIP LOUNGE 👑", Color3.fromRGB(255, 215, 40))
	-- VIP-only breakable field (golden, high reward)
	for i = 1, 16 do
		local ang = (i / 16) * math.pi * 2
		local b = part({ Size = Vector3.new(5, 5, 5), Position = vipOrigin + Vector3.new(math.cos(ang) * 40, 2, math.sin(ang) * 40),
			Color = Color3.fromRGB(255, 200, 60), Material = Enum.Material.Neon, Parent = vip })
		b:SetAttribute("MaxHP", 500); b:SetAttribute("Reward", 250); b:SetAttribute("Currency", "DuckDroppings")
		b:SetAttribute("VIP", true)
		CollectionService:AddTag(b, "Breakable")
	end
	-- VIP entry pad (server checks pass on touch)
	local vpad = part({ Name = "VIPPad", Size = Vector3.new(10, 1, 10), Position = Vector3.new(-60, 0.5, 0),
		Color = Color3.fromRGB(255, 215, 40), Material = Enum.Material.Neon, Parent = world })
	vpad:SetAttribute("VIPTeleport", true); CollectionService:AddTag(vpad, "VIPPad")
	label(vpad, "👑 Enter VIP Lounge", Color3.fromRGB(255, 225, 90))
	WorldBuilder.VIPSpawn = vipOrigin + Vector3.new(0, 6, 0)
end

return WorldBuilder
