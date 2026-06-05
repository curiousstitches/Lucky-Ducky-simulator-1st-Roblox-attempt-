-- src/client/CosmeticRenderer.client.lua  | applies Trail/Aura attributes to every player's character
local Players = game:GetService("Players")

local function parseColor(s)
	if s == "rainbow" then return nil end -- handled specially
	local r, g, b = s:match("(%d+),(%d+),(%d+)")
	if r then return Color3.fromRGB(tonumber(r), tonumber(g), tonumber(b)) end
	return Color3.fromRGB(255, 255, 255)
end

local function applyTrail(char, colorStr)
	local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
	local old = root:FindFirstChild("CosTrail"); if old then old:Destroy() end
	local oldA = root:FindFirstChild("CosTrailA"); if oldA then oldA:Destroy() end
	if not colorStr or colorStr == "" then return end
	local a0 = Instance.new("Attachment"); a0.Name = "CosTrailA"; a0.Position = Vector3.new(0, 1, 0); a0.Parent = root
	local a1 = Instance.new("Attachment"); a1.Name = "CosTrail"; a1.Position = Vector3.new(0, -1, 0); a1.Parent = root
	local tr = Instance.new("Trail"); tr.Name = "CosTrail"; tr.Attachment0 = a0; tr.Attachment1 = a1
	tr.Lifetime = 0.6; tr.WidthScale = NumberSequence.new(1, 0)
	if colorStr == "rainbow" then
		tr.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255,60,90)),
			ColorSequenceKeypoint.new(0.5, Color3.fromRGB(60,200,255)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(160,90,255)) })
	else
		tr.Color = ColorSequence.new(parseColor(colorStr))
	end
	tr.Parent = root
end

local function applyAura(char, colorStr)
	local root = char:FindFirstChild("HumanoidRootPart"); if not root then return end
	local old = root:FindFirstChild("CosAura"); if old then old:Destroy() end
	if not colorStr or colorStr == "" then return end
	local emit = Instance.new("ParticleEmitter"); emit.Name = "CosAura"
	emit.Texture = "rbxassetid://243660364"; emit.Rate = 14; emit.Lifetime = NumberRange.new(0.8, 1.3)
	emit.Speed = NumberRange.new(1, 2); emit.Size = NumberSequence.new(0.6)
	emit.Color = ColorSequence.new(colorStr == "rainbow" and Color3.fromRGB(255,255,255) or parseColor(colorStr))
	emit.Parent = root
end

local function attach(player)
	local function setup(char)
		applyTrail(char, player:GetAttribute("Trail"))
		applyAura(char, player:GetAttribute("Aura"))
	end
	if player.Character then setup(player.Character) end
	player.CharacterAdded:Connect(function(c) task.wait(0.5); setup(c) end)
	player:GetAttributeChangedSignal("Trail"):Connect(function() if player.Character then applyTrail(player.Character, player:GetAttribute("Trail")) end end)
	player:GetAttributeChangedSignal("Aura"):Connect(function() if player.Character then applyAura(player.Character, player:GetAttribute("Aura")) end end)
end

for _, p in ipairs(Players:GetPlayers()) do attach(p) end
Players.PlayerAdded:Connect(attach)
