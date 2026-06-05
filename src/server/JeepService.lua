-- src/server/JeepService.lua  | the social hook: summon your Jeep, others "duck" it, both win
local Players                = game:GetService("Players")
local Workspace              = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage      = game:GetService("ReplicatedStorage")

local Shared          = ReplicatedStorage:WaitForChild("Shared")
local DuckGenerator   = require(Shared:WaitForChild("DuckGenerator"))
local PlayerData      = require(script.Parent.PlayerData)
local CurrencyService = require(script.Parent.CurrencyService)
local InventoryService = require(script.Parent.InventoryService)
local Remotes         = require(script.Parent.Remotes)

local JeepService = {}
local DUCK_COOLDOWN = 600 -- sec before you can re-duck the same person
local DUCKER_REWARD = 100
local OWNER_REWARD  = 50
local jeeps = {}          -- [userId] = model
local Notify, SummonJeep

local function part(props)
	local p = Instance.new("Part"); p.Anchored = true; p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do p[k] = v end
	return p
end

local function buildJeep(owner, position)
	local model = Instance.new("Model"); model.Name = "Jeep_" .. owner.UserId
	local body = part({ Name = "Body", Size = Vector3.new(8, 3, 14), Position = position + Vector3.new(0, 2.5, 0),
		Color = Color3.fromRGB(90, 120, 70), Parent = model })
	part({ Size = Vector3.new(7, 2.5, 5), Position = position + Vector3.new(0, 4.5, -2),
		Color = Color3.fromRGB(70, 95, 55), Parent = model })
	for _, dx in ipairs({ -3.5, 3.5 }) do
		for _, dz in ipairs({ -5, 5 }) do
			part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 3, 3),
				Position = position + Vector3.new(dx, 1.2, dz),
				Orientation = Vector3.new(0, 0, 90), Color = Color3.fromRGB(25, 25, 25), Parent = model })
		end
	end
	model.PrimaryPart = body

	local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(0, 220, 0, 50)
	bb.StudsOffset = Vector3.new(0, 5, 0); bb.AlwaysOnTop = true; bb.Parent = body
	local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1
	t.Font = Enum.Font.GothamBold; t.TextScaled = true; t.TextColor3 = Color3.fromRGB(255, 221, 51)
	t.TextStrokeTransparency = 0.3; t.Text = owner.Name .. "'s Jeep 🦆 Duck it!"; t.Parent = bb

	local prompt = Instance.new("ProximityPrompt"); prompt.ActionText = "Duck this Jeep!"
	prompt.ObjectText = owner.Name .. "'s Jeep"; prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 12; prompt:SetAttribute("JeepOwner", owner.UserId)
	prompt.Parent = body

	model.Parent = Workspace
	return model
end

function JeepService.Summon(player)
	if jeeps[player.UserId] then jeeps[player.UserId]:Destroy(); jeeps[player.UserId] = nil end
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local base = root and (root.Position + root.CFrame.LookVector * 14) or Vector3.new(20, 6, 0)
	jeeps[player.UserId] = buildJeep(player, Vector3.new(base.X, 1, base.Z))
	if Notify then Notify:FireClient(player, { text = "🚙 Your Jeep is parked! Let a friend duck it.", color = Color3.fromRGB(120, 210, 255) }) end
end

local function celebrate(model)
	local body = model.PrimaryPart; if not body then return end
	local duck = part({ Size = Vector3.new(1.4, 1.4, 1.4), Position = body.Position + Vector3.new(0, 4, 0),
		Color = Color3.fromRGB(255, 221, 51), Material = Enum.Material.Neon, Parent = model })
	local d = Instance.new("BillboardGui"); d.Size = UDim2.new(0, 60, 0, 60); d.AlwaysOnTop = true; d.Parent = duck
	local dl = Instance.new("TextLabel"); dl.Size = UDim2.fromScale(1, 1); dl.BackgroundTransparency = 1
	dl.TextScaled = true; dl.Text = "🦆"; dl.Parent = d
end

local function onDuck(ownerId, ducker)
	if ownerId == ducker.UserId then
		if Notify then Notify:FireClient(ducker, { text = "😅 You can't duck your own Jeep!", color = Color3.fromRGB(255, 150, 0) }) end
		return
	end
	local dp = PlayerData.Get(ducker); if not dp then return end
	dp.jeepDuckLog = dp.jeepDuckLog or {}
	local last = dp.jeepDuckLog[tostring(ownerId)] or 0
	if os.time() - last < DUCK_COOLDOWN then
		if Notify then Notify:FireClient(ducker, { text = "⏳ Already ducked them recently — spread the love around!", color = Color3.fromRGB(255, 150, 0) }) end
		return
	end
	dp.jeepDuckLog[tostring(ownerId)] = os.time()
	dp.kindnessStreak = (dp.kindnessStreak or 0) + 1
	if dp.stats then dp.stats.jeepsDucked = (dp.stats.jeepsDucked or 0) + 1 end

	local mult = (dp._rebirthMult or 1)
	CurrencyService.Add(ducker, "DuckDroppings", math.floor(DUCKER_REWARD * mult))
	if Notify then Notify:FireClient(ducker, {
		text = ("🦆 You ducked a Jeep! +%d Droppings • kindness streak %d"):format(math.floor(DUCKER_REWARD * mult), dp.kindnessStreak),
		color = Color3.fromRGB(80, 230, 120) }) end

	local owner = Players:GetPlayerByUserId(ownerId)
	if owner then
		CurrencyService.Add(owner, "DuckDroppings", OWNER_REWARD)
		-- the twist: getting ducked gifts the owner a surprise duck
		InventoryService.AddDuck(owner, DuckGenerator.roll({ origin = "ducked" }))
		if Notify then Notify:FireClient(owner, {
			text = ("🎁 %s ducked your Jeep! +%d Droppings & a surprise duck!"):format(ducker.Name, OWNER_REWARD),
			color = Color3.fromRGB(255, 221, 51) }) end
		if jeeps[ownerId] then celebrate(jeeps[ownerId]) end
	end
end

function JeepService.Start()
	Notify = Remotes.event("Notify")
	SummonJeep = Remotes.event("SummonJeep")
	SummonJeep.OnServerEvent:Connect(function(player) JeepService.Summon(player) end)
	ProximityPromptService.PromptTriggered:Connect(function(prompt, player)
		local ownerId = prompt:GetAttribute("JeepOwner")
		if ownerId then onDuck(ownerId, player) end
	end)
	Players.PlayerRemoving:Connect(function(player)
		if jeeps[player.UserId] then jeeps[player.UserId]:Destroy(); jeeps[player.UserId] = nil end
	end)
end

return JeepService
