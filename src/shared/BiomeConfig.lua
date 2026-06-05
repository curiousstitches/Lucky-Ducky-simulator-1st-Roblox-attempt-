-- src/shared/BiomeConfig.lua  | the Jeep-trail worlds, in unlock order
local BiomeConfig = {}

local SPACING = 300 -- studs between biome platforms along +Z

BiomeConfig.List = {
	{ index = 1, id = "MuddyTrailhead", name = "Muddy Trailhead", currency = "DuckDroppings",  reward = 5,   hp = 60,    crates = 14, color = Color3.fromRGB(78,60,40),  unlockCost = nil,                                       minRebirths = 0 },
	{ index = 2, id = "RockCrawl",      name = "Rock-Crawl Canyon", currency = "CanyonCrystals", reward = 8,   hp = 200,   crates = 14, color = Color3.fromRGB(90,84,76),  unlockCost = { currency = "DuckDroppings", amount = 5000 },     minRebirths = 0 },
	{ index = 3, id = "DuneRun",        name = "Dune Run",         currency = "DuneCoins",      reward = 20,  hp = 800,   crates = 14, color = Color3.fromRGB(214,182,120), unlockCost = { currency = "DuckDroppings", amount = 50000 },    minRebirths = 0 },
	{ index = 4, id = "SnowPass",       name = "Snow Pass",        currency = "FrostFlakes",    reward = 60,  hp = 4000,  crates = 14, color = Color3.fromRGB(225,235,245), unlockCost = { currency = "DuckDroppings", amount = 500000 },   minRebirths = 1 },
	{ index = 5, id = "NightTrail",     name = "Night Trail",      currency = "NightShards",    reward = 200, hp = 25000, crates = 14, color = Color3.fromRGB(40,38,60),  unlockCost = { currency = "DuckDroppings", amount = 5000000 },  minRebirths = 3 },
}

BiomeConfig.HubPos = Vector3.new(0, 6, 0)

function BiomeConfig.get(id)
	for _, b in ipairs(BiomeConfig.List) do if b.id == id then return b end end
end

function BiomeConfig.origin(b)
	return Vector3.new(0, 0, b.index * SPACING)
end

function BiomeConfig.spawnPos(b)
	return Vector3.new(0, 6, b.index * SPACING)
end

return BiomeConfig
