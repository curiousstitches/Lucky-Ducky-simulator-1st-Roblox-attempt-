-- src/server/HubBuilder.lua  | builds a massive, detailed garage hub + decorated biomes,
-- multiple themed zones, dense foliage, hidden gift spots, lamps, fountains, fences, ambiance.
local Workspace         = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local Shared            = ReplicatedStorage:WaitForChild("Shared")
local ShopConfig        = require(Shared:WaitForChild("ShopConfig"))
local BiomeConfig       = require(Shared:WaitForChild("BiomeConfig"))
local Decor             = require(script.Parent.Decor)

local HubBuilder = {}

local function part(props)
	local p = Instance.new("Part"); p.Anchored = true; p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do p[k] = v end
	return p
end

local function label(parentPart, text, color)
	local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(0, 220, 0, 52)
	bb.StudsOffset = Vector3.new(0, 4, 0); bb.AlwaysOnTop = true; bb.Parent = parentPart
	local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold; t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.3; t.TextScaled = true; t.Text = text; t.Parent = bb
end

local function pad(name, position, color, biomeId, parent)
	local p = part({ Name = name, Size = Vector3.new(8, 1, 8), Position = position,
		Color = color, Material = Enum.Material.Neon, Parent = parent })
	p:SetAttribute("BiomeId", biomeId)
	CollectionService:AddTag(p, "BiomePad")
	return p
end

local function dispenserPedestal(cfg, position, parent)
	local colors = { crate = Color3.fromRGB(196,140,70), claw = Color3.fromRGB(90,170,230),
		pond = Color3.fromRGB(70,200,170), gumball = Color3.fromRGB(240,110,160) }
	local c = colors[cfg.id] or Color3.fromRGB(200,200,200)
	-- base + machine body + glowing top
	part({ Size = Vector3.new(8, 1, 8), Position = position + Vector3.new(0, 0.5, 0),
		Color = Color3.fromRGB(45,45,52), Material = Enum.Material.Metal, Parent = parent })
	local ped = part({ Name = "Dispenser_" .. cfg.id, Size = Vector3.new(6, 8, 6),
		Position = position + Vector3.new(0, 4.5, 0), Color = c, Material = Enum.Material.Neon, Parent = parent })
	part({ Shape = Enum.PartType.Ball, Size = Vector3.new(5,5,5), Position = position + Vector3.new(0, 9, 0),
		Color = c, Material = Enum.Material.Glass, Transparency = 0.25, Parent = parent })
	label(ped, ("%s\n%d %s"):format(cfg.name, cfg.cost, cfg.currency == "ShimmerSplats" and "Splats" or "Droppings"), c)
	local prompt = Instance.new("ProximityPrompt"); prompt.ActionText = "Pull"; prompt.ObjectText = cfg.name
	prompt.HoldDuration = 0.15; prompt.MaxActivationDistance = 12
	prompt:SetAttribute("DispenserId", cfg.id); prompt.Parent = ped
end

local function breakable(position, parent, currency, reward, hp, color)
	local b = part({ Size = Vector3.new(4, 4, 4), Position = position + Vector3.new(0, 2, 0),
		Color = color or Color3.fromRGB(120, 90, 55), Material = Enum.Material.Wood, Parent = parent })
	b:SetAttribute("MaxHP", hp); b:SetAttribute("Reward", reward); b:SetAttribute("Currency", currency)
	CollectionService:AddTag(b, "Breakable")
	return b
end

-- a hidden gift spot marker (GiftService spawns loose gifts; these are bonus static finds)
local function hiddenGift(position, parent)
	local g = part({ Name = "HiddenGift", Size = Vector3.new(2.5,2.5,2.5), Position = position + Vector3.new(0,1.5,0),
		Color = Color3.fromRGB(255,120,180), Material = Enum.Material.Neon, Transparency = 0.1, Parent = parent })
	g:SetAttribute("GiftTier", "common"); CollectionService:AddTag(g, "Gift")
	local sparkle = Instance.new("ParticleEmitter"); sparkle.Texture = "rbxassetid://243660364"
	sparkle.Rate = 6; sparkle.Lifetime = NumberRange.new(1,1.5); sparkle.Speed = NumberRange.new(0.5,1)
	sparkle.Color = ColorSequence.new(Color3.fromRGB(255,180,220)); sparkle.Parent = g
