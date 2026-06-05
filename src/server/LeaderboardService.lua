-- src/server/LeaderboardService.lua  | global top-10 by lifetime earnings (OrderedDataStore)
local Players           = game:GetService("Players")
local DataStoreService  = game:GetService("DataStoreService")
local PlayerData        = require(script.Parent.PlayerData)
local Remotes           = require(script.Parent.Remotes)

local LeaderboardService = {}
local STORE
pcall(function()
	STORE = DataStoreService:GetOrderedDataStore("LB_LifetimeEarned_v1")
	STORE:GetSortedAsync(false, 1)
end)
local WRITE_INTERVAL = 90
local nameCache = {}

local function nameFor(userId)
	if nameCache[userId] then return nameCache[userId] end
	local ok, name = pcall(function() return Players:GetNameFromUserIdAsync(userId) end)
	name = ok and name or ("Player" .. userId)
	nameCache[userId] = name
	return name
end

local function writeAll()
	if not STORE then return end
	for _, player in ipairs(Players:GetPlayers()) do
		local p = PlayerData.Get(player)
		if p then
			nameCache[player.UserId] = player.Name
			pcall(function() STORE:SetAsync(tostring(player.UserId), math.floor(p.lifetimeEarned or 0)) end)
		end
	end
end

function LeaderboardService.Top(n)
	n = n or 10
	if not STORE then return {} end
	local ok, pages = pcall(function()
		return STORE:GetSortedAsync(false, n)
	end)
	if not ok then return {} end
	local out = {}
	for _, entry in ipairs(pages:GetCurrentPage()) do
		table.insert(out, { name = nameFor(tonumber(entry.key)), value = entry.value })
	end
	return out
end

function LeaderboardService.Start()
	local getLb = Remotes.func("GetLeaderboard")
	getLb.OnServerInvoke = function() return LeaderboardService.Top(10) end

	task.spawn(function()
		while true do task.wait(WRITE_INTERVAL); writeAll() end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local p = PlayerData.Get(player)
		if p then pcall(function() STORE:SetAsync(tostring(player.UserId), math.floor(p.lifetimeEarned or 0)) end) end
	end)
end

return LeaderboardService
