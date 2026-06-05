-- src/server/LevelBuilder.lua  | builds a long LINEAR path: level 1->N platforms in a straight
-- corridor with side walls, gates between levels, theme change every 10 levels, rebirth shrine
-- every 20. Heavy decoration is sampled for performance; gates+walls span the whole path.
local Workspace         = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ThemeConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ThemeConfig"))
local Decor       = require(script.Parent.Decor)

local LevelBuilder = {}
LevelBuilder.TotalLevels = 200       -- physical levels built (path is huge; raise later if desired)
LevelBuilder.PathX = 600             -- the level corridor runs along +Z starting here (away from hub)

local function part(props)
	local p = Instance.new("Part"); p.Anchored = true; p.Material = Enum.Material.SmoothPlastic
	for k,v in pairs(props) do p[k]=v end
	return p
end
local function label(parentPart, text, color)
	local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,220,0,46); bb.StudsOffset=Vector3.new(0,4,0)
	bb.AlwaysOnTop=true; bb.Parent=parentPart
	local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1
	t.Font=Enum.Font.GothamBlack; t.TextColor3=color or Color3.new(1,1,1); t.TextStrokeTransparency=0.3
	t.TextScaled=true; t.Text=text; t.Parent=bb
end

local function breakable(pos,parent,reward,hp,color,mat,currency)
	local b=part({ Size=Vector3.new(4,4,4), Position=pos+Vector3.new(0,2,0), Color=color, Material=mat or Enum.Material.Wood, Parent=parent })
	b:SetAttribute("MaxHP",hp); b:SetAttribute("Reward",reward); b:SetAttribute("Currency",currency or "DuckDroppings")
	CollectionService:AddTag(b,"Breakable")
end

function LevelBuilder.levelOrigin(level)
	return Vector3.new(LevelBuilder.PathX, 0, level * ThemeConfig.LevelSpacing)
end

function LevelBuilder.Build()
	local world = Workspace:FindFirstChild("World") or Instance.new("Folder")
	world.Name="World"; world.Parent=Workspace
	local folder = Instance.new("Folder"); folder.Name="Levels"; folder.Parent=world

	local PS = ThemeConfig.PlatformSize
	local halfW = PS/2

	for lvl=1, LevelBuilder.TotalLevels do
		local theme, themeIdx = ThemeConfig.forLevel(lvl)
		local origin = LevelBuilder.levelOrigin(lvl)
		local heavy = (lvl<=40) or (lvl%5==0)  -- decorate near levels + every 5th far out

		-- platform floor (raised, themed) — slight height variation for a hilly feel
		local hill = math.sin(lvl*0.6)*2
		local floor = part({ Name="L"..lvl, Size=Vector3.new(PS,4,ThemeConfig.LevelSpacing),
			Position=origin+Vector3.new(0,hill-2,0), Color=theme.floor, Material=theme.floorMat, Parent=folder })

		-- SIDE WALLS to keep players on the path
		for _,side in ipairs({-1,1}) do
			part({ Size=Vector3.new(2,18,ThemeConfig.LevelSpacing), Position=origin+Vector3.new(side*halfW,hill+7,0),
				Color=theme.accent, Material=Enum.Material.SmoothPlastic, Transparency=0.25, Parent=folder })
		end

		-- THEME ENTRANCE every 10 levels: a grand arch + banner
		if (lvl-1)%ThemeConfig.LevelsPerTheme==0 then
			Decor.arch(origin+Vector3.new(0,hill,-ThemeConfig.LevelSpacing/2+4), folder, theme.accent, ("%s  (Lv %d)"):format(theme.name,lvl))
		end

		-- GATE between this level and the next (pay to pass)
		if lvl < LevelBuilder.TotalLevels then
			local gateCost = math.floor(150 * (1.14 ^ (lvl-1)))
			local gate = part({ Name="Gate_"..lvl, Size=Vector3.new(PS-4,16,2),
				Position=origin+Vector3.new(0,hill+8,ThemeConfig.LevelSpacing/2), Color=Color3.fromRGB(40,40,55),
				Material=Enum.Material.ForceField, Transparency=0.35, Parent=folder })
			gate:SetAttribute("GateLevel",lvl+1); gate:SetAttribute("GateCost",gateCost); gate:SetAttribute("GateCurrency",theme.currency)
			CollectionService:AddTag(gate,"LevelGate")
			label(gate, ("⛩️ LEVEL %d\n%d Droppings"):format(lvl+1,gateCost), theme.accent)
		end

		-- REBIRTH SHRINE every 20 levels
		if ThemeConfig.isRebirthLevel(lvl) then
			local shrine = part({ Name="RebirthShrine_"..lvl, Shape=Enum.PartType.Cylinder,
				Size=Vector3.new(3,10,10), Position=origin+Vector3.new(halfW-8,hill+3,0),
				Color=Color3.fromRGB(255,215,40), Material=Enum.Material.Neon,
				CFrame=CFrame.new(origin+Vector3.new(halfW-8,hill+3,0))*CFrame.Angles(0,0,math.pi/2), Parent=folder })
			shrine:SetAttribute("RebirthShrine",true); CollectionService:AddTag(shrine,"RebirthShrine")
			label(shrine,"🔄 REBIRTH SHRINE",Color3.fromRGB(255,230,120))
			local lt=Instance.new("PointLight"); lt.Color=Color3.fromRGB(255,220,90); lt.Range=20; lt.Brightness=2; lt.Parent=shrine
		end

		if heavy then
		-- breakables scale with level, drop THIS theme's local currency
		local hp=math.floor(40*(1.1^(lvl-1)))
		local reward=math.floor(5*(1.08^(lvl-1)))
		local count=math.clamp(6+math.floor(lvl/10),6,16)
		for i=1,count do
			local x=(-halfW+8)+(i/(count+1))*(PS-16)
			local z=math.random(-ThemeConfig.LevelSpacing/2+10, ThemeConfig.LevelSpacing/2-14)
			breakable(origin+Vector3.new(x,hill,z), folder, reward, hp, theme.floor:Lerp(Color3.new(0,0,0),0.3), theme.breakMat, theme.currency)
		end
			-- themed foliage/props along the edges (inside walls)
			for i=1,8 do
				local side = (i%2==0) and 1 or -1
				local z=math.random(-ThemeConfig.LevelSpacing/2+8, ThemeConfig.LevelSpacing/2-8)
				Decor.themed(theme.prop, origin+Vector3.new(side*(halfW-5),hill,z), folder, theme.accent)
			end
			-- underwater / space ambiance bubbles on those themes
			if theme.underwater or theme.space then
				local em=Instance.new("ParticleEmitter")
				em.Texture="rbxassetid://243660364"; em.Rate=10; em.Lifetime=NumberRange.new(2,4)
				em.Speed=NumberRange.new(1,3); em.Size=NumberSequence.new(theme.space and 0.4 or 0.8)
				em.Color=ColorSequence.new(theme.accent); em.Parent=floor
			end
		end
	end
end

return LevelBuilder
