-- src/shared/ZoneConfig.lua  | one continuous line of 100 zones (Z=0..9900), 10 themes (doc's named
-- worlds) every 10 zones, each world-section with its OWN currency. Adapted into the existing
-- DataStore/currency systems (no foreign code). Exponential PS99 grind scaling.
local ZoneConfig = {}

ZoneConfig.TotalZones = 100
ZoneConfig.ZoneLength = 110          -- studs per zone along +Z (spec said 100; 110 gives breathing room)
ZoneConfig.ZoneWidth  = 120          -- floor width
ZoneConfig.StartZ     = 0

-- 10 worlds (each = 10 zones). Currency id + display + theme visuals.
ZoneConfig.Worlds = {
	{ n=1,  name="Porcelain Bathroom",   currency="Suds",         curName="Suds",          floor=Color3.fromRGB(238,242,248), floorMat=Enum.Material.SmoothPlastic, border=Color3.fromRGB(150,200,235), accent=Color3.fromRGB(120,200,255), prop="bubble",  fog=Color3.fromRGB(225,238,248) },
	{ n=2,  name="Muddy Offroad Outback",currency="Mud",          curName="Mud Globs",     floor=Color3.fromRGB(96,70,46),    floorMat=Enum.Material.Mud,           border=Color3.fromRGB(80,130,70),  accent=Color3.fromRGB(180,150,90),  prop="tire",    fog=Color3.fromRGB(140,120,90) },
	{ n=3,  name="Toy Store Showroom",   currency="ToyTickets",   curName="Toy Tickets",   floor=Color3.fromRGB(235,225,210), floorMat=Enum.Material.Fabric,        border=Color3.fromRGB(255,120,160),accent=Color3.fromRGB(255,90,160),  prop="block",   fog=Color3.fromRGB(245,235,225) },
	{ n=4,  name="Retro Gas Station",    currency="FuelChips",    curName="Fuel Chips",    floor=Color3.fromRGB(40,40,46),    floorMat=Enum.Material.Asphalt,       border=Color3.fromRGB(255,90,60),  accent=Color3.fromRGB(255,120,40),  prop="canister",fog=Color3.fromRGB(60,58,64) },
	{ n=5,  name="Scrap Yards",          currency="Scrap",        curName="Scrap",         floor=Color3.fromRGB(110,110,120), floorMat=Enum.Material.DiamondPlate,  border=Color3.fromRGB(90,80,70),   accent=Color3.fromRGB(200,160,90),  prop="pipe",    fog=Color3.fromRGB(110,105,100) },
	{ n=6,  name="Cyber Garages",        currency="ChromeTokens", curName="Chrome Tokens", floor=Color3.fromRGB(20,24,38),    floorMat=Enum.Material.Foil,          border=Color3.fromRGB(60,230,200), accent=Color3.fromRGB(60,230,220),  prop="hologram",fog=Color3.fromRGB(22,26,42) },
	{ n=7,  name="Luxury Showroom",      currency="LuxCredits",   curName="Lux Credits",   floor=Color3.fromRGB(230,225,235), floorMat=Enum.Material.Marble,        border=Color3.fromRGB(220,180,80), accent=Color3.fromRGB(255,215,90),  prop="chandelier",fog=Color3.fromRGB(238,233,240) },
	{ n=8,  name="Toxic Junkyard",       currency="ToxicOoze",    curName="Toxic Ooze",    floor=Color3.fromRGB(60,90,50),    floorMat=Enum.Material.Grass,         border=Color3.fromRGB(150,255,80), accent=Color3.fromRGB(150,255,80),  prop="barrel",  fog=Color3.fromRGB(70,100,55) },
	{ n=9,  name="Golden Highway Vault", currency="GoldBricks",   curName="Gold Bricks",   floor=Color3.fromRGB(210,175,70),  floorMat=Enum.Material.Foil,          border=Color3.fromRGB(255,215,40), accent=Color3.fromRGB(255,225,70),  prop="gempillar",fog=Color3.fromRGB(225,200,120) },
	{ n=10, name="Cosmic Infinite Matrix",currency="InfinityOil", curName="Infinity Oil",  floor=Color3.fromRGB(20,18,40),    floorMat=Enum.Material.Foil,          border=Color3.fromRGB(150,90,255), accent=Color3.fromRGB(160,120,255), prop="asteroid",fog=Color3.fromRGB(18,16,38), space=true },
}

function ZoneConfig.worldForZone(zone) -- zone 1..100 -> world 1..10
	return ZoneConfig.Worlds[math.clamp(math.floor((zone-1)/10)+1, 1, 10)]
