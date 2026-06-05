-- src/server/EnemyEventService.lua  | random timed world events (server-wide alerts) + roaming enemies
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local PlayerData        = require(script.Parent.PlayerData)
local CurrencyService   = require(script.Parent.CurrencyService)
local InventoryService  = require(script.Parent.InventoryService)
local Remotes           = require(script.Parent.Remotes)

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local DuckGenerator = require(Shared:WaitForChild("DuckGenerator"))

local EnemyEventService = {}
local Notify, Alert
local rng = Random.new()

-- ===== RANDOM EVENTS (can fire anytime, anywhere) =====
local RANDOM_EVENTS = {
	{ id = "rain",   text = "🌧️ DROPPINGS RAIN! Breakables pay 3x for 60s!", mult = 3, dur = 60 },
	{ id = "swarm",  text = "🦆 GOLDEN SWARM! Shiny odds way up for 90s!",     mult = 1, dur = 90, luck = 3 },
	{ id = "frenzy", text = "⚡ SMASH FRENZY! Squad power x2 for 45s!",        mult = 1, dur = 45, power = 2 },
	{ id = "gifts",  text = "🎁 GIFT STORM! Boxes everywhere for 60s!",        mult = 1, dur = 60, gifts = true },
}

local function broadcast(text, color)
	for _, player in ipairs(Players:GetPlayers()) do
		if Notify then Notify:FireClient(player, { text = text, color = color or Color3.fromRGB(255, 215, 60) }) end
		if Alert then Alert:FireClient(player, { text = text }) end
	end
end

local function runRandomEvent()
	local ev = RANDOM_EVENTS[rng:NextInteger(1, #RANDOM_EVENTS)]
	broadcast(ev.text, Color3.fromRGB(255, 200, 70))
	for _, player in ipairs(Players:GetPlayers()) do
		local p = PlayerData.Get(player); if p then
			if ev.mult and ev.mult > 1 then p._randomMult = ev.mult end
			if ev.luck then p._randomLuck = ev.luck end
		end
	end
	task.delay(ev.dur, function()
		for _, player in ipairs(Players:GetPlayers()) do
			local p = PlayerData.Get(player); if p then p._randomMult = nil; p._randomLuck = nil end
		end
		broadcast("✨ Event ended — back to normal", Color3.fromRGB(150, 200, 255))
	end)
end

-- ===== ROAMING ENEMIES (scale with the player's highest level) =====
local function spawnEnemy()
	local folder = Workspace:FindFirstChild("Enemies") or Instance.new("Folder")
	folder.Name = "Enemies"; folder.Parent = Workspace
	if #folder:GetChildren() >= 6 then return end
	-- pick a random online player to spawn near, scaled to their progress
	local online = Players:GetPlayers(); if #online == 0 then return end
	local target = online[rng:NextInteger(1, #online)]
	local p = PlayerData.Get(target); if not p then return end
	local lvl = p.highestLevel or 1
	local char = target.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local hp = math.floor(80 * (1.1 ^ lvl))
	local reward = math.floor(50 * (1.08 ^ lvl))
	local enemy = Instance.new("Part")
	enemy.Size = Vector3.new(5, 6, 5); enemy.Anchored = true; enemy.Material = Enum.Material.Neon
	enemy.Color = Color3.fromRGB(200, 40, 40)
	enemy.Position = root.Position + Vector3.new(rng:NextNumber(-20, 20), 3, rng:NextNumber(-20, 20))
	enemy:SetAttribute("HP", hp); enemy:SetAttribute("MaxHP", hp); enemy:SetAttribute("Reward", reward)
	enemy:SetAttribute("EnemyLevel", lvl)
	CollectionService:AddTag(enemy, "Enemy")
	enemy.Parent = folder

	local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(0, 120, 0, 30); bb.AlwaysOnTop = true; bb.Parent = enemy
	local hl = Instance.new("TextLabel"); hl.Size = UDim2.fromScale(1, 1); hl.BackgroundTransparency = 1
	hl.Font = Enum.Font.GothamBold; hl.TextScaled = true; hl.TextColor3 = Color3.fromRGB(255, 120, 120)
	hl.Text = "👹 Lv" .. lvl; hl.Parent = enemy

	if Notify then Notify:FireClient(target, { text = "👹 A Trail Gremlin appeared! Smash it for loot!", color = Color3.fromRGB(255, 90, 90) }) end
	task.delay(45, function() if enemy.Parent then enemy:Destroy() end end)
end

-- enemies take damage from nearby equipped squads (reuses farm-style proximity)
local function combatLoop()
	while true do
		task.wait(0.4)
		local folder = Workspace:FindFirstChild("Enemies")
		if folder then
			for _, enemy in ipairs(folder:GetChildren()) do
				if enemy:IsA("BasePart") and enemy:GetAttribute("HP") then
					for _, player in ipairs(Players:GetPlayers()) do
						local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
						if root and (root.Position - enemy.Position).Magnitude <= 24 then
							local dmg = InventoryService.SquadStrength(player) * 0.4 * 4
							local hp = enemy:GetAttribute("HP") - dmg
							enemy:SetAttribute("HP", hp)
							if hp <= 0 then
								CurrencyService.Add(player, "DuckDroppings", enemy:GetAttribute("Reward") or 0)
								if rng:NextNumber() < 0.3 then InventoryService.AddDuck(player, DuckGenerator.roll({ origin = "enemy" })) end
								if Notify then Notify:FireClient(player, { text = "💥 Gremlin smashed! +" .. (enemy:GetAttribute("Reward") or 0), color = Color3.fromRGB(120, 230, 140) }) end
								enemy:Destroy()
								break
							end
						end
					end
				end
			end
		end
	end
end

function EnemyEventService.Start()
	Notify = Remotes.event("Notify")
	Alert = Remotes.event("Alert")
	-- random world events kept (Droppings Rain, etc.); roaming enemies removed in favor of the Boss Arena.
	task.spawn(function() while true do task.wait(rng:NextInteger(120, 300)); pcall(runRandomEvent) end end)
end

return EnemyEventService
