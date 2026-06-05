-- src/shared/DuckGenerator.lua  | every dispenser (crate/claw/pond/gumball) calls roll()
local HttpService = game:GetService("HttpService")
local DuckSchema = require(script.Parent.DuckSchema)

local DuckGenerator = {}

local function weightedPick(list, rng)
	local total = 0
	for _, o in ipairs(list) do total += (o.weight or 1) end
	local r, acc = rng:NextNumber(0, total), 0
	for _, o in ipairs(list) do
		acc += (o.weight or 1)
		if r <= acc then return o end
	end
	return list[#list]
end

local function pickRarity(rng, luckMul)
	luckMul = luckMul or 1
	local total = 0
	for _, r in ipairs(DuckSchema.Rarities) do total += r.weight * (r.tier >= 4 and luckMul or 1) end
	local roll, acc = rng:NextNumber(0, total), 0
	for _, r in ipairs(DuckSchema.Rarities) do
		acc += r.weight * (r.tier >= 4 and luckMul or 1)
		if roll <= acc then return r end
	end
	return DuckSchema.Rarities[1]
end

function DuckGenerator.newId()
	return HttpService:GenerateGUID(false)
end

function DuckGenerator.computeWorth(duck)
	local rarity = DuckSchema.getRarity(duck.rarity)
	local worth = rarity and rarity.value or 1
	for _, dim in ipairs(DuckSchema.RollOrder) do
		local opt = DuckSchema.findOption(dim, duck.parts[dim])
		if opt and opt.mul then worth *= opt.mul end
	end
	if duck.shiny then worth *= 3 end
	return math.floor(worth + 0.5)
end

function DuckGenerator.computeStrength(duck)
	local rarity = DuckSchema.getRarity(duck.rarity)
	local mul = 1
	for _, dim in ipairs(DuckSchema.RollOrder) do
		local opt = DuckSchema.findOption(dim, duck.parts[dim])
		if opt and opt.mul then mul *= opt.mul end
	end
	local base = rarity and rarity.tier or 1
	return math.max(1, math.floor(base * 4 * mul * (duck.shiny and 2 or 1) + 0.5))
end

-- opts: { rng, luckMul, goldenChance, origin, forceRarity, tier }
function DuckGenerator.roll(opts)
	opts = opts or {}
	local rng = opts.rng or Random.new()
	local duck = {
		id = DuckGenerator.newId(),
		rarity = opts.forceRarity or pickRarity(rng, opts.luckMul).name,
		parts = {},
		origin = opts.origin or "wild",
		shiny = rng:NextNumber() < (opts.goldenChance or 0.01),
		tier = opts.tier or "Small",   -- Small/Huge/Gigantic/Titanic
	}
	for _, dim in ipairs(DuckSchema.RollOrder) do
		local pool = {}
		for _, o in ipairs(DuckSchema.Dimensions[dim]) do
			if not o.forgeOnly then table.insert(pool, o) end
		end
		duck.parts[dim] = weightedPick(pool, rng).name
	end
	duck.worth = DuckGenerator.computeWorth(duck)
	duck.strength = DuckGenerator.computeStrength(duck)
	duck.level = 0
	duck.enchants = {} -- { {type="power"|"luck"|"earn", power=n}, ... }
	return duck
end

-- tier stat multipliers (Section 1 spec)
DuckGenerator.Tiers = {
	Small    = { dmg = 1,   coin = 1,   luck = 1,   scale = 0.5 },
	Huge     = { dmg = 5,   coin = 3,   luck = 1.5, scale = 2.0 },
	Gigantic = { dmg = 25,  coin = 10,  luck = 2.5, scale = 4.0 },
	Titanic  = { dmg = 150, coin = 50,  luck = 5.0, scale = 8.0 },
}

-- effective combat strength factoring in level + power enchants + tier
function DuckGenerator.effectiveStrength(duck)
	local base = duck.strength or DuckGenerator.computeStrength(duck)
	local lvlMul = 1 + (duck.level or 0) * 0.12
	local enchantPower = 0
	for _, e in ipairs(duck.enchants or {}) do
		if e.type == "power" then enchantPower += (e.power or 0) end
	end
	local tier = DuckGenerator.Tiers[duck.tier or "Small"] or DuckGenerator.Tiers.Small
	return math.floor((base * lvlMul + enchantPower) * tier.dmg + 0.5)
end

return DuckGenerator
