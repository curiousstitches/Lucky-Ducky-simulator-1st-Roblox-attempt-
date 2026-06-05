-- src/server/InventoryService.lua  | owns ducks + equipped squad (with slot caps) + client sync
local Players    = game:GetService("Players")
local PlayerData = require(script.Parent.PlayerData)
local Remotes    = require(script.Parent.Remotes)

local InventoryService = {}
local BASE_SLOTS = 4    -- start with 4 active duck slots
local FREE_CAP   = 60   -- unlockable to 60 via gameplay (no Robux)
local HARD_CAP   = 120 -- design ceiling for equipped ducks

local InventoryChanged, EquipDuck

function InventoryService.MaxEquipped(player)
	local p = PlayerData.Get(player); if not p then return BASE_SLOTS end
	-- gameplay-earned slots cap at FREE_CAP (60); Robux pass slots add on top up to HARD_CAP (120)
	local free = math.clamp(BASE_SLOTS + (p.bonusSquadSlots or 0), BASE_SLOTS, FREE_CAP)
	local total = free + (p._passSlots or 0)
	return math.clamp(total, BASE_SLOTS, HARD_CAP)
end

function InventoryService.SquadStrength(player)
	local p = PlayerData.Get(player); if not p then return 0 end
	local byId = {}; for _, d in ipairs(p.ducks) do byId[d.id] = d end
	local t = 0
	for _, id in ipairs(p.equipped) do local d = byId[id]; if d then t += require(game:GetService("ReplicatedStorage").Shared.DuckGenerator).effectiveStrength(d) end end
	return math.max(1, t * (p.attackBoost or 1))
end

-- aggregate luck/earn enchant bonuses across equipped ducks (read by Egg/Farm)
function InventoryService.EnchantBonuses(player)
	local p = PlayerData.Get(player); if not p then return 1, 1 end
	local byId = {}; for _, d in ipairs(p.ducks) do byId[d.id] = d end
	local luck, earn = 1, 1
	for _, id in ipairs(p.equipped) do
		local d = byId[id]
		if d then for _, e in ipairs(d.enchants or {}) do
			if e.type == "luck" then luck += (e.power or 0) * 0.05 end
			if e.type == "earn" then earn += (e.power or 0) * 0.05 end
		end end
	end
	return luck, earn
end

function InventoryService.Push(player)
	local p = PlayerData.Get(player); if not (p and InventoryChanged) then return end
	InventoryChanged:FireClient(player, {
		ducks = p.ducks, equipped = p.equipped, max = InventoryService.MaxEquipped(player),
	})
end

function InventoryService.AddDuck(player, duck)
	local p = PlayerData.Get(player); if not p then return false end
	table.insert(p.ducks, duck)
	p.dex = p.dex or {}
	p.dex[duck.rarity] = (p.dex[duck.rarity] or 0) + 1
	-- tier-keyed record for the Duck Index (rarity|tier)
	p.dexTiered = p.dexTiered or {}
	local tkey = (duck.rarity or "Common").."|"..(duck.tier or "Small")
	p.dexTiered[tkey] = (p.dexTiered[tkey] or 0) + 1
	if p.stats then p.stats.ducksHatched = (p.stats.ducksHatched or 0) + 1 end
	-- auto-equip if there's a free slot, so new players see ducks working instantly
	if #p.equipped < InventoryService.MaxEquipped(player) then table.insert(p.equipped, duck.id) end
	InventoryService.Push(player)
	return true
end

function InventoryService.RemoveDucks(player, idSet)
	local p = PlayerData.Get(player); if not p then return end
	local keepDucks, keepEquip = {}, {}
	for _, d in ipairs(p.ducks) do if not idSet[d.id] then table.insert(keepDucks, d) end end
	for _, id in ipairs(p.equipped) do if not idSet[id] then table.insert(keepEquip, id) end end
	p.ducks, p.equipped = keepDucks, keepEquip
	InventoryService.Push(player)
end

local function isEquipped(p, id)
	for i, v in ipairs(p.equipped) do if v == id then return i end end
end
local function owns(p, id)
	for _, d in ipairs(p.ducks) do if d.id == id then return true end end
end

function InventoryService.Equip(player, id)
	local p = PlayerData.Get(player); if not p then return false end
	if isEquipped(p, id) or not owns(p, id) then return false end
	if #p.equipped >= InventoryService.MaxEquipped(player) then return false end
	table.insert(p.equipped, id); InventoryService.Push(player); return true
end

function InventoryService.Unequip(player, id)
	local p = PlayerData.Get(player); if not p then return false end
	local i = isEquipped(p, id); if not i then return false end
	table.remove(p.equipped, i); InventoryService.Push(player); return true
end

function InventoryService.Start()
	InventoryChanged = Remotes.event("InventoryChanged")
	EquipDuck = Remotes.event("EquipDuck")
	EquipDuck.OnServerEvent:Connect(function(player, action, id)
		if type(id) ~= "string" then return end
		if action == "equip" then InventoryService.Equip(player, id)
		elseif action == "unequip" then InventoryService.Unequip(player, id)
		elseif action == "refresh" then InventoryService.Push(player) end
	end)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			local tries = 0
			while not PlayerData.Get(player) and tries < 50 do task.wait(0.1); tries += 1 end
			InventoryService.Push(player)
		end)
	end)
end

return InventoryService
