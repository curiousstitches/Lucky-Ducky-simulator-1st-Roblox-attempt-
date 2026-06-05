-- src/client/ProximityLabels.client.lua  | fades world labels in only when the player is close,
-- so the hub/colosseum stops rendering 40+ labels through walls at once.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local player = Players.LocalPlayer
local NEAR = 34          -- studs at which a label becomes visible
local FADE = 10          -- fade band
local SCAN_EVERY = 0.25  -- seconds between proximity scans (cheap)

-- auto-discover all world BillboardGuis with an Adornee (no tagging needed), cached + refreshed
local Workspace = game:GetService("Workspace")
local cache = {}
local lastRefresh = -999
local function labels(now)
	if now - lastRefresh > 4 then
		lastRefresh = now
		cache = {}
		for _, d in ipairs(Workspace:GetDescendants()) do
			if d:IsA("BillboardGui") and d.Parent and d.Parent:IsA("BasePart") then
				cache[#cache+1] = d
			end
		end
	end
	return cache
end

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt
	if acc < SCAN_EVERY then return end
	acc = 0
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local pos = root.Position
	for _, bb in ipairs(labels(os.clock())) do
		local anchor = bb.Adornee or bb.Parent
		if anchor and anchor:IsA("BasePart") then
			local d = (anchor.Position - pos).Magnitude
			local target = d <= NEAR and 1 or 0
			for _, t in ipairs(bb:GetDescendants()) do
				if t:IsA("TextLabel") then
					t.TextTransparency = 1 - target
					t.TextStrokeTransparency = target == 1 and 0.3 or 1
				end
			end
			bb.Enabled = d <= NEAR + FADE
		end
	end
end)
