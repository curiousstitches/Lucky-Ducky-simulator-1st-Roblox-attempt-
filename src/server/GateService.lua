-- src/server/GateService.lua  | level gates (pay-to-pass, scales up) + VIP pad entry
local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")
local PlayerData        = require(script.Parent.PlayerData)
local CurrencyService   = require(script.Parent.CurrencyService)
local Remotes           = require(script.Parent.Remotes)

local GateService = {}
local Notify
local debounce = {}

local function tp(player, pos)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then root.CFrame = CFrame.new(pos) end
end

local function onGate(gate, hit)
	local char = hit and hit.Parent
	local player = char and Players:GetPlayerFromCharacter(char)
	if not player then return end
	local key = player.UserId .. "_g"
	if debounce[key] then return end
	debounce[key] = true; task.delay(1, function() debounce[key] = nil end)

	local level = gate:GetAttribute("GateLevel"); local baseCost = gate:GetAttribute("GateCost")
	local gateCurrency = gate:GetAttribute("GateCurrency") or "DuckDroppings"
	local p = PlayerData.Get(player); if not p then return end
	local ModeService = require(script.Parent.ModeService)
	local mode = p.mode or "normal"
	local cost = math.floor(baseCost * ModeService.DifficultyMult(player))
	local highestKey = (mode == "hardcore") and "hardcoreHighest" or "highestLevel"
	if (p[highestKey] or 1) >= level then return end -- already cleared in this mode
	-- mandatory rebirth wall: if the next gate is a rebirth stage the player hasn't done, block it
	local LaunchService = require(script.Parent.LaunchService)
	if level and level % 10 == 0 and LaunchService.NextRebirthStage(p) <= level and (p.rebirthLadder or 0) < (level/10) then
		if Notify then Notify:FireClient(player, { text = ("🔄 Stage %d requires REBIRTH — find the shrine to continue!"):format(level), color = Color3.fromRGB(255, 200, 90) }) end
		tp(player, gate.Position - gate.CFrame.LookVector * 8 + Vector3.new(0, 4, 0))
		return
	end
	if CurrencyService.Spend(player, gateCurrency, cost) then
		p[highestKey] = math.max(p[highestKey] or 1, level)
		if Notify then Notify:FireClient(player, { text = ("⛩️ Level %d unlocked! (%s)"):format(level, mode), color = Color3.fromRGB(80, 230, 120) }) end
	else
		if Notify then Notify:FireClient(player, { text = ("🔒 Gate %d needs %d Duck Droppings"):format(level, cost), color = Color3.fromRGB(255, 150, 0) }) end
		tp(player, gate.Position - gate.CFrame.LookVector * 8 + Vector3.new(0, 4, 0))
	end
end

local function onVIP(pad, hit)
	local char = hit and hit.Parent
	local player = char and Players:GetPlayerFromCharacter(char)
	if not player then return end
	local key = player.UserId .. "_v"
	if debounce[key] then return end
	debounce[key] = true; task.delay(1.5, function() debounce[key] = nil end)
	local p = PlayerData.Get(player); if not p then return end
	if p._vip then
		local WorldBuilder = require(script.Parent.WorldBuilder)
		tp(player, WorldBuilder.VIPSpawn or Vector3.new(-600, 6, 0))
	else
		if Notify then Notify:FireClient(player, { text = "👑 VIP Lounge needs the VIP pass (shop)", color = Color3.fromRGB(255, 200, 60) }) end
	end
end

function GateService.Start()
	Notify = Remotes.event("Notify")
	local function hookGate(g) if g:IsA("BasePart") then g.Touched:Connect(function(h) onGate(g, h) end) end end
	local function hookVIP(g) if g:IsA("BasePart") then g.Touched:Connect(function(h) onVIP(g, h) end) end end
	for _, g in ipairs(CollectionService:GetTagged("LevelGate")) do hookGate(g) end
	CollectionService:GetInstanceAddedSignal("LevelGate"):Connect(hookGate)
	for _, g in ipairs(CollectionService:GetTagged("VIPPad")) do hookVIP(g) end
	CollectionService:GetInstanceAddedSignal("VIPPad"):Connect(hookVIP)

	-- rebirth shrines: touch to do the mandatory ladder rebirth
	local LaunchService = require(script.Parent.LaunchService)
	local function onShrine(shrine, hit)
		local player = Players:GetPlayerFromCharacter(hit and hit.Parent); if not player then return end
		local key = player.UserId .. "_rb"
		if debounce[key] then return end
		debounce[key] = true; task.delay(3, function() debounce[key] = nil end)
		local res = LaunchService.DoRebirth(player)
		if Notify and res and res.reason then Notify:FireClient(player, { text = res.reason, color = Color3.fromRGB(255, 200, 90) }) end
	end
	local function hookShrine(s) if s:IsA("BasePart") then s.Touched:Connect(function(h) onShrine(s, h) end) end end
	for _, s in ipairs(CollectionService:GetTagged("RebirthShrine")) do hookShrine(s) end
	CollectionService:GetInstanceAddedSignal("RebirthShrine"):Connect(hookShrine)
end

return GateService
