-- src/server/DexService.lua  | Duck Index: logs every duck rarity×tier the player has discovered,
-- shows internal value, and grants completion rewards for filling rows.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DuckSchema = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DuckSchema"))
local DuckGenerator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DuckGenerator"))
local PlayerData      = require(script.Parent.PlayerData)
local CurrencyService = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local Remotes         = require(script.Parent.Remotes)
local RemoteGuard     = require(script.Parent.RemoteGuard)

local DexService = {}
local Notify
local TIERS = { "Small","Huge","Gigantic","Titanic" }

-- internal value (player-driven prices come post-publish): rarity tier × duck tier multiplier
local function valueOf(rarityName, tierName)
	local r = DuckSchema.getRarity(rarityName); local rt = r and r.tier or 1
	local tm = (DuckGenerator.Tiers[tierName] or DuckGenerator.Tiers.Small).coin
	return math.floor(100 * (2.2 ^ (rt-1)) * tm)
end

-- discovery is recorded in InventoryService.AddDuck (dexTiered). Kept for compatibility.
function DexService.Record(player, duck) end

function DexService.Snapshot(player)
	local p = PlayerData.Get(player); if not p then return {} end
	p.dex = p.dex or {}; p.dexRewards = p.dexRewards or {}
	local rows = {}; local discovered=0; local total=0
	for _, r in ipairs(DuckSchema.Rarities) do
		for _, tier in ipairs(TIERS) do
			total += 1
			local key = r.name.."|"..tier
			local count = (p.dexTiered or {})[key] or 0
			if count>0 then discovered = discovered + 1 end
			rows[#rows+1] = { rarity=r.name, tier=tier, count=count, found=count>0, value=valueOf(r.name,tier) }
		end
	end
	-- completion milestones (every 25% of the index)
	local pct = math.floor(discovered/total*100)
	return { rows=rows, discovered=discovered, total=total, pct=pct, rewards=p.dexRewards }
end

function DexService.ClaimMilestone(player, milestone)
	local p = PlayerData.Get(player); if not p then return { ok=false } end
	p.dexRewards = p.dexRewards or {}
	local snap = DexService.Snapshot(player)
	local need = { ["25"]=25, ["50"]=50, ["75"]=75, ["100"]=100 }
	local m = need[tostring(milestone)]; if not m then return { ok=false } end
	if snap.pct < m then return { ok=false, reason="Index only "..snap.pct.."% complete" } end
	if p.dexRewards[tostring(milestone)] then return { ok=false, reason="Already claimed" } end
	p.dexRewards[tostring(milestone)] = true
	local splat = m  -- 25/50/75/100 splats
	CurrencyService.Add(player, "ShimmerSplats", splat)
	if m==100 then InventoryService.AddDuck(player, DuckGenerator.roll({origin="dex100",luckMul=10,goldenChance=1,tier="Titanic"})) end
	if Notify then Notify:FireClient(player,{ text=("📖 Index %d%% reward: +%d Splats%s"):format(m,splat,m==100 and " + TITANIC duck!" or ""), color=Color3.fromRGB(120,230,160) }) end
	return { ok=true }
end

function DexService.Start()
	Notify = Remotes.event("Notify")
	Remotes.func("GetDex").OnServerInvoke = function(pl) return DexService.Snapshot(pl) end
	RemoteGuard.func(Remotes.func("ClaimDex"),"dex",5,8,function(pl,m) return DexService.ClaimMilestone(pl,m) end,{ok=false})
end

return DexService
