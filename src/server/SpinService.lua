-- src/server/SpinService.lua  | free daily spin wheel; VIP gets a second daily spin
local PlayerData      = require(script.Parent.PlayerData)
local CurrencyService = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local Remotes         = require(script.Parent.Remotes)
local RemoteGuard     = require(script.Parent.RemoteGuard)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DuckGenerator   = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DuckGenerator"))

local SpinService = {}
local Notify
local rng = Random.new()

-- weighted prize table
local PRIZES = {
	{ w = 35, kind = "currency", currency = "DuckDroppings", amount = 2000,  label = "2K Droppings" },
	{ w = 25, kind = "currency", currency = "DuckDroppings", amount = 8000,  label = "8K Droppings" },
	{ w = 15, kind = "currency", currency = "ShimmerSplats", amount = 10,    label = "10 Splats" },
	{ w = 12, kind = "currency", currency = "DuckDroppings", amount = 25000, label = "25K Droppings" },
	{ w = 8,  kind = "duck",     luck = 2.0,                                  label = "Lucky Duck" },
	{ w = 4,  kind = "currency", currency = "ShimmerSplats", amount = 40,    label = "40 Splats" },
	{ w = 1,  kind = "duck",     luck = 5.0, golden = 0.3,                    label = "MEGA Duck" },
}

local function dayNum() return math.floor(os.time() / 86400) end

local function spin(player)
	local total = 0; for _, p in ipairs(PRIZES) do total += p.w end
	local r = rng:NextNumber(0, total); local acc = 0
	for _, prize in ipairs(PRIZES) do acc += prize.w; if r <= acc then return prize end end
	return PRIZES[1]
end

function SpinService.Spin(player)
	local p = PlayerData.Get(player); if not p then return { ok = false } end
	local today = dayNum()
	local spinsToday = (p._spinsDay == today) and (p._spinsCount or 0) or 0
	local allowed = p._vip and 2 or 1
	if spinsToday >= allowed then
		return { ok = false, reason = p._vip and "Used both spins today" or "Come back tomorrow (VIP gets 2/day)" }
	end
	p._spinsDay = today; p._spinsCount = spinsToday + 1
	local prize = spin(player)
	if prize.kind == "currency" then
		CurrencyService.Add(player, prize.currency, prize.amount)
	else
		InventoryService.AddDuck(player, DuckGenerator.roll({ origin = "spin", luckMul = prize.luck, goldenChance = prize.golden }))
	end
	if Notify then Notify:FireClient(player, { text = "🎡 Spin won: " .. prize.label .. "!", color = Color3.fromRGB(255, 220, 120) }) end
	return { ok = true, label = prize.label }
end

function SpinService.Status(player)
	local p = PlayerData.Get(player); if not p then return {} end
	local today = dayNum()
	local used = (p._spinsDay == today) and (p._spinsCount or 0) or 0
	local allowed = p._vip and 2 or 1
	return { used = used, allowed = allowed, prizes = PRIZES }
end

function SpinService.Start()
	Notify = Remotes.event("Notify")
	local doSpin = Remotes.func("DoSpin")
	local getSpin = Remotes.func("GetSpin")
	RemoteGuard.func(doSpin, "spin", 2, 3, function(pl) return SpinService.Spin(pl) end, { ok = false })
	getSpin.OnServerInvoke = function(player) return SpinService.Status(player) end
end

return SpinService