end

-- a shop building: walls + roof + sign + door opening
local function shopBuilding(position, parent, name, color)
	local model = Instance.new("Model"); model.Name = "Shop_" .. name; model.Parent = parent
	local function wall(size, off) part({ Size = size, Position = position + off, Color = Color3.fromRGB(225,215,195),
		Material = Enum.Material.SmoothPlastic, Parent = model }) end
	wall(Vector3.new(20, 14, 1), Vector3.new(0, 7, -8))           -- back
	wall(Vector3.new(1, 14, 16), Vector3.new(-10, 7, 0))          -- left
	wall(Vector3.new(1, 14, 16), Vector3.new(10, 7, 0))           -- right
	wall(Vector3.new(7, 14, 1), Vector3.new(-6.5, 7, 8))          -- front-left (door gap middle)
	wall(Vector3.new(7, 14, 1), Vector3.new(6.5, 7, 8))           -- front-right
	local roof = part({ Size = Vector3.new(24, 1.5, 20), Position = position + Vector3.new(0, 14.5, 0),
		Color = color or Color3.fromRGB(200, 80, 80), Material = Enum.Material.SmoothPlastic, Parent = model })
	label(roof, "🏪 " .. name, color or Color3.fromRGB(255, 230, 150))
	Decor.lamp(position + Vector3.new(-12, 0, 10), model, Color3.fromRGB(255,230,160))
	Decor.lamp(position + Vector3.new(12, 0, 10), model, Color3.fromRGB(255,230,160))
end

