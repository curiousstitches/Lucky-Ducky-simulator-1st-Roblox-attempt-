-- src/server/LaunchService.lua  | one-time starter duck wheel, gameplay slot unlocks (4->60),
-- and the mandatory rebirth ladder (forced once at stages 10,20,...,100; +30% attack each; re-locks gates).
local Players          = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DuckGenerator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DuckGenerator"))
local PlayerData       = require(script.Parent.PlayerData)
local InventoryService = require(script.Parent.InventoryService)
local CurrencyService  = require(script.Parent.CurrencyService)
local Remotes          = require(script.Parent.Remotes)
local RemoteGuard      = require(script.Parent.RemoteGuard)

local LaunchService = {}
local Notify
local rng = Random.new()

-- ===== STARTER WHEEL =====
-- pool: 6 Common, 5 Uncommon, 2 Rare; each DRAW has 0.01% chance to instead be a basic Huge.
local STARTER_POOL = {}
do
	for _=1,6 do table.insert(STARTER_POOL,"Common") end
	for _=1,5 do table.insert(STARTER_POOL,"Uncommon") end
	for _=1,2 do table.insert(STARTER_POOL,"Rare") end
end

local function drawStarter()
	if rng:NextNumber() < 0.0001 then
		return DuckGenerator.roll({ origin="starter", forceRarity="Uncommon", tier="Huge" })
	end
	local rarity = STARTER_POOL[rng:NextInteger(1,#STARTER_POOL)]
	return DuckGenerator.roll({ origin="starter", forceRarity=rarity, tier="Small" })
end

function LaunchService.SpinStarter(player)
	local p = PlayerData.Get(player); if not p then return { ok=false } end
	if p.starterSpun then return { ok=false, reason="Already claimed your starters" } end
	p.starterSpun = true
	local d1, d2 = drawStarter(), drawStarter()
	InventoryService.AddDuck(player, d1)
	InventoryService.AddDuck(player, d2)
	local huge = (d1.tier=="Huge" or d2.tier=="Huge")
	if Notify then Notify:FireClient(player,{ text = huge and "🦆✨ JACKPOT! A HUGE starter duck!" or ("🎡 Starters: "..d1.rarity.." + "..d2.rarity.."!"), color = huge and Color3.fromRGB(255,215,90) or Color3.fromRGB(120,230,140) }) end
	return { ok=true, ducks={d1,d2}, huge=huge }
end

-- ===== GAMEPLAY SLOT UNLOCKS (4 -> 60, no Robux) =====
-- milestones grant +slots; mix of currency buys + rebirth-ladder rewards.
local SLOT_MILESTONES = {
	{ id="buy1",  cost=8000,    splats=0,  slots=2 },
	{ id="buy2",  cost=40000,   splats=0,  slots=2 },
	{ id="buy3",  cost=150000,  splats=0,  slots=3 },
	{ id="buy4",  cost=0,       splats=25, slots=3 },
	{ id="buy5",  cost=600000,  splats=0,  slots=4 },
	{ id="buy6",  cost=0,       splats=60, slots=5 },
	{ id="buy7",  cost=3000000, splats=0,  slots=6 },
	{ id="buy8",  cost=0,       splats=120,slots=8 },
	{ id="buy9",  cost=20000000,splats=0,  slots=10 },
	{ id="buy10", cost=0,       splats=250,slots=12 }, -- totals: 4 + 65 -> clamped to 60 free cap
}

function LaunchService.SlotInfo(player)
	local p = PlayerData.Get(player); if not p then return {} end
	local rows = {}
	for _, m in ipairs(SLOT_MILESTONES) do
		rows[#rows+1] = { id=m.id, cost=m.cost, splats=m.splats, slots=m.slots, owned=(p.slotUnlocks or {})[m.id]==true }
	end
	return { rows=rows, current=InventoryService.MaxEquipped(player), free=60, hard=120, world1Currency="DuckDroppings", starterSpun=p.starterSpun==true }
end

function LaunchService.BuySlot(player, id)
	local p = PlayerData.Get(player); if not p then return { ok=false } end
	local m; for _,x in ipairs(SLOT_MILESTONES) do if x.id==id then m=x break end end
	if not m then return { ok=false } end
	p.slotUnlocks = p.slotUnlocks or {}
	if p.slotUnlocks[id] then return { ok=false, reason="Already unlocked" } end
	if m.cost>0 and not CurrencyService.Spend(player,"DuckDroppings",m.cost) then return { ok=false, reason="Need "..m.cost.." Droppings" } end
	if m.splats>0 and not CurrencyService.Spend(player,"ShimmerSplats",m.splats) then return { ok=false, reason="Need "..m.splats.." Splats" } end
	p.slotUnlocks[id]=true
	p.bonusSquadSlots = (p.bonusSquadSlots or 0) + m.slots
	InventoryService.Push(player)
	if Notify then Notify:FireClient(player,{ text="➕ +"..m.slots.." duck slots!", color=Color3.fromRGB(120,210,255) }) end
	return { ok=true }
end

-- ===== MANDATORY REBIRTH LADDER =====
-- gate stage for next rebirth = (ladder+1)*10. Doing it: +30% attack, re-lock world gates, send to start.
LaunchService.BOOST_PER = 0.30

function LaunchService.NextRebirthStage(p) return ((p.rebirthLadder or 0)+1)*10 end

-- called when player touches a rebirth shrine
function LaunchService.DoRebirth(player)
	local p = PlayerData.Get(player); if not p then return { ok=false } end
	local nextStage = LaunchService.NextRebirthStage(p)
	if nextStage > 100 then return { ok=false, reason="All rebirths complete!" } end
	-- require having reached that stage in World 1
	if (p.highestLevel or 1) < nextStage then
		return { ok=false, reason=("Reach Stage %d first"):format(nextStage) }
	end
	p.rebirthLadder = (p.rebirthLadder or 0) + 1
	p.rebirths = (p.rebirths or 0) + 1
	p.attackBoost = (p.attackBoost or 1) + LaunchService.BOOST_PER
	-- re-lock gates: reset highest so they must re-clear (they're stronger now)
	p.highestLevel = 1
	-- teleport to World 1 start
	local ZoneBuilder = require(script.Parent.ZoneBuilder)
	local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if r then r.CFrame = CFrame.new(ZoneBuilder.zoneCFrame(1) + Vector3.new(0,8,0)) end
	InventoryService.Push(player)
	if Notify then Notify:FireClient(player,{ text=("🔄 REBIRTH %d! +%d%% attack (now x%.2f). Gates re-locked."):format(p.rebirthLadder, LaunchService.BOOST_PER*100, p.attackBoost), color=Color3.fromRGB(255,215,90) }) end
	return { ok=true, ladder=p.rebirthLadder, boost=p.attackBoost }
end

-- is a given shrine stage currently the player's MANDATORY one (blocks progress)?
function LaunchService.IsMandatory(player, shrineStage)
	local p = PlayerData.Get(player); if not p then return false end
	return shrineStage == LaunchService.NextRebirthStage(p)
end

function LaunchService.Start()
	Notify = Remotes.event("Notify")
	RemoteGuard.func(Remotes.func("SpinStarter"),"starter",2,3,function(pl) return LaunchService.SpinStarter(pl) end,{ok=false})
	Remotes.func("GetSlots").OnServerInvoke = function(pl) return LaunchService.SlotInfo(pl) end
	RemoteGuard.func(Remotes.func("BuySlot"),"slot",5,8,function(pl,id) return LaunchService.BuySlot(pl,id) end,{ok=false})
	RemoteGuard.func(Remotes.func("DoLadderRebirth"),"ladderrb",2,3,function(pl) return LaunchService.DoRebirth(pl) end,{ok=false})
end

return LaunchService
