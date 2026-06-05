-- src/shared/Currencies.lua  | single source of truth for every currency
local Currencies = {}

-- ShimmerSplats = premium currency, styled as poop 💩 (the "Diamonds" of this game).
-- Every theme has its OWN local "droppings" currency (true PS99 local economy): id Theme1Droppings..Theme20Droppings.
-- The themed names live in ThemeConfig (each theme has a `currency` + `currencyName`); ids here must match.
Currencies.List = {
	{ id = "ShimmerSplats",  name = "Shimmer Splats",  kind = "premium", color = Color3.fromRGB(150,110,60), icon = "💩" },
	{ id = "DuckDroppings",  name = "Duck Droppings",  kind = "soft",    color = Color3.fromRGB(150,110,60) }, -- legacy/hub fallback
	-- FishCoins kept for the fishing minigame
	{ id = "FishCoins",      name = "Fish Coins",      kind = "biome", color = Color3.fromRGB(90,200,230) },
}

-- themed local currencies (one per theme). name comes from ThemeConfig; color tints to theme accent.
Currencies.ThemeCurrencies = {
	"DuckDroppings", "CrystalDroppings", "DesertDroppings", "FrostDroppings", "CandyDroppings",
	"LavaDroppings", "OceanDroppings", "SporeDroppings", "CosmicDroppings", "TechnicalDroppings",
	"GildedDroppings", "ToxicDroppings", "CloudDroppings", "MagmaDroppings", "NeonDroppings",
	"BoneDroppings", "CoralDroppings", "GalacticDroppings", "PrismDroppings", "DiamondDroppings",
}

-- register each themed currency dynamically
for i, id in ipairs(Currencies.ThemeCurrencies) do
	if id ~= "DuckDroppings" then -- DuckDroppings already in List above
		table.insert(Currencies.List, { id = id, name = id:gsub("(%l)(%u)", "%1 %2"), kind = "local", color = Color3.fromRGB(150,120,80) })
	end
end

-- PS99 100-zone world currencies (Suds, Mud, ToyTickets, FuelChips, Scrap, ChromeTokens,
-- LuxCredits, ToxicOoze, GoldBricks, InfinityOil) — each spends only in its world-section.
local ZONE_CURRENCIES = {
	{ id="Suds",         name="Suds",          color=Color3.fromRGB(120,200,255) },
	{ id="Mud",          name="Mud Globs",     color=Color3.fromRGB(150,110,70) },
	{ id="ToyTickets",   name="Toy Tickets",   color=Color3.fromRGB(255,120,160) },
	{ id="FuelChips",    name="Fuel Chips",    color=Color3.fromRGB(255,140,60) },
	{ id="Scrap",        name="Scrap",         color=Color3.fromRGB(190,160,110) },
	{ id="ChromeTokens", name="Chrome Tokens", color=Color3.fromRGB(60,230,210) },
	{ id="LuxCredits",   name="Lux Credits",   color=Color3.fromRGB(255,215,90) },
	{ id="ToxicOoze",    name="Toxic Ooze",    color=Color3.fromRGB(150,255,80) },
	{ id="GoldBricks",   name="Gold Bricks",   color=Color3.fromRGB(255,215,50) },
	{ id="InfinityOil",  name="Infinity Oil",  color=Color3.fromRGB(160,120,255) },
}
for _, c in ipairs(ZONE_CURRENCIES) do
	table.insert(Currencies.List, { id=c.id, name=c.name, kind="local", color=c.color })
end

function Currencies.get(id)
	for _, c in ipairs(Currencies.List) do if c.id == id then return c end end
end

function Currencies.isValid(id)
	return Currencies.get(id) ~= nil
end

return Currencies
