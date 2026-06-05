-- src/server/FarmService.lua  | core loop: equipped ducks smash tagged breakables -> currency
-- Tag any BasePart with CollectionService tag "Breakable" and set attributes:
--   MaxHP (number), Reward (number), Currency (string id). Defaults applied if absent.
local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")
local PlayerData        = require(script.Parent.PlayerData)
local CurrencyService   = require(script.Parent.CurrencyService)
local InventoryService  = require(script.Parent.InventoryService)

local FarmService = {}
local TAG     = "Breakable"
local RANGE   = 28   -- studs: ducks farm breakables within this range of their owner
local TICK    = 0.25 -- sec per damage tick
local RESPAWN = 3    -- sec before a smashed breakable returns

local state = {} -- [part] = { hp, max, reward, currency, dmg = {[userId]=n}, alive, t0 }

local function squadStrength(player)
	return InventoryService.SquadStrength(player)
end

local function setup(inst)
	if not inst:IsA("BasePart") then return end
	local max = inst:GetAttribute("MaxHP") or 100
	state[inst] = {
		hp = max, max = max,
		reward = inst:GetAttribute("Reward") or 5,
		currency = inst:GetAttribute("Currency") or "DuckDroppings",
		dmg = {}, alive = true, t0 = inst.Transparency,
	}
end

local function rewardTop(inst, s)
	local topId, topDmg = nil, -1
	for uid, dmg in pairs(s.dmg) do
		if dmg > topDmg then topDmg, topId = dmg, uid end
	end
	if not topId then return end
	local p = Players:GetPlayerByUserId(topId)
	if not p then return end
	local prof = PlayerData.Get(p)
	local mult = ((prof and prof._droppingsMult) or 1) * ((prof and prof._rebirthMult) or 1) * ((prof and prof._eventMult) or 1)
	if prof then
		mult = mult * ((prof._randomMult) or 1)
		if prof._earnPot and prof._earnPot > os.time() then mult = mult * (prof._earnPotPower or 1) end
		if prof._x2forever then mult = mult * 2 end
		if prof.mode == "hardcore" then mult = mult * 2.5 end -- hardcore pays big
	end
	CurrencyService.Add(p, s.currency, math.max(1, math.floor(s.reward * mult)))
	if prof and prof.stats then prof.stats.breakablesSmashed = (prof.stats.breakablesSmashed or 0) + 1 end
end

function FarmService.Start()
	for _, inst in ipairs(CollectionService:GetTagged(TAG)) do setup(inst) end
	CollectionService:GetInstanceAddedSignal(TAG):Connect(setup)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(function(i) state[i] = nil end)

	task.spawn(function()
		while true do
			task.wait(TICK)
			for inst, s in pairs(state) do
				if s.alive and inst.Parent then
					for _, p in ipairs(Players:GetPlayers()) do
						local char = p.Character
						local root = char and char:FindFirstChild("HumanoidRootPart")
						if root and (root.Position - inst.Position).Magnitude <= RANGE then
							local dmg = squadStrength(p) * TICK * 4
							s.hp -= dmg
							s.dmg[p.UserId] = (s.dmg[p.UserId] or 0) + dmg
						end
					end
					if s.hp <= 0 then
						s.alive = false
						rewardTop(inst, s)
						inst.Transparency = 1
						inst.CanCollide = false
						task.delay(RESPAWN, function()
							if inst.Parent and state[inst] then
								s.hp = s.max; s.dmg = {}; s.alive = true
								inst.Transparency = s.t0; inst.CanCollide = true
							end
						end)
					end
				end
			end
		end
	end)
end

return FarmService
