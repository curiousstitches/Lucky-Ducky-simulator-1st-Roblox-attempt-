-- src/server/SeasonService.lua  | season XP (from earnings this season) + tier reward claims
local Players            = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local SeasonConfig  = require(Shared:WaitForChild("SeasonConfig"))
local ShopConfig    = require(Shared:WaitForChild("ShopConfig"))
local PlayerData    = require(script.Parent.PlayerData)
local CurrencyService = require(script.Parent.CurrencyService)
local Remotes       = require(script.Parent.Remotes)
local RemoteGuard   = require(script.Parent.RemoteGuard)

local SeasonService = {}
local Notify

local function passId()
	for _, g in ipairs(ShopConfig.GamePasses) do
		if g.perk == SeasonConfig.PremiumPassKey then return g.id end
	end
	return 0
end

local function ensureSeason(profile)
	profile.season = profile.season or { id = -1, baseEarned = 0, claimed = {}, claimedP = {} }
	local cur = SeasonConfig.currentSeason()
	if profile.season.id ~= cur then
		profile.season = { id = cur, baseEarned = profile.lifetimeEarned or 0, claimed = {}, claimedP = {} }
	end
end

local function tierOf(profile)
	ensureSeason(profile)
	local earnedThisSeason = math.max(0, (profile.lifetimeEarned or 0) - profile.season.baseEarned)
	return math.floor(earnedThisSeason / SeasonConfig.XpPerTier), earnedThisSeason
end

local function hasPremium(player)
	local id = passId(); if id == 0 then return false end
	local ok, owned = pcall(function() return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id) end)
    return ok and owned
end

local function grant(player, spec)
	if spec.type == "luck" then
		local p = PlayerData.Get(player); if not p then return end
		p.luckBoostUntil = math.max(os.time(), p.luckBoostUntil or 0) + (spec.seconds or 600)
	else
		CurrencyService.Add(player, spec.currency, spec.amount)
	end
end

function SeasonService.Snapshot(player)
	local p = PlayerData.Get(player); if not p then return {} end
	local tier, xp = tierOf(p)
	local rows = {}
	for _, t in ipairs(SeasonConfig.Tiers) do
		rows[#rows + 1] = {
			tier = t.tier, unlocked = tier >= t.tier,
			freeClaimed = p.season.claimed[tostring(t.tier)] == true,
			premiumClaimed = p.season.claimedP[tostring(t.tier)] == true,
			free = ("%d %s"):format(t.free.amount, t.free.currency),
			premium = ("%d %s"):format(t.premium.amount, t.premium.currency),
		}
	end
	return {
		tier = tier, xp = xp, xpPerTier = SeasonConfig.XpPerTier,
		premium = hasPremium(player), endsAt = SeasonConfig.seasonEndsAt(),
		season = p.season.id, rows = rows,
	}
end

function SeasonService.Claim(player, tierNum, track)
	local p = PlayerData.Get(player); if not p then return { ok = false } end
	local t = SeasonConfig.Tiers[tierNum]; if not t then return { ok = false } end
	local reached = tierOf(p)
	if reached < t.tier then return { ok = false, reason = "Tier locked" } end
	if track == "premium" then
		if not hasPremium(player) then return { ok = false, reason = "Premium pass required" } end
		if p.season.claimedP[tostring(t.tier)] then return { ok = false, reason = "Already claimed" } end
		p.season.claimedP[tostring(t.tier)] = true
		grant(player, t.premium)
	else
		if p.season.claimed[tostring(t.tier)] then return { ok = false, reason = "Already claimed" } end
		p.season.claimed[tostring(t.tier)] = true
		grant(player, t.free)
	end
	return { ok = true }
end

function SeasonService.Start()
	Notify = Remotes.event("Notify")
	local snap = Remotes.func("GetSeason")
	local claim = Remotes.func("ClaimSeason")
	RemoteGuard.func(snap, "season_get", 4, 6, function(player) return SeasonService.Snapshot(player) end, {})
	RemoteGuard.func(claim, "season_claim", 6, 10, function(player, tierNum, track)
		return SeasonService.Claim(player, tierNum, track)
	end, { ok = false, reason = "slow down" })

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			local tries = 0
			while not PlayerData.Get(player) and tries < 60 do task.wait(0.1); tries += 1 end
			local p = PlayerData.Get(player); if p then ensureSeason(p) end
		end)
	end)
end

return SeasonService