function HubBuilder.Build()
	local world = Instance.new("Folder"); world.Name = "World"; world.Parent = Workspace

	-- ambiance: soft warm lighting + light fog for depth
	Lighting.Brightness = 2; Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 140)
	Lighting.FogEnd = 900; Lighting.FogColor = Color3.fromRGB(170, 200, 220)
	local atmos = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmos.Density = 0.32; atmos.Haze = 1.4; atmos.Color = Color3.fromRGB(210, 220, 235); atmos.Parent = Lighting

	-- ===== HUB (massive central plaza) =====
	local hub = Instance.new("Folder"); hub.Name = "Hub"; hub.Parent = world
	-- big grassy plaza floor with a stone-tile center
	part({ Name = "HubGrass", Size = Vector3.new(300, 2, 300), Position = Vector3.new(0, -1, 0),
		Color = Color3.fromRGB(86, 160, 92), Material = Enum.Material.Grass, Parent = hub })
	part({ Name = "HubPlaza", Size = Vector3.new(120, 2, 120), Position = Vector3.new(0, -0.6, 0),
		Color = Color3.fromRGB(180, 175, 165), Material = Enum.Material.Concrete, Parent = hub })

	-- big arched entrance sign
	Decor.arch(Vector3.new(0, 0, -60), hub, Color3.fromRGB(200,160,90), "🦆 LUCKY DUCK GARAGE 🚙")

	local spawn = Instance.new("SpawnLocation"); spawn.Anchored = true; spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 0.5, 18); spawn.Color = Color3.fromRGB(255, 221, 51); spawn.Neutral = true
	spawn.Material = Enum.Material.Neon; spawn.Parent = hub

	-- central fountain centerpiece
	Decor.fountain(Vector3.new(0, 0, 0), hub)

	-- ring of lamps + benches around the plaza
	for i = 0, 7 do
		local a = (i / 8) * math.pi * 2
		Decor.lamp(Vector3.new(math.cos(a) * 52, 0, math.sin(a) * 52), hub, Color3.fromRGB(255, 235, 170))
		if i % 2 == 0 then Decor.bench(Vector3.new(math.cos(a) * 44, 0, math.sin(a) * 44), hub, math.deg(a) + 90) end
	end

	-- dense foliage ring around the plaza edge (trees, bushes, flowers)
	Decor.scatter(Vector3.new(0,0,0), hub, 26, 66, 140, function(pos, par)
		Decor.tree(pos, par, 0.8 + math.random() * 0.8, Color3.fromRGB(55 + math.random(0,40), 140 + math.random(0,40), 70))
	end)
	Decor.scatter(Vector3.new(0,0,0), hub, 40, 62, 140, function(pos, par) Decor.bush(pos, par) end)
	Decor.scatter(Vector3.new(0,0,0), hub, 50, 60, 140, function(pos, par)
		local cols = { Color3.fromRGB(255,120,180), Color3.fromRGB(255,210,70), Color3.fromRGB(150,130,255), Color3.fromRGB(255,140,90) }
		Decor.flower(pos, par, cols[math.random(1,#cols)])
	end)
	Decor.scatter(Vector3.new(0,0,0), hub, 14, 70, 135, function(pos, par) Decor.rock(pos, par, 0.7 + math.random()) end)

	-- DISPENSER PAVILION (north-east) with fence + banners
	local dz = Vector3.new(58, 0, -38)
	part({ Size = Vector3.new(70, 0.4, 36), Position = dz + Vector3.new(0, 0.1, 0), Color = Color3.fromRGB(150,145,135),
		Material = Enum.Material.Concrete, Parent = hub })
	Decor.banner(dz + Vector3.new(-30, 0, -16), hub, Color3.fromRGB(90,170,230), "EGGS")
	Decor.banner(dz + Vector3.new(30, 0, -16), hub, Color3.fromRGB(240,110,160), "PULL")
	for i, cfg in ipairs(ShopConfig.Dispensers) do
		dispenserPedestal(cfg, dz + Vector3.new(-24 + (i - 1) * 16, 0, 0), hub)
	end

	-- TRAVEL PLAZA (south) — biome pads on a raised stone dais with arch
	local tz = Vector3.new(0, 0, 46)
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.5, 80, 80), Position = tz + Vector3.new(0, 0.4, 0),
		Color = Color3.fromRGB(160,150,140), Material = Enum.Material.Marble,
		CFrame = CFrame.new(tz + Vector3.new(0,0.4,0)) * CFrame.Angles(0,0,math.pi/2), Parent = hub })
	Decor.arch(tz + Vector3.new(0, 0, -18), hub, Color3.fromRGB(120,180,255), "🗺️ TRAVEL")
	for i, b in ipairs(BiomeConfig.List) do
		local a = ((i - 1) / #BiomeConfig.List) * math.pi - math.pi  -- arc across the front
		local p = pad("Pad_" .. b.id, tz + Vector3.new(math.cos(a) * 28, 0.5, math.abs(math.sin(a)) * 16 + 4), b.color, b.id, hub)
		label(p, ("%s%s"):format(b.name, b.unlockCost and ("\n" .. b.unlockCost.amount .. " Droppings") or "\nFREE"), b.color)
	end

	-- SHOP ROW (west) — themed buildings
	local shops = { {"Item Shop", Color3.fromRGB(90,200,120)}, {"Pet Shop", Color3.fromRGB(255,170,80)}, {"Style Shop", Color3.fromRGB(180,120,255)} }
	for i, s in ipairs(shops) do
		shopBuilding(Vector3.new(-72, 0, -30 + (i - 1) * 34), hub, s[1], s[2])
	end

	-- FISHING GARDEN (east) — big pond with lily pads, fence, reeds
	local fz = Vector3.new(80, 0, 28)
	local pond = part({ Name = "FishingPond", Size = Vector3.new(46, 1, 46), Position = fz + Vector3.new(0, 0.2, 0),
		Color = Color3.fromRGB(50, 140, 200), Material = Enum.Material.Glass, Transparency = 0.25, Parent = hub })
	pond:SetAttribute("FishingPad", true); CollectionService:AddTag(pond, "FishingPad")
	label(pond, "🎣 Fishing Pond", Color3.fromRGB(150, 220, 255))
	for _ = 1, 8 do
		Decor.lilypad(fz + Vector3.new(math.random(-18,18), 0, math.random(-18,18)), hub)
	end
	Decor.scatter(fz, hub, 16, 26, 36, function(pos, par) Decor.bush(pos, par, Color3.fromRGB(60,150,90)) end)
	Decor.tree(fz + Vector3.new(-26, 0, -10), hub, 1.4)
	Decor.tree(fz + Vector3.new(26, 0, 14), hub, 1.2)

	-- BOSS ARENA (far north) — dramatic red ring + torches
	local bz = Vector3.new(0, 0, -110)
	part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.5, 60, 60), Position = bz + Vector3.new(0, 0.4, 0),
		Color = Color3.fromRGB(70, 30, 35), Material = Enum.Material.Slate,
		CFrame = CFrame.new(bz + Vector3.new(0,0.4,0)) * CFrame.Angles(0,0,math.pi/2), Parent = hub })
	local bossPad = part({ Name = "BossPad", Size = Vector3.new(14, 1, 14), Position = bz + Vector3.new(0, 1, 0),
		Color = Color3.fromRGB(200, 40, 50), Material = Enum.Material.Neon, Parent = hub })
	bossPad:SetAttribute("BossPad", true); CollectionService:AddTag(bossPad, "BossPad")
	label(bossPad, "💀 SUMMON BOSS", Color3.fromRGB(255, 110, 120))
	for i = 0, 5 do
		local a = (i / 6) * math.pi * 2
		Decor.lamp(bz + Vector3.new(math.cos(a) * 26, 0, math.sin(a) * 26), hub, Color3.fromRGB(255, 80, 50))
	end

	-- hidden gifts tucked behind foliage around the hub
	for _, gp in ipairs({ Vector3.new(-90, 0, 30), Vector3.new(95, 0, -50), Vector3.new(-40, 0, 80), Vector3.new(60, 0, 70), Vector3.new(-110, 0, -60) }) do
		hiddenGift(gp, hub)
	end

	-- some scattered crates/barrels for early smashing right in the plaza
	for i = 1, 10 do
		local a = (i / 10) * math.pi * 2
		breakable(Vector3.new(math.cos(a) * 30, 0, math.sin(a) * 30 + 6), hub, "DuckDroppings", 6, 40)
		if i % 3 == 0 then Decor.barrel(Vector3.new(math.cos(a) * 36, 0, math.sin(a) * 36 + 6), hub) end
	end

	-- ===== BIOMES (each richly themed) =====
	for _, b in ipairs(BiomeConfig.List) do
		local origin = BiomeConfig.origin(b)
		local folder = Instance.new("Folder"); folder.Name = b.id; folder.Parent = world
		-- larger floor + decorative border
		part({ Name = "Floor", Size = Vector3.new(180, 2, 180), Position = origin + Vector3.new(0, -1, 0),
			Color = b.color, Material = Enum.Material.Grass, Parent = folder })
		local bsign = part({ Name = "Sign", Size = Vector3.new(50, 12, 1), Position = origin + Vector3.new(0, 8, -74),
			Color = Color3.fromRGB(30, 30, 38), Parent = folder })
		label(bsign, b.name, b.color)
		Decor.arch(origin + Vector3.new(0, 0, -60), folder, b.color, b.name)

		-- triple the breakables, spread across a wide field
		local crates = (b.crates or 8) * 3
		for i = 1, crates do
			local ang = (i / crates) * math.pi * 2
			local r = 24 + (i % 4) * 12
			breakable(origin + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r), folder, b.currency, b.reward, b.hp,
				b.color:Lerp(Color3.new(0,0,0), 0.3))
		end

		-- biome-themed foliage/props
		Decor.scatter(origin, folder, 22, 50, 86, function(pos, par)
			Decor.tree(pos, par, 0.7 + math.random() * 0.9, b.color:Lerp(Color3.fromRGB(60,150,70), 0.5))
		end)
		Decor.scatter(origin, folder, 30, 46, 86, function(pos, par) Decor.bush(pos, par, b.color:Lerp(Color3.fromRGB(70,140,75),0.5)) end)
		Decor.scatter(origin, folder, 18, 48, 86, function(pos, par) Decor.rock(pos, par, 0.8 + math.random()) end)
		for i = 0, 5 do
			local a = (i / 6) * math.pi * 2
			Decor.lamp(origin + Vector3.new(math.cos(a) * 40, 0, math.sin(a) * 40), folder, b.color)
		end
		-- a hidden gift per biome
		hiddenGift(origin + Vector3.new(70, 0, 70), folder)

		local back = pad("Back_" .. b.id, origin + Vector3.new(0, 0.5, -50), Color3.fromRGB(120, 200, 255), "hub", folder)
		label(back, "↩ Back to Garage", Color3.fromRGB(150, 210, 255))
	end
end

return HubBuilder
