-- src/server/LobbyMachines.lua  | builds the progression machine lobby north of the hub:
-- Duck Merge Machine, Gold/Platinum/Rainbow upgraders, Spin Wheel, Fortune Wheel, Dice minigame.
-- Each is a tagged interactable; client opens the matching UI / fires the matching remote.
local Workspace         = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local Decor             = require(script.Parent.Decor)

local LobbyMachines = {}

local function part(props)
	local p=Instance.new("Part"); p.Anchored=true; p.Material=Enum.Material.SmoothPlastic
	for k,v in pairs(props) do p[k]=v end
	return p
end
local function label(pp,text,color)
	local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,220,0,48); bb.StudsOffset=Vector3.new(0,5,0); bb.AlwaysOnTop=true; bb.Parent=pp
	local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBlack
	t.TextColor3=color or Color3.new(1,1,1); t.TextStrokeTransparency=0.3; t.TextScaled=true; t.Text=text; t.Parent=bb
end

-- a machine: base + body + glowing core + floating label + ProximityPrompt (action tag)
local function machine(pos, parent, name, color, actionTag, actionText)
	local m=Instance.new("Model"); m.Name=name; m.Parent=parent
	part({ Size=Vector3.new(10,1,10), Position=pos+Vector3.new(0,0.5,0), Color=Color3.fromRGB(40,40,48), Material=Enum.Material.Metal, Parent=m })
	local body=part({ Size=Vector3.new(8,10,8), Position=pos+Vector3.new(0,5.5,0), Color=color, Material=Enum.Material.SmoothPlastic, Parent=m })
	part({ Shape=Enum.PartType.Ball, Size=Vector3.new(5,5,5), Position=pos+Vector3.new(0,9,0), Color=color, Material=Enum.Material.Neon, Transparency=0.1, Parent=m })
	local lt=Instance.new("PointLight"); lt.Color=color; lt.Range=16; lt.Brightness=2; lt.Parent=body
	label(body, name, color)
	local prompt=Instance.new("ProximityPrompt"); prompt.ActionText=actionText or "Use"; prompt.ObjectText=name
	prompt.HoldDuration=0.1; prompt.MaxActivationDistance=12
	prompt:SetAttribute("MachineAction", actionTag); prompt.Parent=body
	CollectionService:AddTag(prompt,"Machine")
	return m
end

function LobbyMachines.Build()
	local world=Workspace:FindFirstChild("World") or Instance.new("Folder"); world.Name="World"; world.Parent=Workspace
	local lobby=Instance.new("Folder"); lobby.Name="MachineLobby"; lobby.Parent=world

	-- raised platform lobby north of hub
	local lz=Vector3.new(0,0,-150)
	part({ Name="LobbyFloor", Size=Vector3.new(140,3,90), Position=lz+Vector3.new(0,-1,0),
		Color=Color3.fromRGB(60,62,80), Material=Enum.Material.Marble, Parent=lobby })
	part({ Name="LobbyTrim", Size=Vector3.new(150,1,100), Position=lz+Vector3.new(0,0.2,0),
		Color=Color3.fromRGB(120,90,200), Material=Enum.Material.Neon, Transparency=0.3, Parent=lobby })
	Decor.arch(lz+Vector3.new(0,0,46), lobby, Color3.fromRGB(180,120,255), "⚙️ MACHINE LOBBY")
	Decor.banner(lz+Vector3.new(-60,0,40), lobby, Color3.fromRGB(255,215,40), "UPGRADE")
	Decor.banner(lz+Vector3.new(60,0,40), lobby, Color3.fromRGB(120,200,255), "MERGE")

	-- the machines (PS99-style)
	machine(lz+Vector3.new(-48,0,0), lobby, "Duck Merge Machine", Color3.fromRGB(120,200,255), "forge",   "Merge")
	machine(lz+Vector3.new(-24,0,0), lobby, "Gold Machine",        Color3.fromRGB(255,200,50),  "gold",    "Upgrade")
	machine(lz+Vector3.new(0,0,0),   lobby, "Platinum Machine",    Color3.fromRGB(210,225,235), "platinum","Upgrade")
	machine(lz+Vector3.new(24,0,0),  lobby, "Rainbow Machine",     Color3.fromRGB(255,90,160),  "rainbow", "Upgrade")
	machine(lz+Vector3.new(48,0,0),  lobby, "Enchant Altar",       Color3.fromRGB(150,110,255), "enchant", "Enchant")

	-- minigame stations along the back
	machine(lz+Vector3.new(-36,0,-30), lobby, "Spin Wheel",    Color3.fromRGB(255,170,60),  "spin",    "Spin")
	machine(lz+Vector3.new(-12,0,-30), lobby, "Fortune Wheel", Color3.fromRGB(120,230,150), "fortune", "Spin")
	machine(lz+Vector3.new(12,0,-30),  lobby, "Lucky Dice",    Color3.fromRGB(255,120,120), "dice",    "Roll")
	machine(lz+Vector3.new(36,0,-30),  lobby, "Daily Chest",   Color3.fromRGB(200,160,90),  "chest",   "Open")

	-- lamps for ambiance
	for _,x in ipairs({-66,-22,22,66}) do Decor.lamp(lz+Vector3.new(x,0,-44), lobby, Color3.fromRGB(200,160,255)) end
end

return LobbyMachines
