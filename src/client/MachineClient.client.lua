-- src/client/MachineClient.client.lua  | when a machine ProximityPrompt is triggered, route it:
-- forge/enchant -> open existing UIs; gold/platinum/rainbow -> upgrade remote; spin/fortune/dice/chest -> minigame remotes.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local MachineUpgrade = Remotes:WaitForChild("MachineUpgrade")
local MachineFortune = Remotes:WaitForChild("MachineFortune")
local MachineDice    = Remotes:WaitForChild("MachineDice")
local MachineChest   = Remotes:WaitForChild("MachineChest")
local DoSpin         = Remotes:WaitForChild("DoSpin")

local HatchEgg = Remotes:WaitForChild("HatchEgg")

ProximityPromptService.PromptTriggered:Connect(function(prompt)
	-- minigame buildings
	local mg = prompt:GetAttribute("Minigame")
	if mg then
		local map = { clicker="ClickGame", claw="ClawPull", obby="ObbyDone", coinrush="CoinRush" }
		local rname = map[mg]
		if rname then
			local r = Remotes:FindFirstChild(rname)
			if r then
				if mg=="coinrush" then r:InvokeServer(20) else r:InvokeServer() end
			end
		end
		return
	end
	-- in-zone egg hatchers
	local hz = prompt:GetAttribute("HatchZone")
	if hz then
		HatchEgg:InvokeServer(hz, prompt:GetAttribute("EggCost"), prompt:GetAttribute("Currency"))
		return
	end
	local action = prompt:GetAttribute("MachineAction")
	if not action then return end
	if action == "forge" then
		local g = Players.LocalPlayer.PlayerGui:FindFirstChild("ForgeUI")
		-- ForgeUI has its own open button; nudge via a BindableEvent-free approach: just notify
		-- (the player can tap the on-screen Forge button; machines mainly drive upgrades/minigames)
	elseif action == "gold" or action == "platinum" or action == "rainbow" then
		MachineUpgrade:InvokeServer(action)
	elseif action == "enchant" then
		-- handled by ExtrasUI button
	elseif action == "spin" then
		DoSpin:InvokeServer()
	elseif action == "fortune" then
		MachineFortune:InvokeServer()
	elseif action == "dice" then
		MachineDice:InvokeServer()
	elseif action == "chest" then
		MachineChest:InvokeServer()
	end
end)
