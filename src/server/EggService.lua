-- src/server/EggService.lua  | eggs = jeeps. unlock a jeep -> hatch ducks. open x1/x3/x5/x10.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Shared        = ReplicatedStorage:WaitForChild("Shared")
local DuckGenerator = require(Shared:WaitForChild("DuckGenerator"))
local UnlockConfig  = require(Shared:WaitForChild("UnlockConfig"))
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local Remotes          = require(script.Parent.Remotes)
local RemoteGuard      = require(script.Parent.RemoteGuard)

local EggService = {}
local Notify, RevealDuck

local function maxBatch(profile)
	if profile._open10 then return 10 elseif profile._open5 then return 5 else return 3 end
end

local function activeLuck(profile, base)
	local mult = base
	if profile._luckPot and profile._luckPot > os.time() then mult = mult * (profile._luckPotPower or 1) end
	if profile.luckBoostUntil and profile.luckBoostUntil > os.time() then mult = mult * 2 end
	if profile._eventLuck then mult = mult * profile._eventLuck end
	if profile._randomLuck then mult = mult * profile._randomLuck end
	if profile._luckx2 then mult = mult * 2 end
	return mult
end

function EggService.Unlock(player, eggId)
	local egg = UnlockConfig.find(UnlockConfig.Eggs, eggId); if not egg then return { ok = false } end
	local p = PlayerData.Get(player); if not p then return { ok = false } end
	p.unlockedEggs = p.unlockedEggs or {}
	if p.unlockedEggs[eggId] then return { ok = true } end
	if egg.currency == "Robux" then return { ok = false, reason = "Buy this Jeep in the shop" } end
	-- free unlock slots cap
	local owned = 0; for _ in pairs(p.unlockedEggs) do owned += 1 end
	if owned >= UnlockConfig.FreeEggSlots and egg.free then
		return { ok = false, reason = "Used all 3 free Jeep slots — others need Robux" }
	end
	if not CurrencyService.Spend(player, egg.currency, egg.cost) then
		return { ok = false, reason = "Can't afford this Jeep" }
	end
	p.unlockedEggs[eggId] = true
	if Notify then Notify:FireClient(player, { text = "🚙 Unlocked " .. egg.name .. "!", color = Color3.fromRGB(120, 210, 255) }) end
	return { ok = true }
end

function EggService.Open(player, eggId, count)
	local egg = UnlockConfig.find(UnlockConfig.Eggs, eggId); if not egg then return end
	local p = PlayerData.Get(player); if not p then return end
	if egg.vip and not p._vip then
		if Notify then Notify:FireClient(player, { text = "👑 VIP Jeep — needs the VIP pass", color = Color3.fromRGB(255, 150, 0) }) end
		return
	end
	if not p.unlockedEggs[eggId] then
		if Notify then Notify:FireClient(player, { text = "🔒 Unlock this Jeep first", color = Color3.fromRGB(255, 150, 0) }) end
		return
	end
	if egg.currency == "Robux" then return end -- Robux eggs hatch via product receipt, not here
	count = math.clamp(tonumber(count) or 1, 1, maxBatch(p))
	local total = egg.cost * count
	if not CurrencyService.Spend(player, egg.currency, total) then
		if RevealDuck then RevealDuck:FireClient(player, { ok = false, reason = "Not enough to open " .. count }) end
		return
	end
	local last
	for i = 1, count do
		local duck = DuckGenerator.roll({ origin = eggId, luckMul = activeLuck(p, egg.luck), goldenChance = egg.golden })
		InventoryService.AddDuck(player, duck)
		last = duck
	end
	if RevealDuck then
		RevealDuck:FireClient(player, { ok = true, duck = last, reveal = "burst", dispenser = egg.name .. (count > 1 and (" x" .. count) or "") })
	end
end

function EggService.Start()
	Notify = Remotes.event("Notify")
	RevealDuck = Remotes.event("RevealDuck")
	local unlock = Remotes.func("UnlockEgg")
	local open   = Remotes.event("OpenEgg")
	local list   = Remotes.func("GetEggs")
	RemoteGuard.func(unlock, "egg_unlock", 4, 6, function(player, id) return EggService.Unlock(player, id) end, { ok = false })
	RemoteGuard.event(open, "egg_open", 6, 8, function(player, id, count) EggService.Open(player, id, count) end)
	list.OnServerInvoke = function(player)
		local p = PlayerData.Get(player)
		local out = {}
		for _, e in ipairs(UnlockConfig.Eggs) do
			out[#out + 1] = {
				id = e.id, name = e.name, cost = e.cost, currency = e.currency, vip = e.vip or false,
				robux = e.currency == "Robux", owned = (p and p.unlockedEggs and p.unlockedEggs[e.id]) == true,
			}
		end
		return { eggs = out, maxBatch = p and maxBatch(p) or 3 }
	end
end

return EggService
