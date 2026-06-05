-- src/shared/UnlockConfig.lua  | eggs/jeeps, abilities, potions, gift boxes, shops, passes
local UnlockConfig = {}

-- EGGS = JEEPS. Unlock a Jeep -> hatch ducks from it. First 3 free, rest Robux (devProductKey).
UnlockConfig.Eggs = {
	{ id = "wrangler",  name = "Wrangler Egg",   cost = 0,        currency = "DuckDroppings", luck = 1.0, golden = 0.01, free = true },
	{ id = "renegade",  name = "Renegade Egg",   cost = 2500,     currency = "DuckDroppings", luck = 1.2, golden = 0.02, free = true },
	{ id = "rubicon",   name = "Rubicon Egg",    cost = 25000,    currency = "DuckDroppings", luck = 1.5, golden = 0.03, free = true },
	{ id = "gladiator", name = "Gladiator Egg",  cost = 0, currency = "Robux", devProductKey = "egg_gladiator", luck = 2.0, golden = 0.05 },
	{ id = "trackhawk", name = "Trackhawk Egg",  cost = 0, currency = "Robux", devProductKey = "egg_trackhawk", luck = 2.6, golden = 0.08 },
	{ id = "vipgold",   name = "VIP Golden Jeep",cost = 0, currency = "Robux", devProductKey = "egg_vipgold",   luck = 3.4, golden = 0.12, vip = true },
}
UnlockConfig.FreeEggSlots = 3
UnlockConfig.OpenBatches = { 1, 3, 5, 10 } -- x5 and x10 gated behind passes

-- MOVEMENT ABILITIES (buy with currency or Robux). applied client-side, validated server-side.
UnlockConfig.Abilities = {
	{ id = "doublejump", name = "Double Jump", cost = 5000,    currency = "DuckDroppings" },
	{ id = "triplejump", name = "Triple Jump", cost = 50000,   currency = "DuckDroppings" },
	{ id = "wallclimb",  name = "Wall Climb",  cost = 200000,  currency = "DuckDroppings" },
	{ id = "float",      name = "Float",       cost = 750000,  currency = "DuckDroppings" },
	{ id = "dig",        name = "Dig",         cost = 0, currency = "Robux", devProductKey = "ability_dig" },
	{ id = "teleport",   name = "Teleport",    cost = 0, currency = "Robux", devProductKey = "ability_teleport" },
	{ id = "dash",       name = "Speed Dash",  cost = 2000000, currency = "DuckDroppings" },
}

-- POTIONS: stackable, no tap, durations ADD on re-buy. effect read by FarmService/Dispenser.
UnlockConfig.Potions = {
	{ id = "luck_s",  name = "Lucky Potion I",   effect = "luck",  power = 1.5, seconds = 300,  cost = 1500,   currency = "DuckDroppings" },
	{ id = "luck_m",  name = "Lucky Potion II",  effect = "luck",  power = 2.0, seconds = 600,  cost = 6000,   currency = "DuckDroppings" },
	{ id = "luck_l",  name = "Lucky Potion III", effect = "luck",  power = 3.0, seconds = 1200, cost = 25000,  currency = "DuckDroppings" },
	{ id = "earn_s",  name = "Greed Potion I",   effect = "earn",  power = 1.5, seconds = 300,  cost = 1500,   currency = "DuckDroppings" },
	{ id = "earn_m",  name = "Greed Potion II",  effect = "earn",  power = 2.0, seconds = 600,  cost = 6000,   currency = "DuckDroppings" },
	{ id = "speed_m", name = "Speed Potion",     effect = "speed", power = 1.5, seconds = 600,  cost = 4000,   currency = "DuckDroppings" },
	{ id = "mega",    name = "MEGA Potion",      effect = "earn",  power = 5.0, seconds = 1800, cost = 0, currency = "Robux", devProductKey = "potion_mega" },
}

-- GIFT BOXES: found in the world, opened for loot, or sold.
UnlockConfig.GiftTiers = {
	{ id = "common",  name = "Common Gift",  weight = 70, sell = 500,    reward = { currency = "DuckDroppings", min = 800,  max = 2500 } },
	{ id = "rare",    name = "Rare Gift",    weight = 24, sell = 4000,   reward = { currency = "DuckDroppings", min = 5000, max = 18000 } },
	{ id = "epic",    name = "Epic Gift",    weight = 5,  sell = 30000,  reward = { currency = "ShimmerSplats", min = 8,    max = 25 } },
	{ id = "event",   name = "Event Gift",   weight = 1,  sell = 0,      reward = { currency = "ShimmerSplats", min = 30,   max = 60 }, eventOnly = true },
}

-- SHOPS / FEATURES unlocked as you climb (scattered onto "shop" feature levels by WorldConfig)
UnlockConfig.Shops = {
	"Item Shop", "Board Shop", "Pet Shop", "Clothing Shop", "Potion Stand",
	"Gift Emporium", "Ability Trainer", "Trophy Hall", "Mutation Lab", "Auction House",
}

-- GAME PASSES (mint at create.roblox.com, paste id over 0). perks read by MonetizationService.
UnlockConfig.Passes = {
	{ key = "x2forever",  name = "2x Collect Forever", robux = 499, perk = "x2forever" },
	{ key = "open5",      name = "Open 5 Eggs at Once",robux = 299, perk = "open5" },
	{ key = "open10",     name = "Open 10 Eggs at Once",robux = 599, perk = "open10" },
	{ key = "autocollect",name = "Auto-Collect",       robux = 399, perk = "autocollect" },
	{ key = "vipzone",    name = "VIP Pass",           robux = 799, perk = "vip" },
	{ key = "fasttravel", name = "Fast Travel",        robux = 249, perk = "fasttravel" },
	{ key = "luckx2",     name = "2x Luck Forever",    robux = 449, perk = "luckx2" },
}

function UnlockConfig.find(list, id)
	for _, x in ipairs(list) do if x.id == id then return x end end
end

return UnlockConfig
