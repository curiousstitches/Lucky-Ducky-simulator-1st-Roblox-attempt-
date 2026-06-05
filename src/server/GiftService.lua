-- src/server/GiftService.lua  | gift boxes spawn in the world, get collected, opened, or sold
local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnlockConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UnlockConfig"))
local EventConfig  = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("EventConfig"))
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local Remotes          = require(script.Parent.Remotes)
local RemoteGuard      = require(script.Parent.RemoteGuard)

local GiftService = {}
local Notify
local SPAWN_EVERY = 45
local MAX_LOOSE = 20
local rng = Random.new()

local function rollTier(eventActive)
	local pool = {}
	local total = 0
	for _, t in ipairs(UnlockConfig.GiftTiers) do
		if (not t.eventOnly) or eventActive then pool[#pool + 1] = t; total += t.weight end
	end
	local r = rng:NextNumber(0, total); local acc = 0
	for _, t in ipairs(pool) do acc += t.weight; if r <= acc then return t end end
	return pool[1]
end

local function spawnLoose()
	local folder = Workspace:FindFirstChild("LooseGifts") or Instance.new("Folder")
	folder.Name = "LooseGifts"; folder.Parent = Workspace
	if #folder:GetChildren() >= MAX_LOOSE then return end
	local tier = rollTier(true)
	local box = Instance.new("Part")
	box.Size = Vector3.new(3, 3, 3); box.Anchored = true; box.Material = Enum.Material.Neon
	box.Color = (tier.id == "epic" and Color3.fromRGB(180, 90, 255)) or (tier.id == "event" and Color3.fromRGB(255, 90, 160))
		or (tier.id == "rare" and Color3.fromRGB(90, 150, 255)) or Color3.fromRGB(200, 170, 90)
	box.Position = Vector3.new(rng:NextNumber(-60, 60), 2.5, rng:NextNumber(-60, 60))
	box:SetAttribute("GiftTier", tier.id)
	CollectionService:AddTag(box, "Gift"); box.Parent = folder
	local touched = false
	box.Touched:Connect(function(hit)
		if touched then return end
		local player = Players:GetPlayerFromCharacter(hit and hit.Parent)
		if not player then return end
		touched = true
		local p = PlayerData.Get(player)
		if p then p.gifts = p.gifts or {}; p.gifts[tier.id] = (p.gifts[tier.id] or 0) + 1 end
		if Notify then Notify:FireClient(player, { text = "🎁 Found a " .. tier.name .. "!", color = Color3.fromRGB(255, 220, 120) }) end
		box:Destroy()
	end)
	task.delay(120, function() if box.Parent then box:Destroy() end end)
end

function GiftService.Open(player, tierId)
	local tier = UnlockConfig.find(UnlockConfig.GiftTiers, tierId); if not tier then return { ok = false } end
	local p = PlayerData.Get(player); if not p then return { ok = false } end
	if (p.gifts[tierId] or 0) <= 0 then return { ok = false, reason = "None to open" } end
	p.gifts[tierId] -= 1
	local amt = rng:NextInteger(tier.reward.min, tier.reward.max)
	CurrencyService.Add(player, tier.reward.currency, amt)
	if Notify then Notify:FireClient(player, { text = ("🎁 %s -> +%d %s"):format(tier.name, amt, tier.reward.currency), color = Color3.fromRGB(120, 230, 140) }) end
	return { ok = true, currency = tier.reward.currency, amount = amt }
end

function GiftService.Sell(player, tierId)
	local tier = UnlockConfig.find(UnlockConfig.GiftTiers, tierId); if not tier then return { ok = false } end
	local p = PlayerData.Get(player); if not p then return { ok = false } end
	if (p.gifts[tierId] or 0) <= 0 then return { ok = false, reason = "None to sell" } end
	if tier.sell <= 0 then return { ok = false, reason = "This gift can't be sold" } end
	p.gifts[tierId] -= 1
	CurrencyService.Add(player, "DuckDroppings", tier.sell)
	return { ok = true }
end

function GiftService.Start()
	Notify = Remotes.event("Notify")
	local openF = Remotes.func("OpenGift")
	local sellF = Remotes.func("SellGift")
	local getF  = Remotes.func("GetGifts")
	RemoteGuard.func(openF, "gift_open", 6, 10, function(pl, id) return GiftService.Open(pl, id) end, { ok = false })
	RemoteGuard.func(sellF, "gift_sell", 6, 10, function(pl, id) return GiftService.Sell(pl, id) end, { ok = false })
	getF.OnServerInvoke = function(player)
		local p = PlayerData.Get(player)
		return { gifts = p and p.gifts or {}, tiers = UnlockConfig.GiftTiers }
	end
	task.spawn(function() while true do task.wait(SPAWN_EVERY); pcall(spawnLoose) end end)
end

return GiftService
