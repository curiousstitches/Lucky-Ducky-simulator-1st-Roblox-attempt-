-- src/server/PlayerData.lua  | DataStore-backed profile: the single source of ownership + balances
local Players          = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService       = game:GetService("RunService")

-- DataStores are unavailable in an unpublished Studio place. Detect it safely so the game
-- still runs (in-memory) for testing, instead of crashing the whole server boot.
local STORE
local DATASTORE_OK = pcall(function()
	STORE = DataStoreService:GetDataStore("LuckyDuck_PlayerData_v1")
	-- a cheap probe that throws in an unpublished place
	STORE:GetAsync("__boot_probe__")
end)
if not DATASTORE_OK then
	STORE = nil
	warn("[PlayerData] DataStore unavailable (unpublished place or API off) — running in MEMORY mode. Progress won't save until you Publish + enable API.")
end
local AUTOSAVE = 120 -- seconds

local PlayerData = {}
PlayerData._cache  = {} -- [userId] = profile
PlayerData._loaded = {} -- [userId] = bool (true only if cloud load succeeded)

local DEFAULT = {
	wallet   = { DuckDroppings = 0, ShimmerSplats = 0 },
	ducks    = {},        -- array of duck tables
	equipped = {},        -- array of duck ids
	rank     = 1,
	stats    = { breakablesSmashed = 0, ducksHatched = 0, jeepsDucked = 0 },
	bonusSquadSlots = 0,  -- permanent slots bought via Developer Products
	purchaseHistory = {}, -- [purchaseId] = true  (ProcessReceipt idempotency)
	luckBoostUntil  = 0,  -- os.time() the active luck potion expires
	lastSeen        = 0,  -- os.time() of last save (offline-earnings anchor)
	rebirths        = 0,  -- Lift Kit prestige count
	unlockedBiomes  = { MuddyTrailhead = true },
	dex             = {}, -- [rarityName] = count discovered (collection)
	redeemedCodes   = {}, -- [CODE] = true
	daily           = { lastDay = 0, streak = 0 },
	quests          = { day = 0, snapshot = {}, claimed = {} },
	lifetimeEarned  = 0,  -- all positive currency ever earned (leaderboard)
	kindnessStreak  = 0,  -- consecutive Duck-a-Jeep kindness
	jeepDuckLog     = {}, -- [targetUserId] = os.time() last ducked (cooldown)
	unlockedEggs    = { wrangler = true }, -- egg/jeep ids owned
	abilities       = {}, -- [abilityId] = true
	potions         = {}, -- [effect] = { power, until }  active stacked potion per effect
	gifts           = { common = 0, rare = 0, epic = 0, event = 0 }, -- unopened gift inventory
	highestLevel    = 1,  -- furthest level gate cleared (in current mode)
	mode            = "normal", -- "normal" | "hardcore"
	hardcoreUnlocked = false,   -- earned at level 200 OR via VIP pass
	hardcoreHighest = 1,  -- furthest gate cleared in hardcore mode
	dexComplete     = {}, -- [rarityName]=true once milestone claimed
	clanId          = nil,
	lastSpin        = 0,  -- daily spin wheel anchor (os.time day)
	titles          = {}, -- earned cosmetic titles
	activeTitle     = nil,
	achievements    = {}, -- [id]=true claimed
	cosmeticsOwned  = {}, -- [id]=true
	equippedTrail   = nil,
	equippedAura    = nil,
	starterSpun     = false, -- has used the one-time starter duck wheel
	slotUnlocks     = {},    -- [milestoneId]=true claimed gameplay slot unlocks
	rebirthLadder   = 0,     -- highest mandatory rebirth tier completed (0..10); gate stage = ladder*10
	attackBoost     = 1.0,   -- stacking rebirth attack multiplier (+0.30 each)
	bossTier        = 0,     -- defeated boss tiers (each defeat makes the next boss harder)
	settings        = { autoCollect = true, music = true },
	duckLevels      = {}, -- (reserved) future per-duck meta if needed
}

local function deepCopy(t)
	if type(t) ~= "table" then return t end
	local c = {}
	for k, v in pairs(t) do c[k] = deepCopy(v) end
	return c
end

local function retry(fn, tries)
	tries = tries or 4
	local attempt, ok, res = 0, false, nil
	while attempt < tries do
		ok, res = pcall(fn)
		if ok then return true, res end
		attempt += 1
		task.wait(0.5 * (2 ^ (attempt - 1)))
	end
	return false, res
end

local function migrate(profile)
	for k, v in pairs(DEFAULT) do
		if profile[k] == nil then profile[k] = deepCopy(v) end
	end
	for cur, amt in pairs(DEFAULT.wallet) do
		if profile.wallet[cur] == nil then profile.wallet[cur] = amt end
	end
	for stat, val in pairs(DEFAULT.stats) do
		if profile.stats[stat] == nil then profile.stats[stat] = val end
	end
	return profile
end

function PlayerData.Load(player)
	if not STORE then
		-- memory mode: fresh default profile, no cloud read
		local profile = deepCopy(DEFAULT)
		PlayerData._cache[player.UserId]  = profile
		PlayerData._loaded[player.UserId] = false
		return profile, false
	end
	local key = "u_" .. player.UserId
	local ok, data = retry(function() return STORE:GetAsync(key) end)
	local profile = (ok and type(data) == "table") and data or deepCopy(DEFAULT)
	migrate(profile)
	PlayerData._cache[player.UserId]  = profile
	PlayerData._loaded[player.UserId] = ok
	return profile, ok
end

function PlayerData.Get(player)
	return PlayerData._cache[player.UserId]
end

function PlayerData.Save(player)
	local profile = PlayerData._cache[player.UserId]
	if not profile then return false end
	if not STORE then return false end -- memory mode: nothing to persist to
	if PlayerData._loaded[player.UserId] == false then
		warn("[PlayerData] skip save for " .. player.Name .. " (cloud load had failed; not overwriting)")
		return false
	end
	profile.lastSeen = os.time()
	local ok = retry(function() STORE:SetAsync("u_" .. player.UserId, profile) end)
	if not ok then warn("[PlayerData] save failed for " .. player.Name) end
	return ok
end

function PlayerData.Release(player)
	PlayerData.Save(player)
	PlayerData._cache[player.UserId]  = nil
	PlayerData._loaded[player.UserId] = nil
end

-- immediate save used by trades so a swap can't be lost to a crash. returns ok
function PlayerData.ForceSave(player)
	return PlayerData.Save(player)
end

function PlayerData.Start()
	Players.PlayerAdded:Connect(function(p) PlayerData.Load(p) end)
	Players.PlayerRemoving:Connect(function(p) PlayerData.Release(p) end)
	for _, p in ipairs(Players:GetPlayers()) do
		if not PlayerData._cache[p.UserId] then task.spawn(PlayerData.Load, p) end
	end

	task.spawn(function()
		while true do
			task.wait(AUTOSAVE)
			for _, p in ipairs(Players:GetPlayers()) do task.spawn(PlayerData.Save, p) end
		end
	end)

	game:BindToClose(function()
		if RunService:IsStudio() then return end
		for _, p in ipairs(Players:GetPlayers()) do PlayerData.Save(p) end
		task.wait(2)
	end)
end

return PlayerData
