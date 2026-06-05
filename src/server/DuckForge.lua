-- src/server/DuckForge.lua  | CREATE-YOUR-OWN: fuse up to 100 ducks into a tier-gated custom duck
-- Pure logic. Caller (inventory service) verifies ownership, removes inputs, grants result.
-- Assumes Rojo maps src/shared -> ReplicatedStorage/Shared
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local DuckSchema = require(Shared.DuckSchema)
local DuckGenerator = require(Shared.DuckGenerator)

local DuckForge = {}
DuckForge.MAX_INPUTS = 100

-- inputs: array of duck tables. edits: { Dimension = "OptionName", ... } requested customizations.
-- returns: ok:boolean, resultDuck|errString, info
function DuckForge.forge(inputs, edits)
	edits = edits or {}
	if type(inputs) ~= "table" or #inputs == 0 then return false, "No ducks supplied to the forge." end
	if #inputs > DuckForge.MAX_INPUTS then
		return false, ("Forge accepts at most %d ducks at once (got %d)."):format(DuckForge.MAX_INPUTS, #inputs)
	end

	-- 1) tally forge points; higher rarity contributes disproportionately more
	local points = 0
	for _, d in ipairs(inputs) do
		local worth = d.worth or DuckGenerator.computeWorth(d)
		local rarity = DuckSchema.getRarity(d.rarity)
		local tierWeight = rarity and (1 + (rarity.tier - 1) * 0.35) or 1
		points += worth * tierWeight
	end
	points = math.floor(points)

	-- 2) resolve output tier + the edit dims it unlocks
	local tier = DuckSchema.forgeTierForPoints(points)
	local allowed = {}
	for _, e in ipairs(tier.edits) do allowed[e] = true end

	-- 3) seed a base duck at the output rarity, then apply only-unlocked edits
	local result = DuckGenerator.roll({ origin = "forged" })
	result.rarity = tier.outRarity

	local applied, denied = {}, {}
	for dim, optName in pairs(edits) do
		local opt = DuckSchema.findOption(dim, optName)
		if not allowed[dim] then
			denied[dim] = "locked - needs higher forge tier"
		elseif not opt then
			denied[dim] = "unknown option"
		elseif opt.forgeOnly and not tier.forgeExclusive then
			denied[dim] = "forge-exclusive - needs higher tier"
		else
			result.parts[dim] = optName
			applied[dim] = optName
		end
	end

	result.worth = DuckGenerator.computeWorth(result)
	result.forgedFrom = #inputs
	result.forgePoints = points

	return true, result, {
		points = points, outRarity = tier.outRarity,
		unlockedEdits = tier.edits, applied = applied, denied = denied,
	}
end

return DuckForge
