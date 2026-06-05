-- src/server/AbilityService.lua  | buy movement abilities + stackable potions; syncs ability list
local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UnlockConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UnlockConfig"))
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local Remotes          = require(script.Parent.Remotes)
local RemoteGuard      = require(script.Parent.RemoteGuard)

local AbilityService = {}
local Notify, AbilitySync

function AbilityService.PushAbilities(player)
	local p = PlayerData.Get(player); if not (p and AbilitySync) then return end
	AbilitySync:FireClient(player, p.abilities or {})
end

function AbilityService.BuyAbility(player, id)
	local a = UnlockConfig.find(UnlockConfig.Abilities, id); if not a then return { ok = false } end
	local p = PlayerData.Get(player); if not p then return { ok = false } end
	p.abilities = p.abilities or {}
	if p.abilities[id] then return { ok = true } end
	if a.currency == "Robux" then return { ok = false, reason = "Buy in shop with Robux" } end
	if not CurrencyService.Spend(player, a.currency, a.cost) then return { ok = false, reason = "Can't afford" } end
	p.abilities[id] = true
	AbilityService.PushAbilities(player)
	if Notify then Notify:FireClient(player, { text = "✨ Unlocked " .. a.name .. "!", color = Color3.fromRGB(120, 210, 255) }) end
	return { ok = true }
end

-- potions: stack by ADDING duration; power takes the max active. no tap, never resets.
function AbilityService.BuyPotion(player, id)
	local pot = UnlockConfig.find(UnlockConfig.Potions, id); if not pot then return { ok = false } end
	local p = PlayerData.Get(player); if not p then return { ok = false } end
	if pot.currency == "Robux" then return { ok = false, reason = "Buy in shop with Robux" } end
	if not CurrencyService.Spend(player, pot.currency, pot.cost) then return { ok = false, reason = "Can't afford" } end
	p.potions = p.potions or {}
	local now = os.time()
	local cur = p.potions[pot.effect]
	if cur and (cur["until"] or 0) > now then
		cur["until"] = cur["until"] + pot.seconds          -- stack duration
		cur.power = math.max(cur.power or 1, pot.power)     -- keep strongest
	else
		p.potions[pot.effect] = { power = pot.power, ["until"] = now + pot.seconds }
	end
	if Notify then Notify:FireClient(player, {
		text = ("🧪 %s active! (%s stacks duration)"):format(pot.name, pot.effect),
		color = Color3.fromRGB(150, 230, 160) }) end
	return { ok = true }
end

-- recompute potion-derived runtime flags (read by Egg/Farm services)
function AbilityService.RefreshPotions(player)
	local p = PlayerData.Get(player); if not p then return end
	local now = os.time()
	local luck = p.potions and p.potions.luck
	p._luckPot = (luck and luck["until"]) or 0
	p._luckPotPower = (luck and luck.power) or 1
	local earn = p.potions and p.potions.earn
	p._earnPot = (earn and earn["until"]) or 0
	p._earnPotPower = (earn and earn.power) or 1
	local speed = p.potions and p.potions.speed
	p._speedPot = (speed and speed["until"]) or 0
end

function AbilityService.Start()
	Notify = Remotes.event("Notify")
	AbilitySync = Remotes.event("AbilitySync")
	local buyA = Remotes.func("BuyAbility")
	local buyP = Remotes.func("BuyPotion")
	local list = Remotes.func("GetUnlocks")
	RemoteGuard.func(buyA, "buy_ability", 4, 6, function(pl, id) return AbilityService.BuyAbility(pl, id) end, { ok = false })
	RemoteGuard.func(buyP, "buy_potion", 6, 8, function(pl, id) return AbilityService.BuyPotion(pl, id) end, { ok = false })
	list.OnServerInvoke = function(player)
		local p = PlayerData.Get(player)
		return {
			abilities = UnlockConfig.Abilities, potions = UnlockConfig.Potions,
			owned = p and p.abilities or {}, activePotions = p and p.potions or {},
		}
	end

	Remotes.event("AbilitySync") -- ensure exists
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			local tries = 0
			while not PlayerData.Get(player) and tries < 60 do task.wait(0.1); tries += 1 end
			AbilityService.PushAbilities(player)
		end)
	end)

	-- keep potion flags fresh
	task.spawn(function()
		while true do
			for _, player in ipairs(Players:GetPlayers()) do AbilityService.RefreshPotions(player) end
			task.wait(2)
		end
	end)
end

return AbilityService
