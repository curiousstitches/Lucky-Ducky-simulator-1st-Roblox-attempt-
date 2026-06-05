-- src/server/CosmeticService.lua  | buy/equip flashy trails & auras (stack: one trail + one aura)
local Players          = game:GetService("Players")
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local Remotes          = require(script.Parent.Remotes)
local RemoteGuard      = require(script.Parent.RemoteGuard)

local CosmeticService = {}
local Notify, CosmeticSync

-- kind: "trail" | "aura". color drives the client effect.
local COSMETICS = {
	{ id = "trail_rainbow", kind = "trail", name = "Rainbow Trail",  cost = 40,  currency = "ShimmerSplats", color = "rainbow" },
	{ id = "trail_fire",    kind = "trail", name = "Fire Trail",     cost = 25,  currency = "ShimmerSplats", color = "255,90,20" },
	{ id = "trail_ice",     kind = "trail", name = "Ice Trail",      cost = 25,  currency = "ShimmerSplats", color = "120,210,255" },
	{ id = "trail_gold",    kind = "trail", name = "Golden Trail",   cost = 60,  currency = "ShimmerSplats", color = "255,200,50" },
	{ id = "trail_void",    kind = "trail", name = "Void Trail",     cost = 90,  currency = "ShimmerSplats", color = "150,60,255", eventOnly = true },
	{ id = "aura_sparkle",  kind = "aura",  name = "Sparkle Aura",   cost = 30,  currency = "ShimmerSplats", color = "255,255,180" },
	{ id = "aura_storm",    kind = "aura",  name = "Storm Aura",     cost = 50,  currency = "ShimmerSplats", color = "120,170,255" },
	{ id = "aura_inferno",  kind = "aura",  name = "Inferno Aura",   cost = 70,  currency = "ShimmerSplats", color = "255,70,30" },
	{ id = "aura_galaxy",   kind = "aura",  name = "Galaxy Aura",    cost = 120, currency = "ShimmerSplats", color = "180,90,255" },
	{ id = "trail_duck",    kind = "trail", name = "Duck Parade",    cost = 80,  currency = "ShimmerSplats", color = "255,221,51" },
}

local function find(id) for _, c in ipairs(COSMETICS) do if c.id == id then return c end end end

function CosmeticService.Sync(player)
	local p = PlayerData.Get(player); if not p then return end
	local trail = p.equippedTrail and find(p.equippedTrail)
	local aura = p.equippedAura and find(p.equippedAura)
	player:SetAttribute("Trail", trail and trail.color or "")
	player:SetAttribute("Aura", aura and aura.color or "")
	if CosmeticSync then CosmeticSync:FireClient(player, {
		owned = p.cosmeticsOwned or {}, trail = p.equippedTrail, aura = p.equippedAura }) end
end

function CosmeticService.Buy(player, id)
	local c = find(id); if not c then return { ok = false } end
	local p = PlayerData.Get(player); if not p then return { ok = false } end
	p.cosmeticsOwned = p.cosmeticsOwned or {}
	if p.cosmeticsOwned[id] then return { ok = true } end
	if not CurrencyService.Spend(player, c.currency, c.cost) then return { ok = false, reason = "Can't afford" } end
	p.cosmeticsOwned[id] = true
	if Notify then Notify:FireClient(player, { text = "🌈 Unlocked " .. c.name .. "!", color = Color3.fromRGB(200, 160, 255) }) end
	CosmeticService.Sync(player)
	return { ok = true }
end

function CosmeticService.Equip(player, id)
	local p = PlayerData.Get(player); if not p then return { ok = false } end
	if id == nil then p.equippedTrail = nil; p.equippedAura = nil; CosmeticService.Sync(player); return { ok = true } end
	local c = find(id); if not c then return { ok = false } end
	if not (p.cosmeticsOwned or {})[id] then return { ok = false, reason = "Not owned" } end
	if c.kind == "trail" then p.equippedTrail = id else p.equippedAura = id end
	CosmeticService.Sync(player)
	return { ok = true }
end

function CosmeticService.Start()
	Notify = Remotes.event("Notify")
	CosmeticSync = Remotes.event("CosmeticSync")
	Remotes.func("GetCosmetics").OnServerInvoke = function(player)
		local p = PlayerData.Get(player)
		return { items = COSMETICS, owned = p and p.cosmeticsOwned or {}, trail = p and p.equippedTrail, aura = p and p.equippedAura }
	end
	RemoteGuard.func(Remotes.func("BuyCosmetic"), "cos_buy", 5, 8, function(pl, id) return CosmeticService.Buy(pl, id) end, { ok = false })
	RemoteGuard.event(Remotes.event("EquipCosmetic"), "cos_eq", 6, 10, function(pl, id) CosmeticService.Equip(pl, id) end)

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			local tries = 0
			while not PlayerData.Get(player) and tries < 60 do task.wait(0.1); tries += 1 end
			CosmeticService.Sync(player)
		end)
	end)
end

return CosmeticService
