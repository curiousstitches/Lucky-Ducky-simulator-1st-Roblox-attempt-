-- src/server/MachineService.lua  | new minigames + duck upgraders driven by the lobby machines.
-- gold/platinum/rainbow = permanent duck tier upgrades (power multipliers). fortune/dice/chest = luck games.
local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DuckGenerator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DuckGenerator"))
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local Remotes          = require(script.Parent.Remotes)
local RemoteGuard      = require(script.Parent.RemoteGuard)

local MachineService = {}
local Notify
local rng = Random.new()

local TIER = {
	gold     = { mult = 2,  cost = 15000,  currency = "DuckDroppings", tag = "Gold",     color = "255,200,50" },
	platinum = { mult = 4,  cost = 50,     currency = "ShimmerSplats", tag = "Platinum", color = "210,225,235" },
	rainbow  = { mult = 8,  cost = 150,    currency = "ShimmerSplats", tag = "Rainbow",  color = "255,90,160" },
}

local function firstEquipped(p)
	local byId={}; for _,d in ipairs(p.ducks) do byId[d.id]=d end
	for _,id in ipairs(p.equipped) do if byId[id] then return byId[id] end end
	return p.ducks[1]
end

function MachineService.Upgrade(player, tier)
	local t = TIER[tier]; if not t then return { ok=false } end
	local p = PlayerData.Get(player); if not p then return { ok=false } end
	local duck = firstEquipped(p); if not duck then return { ok=false, reason="No duck equipped" } end
	if duck.upgrade == tier then return { ok=false, reason="Already "..t.tag } end
	if not CurrencyService.Spend(player, t.currency, t.cost) then return { ok=false, reason="Need "..t.cost.." "..t.currency } end
	duck.upgrade = tier
	duck.strength = math.floor((duck.strength or 1) * t.mult)
	InventoryService.Push(player)
	if Notify then Notify:FireClient(player,{ text="⭐ Duck upgraded to "..t.tag.."! x"..t.mult.." power", color=Color3.fromRGB(255,215,90) }) end
	return { ok=true }
end

-- FORTUNE WHEEL: bigger gamble than daily spin, costs Shimmer, can hit jackpots
function MachineService.Fortune(player)
	local p = PlayerData.Get(player); if not p then return { ok=false } end
	if not CurrencyService.Spend(player, "ShimmerSplats", 5) then return { ok=false, reason="Need 5 Shimmer Splats" } end
	local roll = rng:NextNumber()
	local prize
	if roll < 0.5 then prize={t="cur",c="DuckDroppings",a=rng:NextInteger(5000,20000),label="Droppings"}
	elseif roll < 0.8 then prize={t="cur",c="ShimmerSplats",a=rng:NextInteger(8,20),label="Splats"}
	elseif roll < 0.97 then prize={t="duck",luck=3,label="Rare Duck"}
	else prize={t="duck",luck=8,golden=0.6,label="JACKPOT MEGA DUCK"} end
	if prize.t=="cur" then CurrencyService.Add(player,prize.c,prize.a)
	else InventoryService.AddDuck(player, DuckGenerator.roll({origin="fortune",luckMul=prize.luck,goldenChance=prize.golden})) end
	if Notify then Notify:FireClient(player,{ text="🎡 Fortune: "..prize.label.."!", color=Color3.fromRGB(255,220,120) }) end
	return { ok=true, label=prize.label }
end

-- LUCKY DICE: cheap, pays out a multiple of the stake
function MachineService.Dice(player)
	local p = PlayerData.Get(player); if not p then return { ok=false } end
	local stake = 2500
	if not CurrencyService.Spend(player, "DuckDroppings", stake) then return { ok=false, reason="Need "..stake } end
	local d1,d2 = rng:NextInteger(1,6), rng:NextInteger(1,6)
	local total=d1+d2
	local mult = (total==12 and 10) or (d1==d2 and 4) or (total>=9 and 2) or 0
	local win = stake*mult
	if win>0 then CurrencyService.Add(player,"DuckDroppings",win) end
	if Notify then Notify:FireClient(player,{ text=("🎲 %d+%d=%d → %s"):format(d1,d2,total, win>0 and ("WON "..win) or "no win"), color = win>0 and Color3.fromRGB(120,230,140) or Color3.fromRGB(220,160,90) }) end
	return { ok=true, d1=d1, d2=d2, win=win }
end

-- DAILY CHEST: one free chest per day, scales with progress
function MachineService.Chest(player)
	local p = PlayerData.Get(player); if not p then return { ok=false } end
	local day = math.floor(os.time()/86400)
	if p._chestDay == day then return { ok=false, reason="Come back tomorrow!" } end
	p._chestDay = day
	local amt = math.floor(3000 * (1 + (p.highestLevel or 1)*0.1))
	CurrencyService.Add(player,"DuckDroppings",amt)
	CurrencyService.Add(player,"ShimmerSplats",5)
	if Notify then Notify:FireClient(player,{ text=("🎁 Daily Chest: +%d Droppings +5 Splats!"):format(amt), color=Color3.fromRGB(255,210,120) }) end
	return { ok=true }
end

function MachineService.Start()
	Notify = Remotes.event("Notify")
	RemoteGuard.func(Remotes.func("MachineUpgrade"),"m_up",5,8,function(pl,tier) return MachineService.Upgrade(pl,tier) end,{ok=false})
	RemoteGuard.func(Remotes.func("MachineFortune"),"m_for",4,5,function(pl) return MachineService.Fortune(pl) end,{ok=false})
	RemoteGuard.func(Remotes.func("MachineDice"),"m_dice",6,8,function(pl) return MachineService.Dice(pl) end,{ok=false})
	RemoteGuard.func(Remotes.func("MachineChest"),"m_chest",3,4,function(pl) return MachineService.Chest(pl) end,{ok=false})
end

return MachineService
