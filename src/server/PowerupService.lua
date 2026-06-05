-- src/server/PowerupService.lua  | PS99-style boosts: buy timed multipliers that stack durations.
-- Reads existing profile flags so Farm/Egg/Hatcher pick them up automatically.
local Players          = game:GetService("Players")
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local Remotes          = require(script.Parent.Remotes)
local RemoteGuard      = require(script.Parent.RemoteGuard)

local PowerupService = {}
local Notify

-- effect maps to a profile flag the other services already read where possible
local BOOSTS = {
	{ id="luck2",   name="2x Luck (15m)",     effect="luck",  power=2, secs=900,  cost=20 },
	{ id="luck3",   name="3x Luck (10m)",     effect="luck",  power=3, secs=600,  cost=40 },
	{ id="coins2",  name="2x Coins (15m)",    effect="earn",  power=2, secs=900,  cost=20 },
	{ id="coins3",  name="3x Coins (10m)",    effect="earn",  power=3, secs=600,  cost=40 },
	{ id="dmg2",    name="2x Damage (15m)",   effect="dmg",   power=2, secs=900,  cost=25 },
	{ id="speed",   name="+Speed (20m)",      effect="speed", power=1.5,secs=1200, cost=15 },
	{ id="mega",    name="MEGA All x2 (30m)", effect="mega",  power=2, secs=1800, cost=80 },
}

function PowerupService.Buy(player, id)
	local b; for _,x in ipairs(BOOSTS) do if x.id==id then b=x break end end
	if not b then return { ok=false } end
	local p = PlayerData.Get(player); if not p then return { ok=false } end
	if not CurrencyService.Spend(player, "ShimmerSplats", b.cost) then return { ok=false, reason="Need "..b.cost.." Splats" } end
	p.boosts = p.boosts or {}
	local now = os.time()
	local function stack(effect, power)
		local cur = p.boosts[effect]
		if cur and (cur["until"] or 0) > now then cur["until"] += b.secs; cur.power=math.max(cur.power or 1, power)
		else p.boosts[effect] = { power=power, ["until"]=now+b.secs } end
	end
	if b.effect=="mega" then stack("luck",b.power); stack("earn",b.power)
	else stack(b.effect, b.power) end
	if Notify then Notify:FireClient(player,{ text="🔮 "..b.name.." active! (stacks)", color=Color3.fromRGB(180,140,255) }) end
	return { ok=true }
end

-- recompute the runtime flags other services read (luck/earn) from active boosts
function PowerupService.Refresh(player)
	local p = PlayerData.Get(player); if not p then return end
	local now=os.time(); p.boosts=p.boosts or {}
	local luck=p.boosts.luck; p._luckPot = luck and luck["until"] or p._luckPot or 0; if luck then p._luckPotPower=luck.power end
	local earn=p.boosts.earn; p._earnPot = earn and earn["until"] or p._earnPot or 0; if earn then p._earnPotPower=earn.power end
end

function PowerupService.Info(player)
	local p = PlayerData.Get(player)
	return { boosts=BOOSTS, active=p and p.boosts or {} }
end

function PowerupService.Start()
	Notify = Remotes.event("Notify")
	Remotes.func("GetPowerups").OnServerInvoke = function(pl) return PowerupService.Info(pl) end
	RemoteGuard.func(Remotes.func("BuyPowerup"),"pw",6,10,function(pl,id) return PowerupService.Buy(pl,id) end,{ok=false})
	task.spawn(function() while true do for _,pl in ipairs(Players:GetPlayers()) do PowerupService.Refresh(pl) end; task.wait(2) end end)
end

return PowerupService
