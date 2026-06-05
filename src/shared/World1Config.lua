-- src/shared/World1Config.lua  | Grassland Odyssey: 100 stages, scaling curves, per-stage layout
-- variety (flat/hills/tunnel/sky-island/water), and shop/upgrade tiering that improves as you climb.
local World1Config = {}

World1Config.Id = "GrasslandOdyssey"
World1Config.Name = "Grassland Odyssey"
World1Config.Stages = 100
World1Config.Currency = "DuckDroppings"      -- local currency (Section spec: per-world)
World1Config.StageSpacing = 110              -- big spacing per your request
World1Config.PlatformSize = 64
World1Config.TravelMechanic = "Giant Rubber Band Slingshot"

-- palette (bright + vibrant, with dark/dingy corners added per-stage)
World1Config.Palette = {
	grass    = Color3.fromRGB(118, 200, 96),
	grassDk  = Color3.fromRGB(70, 140, 70),
	dirt     = Color3.fromRGB(120, 90, 55),
	water    = Color3.fromRGB(70, 170, 220),
	accent   = Color3.fromRGB(255, 220, 90),
	flower   = { Color3.fromRGB(255,120,180), Color3.fromRGB(255,210,70), Color3.fromRGB(150,130,255), Color3.fromRGB(255,140,90) },
	rock     = Color3.fromRGB(120, 122, 130),
	fog      = Color3.fromRGB(200, 225, 200),
}

-- deterministic layout per stage so it's varied but stable across servers
-- types: flat, hills, tunnel, skyisland, water, mixed
function World1Config.layout(stage)
	local r = (stage * 2654435761) % 100
	if stage % 25 == 0 then return "skyisland"      -- showcase stages
	elseif stage % 10 == 0 then return "water"       -- a pond stage each 10
	elseif r < 22 then return "hills"
	elseif r < 38 then return "tunnel"
	elseif r < 50 then return "mixed"
	else return "hills" end                          -- default to hilly (never flat per request)
end

-- scaling curves across 100 stages
function World1Config.stageStats(stage)
	return {
		hp        = math.floor(40 * (1.085 ^ (stage - 1))),
		reward    = math.floor(5 * (1.07 ^ (stage - 1))),
		gateCost  = math.floor(150 * (1.12 ^ (stage - 1))),
		enemyHp   = math.floor(60 * (1.09 ^ (stage - 1))),
		enemyDmg  = math.floor(4 * (1.06 ^ (stage - 1))),
	}
end

-- shops/upgrade booths improve as you climb. returns a tier 1..5 by stage band.
function World1Config.shopTier(stage)
	return math.clamp(math.floor((stage - 1) / 20) + 1, 1, 5)
end

-- which stages host which facilities (scattered, scaling). returns a feature string or nil.
function World1Config.feature(stage)
	local r = (stage * 40503) % 100
	if stage == 1 then return "start"
	elseif stage % 20 == 0 then return "rebirth"        -- rebirth shrine every 20
	elseif stage % 10 == 5 then return "merchant"       -- traveling merchant
	elseif r < 8 then return "upgrade"                  -- upgrade booth
	elseif r < 14 then return "minigame"                -- mini spin/dice
	elseif r < 20 then return "shop"                    -- gear shop
	elseif r < 24 then return "secret"                  -- hidden/dingy reward room
	end
	return nil
end

-- breakable kinds for this world (themed)
World1Config.Breakables = {
	{ kind = "crate",  color = Color3.fromRGB(170,120,70),  mat = Enum.Material.Wood,   hpMul = 1.0, rewardMul = 1.0 },
	{ kind = "rock",   color = Color3.fromRGB(120,122,130), mat = Enum.Material.Slate,  hpMul = 1.6, rewardMul = 1.5 },
	{ kind = "tree",   color = Color3.fromRGB(90,150,80),   mat = Enum.Material.Grass,  hpMul = 1.3, rewardMul = 1.3 },
	{ kind = "chest",  color = Color3.fromRGB(200,160,70),  mat = Enum.Material.Wood,   hpMul = 2.5, rewardMul = 3.0 },
	{ kind = "bush",   color = Color3.fromRGB(80,160,90),   mat = Enum.Material.Grass,  hpMul = 0.7, rewardMul = 0.8 },
}

return World1Config
