-- src/server/ClanService.lua  | create/join clans, shared XP pool, clan board (DataStore-backed)
local DataStoreService = game:GetService("DataStoreService")
local Players          = game:GetService("Players")
local PlayerData      = require(script.Parent.PlayerData)
local Remotes         = require(script.Parent.Remotes)
local RemoteGuard     = require(script.Parent.RemoteGuard)

local ClanService = {}
local Notify
local CLAN_STORE, INDEX_STORE
pcall(function()
	CLAN_STORE = DataStoreService:GetDataStore("LuckyDuck_Clans_v1")
	INDEX_STORE = DataStoreService:GetOrderedDataStore("LuckyDuck_ClanXP_v1")
	CLAN_STORE:GetAsync("__boot_probe__")
end)
local CLANS_OK = CLAN_STORE ~= nil

local function retry(fn, n)
	n = n or 3
	for i = 1, n do local ok, res = pcall(fn); if ok then return true, res end; task.wait(0.4 * i) end
	return false
end

local function sanitize(name)
	name = tostring(name or ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	return name:sub(1, 18)
end

function ClanService.Create(player, rawName)
	if not CLANS_OK then return { ok = false, reason = "Clans need a published game" } end
	local p = PlayerData.Get(player); if not p then return { ok = false } end
	if p.clanId then return { ok = false, reason = "Leave your clan first" } end
	local name = sanitize(rawName)
	if #name < 3 then return { ok = false, reason = "Name too short" } end
	local key = "clan_" .. name:lower():gsub("[^%w]", "")
	local ok, existing = retry(function() return CLAN_STORE:GetAsync(key) end)
	if ok and existing then return { ok = false, reason = "Name taken" } end
	local clan = { id = key, name = name, owner = player.UserId, members = { [tostring(player.UserId)] = player.Name }, xp = 0 }
	retry(function() CLAN_STORE:SetAsync(key, clan) end)
	p.clanId = key
	if Notify then Notify:FireClient(player, { text = "🛡️ Clan created: " .. name, color = Color3.fromRGB(150, 120, 255) }) end
	return { ok = true, clan = clan }
end

function ClanService.Join(player, rawName)
	if not CLANS_OK then return { ok = false, reason = "Clans need a published game" } end
	local p = PlayerData.Get(player); if not p then return { ok = false } end
	if p.clanId then return { ok = false, reason = "Leave your clan first" } end
	local key = "clan_" .. sanitize(rawName):lower():gsub("[^%w]", "")
	local ok, clan = retry(function() return CLAN_STORE:GetAsync(key) end)
	if not (ok and clan) then return { ok = false, reason = "Clan not found" } end
	retry(function()
		CLAN_STORE:UpdateAsync(key, function(c)
			c = c or clan; c.members = c.members or {}
			c.members[tostring(player.UserId)] = player.Name
			return c
		end)
	end)
	p.clanId = key
	if Notify then Notify:FireClient(player, { text = "🛡️ Joined " .. clan.name, color = Color3.fromRGB(150, 120, 255) }) end
	return { ok = true }
end

function ClanService.Leave(player)
	local p = PlayerData.Get(player); if not p or not p.clanId then return { ok = false } end
	local key = p.clanId
	retry(function()
		CLAN_STORE:UpdateAsync(key, function(c)
			if c and c.members then c.members[tostring(player.UserId)] = nil end
			return c
		end)
	end)
	p.clanId = nil
	return { ok = true }
end

-- members contribute XP from earnings (called by CurrencyService hook via flag)
function ClanService.Contribute(player, amount)
	local p = PlayerData.Get(player); if not (p and p.clanId) then return end
	p._clanPending = (p._clanPending or 0) + amount
end

local function flushContributions()
	if not CLANS_OK then return end
	for _, player in ipairs(Players:GetPlayers()) do
		local p = PlayerData.Get(player)
		if p and p.clanId and (p._clanPending or 0) > 0 then
			local add = math.floor(p._clanPending); p._clanPending = 0
			local key = p.clanId
			retry(function()
				CLAN_STORE:UpdateAsync(key, function(c)
					if c then c.xp = (c.xp or 0) + add end; return c
				end)
			end)
			pcall(function()
				INDEX_STORE:UpdateAsync(key, function(v) return (v or 0) + add end)
			end)
		end
	end
end

function ClanService.Info(player)
	local p = PlayerData.Get(player); if not p then return {} end
	if not CLANS_OK then return { inClan = false } end
	if not p.clanId then return { inClan = false } end
	local ok, clan = retry(function() return CLAN_STORE:GetAsync(p.clanId) end)
	if not (ok and clan) then return { inClan = false } end
	local count = 0; for _ in pairs(clan.members or {}) do count += 1 end
	return { inClan = true, name = clan.name, xp = clan.xp or 0, members = count, owner = clan.owner == player.UserId }
end

function ClanService.Top()
	if not CLANS_OK then return {} end
	local ok, pages = pcall(function() return INDEX_STORE:GetSortedAsync(false, 10) end)
	if not ok then return {} end
	local out = {}
	for _, e in ipairs(pages:GetCurrentPage()) do
		local k = e.key
		local ok2, clan = retry(function() return CLAN_STORE:GetAsync(k) end)
		out[#out + 1] = { name = (ok2 and clan and clan.name) or k, xp = e.value }
	end
	return out
end

function ClanService.Start()
	Notify = Remotes.event("Notify")
	RemoteGuard.func(Remotes.func("ClanCreate"), "clan_create", 2, 3, function(pl, n) return ClanService.Create(pl, n) end, { ok = false })
	RemoteGuard.func(Remotes.func("ClanJoin"),   "clan_join",   3, 4, function(pl, n) return ClanService.Join(pl, n) end, { ok = false })
	RemoteGuard.func(Remotes.func("ClanLeave"),  "clan_leave",  2, 3, function(pl) return ClanService.Leave(pl) end, { ok = false })
	Remotes.func("ClanInfo").OnServerInvoke = function(player) return ClanService.Info(player) end
	Remotes.func("ClanTop").OnServerInvoke = function() return ClanService.Top() end
	task.spawn(function() while true do task.wait(60); pcall(flushContributions) end end)
end

return ClanService
