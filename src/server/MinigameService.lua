-- src/server/MinigameService.lua  | quick side-games launched from the lobby minigame buildings.
-- Coin Rush (timed click burst), Clicker (per-tap), Obby (completion reward), Claw (gacha pull).
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DuckGenerator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DuckGenerator"))
local Remotes         = require(script.Parent.Remotes)
local RemoteGuard     = require(script.Parent.RemoteGuard)

local MinigameService = {}
local Notify
local rng = Random.new()

-- Coin Rush: client reports a click count over a short window; server rewards (rate-limited + capped)
function MinigameService.CoinRush(player, clicks)
	local p = PlayerData.Get(player); if not p then return { ok=false } end
	clicks = math.clamp(tonumber(clicks) or 0, 0, 200)  -- cap prevents exploit
	local reward = clicks * (50 + (p.highestLevel or 1)*5)
	CurrencyService.Add(player, "DuckDroppings", reward)
	if Notify then Notify:FireClient(player,{ text="💰 Coin Rush: +"..reward.."!", color=Color3.fromRGB(255,210,90) }) end
	return { ok=true, reward=reward }
end

-- Clicker: a single tap reward (rate-limited so it can't be spammed faster than human)
function MinigameService.Click(player)
	local p = PlayerData.Get(player); if not p then return { ok=false } end
	local reward = 25 + (p.highestLevel or 1)*3
	CurrencyService.Add(player, "DuckDroppings", reward)
	return { ok=true, reward=reward }
end

-- Obby: client reports completion of the tower; server grants a one-per-cooldown reward
function MinigameService.ObbyComplete(player)
	local p = PlayerData.Get(player); if not p then return { ok=false } end
	local now=os.time()
	if (p._obbyCd or 0) > now then return { ok=false, reason="On cooldown" } end
	p._obbyCd = now + 120
	CurrencyService.Add(player, "ShimmerSplats", 8)
	InventoryService.AddDuck(player, DuckGenerator.roll({origin="obby",luckMul=2}))
	if Notify then Notify:FireClient(player,{ text="🧗 Obby cleared! +8 Splats + a duck!", color=Color3.fromRGB(150,230,150) }) end
	return { ok=true }
end

-- Claw Machine: a Splat-cost gacha pull
function MinigameService.Claw(player)
	local p = PlayerData.Get(player); if not p then return { ok=false } end
	if not CurrencyService.Spend(player, "ShimmerSplats", 10) then return { ok=false, reason="Need 10 Splats" } end
	local r=rng:NextNumber()
	local tier = r<0.02 and "Gigantic" or r<0.12 and "Huge" or "Small"
	InventoryService.AddDuck(player, DuckGenerator.roll({origin="claw",luckMul=3,goldenChance=0.1,tier=tier}))
	if Notify then Notify:FireClient(player,{ text="🕹️ Claw grabbed a "..tier.." duck!", color=Color3.fromRGB(255,140,180) }) end
	return { ok=true, tier=tier }
end

function MinigameService.Start()
	Notify = Remotes.event("Notify")
	RemoteGuard.func(Remotes.func("CoinRush"),"cr",2,3,function(pl,c) return MinigameService.CoinRush(pl,c) end,{ok=false})
	RemoteGuard.func(Remotes.func("ClickGame"),"clk",15,20,function(pl) return MinigameService.Click(pl) end,{ok=false})
	RemoteGuard.func(Remotes.func("ObbyDone"),"obby",2,3,function(pl) return MinigameService.ObbyComplete(pl) end,{ok=false})
	RemoteGuard.func(Remotes.func("ClawPull"),"claw",4,6,function(pl) return MinigameService.Claw(pl) end,{ok=false})
end

return MinigameService
