-- src/shared/WorldConfig.lua  | procedurally defines hundreds of scaling levels across 3 worlds,
-- with shops/features/clan/secrets scattered and balanced low->advanced as you climb.
local WorldConfig = {}

WorldConfig.Worlds = {
	{ index = 1, id = "TrailheadValley", name = "Trailhead Valley", levels = 100, baseColor = Color3.fromRGB(96, 140, 90),  currency = "DuckDroppings" },
	{ index = 2, id = "CanyonExpanse",   name = "Canyon Expanse",   levels = 100, baseColor = Color3.fromRGB(150, 110, 80), currency = "CanyonCrystals" },
	{ index = 3, id = "AuroraReaches",   name = "Aurora Reaches",   levels = 100, baseColor = Color3.fromRGB(90, 80, 150),  currency = "NightShards" },
}
WorldConfig.LevelsPerWorld = 100
WorldConfig.TotalLevels = 300
WorldConfig.LevelSpacing = 120   -- studs between level platforms (Z axis within a world)
WorldConfig.WorldSpacing = 16000 -- studs between worlds (X axis)

-- deterministic per-level definition (same every server, no storage needed)
function WorldConfig.levelDef(globalLevel)
	globalLevel = math.clamp(globalLevel, 1, WorldConfig.TotalLevels)
	local worldIdx = math.min(3, math.floor((globalLevel - 1) / WorldConfig.LevelsPerWorld) + 1)
	local world = WorldConfig.Worlds[worldIdx]
	local local_ = ((globalLevel - 1) % WorldConfig.LevelsPerWorld) + 1

	-- scaling curves
	local hp     = math.floor(40 * (1.12 ^ (globalLevel - 1)))
	local reward = math.floor(4 * (1.085 ^ (globalLevel - 1)))
	-- gate cost to ENTER this level (grind wall), scales hard
	local gateCost = math.floor(120 * (1.16 ^ (globalLevel - 1)))

	-- scattered, balanced feature on some levels (deterministic but varied)
	local feature = nil
	local r = (globalLevel * 2654435761) % 100 -- cheap deterministic hash 0-99
	if local_ == 1 then feature = "worldgate"            -- world entrances
	elseif globalLevel % 25 == 0 then feature = "clan"   -- clan hubs every 25
	elseif globalLevel % 10 == 0 then feature = "boss"   -- mini-boss arenas every 10
	elseif r < 6 then feature = "shop"                   -- ~6% shops
	elseif r < 10 then feature = "secret"                -- ~4% secret rooms
	elseif r < 16 then feature = "egglab"                -- ~6% extra egg machines
	end

	return {
		level = globalLevel, world = world, worldIndex = worldIdx, localLevel = local_,
		hp = hp, reward = reward, gateCost = gateCost, currency = world.currency, feature = feature,
		color = world.baseColor,
	}
end

function WorldConfig.levelOrigin(globalLevel)
	local def = WorldConfig.levelDef(globalLevel)
	local x = (def.worldIndex - 1) * WorldConfig.WorldSpacing
	local z = def.localLevel * WorldConfig.LevelSpacing
	return Vector3.new(x, 0, z)
end

return WorldConfig
