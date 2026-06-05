-- src/server/ModeService.lua  | Normal vs Hardcore dual-mode.
-- RULES (per the design):
--   * Every new player is in NORMAL.
--   * Hardcore unlocks by reaching level 200 in Normal, OR owning the VIP pass.
--   * Hardcore difficulty/cost scales as if you were at level 400 (2x the curve),
--     so the grind is harder UNLESS you've already finished all 400 Normal levels.
--   * Players without the unlock CANNOT enter hardcore even if invited/teleported.
local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))
local PlayerData  = require(script.Parent.PlayerData)
local Remotes     = require(script.Parent.Remotes)
local RemoteGuard = require(script.Parent.RemoteGuard)

local ModeService = {}
local Notify, ModeSync
ModeService.HARDCORE_UNLOCK_LEVEL = math.floor(WorldConfig.TotalLevels / 2) -- 150 of 300 (==“200 of 400” ratio)
ModeService.HARDCORE_DIFFICULTY_MULT = 2.0 -- hardcore plays like the far end of the curve

function ModeService.IsHardcoreEligible(player)
	local p = PlayerData.Get(player); if not p then return false end
	if p._vip then return true end                              -- VIP pass auto-unlocks
	if (p.highestLevel or 1) >= ModeService.HARDCORE_UNLOCK_LEVEL then return true end
	return false
end

-- the multiplier applied to gate costs / enemy hp etc. depending on active mode
function ModeService.DifficultyMult(player)
	local p = PlayerData.Get(player); if not p then return 1 end
	return (p.mode == "hardcore") and ModeService.HARDCORE_DIFFICULTY_MULT or 1
end

-- the reward multiplier for braving hardcore (worth the pain)
function ModeService.HardcoreRewardMult(player)
	local p = PlayerData.Get(player)
	return (p and p.mode == "hardcore") and 2.5 or 1
end

function ModeService.Sync(player)
	local p = PlayerData.Get(player); if not (p and ModeSync) then return end
	-- keep the unlock flag fresh
	if not p.hardcoreUnlocked and ModeService.IsHardcoreEligible(player) then
		p.hardcoreUnlocked = true
		if Notify then Notify:FireClient(player, { text = "🔥 HARDCORE MODE UNLOCKED! Brutal grind, 2.5x rewards.", color = Color3.fromRGB(255, 90, 90) }) end
	end
	ModeSync:FireClient(player, {
		mode = p.mode or "normal",
		unlocked = p.hardcoreUnlocked or ModeService.IsHardcoreEligible(player),
		unlockLevel = ModeService.HARDCORE_UNLOCK_LEVEL,
		highest = p.highestLevel or 1,
		hardcoreHighest = p.hardcoreHighest or 1,
		isVip = p._vip or false,
	})
end

function ModeService.SetMode(player, mode)
	local p = PlayerData.Get(player); if not p then return { ok = false } end
	if mode == "hardcore" then
		if not ModeService.IsHardcoreEligible(player) then
			if Notify then Notify:FireClient(player, {
				text = ("🔒 Hardcore needs Level %d in Normal, or the VIP pass."):format(ModeService.HARDCORE_UNLOCK_LEVEL),
				color = Color3.fromRGB(255, 150, 0) }) end
			return { ok = false, reason = "locked" }
		end
		p.hardcoreUnlocked = true
		p.mode = "hardcore"
	else
		p.mode = "normal"
	end
	ModeService.Sync(player)
	if Notify then Notify:FireClient(player, { text = (p.mode == "hardcore") and "🔥 Entered HARDCORE" or "🌿 Back to NORMAL", color = Color3.fromRGB(120, 210, 255) }) end
	return { ok = true, mode = p.mode }
end

function ModeService.Start()
	Notify = Remotes.event("Notify")
	ModeSync = Remotes.event("ModeSync")
	local setMode = Remotes.func("SetMode")
	RemoteGuard.func(setMode, "set_mode", 3, 4, function(player, mode) return ModeService.SetMode(player, mode) end, { ok = false })

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			local tries = 0
			while not PlayerData.Get(player) and tries < 60 do task.wait(0.1); tries += 1 end
			task.wait(1.5) -- let monetization set _vip first
			ModeService.Sync(player)
		end)
	end)
	-- periodic re-sync so the unlock fires the moment they hit the level
	task.spawn(function()
		while true do
			task.wait(5)
			for _, player in ipairs(Players:GetPlayers()) do ModeService.Sync(player) end
		end
	end)
end

return ModeService
