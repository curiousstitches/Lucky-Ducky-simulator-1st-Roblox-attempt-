-- src/server/DispenserService.lua  | server-authoritative rolls for crate/claw/pond/gumball
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage      = game:GetService("ReplicatedStorage")

local Shared           = ReplicatedStorage:WaitForChild("Shared")
local DuckGenerator    = require(Shared:WaitForChild("DuckGenerator"))
local ShopConfig       = require(Shared:WaitForChild("ShopConfig"))
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local Remotes          = require(script.Parent.Remotes)

local DispenserService = {}
local RevealDuck

local function activeLuck(player, base)
	local p = PlayerData.Get(player)
	local mult = base
	if p and (p.luckBoostUntil or 0) > os.time() then mult = mult * 2 end
	if p and p._eventLuck then mult = mult * p._eventLuck end
	return mult
end

function DispenserService.Roll(player, dispenserId)
	local cfg = ShopConfig.getDispenser(dispenserId)
	if not cfg then return end
	if not CurrencyService.CanAfford(player, cfg.currency, cfg.cost) then
		if RevealDuck then RevealDuck:FireClient(player, { ok = false, reason = "Not enough " .. cfg.currency }) end
		return
	end
	if not CurrencyService.Spend(player, cfg.currency, cfg.cost) then return end

	local duck = DuckGenerator.roll({
		origin = dispenserId,
		luckMul = activeLuck(player, cfg.luck),
		goldenChance = cfg.golden,
	})
	InventoryService.AddDuck(player, duck)
	if RevealDuck then
		RevealDuck:FireClient(player, { ok = true, duck = duck, reveal = cfg.reveal, dispenser = cfg.name })
	end
end

function DispenserService.Start()
	RevealDuck = Remotes.event("RevealDuck")
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		local id = prompt:GetAttribute("DispenserId")
		if id then DispenserService.Roll(player, id) end
	end)
end

return DispenserService
