-- src/server/CurrencyService.lua  | server-authoritative wallet ops + client sync
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerData = require(script.Parent.PlayerData)
local Currencies = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Currencies"))
local BigNum     = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("BigNum"))

local CurrencyService = {}
local BalanceChanged

function CurrencyService.Start()
	local folder = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage

	BalanceChanged = folder:FindFirstChild("BalanceChanged") or Instance.new("RemoteEvent")
	BalanceChanged.Name = "BalanceChanged"
	BalanceChanged.Parent = folder

	local req = folder:FindFirstChild("RequestBalance") or Instance.new("RemoteEvent")
	req.Name = "RequestBalance"
	req.Parent = folder
	req.OnServerEvent:Connect(function(player) CurrencyService.PushBalance(player) end)
end

function CurrencyService.PushBalance(player)
	local profile = PlayerData.Get(player)
	if profile and BalanceChanged then BalanceChanged:FireClient(player, profile.wallet) end
end

function CurrencyService.Get(player, currency)
	local profile = PlayerData.Get(player)
	return profile and (profile.wallet[currency] or 0) or 0
end

function CurrencyService.Add(player, currency, amount)
	if currency == "Robux" then return false end -- Robux is never a wallet balance
	if not Currencies.isValid(currency) then
		warn("[Currency] rejected unknown id: " .. tostring(currency)); return false
	end
	if type(amount) ~= "number" or amount == 0 then return false end
	local profile = PlayerData.Get(player)
	if not profile then return false end
	profile.wallet[currency] = BigNum.safe((profile.wallet[currency] or 0) + amount)
	if amount > 0 then
		profile.lifetimeEarned = (profile.lifetimeEarned or 0) + amount
		if profile.clanId then profile._clanPending = (profile._clanPending or 0) + amount end
	end
	CurrencyService.PushBalance(player)
	return true
end

function CurrencyService.CanAfford(player, currency, cost)
	return CurrencyService.Get(player, currency) >= cost
end

function CurrencyService.Spend(player, currency, cost)
	if cost <= 0 then return true end
	if not CurrencyService.CanAfford(player, currency, cost) then return false end
	return CurrencyService.Add(player, currency, -cost)
end

return CurrencyService
