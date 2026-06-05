-- src/server/VoidProtection.lua  | tracks each player's last safe ground position and smoothly
-- resets them there if they fall below Y = -20 (off sky islands or out of the zone path).
local Players   = game:GetService("Players")
local RunService = game:GetService("RunService")

local VoidProtection = {}
local FALL_Y = -20
local safe = {} -- [userId] = Vector3 last grounded position

local function isGrounded(char)
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return false end
	local st = hum:GetState()
	return st == Enum.HumanoidStateType.Running or st == Enum.HumanoidStateType.Landed
		or st == Enum.HumanoidStateType.RunningNoPhysics
end

function VoidProtection.Start()
	-- poll at a stable 0.5s (cheap, server-side)
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, player in ipairs(Players:GetPlayers()) do
				local char = player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				if root then
					if root.Position.Y < FALL_Y then
						-- fell into the void: reset to last safe spot (or spawn if none)
						local target = safe[player.UserId]
						if target then
							root.CFrame = CFrame.new(target + Vector3.new(0, 4, 0))
							root.AssemblyLinearVelocity = Vector3.zero
						else
							-- no record yet; let Roblox respawn handle it
							local hum = char:FindFirstChildOfClass("Humanoid")
							if hum then hum.Health = 0 end
						end
					elseif isGrounded(char) and root.Position.Y > FALL_Y + 2 then
						-- record this as a safe spot
						safe[player.UserId] = root.Position
					end
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(p) safe[p.UserId] = nil end)
end

return VoidProtection
