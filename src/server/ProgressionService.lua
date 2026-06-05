-- src/server/ProgressionService.lua  | biome unlock + teleport via tagged pads
local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local BiomeConfig   = require(Shared:WaitForChild("BiomeConfig"))
local PlayerData     = require(script.Parent.PlayerData)
local CurrencyService = require(script.Parent.CurrencyService)
local Remotes        = require(script.Parent.Remotes)

local ProgressionService = {}
local Notify
local touchDebounce = {}

function ProgressionService.IsUnlocked(player, biomeId)
	local p = PlayerData.Get(player)
	return p and p.unlockedBiomes and p.unlockedBiomes[biomeId] == true
end

-- returns ok, reason
function ProgressionService.TryUnlock(player, biome)
	local p = PlayerData.Get(player); if not p then return false, "loading" end
	if p.unlockedBiomes[biome.id] then return true end
	if (p.rebirths or 0) < (biome.minRebirths or 0) then
		return false, ("Needs %d rebirth(s)"):format(biome.minRebirths)
	end
	local cost = biome.unlockCost
	if cost then
		if not CurrencyService.CanAfford(player, cost.currency, cost.amount) then
			return false, ("Costs %d %s"):format(cost.amount, cost.currency)
		end
		CurrencyService.Spend(player, cost.currency, cost.amount)
	end
	p.unlockedBiomes[biome.id] = true
	return true
end

local function teleport(player, pos)
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root then root.CFrame = CFrame.new(pos) end
end

local function onPadTouch(pad, hit)
	local char = hit and hit.Parent
	local player = char and Players:GetPlayerFromCharacter(char)
	if not player then return end
	if touchDebounce[player.UserId] then return end
	touchDebounce[player.UserId] = true
	task.delay(1.2, function() touchDebounce[player.UserId] = nil end)

	local biomeId = pad:GetAttribute("BiomeId")
	if biomeId == "hub" then
		teleport(player, BiomeConfig.HubPos); return
	end
	local biome = BiomeConfig.get(biomeId); if not biome then return end
	if ProgressionService.IsUnlocked(player, biomeId) then
		teleport(player, BiomeConfig.spawnPos(biome))
	else
		local ok, reason = ProgressionService.TryUnlock(player, biome)
		if ok then
			if Notify then Notify:FireClient(player, { text = "🔓 Unlocked " .. biome.name .. "!", color = Color3.fromRGB(80,230,120) }) end
			teleport(player, BiomeConfig.spawnPos(biome))
		else
			if Notify then Notify:FireClient(player, { text = "🔒 " .. biome.name .. " — " .. (reason or "locked"), color = Color3.fromRGB(255,150,0) }) end
		end
	end
end

function ProgressionService.Start()
	Notify = Remotes.event("Notify")
	local function hook(pad) if pad:IsA("BasePart") then pad.Touched:Connect(function(hit) onPadTouch(pad, hit) end) end end
	for _, pad in ipairs(CollectionService:GetTagged("BiomePad")) do hook(pad) end
	CollectionService:GetInstanceAddedSignal("BiomePad"):Connect(hook)
end

return ProgressionService