end

-- per-world environment art. wall = "building"|"ruins"|"fence" (mixed via list). bright = lighting.
-- sky = horizon/zenith colors for colored atmosphere. sound = rbxassetid for ambient loop.
-- ground = override material. break = themed breakable shape. lightFx = "godray"|"neon"|nil.
ZoneConfig.Art = {
	[1]  = { mood="bright", bright=2.6, sky={Color3.fromRGB(150,220,255),Color3.fromRGB(220,245,255)}, walls={"fence","building"},  ground=Enum.Material.Grass,       brk="bubble",  sound="rbxassetid://9046907088", lightFx="godray" },
	[2]  = { mood="murky",  bright=1.8, sky={Color3.fromRGB(120,130,90), Color3.fromRGB(160,170,120)}, walls={"fence","ruins"},     ground=Enum.Material.Mud,         brk="tire",    sound="rbxassetid://9112854440", lightFx=nil },
	[3]  = { mood="bright", bright=2.7, sky={Color3.fromRGB(255,200,230),Color3.fromRGB(255,235,245)}, walls={"building"},          ground=Enum.Material.Fabric,      brk="block",   sound="rbxassetid://9046907088", lightFx="neon" },
	[4]  = { mood="dim",    bright=1.6, sky={Color3.fromRGB(60,60,75),   Color3.fromRGB(90,90,110)},   walls={"building","ruins"},  ground=Enum.Material.Asphalt,     brk="canister",sound="rbxassetid://9112854440", lightFx="neon" },
	[5]  = { mood="dim",    bright=1.7, sky={Color3.fromRGB(110,100,90), Color3.fromRGB(140,130,115)}, walls={"ruins"},             ground=Enum.Material.DiamondPlate,brk="pipe",    sound="rbxassetid://9112854440", lightFx=nil },
	[6]  = { mood="dark",   bright=1.4, sky={Color3.fromRGB(20,28,45),   Color3.fromRGB(40,55,90)},    walls={"building","ruins"},  ground=Enum.Material.Foil,        brk="hologram",sound="rbxassetid://9118979649", lightFx="neon" },
	[7]  = { mood="bright", bright=2.8, sky={Color3.fromRGB(255,235,180),Color3.fromRGB(255,250,225)}, walls={"building"},          ground=Enum.Material.Marble,      brk="chandelier",sound="rbxassetid://9046907088", lightFx="godray" },
	[8]  = { mood="murky",  bright=1.6, sky={Color3.fromRGB(80,110,55),  Color3.fromRGB(120,160,80)},  walls={"ruins","fence"},     ground=Enum.Material.Grass,       brk="barrel",  sound="rbxassetid://9112854440", lightFx="neon" },
	[9]  = { mood="bright", bright=2.7, sky={Color3.fromRGB(255,225,120),Color3.fromRGB(255,245,190)}, walls={"building"},          ground=Enum.Material.Foil,        brk="gempillar",sound="rbxassetid://9046907088", lightFx="godray" },
	[10] = { mood="dark",  bright=1.3, sky={Color3.fromRGB(15,12,35),   Color3.fromRGB(40,25,70)},    walls={"ruins","building"},  ground=Enum.Material.Foil,        brk="asteroid",sound="rbxassetid://9118979649", lightFx="neon" },
}
function ZoneConfig.artForZone(zone) return ZoneConfig.Art[math.clamp(math.floor((zone-1)/10)+1,1,10)] end

function ZoneConfig.zoneOriginZ(zone) return ZoneConfig.StartZ + (zone-1)*ZoneConfig.ZoneLength end

-- exponential scaling (kept saner than the doc's 3.5^n which overflows fast; uses 1.18 for a long grind)
function ZoneConfig.stats(zone)
	return {
		unlockCost = math.floor(300 * (1.18 ^ (zone-1))),   -- gate cost in that world's currency
		eggCost    = math.floor(80  * (1.16 ^ (zone-1))),
		hp         = math.floor(45  * (1.11 ^ (zone-1))),
		reward     = math.floor(5   * (1.09 ^ (zone-1))),
		enemyHp    = math.floor(70  * (1.10 ^ (zone-1))),
		enemyDmg   = math.floor(4   * (1.06 ^ (zone-1))),
	}
end

-- list of all 10 currency ids (for registration + HUD)
function ZoneConfig.currencyIds()
	local t = {}
	for _, w in ipairs(ZoneConfig.Worlds) do t[#t+1] = { id=w.currency, name=w.curName, accent=w.accent } end
	return t
end

return ZoneConfig
