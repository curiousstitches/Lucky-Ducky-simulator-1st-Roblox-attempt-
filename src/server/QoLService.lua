-- src/server/QoLService.lua  | open-eggs-until-rare, persistent settings, auto-collect flag
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DuckGenerator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DuckGenerator"))
local DuckSchema    = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DuckSchema"))
local UnlockConfig  = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UnlockConfig"))
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local Remotes          = require(script.Parent.Remotes)
local RemoteGuard      = require(script.Parent.RemoteGuard)

local QoLService = {}
local Notify, RevealDuck
local MAX_AUTO = 50 -- safety cap on a single "open until rare" burst

local function tierOf(name) local r = DuckSchema.getRarity(name); return r and r.tier or 1 end

-- open one egg repeatedly until a duck of >= stopTier rarity appears (or cap/funds hit)
function QoLService.OpenUntil(player, eggId, stopTierName)
	local egg = UnlockConfig.find(UnlockConfig.Eggs, eggId); if not egg then return end
	local p = PlayerData.Get(player); if not p then return end
	if egg.currency == "Robux" or not (p.unlockedEggs or {})[eggId] then return end
	local stopTier = tierOf(stopTierName or "Epic")
	local opened, last, hit = 0, nil, false
	while opened < MAX_AUTO and CurrencyService.CanAfford(player, egg.currency, egg.cost) do
		CurrencyService.Spend(player, egg.currency, egg.cost)
		local lk = egg.luck
		local enLuck = select(1, InventoryService.EnchantBonuses(player))
		local duck = DuckGenerator.roll({ origin = eggId, luckMul = lk * (enLuck or 1), goldenChance = egg.golden })
		InventoryService.AddDuck(player, duck)
		opened += 1; last = duck
		if tierOf(duck.rarity) >= stopTier then hit = true; break end
	end
	if RevealDuck and last then
		RevealDuck:FireClient(player, { ok = true, duck = last, reveal = "burst",
			dispenser = ("%s — opened %d%s"):format(egg.name, opened, hit and " (rare!)" or "") })
	end
end

function QoLService.Start()
	Notify = Remotes.event("Notify")
	RevealDuck = Remotes.event("RevealDuck")
	RemoteGuard.event(Remotes.event("OpenUntil"), "open_until", 2, 3, function(pl, eggId, tier) QoLService.OpenUntil(pl, eggId, tier) end)

	Remotes.func("GetSettings").OnServerInvoke = function(player)
		local p = PlayerData.Get(player); return p and p.settings or { autoCollect = true, music = true }
	end
	RemoteGuard.event(Remotes.event("SetSetting"), "setting", 6, 10, function(player, key, val)
		local p = PlayerData.Get(player); if not p then return end
		p.settings = p.settings or {}
		if key == "autoCollect" or key == "music" then p.settings[key] = (val == true) end
	end)
end

return QoLService
