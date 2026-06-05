-- src/server/EngagementService.lua  | daily login streak reward + 3 rotating daily quests
local Players          = game:GetService("Players")
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local Remotes          = require(script.Parent.Remotes)

local EngagementService = {}
local Notify, GetTasks, ClaimQuest

local QUESTS = {
	{ key = "breakablesSmashed", target = 100, name = "Smash 100 crates",  reward = { currency = "DuckDroppings", amount = 1500 } },
	{ key = "ducksHatched",      target = 10,  name = "Collect 10 ducks",  reward = { currency = "DuckDroppings", amount = 1000 } },
	{ key = "jeepsDucked",       target = 3,   name = "Duck 3 Jeeps",      reward = { currency = "ShimmerSplats", amount = 5 } },
}

local function today() return math.floor(os.time() / 86400) end

local function rollDaily(player)
	local p = PlayerData.Get(player); if not p then return end
	local d = today()
	p.daily = p.daily or { lastDay = 0, streak = 0 }
	if p.daily.lastDay == d then return end
	p.daily.streak = (p.daily.lastDay == d - 1) and (p.daily.streak + 1) or 1
	p.daily.lastDay = d
	local reward = math.min(250 * p.daily.streak, 5000)
	CurrencyService.Add(player, "DuckDroppings", reward)
	if Notify then Notify:FireClient(player, {
		text = ("📅 Daily reward! Day %d streak — +%d Duck Droppings"):format(p.daily.streak, reward),
		color = Color3.fromRGB(120, 210, 255) }) end
end

local function refreshQuests(player)
	local p = PlayerData.Get(player); if not p then return end
	local d = today()
	p.quests = p.quests or { day = 0, snapshot = {}, claimed = {} }
	if p.quests.day ~= d then
		p.quests.day = d
		p.quests.claimed = {}
		p.quests.snapshot = {}
		for _, q in ipairs(QUESTS) do
			p.quests.snapshot[q.key] = (p.stats and p.stats[q.key]) or 0
		end
	end
end

local function tasksFor(player)
	local p = PlayerData.Get(player); if not p then return {} end
	refreshQuests(player)
	local out = {}
	for i, q in ipairs(QUESTS) do
		local base = (p.quests.snapshot[q.key]) or 0
		local cur = (p.stats and p.stats[q.key]) or 0
		out[i] = {
			name = q.name, target = q.target,
			progress = math.clamp(cur - base, 0, q.target),
			claimed = p.quests.claimed[tostring(i)] == true,
			reward = ("%d %s"):format(q.reward.amount, q.reward.currency),
		}
	end
	return out
end

function EngagementService.Start()
	Notify = Remotes.event("Notify")
	GetTasks = Remotes.func("GetTasks")
	ClaimQuest = Remotes.func("ClaimQuest")

	GetTasks.OnServerInvoke = function(player) return tasksFor(player) end
	ClaimQuest.OnServerInvoke = function(player, index)
		local p = PlayerData.Get(player); if not p then return { ok = false } end
		local q = QUESTS[index]; if not q then return { ok = false } end
		refreshQuests(player)
		if p.quests.claimed[tostring(index)] then return { ok = false, reason = "Already claimed" } end
		local base = p.quests.snapshot[q.key] or 0
		local cur = (p.stats and p.stats[q.key]) or 0
		if (cur - base) < q.target then return { ok = false, reason = "Not finished yet" } end
		p.quests.claimed[tostring(index)] = true
		CurrencyService.Add(player, q.reward.currency, q.reward.amount)
		if Notify then Notify:FireClient(player, { text = "✅ Quest complete: " .. q.name, color = Color3.fromRGB(80, 230, 120) }) end
		return { ok = true }
	end

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			local tries = 0
			while not PlayerData.Get(player) and tries < 60 do task.wait(0.1); tries += 1 end
			refreshQuests(player)
			task.wait(1.5) -- let the welcome settle before the daily toast
			rollDaily(player)
		end)
	end)
end

return EngagementService
