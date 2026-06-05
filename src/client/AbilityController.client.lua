-- src/client/AbilityController.client.lua  | applies unlocked movement abilities to your character
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")

local player  = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local AbilitySync = Remotes:WaitForChild("AbilitySync")

local owned = {}
local jumpsUsed = 0
local lastDash = 0
local floating = false

local function char() return player.Character end
local function humanoid()
	local c = char(); return c and c:FindFirstChildOfClass("Humanoid")
end
local function root()
	local c = char(); return c and c:FindFirstChild("HumanoidRootPart")
end

AbilitySync.OnClientEvent:Connect(function(list) owned = list or {} end)

-- reset multi-jump counter on landing
local function hookCharacter(c)
	local hum = c:WaitForChild("Humanoid")
	jumpsUsed = 0
	hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			jumpsUsed = 0
		end
	end)
end
if char() then hookCharacter(char()) end
player.CharacterAdded:Connect(hookCharacter)

local function maxJumps()
	if owned.triplejump then return 3 elseif owned.doublejump then return 2 else return 1 end
end

UserInputService.JumpRequest:Connect(function()
	local hum = humanoid(); if not hum then return end
	local state = hum:GetState()
	if state == Enum.HumanoidStateType.Freefall and jumpsUsed < maxJumps() - 0 then
		if jumpsUsed < maxJumps() then
			-- mid-air jump
			local r = root()
			if r and jumpsUsed >= 1 then
				r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, 50, r.AssemblyLinearVelocity.Z)
			end
		end
	end
	if state == Enum.HumanoidStateType.Freefall then jumpsUsed += 1 end
end)

-- count the initial ground jump
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Space then
		local hum = humanoid()
		if hum and hum:GetState() ~= Enum.HumanoidStateType.Freefall then jumpsUsed = 1 end
	end
	-- DASH (Q) — requires dash ability
	if input.KeyCode == Enum.KeyCode.Q and owned.dash then
		if os.clock() - lastDash > 2 then
			lastDash = os.clock()
			local r, hum = root(), humanoid()
			if r and hum then
				local dir = hum.MoveDirection
				if dir.Magnitude < 0.1 then dir = r.CFrame.LookVector end
				r.AssemblyLinearVelocity = dir * 90 + Vector3.new(0, 10, 0)
			end
		end
	end
	-- FLOAT toggle (F) — requires float ability
	if input.KeyCode == Enum.KeyCode.F and owned.float then
		floating = not floating
	end
end)

-- float: gently cancel gravity while held on
RunService.Heartbeat:Connect(function()
	local r = root()
	if floating and owned.float and r then
		if r.AssemblyLinearVelocity.Y < 0 then
			r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, 0, r.AssemblyLinearVelocity.Z)
		end
	end
	-- WALL CLIMB: holding into a wall while in air gives upward boost
	if owned.wallclimb and r then
		local hum = humanoid()
		if hum and hum:GetState() == Enum.HumanoidStateType.Freefall and hum.MoveDirection.Magnitude > 0.1 then
			local origin = r.Position
			local rp = RaycastParams.new(); rp.FilterDescendantsInstances = { char() }; rp.FilterType = Enum.RaycastFilterType.Exclude
			local hit = workspace:Raycast(origin, hum.MoveDirection * 3, rp)
			if hit then
				r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, 28, r.AssemblyLinearVelocity.Z)
			end
		end
	end
end)

-- speed potion: bump WalkSpeed when a speed potion is active (re-applied each spawn)
task.spawn(function()
	while true do
		local hum = humanoid()
		if hum then hum.WalkSpeed = (owned.dash and 20 or 16) end
		task.wait(2)
	end
end)
