-- src/server/DuckLevelService.lua  | level a duck (escalating cost) + enchant it (power/luck/earn)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DuckGenerator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DuckGenerator"))
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local Remotes          = require(script.Parent.Remotes)
local RemoteGuard      = require(script.Parent.RemoteGuard)

local DuckLevelService = {}
local Notify
local MAX_ENCHANTS = 3

local function findDuck(p, id) for _, d in ipairs(p.ducks) do if d.id == id then return d end end end

local function levelCost(duck)
	return math.floor(800 * (1.35 ^ (duck.level or 0)) * ((DuckGenerator.computeStrength(duck)) / 8 + 1))
end

function DuckLevelService.Level(player, id)
	local p = PlayerData.Get(player); if not p then return { ok = false } end
	local d = findDuck(p, id); if not d then return { ok = false, reason = "Not found" } end
	local cost = levelCost(d)
	if not CurrencyService.Spend(player, "DuckDroppings", cost) then return { ok = false, reason = "Need " .. cost } end
	d.level = (d.level or 0) + 1
	d.strength = DuckGenerator.computeStrength(d) -- keep base fresh
	InventoryService.Push(player)
	return { ok = true, level = d.level }
end

function DuckLevelService.Enchant(player, id, etype)
	local p = PlayerData.Get(player); if not p then return { ok = false } end
	local d = findDuck(p, id); if not d then return { ok = false } end
	d.enchants = d.enchants or {}
	if #d.enchants >= MAX_ENCHANTS then return { ok = false, reason = "Max 3 enchants" } end
	if etype ~= "power" and etype ~= "luck" and etype ~= "earn" then return { ok = false } end
	-- enchanting costs Shimmer Splats; power scales with rarity
	if not CurrencyService.Spend(player, "ShimmerSplats", 15) then return { ok = false, reason = "Need 15 Shimmer Splats" } end
	local rar = DuckGenerator.computeStrength(d)
	local power = (etype == "power") and math.max(2, math.floor(rar * 0.5)) or math.random(2, 5)
	table.insert(d.enchants, { type = etype, power = power })
	InventoryService.Push(player)
	if Notify then Notify:FireClient(player, { text = ("🔮 Enchanted +%s!"):format(etype), color = Color3.fromRGB(180, 140, 255) }) end
	return { ok = true }
end

function DuckLevelService.Start()
	Notify = Remotes.event("Notify")
	RemoteGuard.func(Remotes.func("LevelDuck"), "lvl", 8, 12, function(pl, id) return DuckLevelService.Level(pl, id) end, { ok = false })
	RemoteGuard.func(Remotes.func("EnchantDuck"), "ench", 5, 8, function(pl, id, t) return DuckLevelService.Enchant(pl, id, t) end, { ok = false })
end

return DuckLevelService
