-- src/server/SeasonsFX.lua  | World 1 (zones 1-10) cycles through seasons, recoloring grass + tree
-- leaves on a timer (Spring → Summer → Autumn → Winter). Light + only touches World 1 parts.
local Workspace = game:GetService("Workspace")

local SeasonsFX = {}

local SEASONS = {
	{ name="Spring", grass=Color3.fromRGB(130,210,120), leaf=Color3.fromRGB(120,220,130) },
	{ name="Summer", grass=Color3.fromRGB(110,195,90),  leaf=Color3.fromRGB(70,170,80) },
	{ name="Autumn", grass=Color3.fromRGB(170,150,80),  leaf=Color3.fromRGB(220,140,60) },
	{ name="Winter", grass=Color3.fromRGB(225,235,245), leaf=Color3.fromRGB(210,225,235) },
}
local SECONDS_PER_SEASON = 90

function SeasonsFX.Start()
	task.spawn(function()
		local zonesRoot
		while not zonesRoot do zonesRoot = Workspace:FindFirstChild("Zones"); task.wait(1) end
		local idx = 0
		while true do
			idx = (idx % #SEASONS) + 1
			local s = SEASONS[idx]
			-- recolor zones 1-10 (World 1) only
			for z=1,10 do
				local folder = zonesRoot:FindFirstChild("Zone_"..z)
				if folder then
					for _, part in ipairs(folder:GetDescendants()) do
						if part:IsA("BasePart") then
							if part.Name=="Floor" then
								part.Color = s.grass
							elseif part.Material==Enum.Material.Grass then
								part.Color = s.leaf
							end
						end
					end
				end
			end
			task.wait(SECONDS_PER_SEASON)
		end
	end)
end

return SeasonsFX
