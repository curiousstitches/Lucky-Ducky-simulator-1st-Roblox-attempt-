-- src/shared/ThemeConfig.lua  | every 10 levels = a new themed zone (PS99-style linear progression).
-- Each theme drives floor color/material, prop palette, fog, breakable look, and currency flavor.
local ThemeConfig = {}

-- 50 themes -> 500 levels (10 levels each). Cycles/extends gracefully past that.
ThemeConfig.LevelsPerTheme = 10
ThemeConfig.RebirthEvery = 20      -- a rebirth shrine every 20 levels
ThemeConfig.LevelSpacing = 90      -- studs between level platforms (big spacing)
ThemeConfig.PlatformSize = 60      -- each level platform footprint

-- palette helper fields: floor, floorMat, accent, prop ("tree"/"rock"/"crystal"/"mushroom"/"coral"/"cactus"/"star"/"candy"/"gear"/"bone"),
-- fog (Color3), breakMat, currency (display flavor)
ThemeConfig.Themes = {
	{ name = "Sunny Meadow",   floor = Color3.fromRGB(120,200,110), floorMat = Enum.Material.Grass,      accent = Color3.fromRGB(255,220,80),  prop = "tree",     fog = Color3.fromRGB(190,220,235), breakMat = Enum.Material.Wood , currency = "DuckDroppings" },
	{ name = "Crystal Caverns",floor = Color3.fromRGB(70,80,120),   floorMat = Enum.Material.Slate,      accent = Color3.fromRGB(130,200,255), prop = "crystal",  fog = Color3.fromRGB(80,90,140),   breakMat = Enum.Material.Glass , currency = "CrystalDroppings" },
	{ name = "Sandy Dunes",    floor = Color3.fromRGB(225,200,130), floorMat = Enum.Material.Sand,       accent = Color3.fromRGB(255,170,60),  prop = "cactus",   fog = Color3.fromRGB(240,225,180), breakMat = Enum.Material.Sandstone , currency = "DesertDroppings" },
	{ name = "Frozen Tundra",  floor = Color3.fromRGB(210,235,250), floorMat = Enum.Material.Glacier,    accent = Color3.fromRGB(150,220,255), prop = "tree",     fog = Color3.fromRGB(220,240,255), breakMat = Enum.Material.Ice , currency = "FrostDroppings" },
	{ name = "Candy Land",     floor = Color3.fromRGB(255,180,220), floorMat = Enum.Material.SmoothPlastic, accent = Color3.fromRGB(255,90,160), prop = "candy",  fog = Color3.fromRGB(255,210,235), breakMat = Enum.Material.Neon , currency = "CandyDroppings" },
	{ name = "Lava Fields",    floor = Color3.fromRGB(60,30,30),    floorMat = Enum.Material.Basalt,     accent = Color3.fromRGB(255,90,30),   prop = "rock",     fog = Color3.fromRGB(120,50,40),   breakMat = Enum.Material.CrackedLava , currency = "LavaDroppings" },
	{ name = "Deep Ocean",     floor = Color3.fromRGB(30,90,140),   floorMat = Enum.Material.Sand,       accent = Color3.fromRGB(70,200,220),  prop = "coral",    fog = Color3.fromRGB(30,110,160),  breakMat = Enum.Material.Glass, underwater = true , currency = "OceanDroppings" },
	{ name = "Mushroom Grove", floor = Color3.fromRGB(90,140,90),   floorMat = Enum.Material.Grass,      accent = Color3.fromRGB(255,120,200), prop = "mushroom", fog = Color3.fromRGB(140,170,150), breakMat = Enum.Material.Wood , currency = "SporeDroppings" },
	{ name = "Outer Space",    floor = Color3.fromRGB(25,20,45),    floorMat = Enum.Material.Foil,       accent = Color3.fromRGB(180,120,255), prop = "star",     fog = Color3.fromRGB(20,15,40),    breakMat = Enum.Material.Neon, space = true , currency = "CosmicDroppings" },
	{ name = "Tech Grid",      floor = Color3.fromRGB(30,40,55),    floorMat = Enum.Material.DiamondPlate, accent = Color3.fromRGB(60,230,200), prop = "gear",   fog = Color3.fromRGB(30,45,60),    breakMat = Enum.Material.Metal , currency = "TechnicalDroppings" },
	{ name = "Golden Temple",  floor = Color3.fromRGB(200,170,80),  floorMat = Enum.Material.Marble,     accent = Color3.fromRGB(255,215,40),  prop = "rock",     fog = Color3.fromRGB(230,210,150), breakMat = Enum.Material.Foil , currency = "GildedDroppings" },
	{ name = "Toxic Swamp",    floor = Color3.fromRGB(80,110,60),   floorMat = Enum.Material.Mud,        accent = Color3.fromRGB(160,255,80),  prop = "mushroom", fog = Color3.fromRGB(90,120,70),   breakMat = Enum.Material.Slate , currency = "ToxicDroppings" },
	{ name = "Cloud Kingdom",  floor = Color3.fromRGB(235,240,255), floorMat = Enum.Material.SmoothPlastic, accent = Color3.fromRGB(255,255,255), prop = "tree", fog = Color3.fromRGB(240,245,255), breakMat = Enum.Material.Neon , currency = "CloudDroppings" },
	{ name = "Volcano Core",   floor = Color3.fromRGB(50,25,25),    floorMat = Enum.Material.Rock,       accent = Color3.fromRGB(255,140,30),  prop = "crystal",  fog = Color3.fromRGB(110,45,35),   breakMat = Enum.Material.CrackedLava , currency = "MagmaDroppings" },
	{ name = "Neon City",      floor = Color3.fromRGB(20,20,35),    floorMat = Enum.Material.SmoothPlastic, accent = Color3.fromRGB(255,40,200), prop = "gear",  fog = Color3.fromRGB(25,20,45),    breakMat = Enum.Material.Neon , currency = "NeonDroppings" },
	{ name = "Bone Desert",    floor = Color3.fromRGB(210,195,160), floorMat = Enum.Material.Sand,       accent = Color3.fromRGB(230,220,200), prop = "bone",     fog = Color3.fromRGB(225,215,185), breakMat = Enum.Material.Sandstone , currency = "BoneDroppings" },
	{ name = "Coral Reef",     floor = Color3.fromRGB(40,120,160),  floorMat = Enum.Material.Sand,       accent = Color3.fromRGB(255,140,160), prop = "coral",    fog = Color3.fromRGB(40,140,180),  breakMat = Enum.Material.Glass, underwater = true , currency = "CoralDroppings" },
	{ name = "Galaxy Edge",    floor = Color3.fromRGB(30,25,55),    floorMat = Enum.Material.Foil,       accent = Color3.fromRGB(120,200,255), prop = "star",     fog = Color3.fromRGB(25,20,50),    breakMat = Enum.Material.Neon, space = true , currency = "GalacticDroppings" },
	{ name = "Rainbow Road",   floor = Color3.fromRGB(120,120,200), floorMat = Enum.Material.Neon,       accent = Color3.fromRGB(255,255,255), prop = "crystal",  fog = Color3.fromRGB(180,180,230), breakMat = Enum.Material.Neon , currency = "PrismDroppings" },
	{ name = "Diamond Mine",   floor = Color3.fromRGB(120,140,160), floorMat = Enum.Material.Slate,      accent = Color3.fromRGB(190,240,255), prop = "crystal",  fog = Color3.fromRGB(120,140,165), breakMat = Enum.Material.Glass , currency = "DiamondDroppings" },
}

-- 1-indexed global level -> theme record (cycles through the list for very high levels)
function ThemeConfig.forLevel(level)
	local idx = math.floor((level - 1) / ThemeConfig.LevelsPerTheme) % #ThemeConfig.Themes + 1
	return ThemeConfig.Themes[idx], idx
end

function ThemeConfig.isRebirthLevel(level)
	return level % ThemeConfig.RebirthEvery == 0
end

return ThemeConfig
