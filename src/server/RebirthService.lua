-- src/server/RebirthService.lua  | the never-ending engine: Lift Kit prestige
local Players           = game:GetService("Players")
local PlayerData        = require(script.Parent.PlayerData)
local CurrencyService   = require(script.Parent.CurrencyService)
local InventoryService  = require(script.Parent.InventoryService)
local Remotes           = require(script.Parent.Remotes)

local RebirthService = {}
local Notify, RebirthDo, GetProgress

-- each rebirth grants +50% permanent earnings, forever
local function multFor(rebirths) return 1 + (rebirths or 0) * 0.5 end
-- escalating cost in lifetimeEarned-equivalent Droppings
function RebirthService.Cost(rebirths) return 1000000 * ((rebirths or 0) + 1) end

local function applyMult(player)
	local p = PlayerData.Get(player); if not p then return end
	p._rebirthMult = multFor(p.rebirths)
end

function RebirthService.CanRebirth(player)
	local p = PlayerData.Get(player); if not p then return false end
	return CurrencyService.Get(player, "DuckDroppings") >= RebirthService.Cost(p.rebirths)
end

function RebirthService.Do(player)
	local p = PlayerData.Get(player); if not p then return { ok = false, reason = "loading" } end
	local cost = RebirthService.Cost(p.rebirths)
	if CurrencyService.Get(player, "DuckDroppings") < cost then
		return { ok = false, reason = ("Need %d Duck Droppings"):format(cost) }
	end
	-- LIFT KIT: wipe the run, keep collection (dex) + rebirth count
	p.rebirths = (p.rebirths or 0) + 1
	p.wallet = { DuckDroppings = 0, ShimmerSplats = p.wallet.ShimmerSplats or 0 }
	p.ducks = {}
	p.equipped = {}
	p.unlockedBiomes = { MuddyTrailhead = true }
	applyMult(player)

	-- fresh starter so they're never stuck at zero
	local DuckGenerator = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("DuckGenerator"))
	InventoryService.AddDuck(player, DuckGenerator.roll({ origin = "starter" }))
	CurrencyService.PushBalance(player)
	InventoryService.Push(player)

	if Notify then
		Notify:FireClient(player, {
			text = ("🔧 LIFT KIT #%d installed! Earnings now x%.1f forever"):format(p.rebirths, multFor(p.rebirths)),
			color = Color3.fromRGB(255, 200, 80),
		})
	end
	return { ok = true, rebirths = p.rebirths, mult = multFor(p.rebirths) }
end

function RebirthService.Start()
	Notify = Remotes.event("Notify")
	RebirthDo = Remotes.func("RebirthDo")
	GetProgress = Remotes.func("GetProgress")

	RebirthDo.OnServerInvoke = function(player) return RebirthService.Do(player) end
	GetProgress.OnServerInvoke = function(player)
		local p = PlayerData.Get(player); if not p then return {} end
		return {
			rebirths = p.rebirths or 0,
			mult = multFor(p.rebirths),
			nextCost = RebirthService.Cost(p.rebirths),
			droppings = CurrencyService.Get(player, "DuckDroppings"),
			canRebirth = RebirthService.CanRebirth(player),
			dex = p.dex or {},
			kindness = p.kindnessStreak or 0,
		}
	end

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			local tries = 0
			while not PlayerData.Get(player) and tries < 60 do task.wait(0.1); tries += 1 end
			applyMult(player)
		end)
	end)
	for _, p in ipairs(Players:GetPlayers()) do task.spawn(applyMult, p) end
end

return RebirthService
