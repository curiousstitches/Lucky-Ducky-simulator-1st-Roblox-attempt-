-- src/server/ForgeService.lua  | bridges the client forge to DuckForge logic, securely
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerData       = require(script.Parent.PlayerData)
local InventoryService = require(script.Parent.InventoryService)
local DuckForge        = require(script.Parent.DuckForge)
local Remotes          = require(script.Parent.Remotes)

local ForgeService = {}
local Notify

function ForgeService.Start()
	Notify = Remotes.event("Notify")
	local forge = Remotes.func("ForgeDucks")
	forge.OnServerInvoke = function(player, payload)
		local p = PlayerData.Get(player)
		if not p then return { ok = false, reason = "loading" } end
		if type(payload) ~= "table" or type(payload.ids) ~= "table" then
			return { ok = false, reason = "bad request" }
		end
		local edits = type(payload.edits) == "table" and payload.edits or {}

		-- resolve + validate ownership; reject dupes
		local owned = {}; for _, d in ipairs(p.ducks) do owned[d.id] = d end
		local idSet, inputs = {}, {}
		for _, id in ipairs(payload.ids) do
			if type(id) == "string" and owned[id] and not idSet[id] then
				idSet[id] = true
				table.insert(inputs, owned[id])
			end
		end
		if #inputs == 0 then return { ok = false, reason = "No valid ducks selected" } end
		if #inputs > DuckForge.MAX_INPUTS then return { ok = false, reason = "Max 100 ducks" } end

		local ok, result, info = DuckForge.forge(inputs, edits)
		if not ok then return { ok = false, reason = result } end

		InventoryService.RemoveDucks(player, idSet)
		InventoryService.AddDuck(player, result)
		if Notify then
			Notify:FireClient(player, {
				text = ("🔥 Forged a %s duck! (worth %d)"):format(result.rarity, result.worth or 0),
				color = Color3.fromRGB(255, 140, 60),
			})
		end
		return { ok = true, result = result, info = info }
	end
end

return ForgeService
