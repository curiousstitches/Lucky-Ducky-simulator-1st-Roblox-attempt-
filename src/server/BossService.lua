-- src/server/BossService.lua  | summon a solo boss at a BossPad; smash it for big loot + exclusive duck
local CollectionService = game:GetService("CollectionService")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DuckGenerator = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DuckGenerator"))
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local Remotes          = require(script.Parent.Remotes)
local RemoteGuard      = require(script.Parent.RemoteGuard)

local BossService = {}
local Notify
local active = {} -- [userId] = model
local rng = Random.new()

local function buildBoss(player, tier)
	local folder = Workspace:FindFirstChild("Bosses") or Instance.new("Folder")
	folder.Name = "Bosses"; folder.Parent = Workspace
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	-- HP scales with the player's persistent boss tier: each defeat makes the next ~60% tougher
	local hp = math.floor(1500 * (1.6 ^ tier))
	local boss = Instance.new("Part")
	boss.Size = Vector3.new(12 + tier, 14 + tier, 12 + tier); boss.Anchored = true; boss.Material = Enum.Material.Neon
	boss.Color = Color3.fromRGB(150, 30, 60); boss.Position = root.Position + root.CFrame.LookVector * 18 + Vector3.new(0, 7, 0)
	boss:SetAttribute("HP", hp); boss:SetAttribute("MaxHP", hp); boss:SetAttribute("Owner", player.UserId)
	boss:SetAttribute("Tier", tier)
	CollectionService:AddTag(boss, "Boss"); boss.Parent = folder
	local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(0, 220, 0, 40); bb.AlwaysOnTop = true; bb.StudsOffset = Vector3.new(0, 9 + tier*0.4, 0); bb.Parent = boss
	local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBlack; t.TextScaled = true; t.TextColor3 = Color3.fromRGB(255, 120, 120)
	t.Text = "💀 DUCK TITAN  Tier " .. (tier+1); t.Parent = boss
	active[player.UserId] = boss
	if Notify then Notify:FireClient(player, { text = ("💀 DUCK TITAN Tier %d summoned! Smash it!"):format(tier+1), color = Color3.fromRGB(255, 80, 80) }) end
	task.delay(120, function() if boss.Parent then boss:Destroy() end; active[player.UserId] = nil end)
end

function BossService.Summon(player)
	local p = PlayerData.Get(player); if not p then return { ok = false } end
	if active[player.UserId] and active[player.UserId].Parent then return { ok = false, reason = "Boss already active" } end
	buildBoss(player, p.bossTier or 0)
	return { ok = true }
end

local function combat()
	while true do
		task.wait(0.4)
		local folder = Workspace:FindFirstChild("Bosses")
		if folder then
			for _, boss in ipairs(folder:GetChildren()) do
				if boss:IsA("BasePart") and boss:GetAttribute("HP") then
					local ownerId = boss:GetAttribute("Owner")
					for _, player in ipairs(Players:GetPlayers()) do
						local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
						if root and (root.Position - boss.Position).Magnitude <= 30 then
							local hp = boss:GetAttribute("HP") - InventoryService.SquadStrength(player) * 0.4 * 4
							boss:SetAttribute("HP", hp)
							local max = boss:GetAttribute("MaxHP") or 1
							local lbl = boss:FindFirstChildOfClass("BillboardGui")
							if lbl and lbl:FindFirstChildOfClass("TextLabel") then
								lbl.TextLabel.Text = ("💀 TITAN %d%%"):format(math.max(0, math.floor(hp / max * 100)))
							end
							if hp <= 0 then
								local tier = boss:GetAttribute("Tier") or 0
								local owner = Players:GetPlayerByUserId(ownerId) or player
								local op = PlayerData.Get(owner)
								if op then op.bossTier = (op.bossTier or 0) + 1 end
								CurrencyService.Add(owner, "DuckDroppings", math.floor(8000 * (1.7 ^ tier)))
								CurrencyService.Add(owner, "ShimmerSplats", 5 + tier * 2)
								-- exclusive boss duck, luckier each tier
								InventoryService.AddDuck(owner, DuckGenerator.roll({ origin = "boss", luckMul = 6 + tier, goldenChance = 0.5, tier = tier >= 5 and "Gigantic" or "Huge" }))
								if Notify then Notify:FireClient(owner, { text = ("💥 TIER %d TITAN DOWN! Next one's tougher — keep growing!"):format(tier+1), color = Color3.fromRGB(120, 230, 140) }) end
								active[ownerId] = nil
								boss:Destroy()
								break
							end
						end
					end
				end
			end
		end
	end
end

function BossService.Start()
	Notify = Remotes.event("Notify")
	RemoteGuard.func(Remotes.func("SummonBoss"), "boss", 2, 3, function(pl) return BossService.Summon(pl) end, { ok = false })
	-- also allow BossPad touch to summon
	local function hook(pad)
		if pad:IsA("BasePart") then
			pad.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit and hit.Parent)
				if player then BossService.Summon(player) end
			end)
		end
	end
	for _, pad in ipairs(CollectionService:GetTagged("BossPad")) do hook(pad) end
	CollectionService:GetInstanceAddedSignal("BossPad"):Connect(hook)
	task.spawn(combat)
	Players.PlayerRemoving:Connect(function(pl) if active[pl.UserId] then active[pl.UserId]:Destroy(); active[pl.UserId] = nil end end)
end

return BossService
