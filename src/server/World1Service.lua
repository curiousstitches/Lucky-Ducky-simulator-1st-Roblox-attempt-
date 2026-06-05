-- src/server/World1Service.lua  | enemy-duck combat + facility booths (shop/upgrade/merchant/minigame/secret)
-- Enemies chase nearby players, damage them, and take damage from the player's equipped squad strength.
-- Facilities give scaling rewards/upgrades based on their tier (improves per stage).
local Players          = game:GetService("Players")
local Workspace        = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DuckGenerator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DuckGenerator"))
local W1             = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("World1Config"))
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local Remotes          = require(script.Parent.Remotes)
local RemoteGuard      = require(script.Parent.RemoteGuard)

local World1Service = {}
local Notify
local rng = Random.new()

-- ===== ENEMY DUCK COMBAT =====
local function combatLoop()
	while true do
		task.wait(0.5)
		for _, e in ipairs(CollectionService:GetTagged("EnemyDuck")) do
			if e:IsA("BasePart") and e:GetAttribute("HP") then
				-- find nearest player in range
				local nearest, nd
				for _, pl in ipairs(Players:GetPlayers()) do
					local r = pl.Character and pl.Character:FindFirstChild("HumanoidRootPart")
					if r then
						local d = (r.Position - e.Position).Magnitude
						if d <= 40 and (not nd or d < nd) then nearest, nd = pl, d end
					end
				end
				if nearest then
					local r = nearest.Character.HumanoidRootPart
					-- drift toward player
					e.Position = e.Position:Lerp(Vector3.new(r.Position.X, e.Position.Y, r.Position.Z), 0.05)
					-- player squad damages enemy when close
					if nd <= 22 then
						local hp = e:GetAttribute("HP") - InventoryService.SquadStrength(nearest) * 0.4 * 2
						e:SetAttribute("HP", hp)
						if hp <= 0 then
							CurrencyService.Add(nearest, W1.Currency, e:GetAttribute("Reward") or 0)
							if rng:NextNumber() < 0.2 then InventoryService.AddDuck(nearest, DuckGenerator.roll({origin="enemy"})) end
							if Notify then Notify:FireClient(nearest,{ text="💥 Rogue Duck defeated! +"..(e:GetAttribute("Reward") or 0), color=Color3.fromRGB(120,230,140) }) end
							e:Destroy()
						end
					elseif nd <= 8 then
						-- enemy hits the player's character
						local hum = nearest.Character:FindFirstChildOfClass("Humanoid")
						if hum then hum:TakeDamage(e:GetAttribute("Damage") or 4) end
					end
				end
			end
		end
	end
end

-- ===== FACILITIES =====
function World1Service.UseFacility(player, kind, tier, stage)
	local p = PlayerData.Get(player); if not p then return { ok=false } end
	tier = tonumber(tier) or 1; stage = tonumber(stage) or 1
	if kind == "merchant" or kind == "shop" then
		-- sells a duck scaled to tier (price in local currency, scales with stage)
		local price = math.floor(2000 * (1.2 ^ stage))
		if not CurrencyService.Spend(player, W1.Currency, price) then return { ok=false, reason="Need "..price } end
		InventoryService.AddDuck(player, DuckGenerator.roll({ origin="shop", luckMul = 1 + tier*0.4 }))
		if Notify then Notify:FireClient(player,{ text="🛒 Bought a Tier "..tier.." duck!", color=Color3.fromRGB(120,230,140) }) end
		return { ok=true }
	elseif kind == "upgrade" then
		-- permanent small droppings multiplier, scaling cost
		local price = math.floor(5000 * (1.25 ^ stage))
		if not CurrencyService.Spend(player, W1.Currency, price) then return { ok=false, reason="Need "..price } end
		p._w1Mult = (p._w1Mult or 1) + 0.1 * tier
        p._droppingsMult = (p._droppingsMult or 1)
		if Notify then Notify:FireClient(player,{ text="⬆️ Upgrade! +"..(10*tier).."% earnings here", color=Color3.fromRGB(120,180,255) }) end
		return { ok=true }
	elseif kind == "minigame" then
		-- free-ish quick gamble
		local prize = rng:NextInteger(500, 2000) * tier
		CurrencyService.Add(player, W1.Currency, prize)
		if Notify then Notify:FireClient(player,{ text="🎡 Mini-game won "..prize.."!", color=Color3.fromRGB(255,210,120) }) end
		return { ok=true }
	elseif kind == "secret" then
		local once = "_secret_"..stage
		if p[once] then return { ok=false, reason="Already looted" } end
		p[once] = true
		CurrencyService.Add(player, "ShimmerSplats", 5 + tier*3)
		InventoryService.AddDuck(player, DuckGenerator.roll({ origin="secret", luckMul=2+tier, goldenChance=0.1 }))
		if Notify then Notify:FireClient(player,{ text="❓ Secret stash! +Splats + rare duck", color=Color3.fromRGB(255,215,90) }) end
		return { ok=true }
	end
	return { ok=false }
end

function World1Service.Start()
	Notify = Remotes.event("Notify")
	RemoteGuard.func(Remotes.func("UseFacility"),"facility",6,10,function(pl,k,t,s) return World1Service.UseFacility(pl,k,t,s) end,{ok=false})
	task.spawn(combatLoop)
end

return World1Service
