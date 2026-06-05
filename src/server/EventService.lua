-- src/server/EventService.lua  | applies the active rotating event's multipliers to every player
local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared       = ReplicatedStorage:WaitForChild("Shared")
local EventConfig  = require(Shared:WaitForChild("EventConfig"))
local PlayerData   = require(script.Parent.PlayerData)
local Remotes      = require(script.Parent.Remotes)

local EventService = {}

function EventService.Apply(player)
	local p = PlayerData.Get(player); if not p then return end
	local ev = EventConfig.active()
	p._eventMult = ev.droppingsMult or 1
	p._eventLuck = ev.luckMult or 1
end

function EventService.Start()
	local getEvent = Remotes.func("GetEvent")
	getEvent.OnServerInvoke = function()
		local ev = EventConfig.active()
		return { id = ev.id, name = ev.name, blurb = ev.blurb, endsAt = EventConfig.endsAt() }
	end

	Players.PlayerAdded:Connect(function(player)
		task.spawn(function()
			local tries = 0
			while not PlayerData.Get(player) and tries < 60 do task.wait(0.1); tries += 1 end
			EventService.Apply(player)
		end)
	end)
	for _, p in ipairs(Players:GetPlayers()) do task.spawn(EventService.Apply, p) end

	-- re-apply when the week rolls over mid-session
	task.spawn(function()
		local lastIdx = EventConfig.activeIndex()
		while true do
			task.wait(60)
			local idx = EventConfig.activeIndex()
			if idx ~= lastIdx then
				lastIdx = idx
				for _, player in ipairs(Players:GetPlayers()) do EventService.Apply(player) end
			end
		end
	end)
end

return EventService
