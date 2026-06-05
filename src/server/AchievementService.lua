-- src/server/AchievementService.lua  | milestone achievements grant currency + equippable titles
local Players          = game:GetService("Players")
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local Remotes          = require(script.Parent.Remotes)
local RemoteGuard      = require(script.Parent.RemoteGuard)

local AchievementService = {}
local Notify

-- stat keys come from profile.stats + a few derived. title = unlockable name tag.
local ACH = {
	{ id = "first_duck",  name = "First Feathers",   stat = "ducksHatched",      target = 1,    title = "Hatchling",     reward = { c = "DuckDroppings", a = 500 } },
	{ id = "smash100",    name = "Crate Crusher",    stat = "breakablesSmashed", target = 100,  title = "Crusher",       reward = { c = "DuckDroppings", a = 2500 } },
	{ id = "smash5k",     name = "Demolisher",       stat = "breakablesSmashed", target = 5000, title = "Demolisher",    reward = { c = "ShimmerSplats", a = 25 } },
	{ id = "hatch100",    name = "Duck Hoarder",     stat = "ducksHatched",      target = 100,  title = "Hoarder",       reward = { c = "DuckDroppings", a = 10000 } },
	{ id = "hatch1k",     name = "Flock Master",     stat = "ducksHatched",      target = 1000, title = "Flock Master",  reward = { c = "ShimmerSplats", a = 60 } },
	{ id = "duck10",      name = "Spreading Joy",    stat = "jeepsDucked",       target = 10,   title = "Kind Soul",     reward = { c = "DuckDroppings", a = 3000 } },
	{ id = "duck100",     name = "Duck Crusader",    stat = "jeepsDucked",       target = 100,  title = "Crusader",      reward = { c = "ShimmerSplats", a = 50 } },
	{ id = "rich1m",      name = "Millionaire",      stat = "lifetimeEarned",    target = 1000000,    title = "Millionaire",   reward = { c = "ShimmerSplats", a = 40 } },
	{ id = "rich1b",      name = "Tycoon",           stat = "lifetimeEarned",    target = 1000000000, title = "Tycoon",        reward = { c = "ShimmerSplats", a = 150 } },
	{ id = "level50",     name = "Trailblazer",      stat = "highestLevel",      target = 50,   title = "Trailblazer",   reward = { c = "DuckDroppings", a = 15000 } },
	{ id = "level150",    name = "Pathfinder",       stat = "highestLevel",      target = 150,  title = "Pathfinder",    reward = { c = "ShimmerSplats", a = 75 } },
	{ id = "rebirth1",    name = "Reborn",           stat = "rebirths",          target = 1,    title = "Reborn",        reward = { c = "ShimmerSplats", a = 20 } },
	{ id = "rebirth10",   name = "Ascended",         stat = "rebirths",          target = 10,   title = "Ascended",      reward = { c = "ShimmerSplats", a = 100 } },
}

local function statVal(p, key)
	if key == "lifetimeEarned" then return p.lifetimeEarned or 0 end
	if key == "highestLevel" then return p.highestLevel or 1 end
	if key == "rebirths" then return p.rebirths or 0 end
	return (p.stats and p.stats[key]) or 0
end

function AchievementService.Check(player)
	local p = PlayerData.Get(player); if not p then return end
	p.achievements = p.achievements or {}; p.titles = p.titles or {}
	for _, a in ipairs(ACH) do
		if not p.achievements[a.id] and statVal(p, a.stat) >= a.target then
			p.achievements[a.id] = true
			p.titles[a.title] = true
			CurrencyService.Add(player, a.reward.c, a.reward.a)
			if Notify then Notify:FireClient(player, { text = ("🏆 Achievement: %s! Title unlocked: \"%s\""):format(a.name, a.title), color = Color3.fromRGB(255, 215, 60) }) end
		end
	end
end

function AchievementService.Snapshot(player)
	local p = PlayerData.Get(player); if not p then return {} end
	local rows = {}
	for _, a in ipairs(ACH) do
		rows[#rows + 1] = { id = a.id, name = a.name, title = a.title,
			done = (p.achievements or {})[a.id] == true,
			progress = math.min(statVal(p, a.stat), a.target), target = a.target }
	end
	return { rows = rows, titles = p.titles or {}, active = p.activeTitle }
end

function AchievementService.SetTitle(player, title)
	local p = PlayerData.Get(player); if not p then return { ok = false } end
	if title == nil or title == "" then p.activeTitle = nil; player:SetAttribute("Title", "")
	elseif (p.titles or {})[title] then p.activeTitle = title; player:SetAttribute("Title", title)
	else return { ok = false } end
	return { ok = true }
end

function AchievementService.Start()
	Notify = Remotes.event("Notify")
	Remotes.func("GetAchievements").OnServerInvoke = function(player) return AchievementService.Snapshot(player) end
	RemoteGuard.func(Remotes.func("SetTitle"), "title", 4, 6, function(pl, t) return AchievementService.SetTitle(pl, t) end, { ok = false })

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			local tries = 0
			while not PlayerData.Get(player) and tries < 60 do task.wait(0.1); tries += 1 end
			local p = PlayerData.Get(player)
			if p and p.activeTitle then player:SetAttribute("Title", p.activeTitle) end
		end)
	end)
	task.spawn(function()
		while true do
			task.wait(8)
			for _, player in ipairs(Players:GetPlayers()) do AchievementService.Check(player) end
		end
	end)
end

return AchievementService
