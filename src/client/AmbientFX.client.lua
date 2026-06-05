-- src/client/AmbientFX.client.lua  | gently sways SwayTree models and flows FlowWater surfaces.
-- Light + capped to nearby instances for mobile performance.
local CollectionService = game:GetService("CollectionService")
local RunService        = game:GetService("RunService")
local Players           = game:GetService("Players")

local player = Players.LocalPlayer
local MAX_ACTIVE = 60   -- only animate the closest N of each type
local t = 0

local function nearest(tagged, originPos, max)
	local out = {}
	for _, inst in ipairs(tagged) do
		local pivotOk, pos = pcall(function()
			if inst:IsA("Model") and inst.PrimaryPart then return inst.PrimaryPart.Position
			elseif inst:IsA("BasePart") then return inst.Position end
		end)
		if pivotOk and pos then
			out[#out+1] = { inst = inst, d = (pos - originPos).Magnitude }
		end
	end
	table.sort(out, function(a,b) return a.d < b.d end)
	local res = {}
	for i=1, math.min(max, #out) do res[i] = out[i].inst end
	return res
end

local treeBase = {}  -- cache original CFrame

RunService.RenderStepped:Connect(function(dt)
	t += dt
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local origin = root.Position

	-- SWAY TREES
	local trees = nearest(CollectionService:GetTagged("SwayTree"), origin, MAX_ACTIVE)
	for i, tree in ipairs(trees) do
		if tree:IsA("Model") and tree.PrimaryPart then
			if not treeBase[tree] then treeBase[tree] = tree:GetPivot() end
			local sway = math.sin(t * 1.2 + i) * 0.04
			tree:PivotTo(treeBase[tree] * CFrame.Angles(0, 0, sway))
		end
	end

	-- FLOW WATER (scroll texture-like bob via transparency + slight y)
	local waters = nearest(CollectionService:GetTagged("FlowWater"), origin, MAX_ACTIVE)
	for i, w in ipairs(waters) do
		if w:IsA("BasePart") then
			w.Transparency = 0.25 + math.sin(t*1.5 + i)*0.06
		end
	end
end)
