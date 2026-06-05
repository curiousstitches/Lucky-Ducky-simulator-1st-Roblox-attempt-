-- src/server/IndexService.lua  | collection index: claim milestone rewards for discovering rarities
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DuckSchema = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DuckSchema"))
local PlayerData      = require(script.Parent.PlayerData)
local CurrencyService = require(script.Parent.CurrencyService)
local Remotes         = require(script.Parent.Remotes)
local RemoteGuard     = require(script.Parent.RemoteGuard)

local IndexService = {}
local Notify

-- reward for first discovery of each rarity (scaled to rarity tier)
local function milestoneReward(rarityName)
	local r = DuckSchema.getRarity(rarityName)
	local tier = r and r.tier or 1
	return { currency = (tier >= 6) and "ShimmerSplats" or "DuckDroppings",
		amount = (tier >= 6) and (tier * 10) or math.floor(500 * (3 ^ (tier - 1))) }
end

function IndexService.Snapshot(player)
	local p = PlayerData.Get(player); if not p then return {} end
	p.dex = p.dex or {}; p.dexComplete = p.dexComplete or {}
	local rows = {}
	for _, r in ipairs(DuckSchema.Rarities) do
		local found = (p.dex[r.name] or 0)
		rows[#rows + 1] = {
			name = r.name, tier = r.tier, found = found,
			discovered = found > 0, claimed = p.dexComplete[r.name] == true,
			reward = milestoneReward(r.name),
		}
	end
	return { rows = rows }
end

function IndexService.Claim(player, rarityName)
	local p = PlayerData.Get(player); if not p then return { ok = false } end
	p.dex = p.dex or {}; p.dexComplete = p.dexComplete or {}
	if (p.dex[rarityName] or 0) <= 0 then return { ok = false, reason = "Not discovered yet" } end
	if p.dexComplete[rarityName] then return { ok = false, reason = "Already claimed" } end
	p.dexComplete[rarityName] = true
	local rw = milestoneReward(rarityName)
	CurrencyService.Add(player, rw.currency, rw.amount)
	if Notify then Notify:FireClient(player, { text = ("📖 Index reward: %s -> +%d %s"):format(rarityName, rw.amount, rw.currency), color = Color3.fromRGB(120, 230, 140) }) end
	return { ok = true }
end

function IndexService.Start()
	Notify = Remotes.event("Notify")
	local snap = Remotes.func("GetIndex")
	local claim = Remotes.func("ClaimIndex")
	snap.OnServerInvoke = function(player) return IndexService.Snapshot(player) end
	RemoteGuard.func(claim, "index_claim", 6, 10, function(pl, name) return IndexService.Claim(pl, name) end, { ok = false })
end

return IndexService
