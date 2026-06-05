-- src/server/IdlerService.lua  | Roblox Premium-gated idle + offline earnings
local Players          = game:GetService("Players")
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local Remotes          = require(script.Parent.Remotes)

local IdlerService = {}
local OFFLINE_CAP = 8 * 3600 -- 8 hours max banked
local TICK        = 60        -- live passive payout cadence (sec)
local OfflineEarnings

local function ratePerSec(player)
	-- passive income scales with your squad so stronger collections idle harder
	return math.max(1, InventoryService.SquadStrength(player) * 0.25)
end

local function isPremium(player)
	local p = PlayerData.Get(player)
	return p and p._premium == true
end

function IdlerService.Start()
	OfflineEarnings = Remotes.event("OfflineEarnings")

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			local tries = 0
			while not PlayerData.Get(player) and tries < 80 do task.wait(0.1); tries += 1 end
			local p = PlayerData.Get(player); if not p then return end
			-- wait a beat for MonetizationService to set the premium flag
			task.wait(1)
			if not isPremium(player) then return end
			if (p.lastSeen or 0) > 0 then
				local away = math.clamp(os.time() - p.lastSeen, 0, OFFLINE_CAP)
				local earned = math.floor(away * ratePerSec(player))
				if earned > 0 then
					CurrencyService.Add(player, "DuckDroppings", earned)
					OfflineEarnings:FireClient(player, { amount = earned, seconds = away })
				end
			end
		end)
	end)

	-- live trickle for premium players while they play
	task.spawn(function()
		while true do
			task.wait(TICK)
			for _, player in ipairs(Players:GetPlayers()) do
				if isPremium(player) then
					CurrencyService.Add(player, "DuckDroppings", math.floor(ratePerSec(player) * TICK))
				end
			end
		end
	end)
end

return IdlerService
