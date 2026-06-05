-- src/shared/SeasonConfig.lua  | season pass: tiers with free + premium rewards
local SeasonConfig = {}

SeasonConfig.SeasonLengthDays = 30
SeasonConfig.XpPerTier = 2500          -- season XP earned per tier (1 XP per Dropping earned this season)
SeasonConfig.PremiumPassKey = "season" -- matches a GamePass perk in ShopConfig (id 0 until you mint it)

-- tier -> { free = grant, premium = grant }  grant: {type, currency, amount} | {type="luck"...}
SeasonConfig.Tiers = {
	{ tier = 1,  free = { currency = "DuckDroppings", amount = 1000 }, premium = { currency = "ShimmerSplats", amount = 10 } },
	{ tier = 2,  free = { currency = "DuckDroppings", amount = 2000 }, premium = { currency = "ShimmerSplats", amount = 12 } },
	{ tier = 3,  free = { currency = "ShimmerSplats", amount = 5 },    premium = { currency = "DuckDroppings", amount = 8000 } },
	{ tier = 4,  free = { currency = "DuckDroppings", amount = 5000 }, premium = { currency = "ShimmerSplats", amount = 18 } },
	{ tier = 5,  free = { currency = "DuckDroppings", amount = 9000 }, premium = { currency = "ShimmerSplats", amount = 25 } },
	{ tier = 6,  free = { currency = "ShimmerSplats", amount = 10 },   premium = { currency = "DuckDroppings", amount = 30000 } },
	{ tier = 7,  free = { currency = "DuckDroppings", amount = 20000 },premium = { currency = "ShimmerSplats", amount = 35 } },
	{ tier = 8,  free = { currency = "DuckDroppings", amount = 35000 },premium = { currency = "ShimmerSplats", amount = 45 } },
	{ tier = 9,  free = { currency = "ShimmerSplats", amount = 20 },   premium = { currency = "DuckDroppings", amount = 120000 } },
	{ tier = 10, free = { currency = "DuckDroppings", amount = 80000 },premium = { currency = "ShimmerSplats", amount = 80 } },
}

function SeasonConfig.currentSeason()
	return math.floor(os.time() / (SeasonConfig.SeasonLengthDays * 86400))
end

function SeasonConfig.seasonEndsAt()
	return (SeasonConfig.currentSeason() + 1) * (SeasonConfig.SeasonLengthDays * 86400)
end

return SeasonConfig
