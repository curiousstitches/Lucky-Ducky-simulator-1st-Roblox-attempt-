-- src/server/FishingService.lua  | stand near a FishingPad to passively earn Fish Coins + aquatic ducks
local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DuckGenerator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DuckGenerator"))
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local Remotes          = require(script.Parent.Remotes)

local FishingService = {}
local Notify
local RANGE = 22
local TICK = 5
local rng = Random.new()

local function nearAnyPad(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	for _, pad in ipairs(CollectionService:GetTagged("FishingPad")) do
		if pad:IsA("BasePart") and (pad.Position - root.Position).Magnitude <= RANGE then return true end
	end
	return false
end

function FishingService.Start()
	Notify = Remotes.event("Notify")
	task.spawn(function()
		while true do
			task.wait(TICK)
			for _, player in ipairs(Players:GetPlayers()) do
				if nearAnyPad(player) then
					local p = PlayerData.Get(player)
					local coins = 3 + math.floor((p and p.highestLevel or 1) / 2)
					CurrencyService.Add(player, "FishCoins", coins)
					-- rare aquatic duck catch
					if rng:NextNumber() < 0.08 then
						InventoryService.AddDuck(player, DuckGenerator.roll({ origin = "fishing", luckMul = 1.5, goldenChance = 0.04 }))
						if Notify then Notify:FireClient(player, { text = "🎣 You reeled in a Duck!", color = Color3.fromRGB(90, 200, 230) }) end
					end
				end
			end
		end
	end)
end

return FishingService
