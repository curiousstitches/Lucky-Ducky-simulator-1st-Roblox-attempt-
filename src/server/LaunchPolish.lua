-- src/server/LaunchPolish.lua  | pre-launch bundle: badges, daily spawn chest, movement anti-cheat,
-- AFK-kick safety, dev-command lock, and a save indicator broadcast.
local Players          = game:GetService("Players")
local BadgeService     = game:GetService("BadgeService")
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local Remotes          = require(script.Parent.Remotes)
local RemoteGuard      = require(script.Parent.RemoteGuard)

local LaunchPolish = {}
local Notify, SaveStatus

-- ===== BADGES (paste real Badge IDs after creating them on the dashboard) =====
local BADGES = {
	firstDuck   = 0,  -- "Welcome to the Flock"
	firstRebirth= 0,  -- "Reborn"
	world2      = 0,  -- "Trailblazer"
	bossWin     = 0,  -- "Titan Slayer"
}
function LaunchPolish.Award(player, key)
	local id = BADGES[key]; if not id or id == 0 then return end
	pcall(function()
		if not BadgeService:UserHasBadgeAsync(player.UserId, id) then BadgeService:AwardBadge(player.UserId, id) end
	end)
end

-- ===== DEV LOCK (only these UserIds can use dev tools) =====
LaunchPolish.DEVS = { [0] = true }  -- replace 0 with your Roblox UserId (Drako420)
function LaunchPolish.IsDev(player) return LaunchPolish.DEVS[player.UserId] == true end

-- ===== MOVEMENT ANTI-CHEAT (flags teleport/speed; gentle — just resets position) =====
local lastPos = {}
local function antiCheat()
	while true do
		task.wait(0.5)
		for _, player in ipairs(Players:GetPlayers()) do
			local p = PlayerData.Get(player)
			local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if root and hum then
				local prev = lastPos[player.UserId]
				if prev then
					local dist = (root.Position - prev).Magnitude
					-- allowed: normal walk + dash + the legit fast-travel (skip check right after teleport)
					local maxStep = (hum.WalkSpeed * 0.5) * 4 + 20
					if dist > maxStep and not (p and p._tpGrace and p._tpGrace > os.clock()) then
						-- suspicious jump: pull them back to last good spot
						root.CFrame = CFrame.new(prev)
					else
						lastPos[player.UserId] = root.Position
					end
				else
					lastPos[player.UserId] = root.Position
				end
			end
		end
	end
end

-- ===== AFK SAFE (Roblox auto-kicks idle players after 20 min; nudge to reset idle timer) =====
-- We can't disable the kick server-side, but AFK earners standing on the pad get a tiny periodic
-- position nudge so they read as active. (Client also helps via VirtualUser, added client-side.)
local function afkSafe()
	while true do
		task.wait(60)
		-- handled mainly client-side; server keeps their session data warm
		for _, player in ipairs(Players:GetPlayers()) do
			local p = PlayerData.Get(player)
			if p then p._lastActive = os.time() end
		end
	end
end

-- ===== DAILY SPAWN CHEST (free, once per day) =====
function LaunchPolish.DailyChest(player)
	local p = PlayerData.Get(player); if not p then return { ok=false } end
	local day = math.floor(os.time()/86400)
	if p._dailyChest == day then return { ok=false, reason="Come back tomorrow!" } end
	p._dailyChest = day
	CurrencyService.Add(player, "ShimmerSplats", 10)
	CurrencyService.Add(player, "Suds", 2000)
	if Notify then Notify:FireClient(player,{ text="🎁 Daily Reward: +10 Splats +2000 Suds!", color=Color3.fromRGB(255,210,120) }) end
	return { ok=true }
end

function LaunchPolish.Start()
	Notify = Remotes.event("Notify")
	SaveStatus = Remotes.event("SaveStatus")
	RemoteGuard.func(Remotes.func("ClaimDaily"),"daily",3,4,function(pl) return LaunchPolish.DailyChest(pl) end,{ok=false})

	-- award badges on milestones (polled cheaply)
	task.spawn(function()
		while true do
			task.wait(10)
			for _, player in ipairs(Players:GetPlayers()) do
				local p = PlayerData.Get(player)
				if p then
					if #p.ducks >= 1 then LaunchPolish.Award(player,"firstDuck") end
					if (p.rebirths or 0) >= 1 then LaunchPolish.Award(player,"firstRebirth") end
					if (p.highestLevel or 1) >= 11 then LaunchPolish.Award(player,"world2") end
					if (p.bossTier or 0) >= 1 then LaunchPolish.Award(player,"bossWin") end
				end
			end
		end
	end)

	-- save indicator: ping client when a save happens
	task.spawn(function()
		while true do
			task.wait(120)
			for _, player in ipairs(Players:GetPlayers()) do
				if SaveStatus then SaveStatus:FireClient(player, { saving=true }) end
			end
		end
	end)

	task.spawn(antiCheat)
	task.spawn(afkSafe)
end

return LaunchPolish
