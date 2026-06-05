-- src/server/MonetizationService.lua  | the money brain: receipts, passes, subscription, premium.
-- Sets runtime boost flags on each profile that other services read:
--   profile._droppingsMult (number), profile._passSlots (number), profile._premium (bool)
local Players          = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local Remotes          = require(script.Parent.Remotes)
local ShopConfig       = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ShopConfig"))
local UnlockConfig     = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UnlockConfig"))

local MonetizationService = {}

-- product lookup by id (ignore unset 0 placeholders)
local productById = {}
for _, prod in ipairs(ShopConfig.DeveloperProducts) do
	if prod.id and prod.id ~= 0 then productById[prod.id] = prod end
end
-- extra products (eggs/abilities/potions) keyed for receipt grants
local extraById = {}
for _, prod in ipairs(ShopConfig.ExtraProducts or {}) do
	if prod.id and prod.id ~= 0 then extraById[prod.id] = prod end
end

local function grant(player, spec)
	local profile = PlayerData.Get(player); if not profile then return false end
	if spec.type == "currency" then
		return CurrencyService.Add(player, spec.currency, spec.amount)
	elseif spec.type == "luck" then
		local now = os.time()
		local base = math.max(now, profile.luckBoostUntil or 0)
		profile.luckBoostUntil = base + (spec.seconds or 0)
		return true
	elseif spec.type == "slots" then
		profile.bonusSquadSlots = (profile.bonusSquadSlots or 0) + (spec.slots or 0)
		InventoryService.Push(player)
		return true
	end
	return false
end

-- recompute every boost flag for a player (called on join + purchase + status changes)
function MonetizationService.Refresh(player)
	local profile = PlayerData.Get(player); if not profile then return end
	local mult, passSlots = 1, 0

	-- premium membership (native) -> powers the idler + small boost
	profile._premium = (player.MembershipType == Enum.MembershipType.Premium)
	if profile._premium then mult *= 1.1 end

	-- game passes (from ShopConfig + the big UnlockConfig pass list)
	local passDefs = {}
	for _, g in ipairs(ShopConfig.GamePasses) do passDefs[#passDefs + 1] = g end
	for _, g in ipairs(UnlockConfig.Passes) do passDefs[#passDefs + 1] = g end

	-- reset perk flags, then set from owned passes
	profile._passSlots = 0
	profile._open5 = false; profile._open10 = false; profile._autocollect = false
	profile._x2forever = false; profile._luckx2 = false; profile._fasttravel = false
	profile._vip = profile._premium or false

	for _, pass in ipairs(passDefs) do
		if pass.id and pass.id ~= 0 then
			local ok, owned = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			if ok and owned then
				local k = pass.perk
				if k == "vip" then mult *= 2; profile._vip = true
				elseif k == "slots10" then passSlots += 10
				elseif k == "x2forever" then profile._x2forever = true
				elseif k == "luckx2" then profile._luckx2 = true
				elseif k == "open5" then profile._open5 = true
				elseif k == "open10" then profile._open10 = true; profile._open5 = true
				elseif k == "autocollect" then profile._autocollect = true
				elseif k == "fasttravel" then profile._fasttravel = true end
			end
		end
	end

	-- native subscription
	local sub = ShopConfig.Subscription
	if sub and sub.id and sub.id ~= "EXP-REPLACE" then
		local ok, status = pcall(function()
			return MarketplaceService:GetUserSubscriptionStatusAsync(player, sub.id)
		end)
		if ok and status and status.IsSubscribed then mult *= 1.25 end
	end

	profile._droppingsMult = mult
	profile._passSlots = passSlots
	InventoryService.Push(player)
end

function MonetizationService.Start()
	-- ONE ProcessReceipt for the whole game, idempotent via profile.purchaseHistory
	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
		local profile = PlayerData.Get(player)
		if not profile or PlayerData._loaded[player.UserId] == false then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		profile.purchaseHistory = profile.purchaseHistory or {}
		if profile.purchaseHistory[receipt.PurchaseId] then
			return Enum.ProductPurchaseDecision.PurchaseGranted -- already handled
		end
		local prod = productById[receipt.ProductId]
		local extra = extraById[receipt.ProductId]
		if not prod and not extra then return Enum.ProductPurchaseDecision.NotProcessedYet end

		local okGrant
		if prod then
			okGrant = grant(player, prod.grant)
		else
			-- eggs/abilities/potions by key
			local key = extra.key
			if key:sub(1, 4) == "egg_" then
				profile.unlockedEggs = profile.unlockedEggs or {}
				profile.unlockedEggs[key:sub(5)] = true; okGrant = true
			elseif key:sub(1, 8) == "ability_" then
				profile.abilities = profile.abilities or {}
				profile.abilities[key:sub(9)] = true; okGrant = true
			elseif key == "potion_mega" then
				profile.potions = profile.potions or {}
				local now = os.time(); local cur = profile.potions.earn
				if cur and (cur["until"] or 0) > now then cur["until"] += 1800; cur.power = math.max(cur.power or 1, 5)
				else profile.potions.earn = { power = 5, ["until"] = now + 1800 } end
				okGrant = true
			end
		end
		if not okGrant then return Enum.ProductPurchaseDecision.NotProcessedYet end

		profile.purchaseHistory[receipt.PurchaseId] = true
		local saved = PlayerData.Save(player) -- persist BEFORE acknowledging
		if not saved then return Enum.ProductPurchaseDecision.NotProcessedYet end
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	-- grant pass perks the moment a pass is bought
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased then task.spawn(MonetizationService.Refresh, player) end
	end)
	-- react to subscription changes mid-session (only available on published games; guard for Studio)
	pcall(function()
		MarketplaceService.UserSubscriptionStatusChanged:Connect(function(_, userId)
			local player = Players:GetPlayerByUserId(userId)
			if player then task.spawn(MonetizationService.Refresh, player) end
		end)
	end)

	Players.PlayerAdded:Connect(function(player)
		player:GetPropertyChangedSignal("MembershipType"):Connect(function()
			MonetizationService.Refresh(player)
		end)
		task.spawn(function()
			local tries = 0
			while not PlayerData.Get(player) and tries < 50 do task.wait(0.1); tries += 1 end
			MonetizationService.Refresh(player)
		end)
	end)
	for _, p in ipairs(Players:GetPlayers()) do task.spawn(MonetizationService.Refresh, p) end

	-- let the client ask "am I subscribed?" so the shop can hide the subscribe button
	local getStatus = Remotes.func("GetSubscriptionStatus")
	getStatus.OnServerInvoke = function(player)
		local profile = PlayerData.Get(player)
		return {
			subscribed = (profile and (profile._droppingsMult or 1) >= 1.25) or false,
			premium = profile and profile._premium or false,
		}
	end
end

return MonetizationService
