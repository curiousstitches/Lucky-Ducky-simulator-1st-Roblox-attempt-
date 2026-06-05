-- src/server/HatcherService.lua  | hatch ducks from the in-zone egg pods. Server-authoritative,
-- spends the zone's world currency, uses YOUR DuckGenerator + InventoryService (no foreign code).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DuckGenerator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DuckGenerator"))
local ZoneConfig    = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ZoneConfig"))
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local Remotes          = require(script.Parent.Remotes)
local RemoteGuard      = require(script.Parent.RemoteGuard)

local HatcherService = {}
local Notify, RevealDuck

-- deeper zones roll luckier + tiny chance of higher tiers (Huge/Gigantic)
local function tierForZone(zone, rng)
	local r = rng:NextNumber()
	if zone >= 70 and r < 0.01 then return "Gigantic"
	elseif zone >= 30 and r < 0.03 then return "Huge"
	else return "Small" end
end

function HatcherService.Hatch(player, zone, cost, currency)
	local p = PlayerData.Get(player); if not p then return { ok=false } end
	zone = tonumber(zone) or 1
	-- validate the cost/currency against config (don't trust client numbers)
	local stats = ZoneConfig.stats(zone)
	local wd = ZoneConfig.worldForZone(zone)
	if currency ~= wd.currency then currency = wd.currency end
	cost = stats.eggCost
	-- must have reached this zone
	if (p.highestLevel or 1) < zone then
		if Notify then Notify:FireClient(player,{ text="🔒 Reach Zone "..zone.." to hatch here", color=Color3.fromRGB(255,170,80) }) end
		return { ok=false }
	end
	if not CurrencyService.Spend(player, currency, cost) then
		if Notify then Notify:FireClient(player,{ text="Need "..cost.." "..wd.curName, color=Color3.fromRGB(255,150,0) }) end
		return { ok=false }
	end
	local rng = Random.new()
	local luck = 1 + zone*0.04
	local duck = DuckGenerator.roll({ origin="hatcher_z"..zone, luckMul=luck, goldenChance=0.01+zone*0.001, tier=tierForZone(zone,rng) })
	InventoryService.AddDuck(player, duck)
	if RevealDuck then RevealDuck:FireClient(player, { ok=true, duck=duck, reveal="burst", dispenser="Jeep Egg "..zone }) end
	return { ok=true }
end

function HatcherService.Start()
	Notify = Remotes.event("Notify")
	RevealDuck = Remotes.event("RevealDuck")
	RemoteGuard.func(Remotes.func("HatchEgg"),"hatch",8,12,function(pl,zone,cost,cur) return HatcherService.Hatch(pl,zone,cost,cur) end,{ok=false})
end

return HatcherService
