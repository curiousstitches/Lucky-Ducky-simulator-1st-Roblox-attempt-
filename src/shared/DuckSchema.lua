-- src/shared/DuckSchema.lua  | single source of truth for every duck attribute
local DuckSchema = {}

-- Rarity ladder. weight = relative roll chance, value = base worth, tier = ordinal (1..7)
DuckSchema.Rarities = {
	{ name = "Common",    weight = 1000, value = 5,     tier = 1, color = Color3.fromRGB(180,180,180) },
	{ name = "Uncommon",  weight = 450,  value = 18,    tier = 2, color = Color3.fromRGB(110,210,120) },
	{ name = "Rare",      weight = 160,  value = 60,    tier = 3, color = Color3.fromRGB(80,150,255) },
	{ name = "Epic",      weight = 55,   value = 220,   tier = 4, color = Color3.fromRGB(180,90,255) },
	{ name = "Legendary", weight = 14,   value = 900,   tier = 5, color = Color3.fromRGB(255,180,40) },
	{ name = "Mythic",    weight = 3,    value = 4200,  tier = 6, color = Color3.fromRGB(255,70,90) },
	{ name = "Secret",    weight = 1,    value = 25000, tier = 7, color = Color3.fromRGB(20,20,20) },
}

-- Procedural axes. mul = worth multiplier, weight = roll bias (default 1), forgeOnly = craft-exclusive
DuckSchema.Dimensions = {
	Body = {
		{ name = "Classic", mul = 1.0, weight = 4 }, { name = "Chonk", mul = 1.1 },
		{ name = "Tiny", mul = 1.1 }, { name = "Tall", mul = 1.15 },
		{ name = "Slime", mul = 1.4, weight = 0.4 }, { name = "Crystal", mul = 1.8, weight = 0.2 },
		{ name = "Mecha", mul = 2.2, weight = 0.12 }, { name = "Ghost", mul = 2.0, weight = 0.15 },
		{ name = "Lava", mul = 2.4, weight = 0.1 }, { name = "Cloud", mul = 1.9, weight = 0.18 },
		{ name = "Cyborg", mul = 2.6, weight = 0.08 }, { name = "Plush", mul = 1.3, weight = 0.5 },
		{ name = "Golden Idol", mul = 3.5, forgeOnly = true },
		{ name = "Diamond Core", mul = 4.2, forgeOnly = true },
	},
	Head = {
		{ name = "None", mul = 1.0, weight = 3 }, { name = "Cowboy Hat", mul = 1.1 },
		{ name = "Helmet", mul = 1.1 }, { name = "Propeller Cap", mul = 1.2 },
		{ name = "Antlers", mul = 1.25 }, { name = "Crown", mul = 1.6, weight = 0.3 },
		{ name = "Halo", mul = 1.7, weight = 0.2 },
		{ name = "Jeep Roof Rack", mul = 2.5, forgeOnly = true },
	},
	Face = {
		{ name = "Default", mul = 1.0, weight = 3 }, { name = "Cool Shades", mul = 1.15 },
		{ name = "Derp", mul = 1.05 }, { name = "Kawaii", mul = 1.2 },
		{ name = "Angry", mul = 1.1 }, { name = "Skull", mul = 1.5, weight = 0.3 },
		{ name = "Star Eyes", mul = 1.35, weight = 0.4 }, { name = "Sleepy", mul = 1.05 },
		{ name = "Robot Visor", mul = 1.6, weight = 0.25 }, { name = "Heart Eyes", mul = 1.3, weight = 0.4 },
	},
	Color = {
		{ name = "Bath Yellow", hex = Color3.fromRGB(255,221,51), mul = 1.0, weight = 4 },
		{ name = "Trail Orange", hex = Color3.fromRGB(240,120,30), mul = 1.05 },
		{ name = "Mud Brown", hex = Color3.fromRGB(110,75,45), mul = 1.05 },
		{ name = "Forest Green", hex = Color3.fromRGB(40,120,60), mul = 1.1 },
		{ name = "River Blue", hex = Color3.fromRGB(50,140,210), mul = 1.1 },
		{ name = "Sunset Pink", hex = Color3.fromRGB(245,120,170), mul = 1.2 },
		{ name = "Midnight", hex = Color3.fromRGB(30,30,55), mul = 1.3, weight = 0.5 },
		{ name = "Trail Rainbow", hex = Color3.fromRGB(255,255,255), mul = 2.4, forgeOnly = true },
	},
	Shimmer = {
		{ name = "Matte", mul = 1.0, weight = 4 }, { name = "Glossy", mul = 1.1 },
		{ name = "Metallic", mul = 1.3 }, { name = "Holographic", mul = 1.7, weight = 0.4 },
		{ name = "Prismatic", mul = 2.2, weight = 0.2 }, { name = "Galaxy", mul = 2.6, weight = 0.1 },
		{ name = "Liquid Chrome", mul = 3.0, forgeOnly = true },
	},
	Particle = {
		{ name = "None", mul = 1.0, weight = 5 }, { name = "Sparkle", mul = 1.2 },
		{ name = "Bubbles", mul = 1.15 }, { name = "Flame", mul = 1.4, weight = 0.5 },
		{ name = "Lightning", mul = 1.6, weight = 0.35 }, { name = "Stardust", mul = 2.0, weight = 0.15 },
		{ name = "Hearts", mul = 1.3, weight = 0.4 }, { name = "Snow", mul = 1.35, weight = 0.35 },
		{ name = "Confetti", mul = 1.5, weight = 0.25 }, { name = "Smoke", mul = 1.25, weight = 0.4 },
		{ name = "Aurora", mul = 2.8, forgeOnly = true },
		{ name = "Black Hole", mul = 3.6, forgeOnly = true },
	},
}

DuckSchema.RollOrder = { "Body", "Head", "Face", "Color", "Shimmer", "Particle" }

-- Forge tiers: forgePoints -> output rarity + which dims the player may edit. ascending order.
DuckSchema.ForgeTiers = {
	{ minPoints = 0,      outRarity = "Common",    edits = {"Color"} },
	{ minPoints = 500,    outRarity = "Uncommon",  edits = {"Color","Face"} },
	{ minPoints = 2500,   outRarity = "Rare",      edits = {"Color","Face","Shimmer"} },
	{ minPoints = 9000,   outRarity = "Epic",      edits = {"Color","Face","Shimmer","Head"} },
	{ minPoints = 30000,  outRarity = "Legendary", edits = {"Color","Face","Shimmer","Head","Particle"} },
	{ minPoints = 120000, outRarity = "Mythic",    edits = {"Color","Face","Shimmer","Head","Particle","Body"}, forgeExclusive = true },
	{ minPoints = 500000, outRarity = "Secret",    edits = {"Color","Face","Shimmer","Head","Particle","Body"}, forgeExclusive = true },
}

function DuckSchema.getRarity(name)
	for _, r in ipairs(DuckSchema.Rarities) do if r.name == name then return r end end
end
function DuckSchema.findOption(dim, name)
	for _, o in ipairs(DuckSchema.Dimensions[dim] or {}) do if o.name == name then return o end end
end
function DuckSchema.forgeTierForPoints(points)
	local chosen = DuckSchema.ForgeTiers[1]
	for _, t in ipairs(DuckSchema.ForgeTiers) do
		if points >= t.minPoints then chosen = t else break end
	end
	return chosen
end

return DuckSchema
