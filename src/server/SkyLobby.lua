-- src/server/SkyLobby.lua  | floating sky-island hub: a central island + satellite islands linked by
-- bridges. Buildings house each store, the 10 world portals, and egg spawners. Replaces the colosseum.
local Workspace         = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local Decor             = require(script.Parent.Decor)

local SkyLobby = {}
local Y = 250  -- lobby floats high in the sky

local function part(props)
	local p=Instance.new("Part"); p.Anchored=true; p.Material=Enum.Material.SmoothPlastic
	p.TopSurface=Enum.SurfaceType.Smooth; p.BottomSurface=Enum.SurfaceType.Smooth
	for k,v in pairs(props) do p[k]=v end
	return p
end
local function label(pp,text,color,size)
	local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,size or 210,0,46); bb.StudsOffset=Vector3.new(0,5,0)
	bb.AlwaysOnTop=true; bb.Adornee=pp; bb.Parent=pp
	local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBlack
	t.TextColor3=color or Color3.new(1,1,1); t.TextStrokeTransparency=0.3; t.TextScaled=true; t.Text=text; t.Parent=bb
end

-- a floating grassy island disc
local function island(center, parent, radius)
	local top=part({ Shape=Enum.PartType.Cylinder, Size=Vector3.new(6, radius*2, radius*2), Position=center,
		Color=Color3.fromRGB(120,200,110), Material=Enum.Material.Grass, CFrame=CFrame.new(center)*CFrame.Angles(0,0,math.pi/2), Parent=parent })
	-- tapered rock underside
	part({ Shape=Enum.PartType.Cylinder, Size=Vector3.new(10, radius*1.4, radius*1.4), Position=center-Vector3.new(0,7,0),
		Color=Color3.fromRGB(110,95,80), Material=Enum.Material.Slate, CFrame=CFrame.new(center-Vector3.new(0,7,0))*CFrame.Angles(0,0,math.pi/2), Parent=parent })
	part({ Shape=Enum.PartType.Cylinder, Size=Vector3.new(10, radius*0.7, radius*0.7), Position=center-Vector3.new(0,15,0),
		Color=Color3.fromRGB(90,78,68), Material=Enum.Material.Slate, CFrame=CFrame.new(center-Vector3.new(0,15,0))*CFrame.Angles(0,0,math.pi/2), Parent=parent })
	return top
end

-- a bridge between two island centers
local function bridge(a, b, parent)
	local mid=(a+b)/2; local dir=b-a; local len=dir.Magnitude
	local cf=CFrame.lookAt(mid, b)
	part({ Size=Vector3.new(8,1,len), CFrame=cf*CFrame.new(0,3,0), Color=Color3.fromRGB(150,110,70), Material=Enum.Material.WoodPlanks, Parent=parent })
	-- rope rails
	for _,s in ipairs({-1,1}) do
		part({ Size=Vector3.new(0.3,3,len), CFrame=cf*CFrame.new(s*4,4.5,0), Color=Color3.fromRGB(90,65,40), Material=Enum.Material.Wood, CanCollide=false, Parent=parent })
	end
end

-- a building (store/portal/egg house): walls + roof + sign + a doorway
local function building(center, parent, name, color, tagInfo)
	local m=Instance.new("Model"); m.Name="Building_"..name; m.Parent=parent
	local function wall(size,off,c) local w=part({Size=size,Position=center+off,Color=c or Color3.fromRGB(232,224,208),Material=Enum.Material.SmoothPlastic,Parent=m}); return w end
	wall(Vector3.new(22,16,1),Vector3.new(0,8,-9))
	wall(Vector3.new(1,16,18),Vector3.new(-11,8,0))
	wall(Vector3.new(1,16,18),Vector3.new(11,8,0))
	wall(Vector3.new(8,16,1),Vector3.new(-7,8,9))
	wall(Vector3.new(8,16,1),Vector3.new(7,8,9))
	local roof=part({Size=Vector3.new(26,2,22),Position=center+Vector3.new(0,16.5,0),Color=color or Color3.fromRGB(200,80,80),Material=Enum.Material.SmoothPlastic,Parent=m})
	-- decorative roof peak
	part({Size=Vector3.new(26,2,8),Position=center+Vector3.new(0,18,0),Color=(color or Color3.fromRGB(200,80,80)):Lerp(Color3.new(0,0,0),0.15),Material=Enum.Material.SmoothPlastic,Parent=m})
	label(roof, name, color or Color3.fromRGB(255,230,150))
	Decor.lamp(center+Vector3.new(-13,0,10), m, color); Decor.lamp(center+Vector3.new(13,0,10), m, color)
	-- the interactable inside (prompt on a glowing core)
	if tagInfo then
		local core=part({Size=Vector3.new(6,7,6),Position=center+Vector3.new(0,4,-2),Color=color or Color3.fromRGB(120,200,255),Material=Enum.Material.Neon,Parent=m})
		local prompt=Instance.new("ProximityPrompt"); prompt.ActionText=tagInfo.action or "Open"; prompt.ObjectText=name
		prompt.HoldDuration=0.12; prompt.MaxActivationDistance=12
		for k,v in pairs(tagInfo.attrs or {}) do prompt:SetAttribute(k,v) end
		prompt.Parent=core
		if tagInfo.tag then CollectionService:AddTag(prompt, tagInfo.tag) end
	end
	return m
end

local WORLD_NAMES = {
	"Porcelain Bathroom","Muddy Outback","Toy Store","Gas Station","Scrap Yards",
	"Cyber Garages","Luxury Showroom","Toxic Junkyard","Golden Vault","Cosmic Matrix",
}

function SkyLobby.Build()
	local world=Workspace:FindFirstChild("World") or Instance.new("Folder"); world.Name="World"; world.Parent=Workspace
	local hub=Instance.new("Folder"); hub.Name="SkyLobby"; hub.Parent=world

	Lighting.Brightness=2.4; Lighting.OutdoorAmbient=Color3.fromRGB(150,160,185)
	local atmos=Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmos.Density=0.28; atmos.Haze=1; atmos.Color=Color3.fromRGB(220,230,245); atmos.Parent=Lighting

	local C=Vector3.new(0,Y,-400)  -- central island (away from the zone line at Z>=0)
	island(C, hub, 70)
	local spawn=Instance.new("SpawnLocation"); spawn.Anchored=true; spawn.Size=Vector3.new(12,1,12)
	spawn.Position=C+Vector3.new(0,4,0); spawn.Color=Color3.fromRGB(255,221,51); spawn.Material=Enum.Material.Neon; spawn.Neutral=true; spawn.Parent=hub
	Decor.fountain(C+Vector3.new(0,3,0), hub)
	SkyLobby.Spawn = C+Vector3.new(0,8,0)

	-- ===== SATELLITE ISLANDS for stores (ring around center) =====
	local stores={
		{name="🥚 Egg Hatchery", color=Color3.fromRGB(255,200,80),  tag="Machine", attrs={MachineAction="eggs"}},
		{name="🏪 Item Shop",    color=Color3.fromRGB(90,200,120),  tag="Machine", attrs={MachineAction="shop"}},
		{name="🐾 Pet Shop",     color=Color3.fromRGB(255,170,80),  tag="Machine", attrs={MachineAction="shop"}},
		{name="🌈 Style Shop",   color=Color3.fromRGB(180,120,255), tag="Machine", attrs={MachineAction="shop"}},
		{name="⚙️ Merge Machine",color=Color3.fromRGB(120,200,255), tag="Machine", attrs={MachineAction="forge"}},
		{name="🔮 Powerups",     color=Color3.fromRGB(150,110,255), tag="Machine", attrs={MachineAction="powerups"}},
		{name="📖 Duck Index",   color=Color3.fromRGB(120,230,160), tag="Machine", attrs={MachineAction="index"}},
		{name="🔁 Trading Hub",  color=Color3.fromRGB(90,210,200),  tag="Machine", attrs={MachineAction="trade"}},
	}
	for i,s in ipairs(stores) do
		local a=((i-1)/#stores)*math.pi*2
		local ic=C+Vector3.new(math.cos(a)*150, math.sin(a*1.3)*8, math.sin(a)*150)
		island(ic, hub, 34)
		bridge(C+Vector3.new(math.cos(a)*66, 0, math.sin(a)*66), ic+Vector3.new(0,0,0), hub)
		building(ic+Vector3.new(0,3,0), hub, s.name, s.color, { action="Open", tag=s.tag, attrs=s.attrs })
	end

	-- ===== MINIGAME ISLANDS (outer ring) =====
	local games={
		{name="💰 Coin Rush",  color=Color3.fromRGB(255,210,70),  act="coinrush"},
		{name="👆 Clicker",    color=Color3.fromRGB(120,200,255), act="clicker"},
		{name="🧗 Obby Tower", color=Color3.fromRGB(150,230,150), act="obby"},
		{name="🕹️ Claw Machine",color=Color3.fromRGB(255,120,160), act="claw"},
	}
	for i,g in ipairs(games) do
		local a=((i-1)/#games)*math.pi*2 + 0.4
		local ic=C+Vector3.new(math.cos(a)*240, -10+math.sin(a)*6, math.sin(a)*240)
		island(ic, hub, 30)
		bridge(C+Vector3.new(math.cos(a)*66,0,math.sin(a)*66), ic, hub)
		building(ic+Vector3.new(0,3,0), hub, g.name, g.color, { action="Play", tag="Minigame", attrs={Minigame=g.act} })
	end

	-- ===== BRIDGE TO WORLD 1 (no more portal wall — walk straight into the zone line) =====
	-- World 1 zone 1 is built at lobby height; connect the lobby front to it with a long bridge.
	local ZoneBuilder = require(script.Parent.ZoneBuilder)
	local zone1 = ZoneBuilder.zoneCFrame(1)
	local lobbyFront = C + Vector3.new(0,0,66)
	bridge(lobbyFront, Vector3.new(zone1.X, C.Y, zone1.Z - 60), hub)
	-- a welcome arch at the World 1 entrance
	local entry=part({ Name="World1Entry", Size=Vector3.new(30,3,8), Position=Vector3.new(0,C.Y+1,zone1.Z-58), Color=Color3.fromRGB(120,200,110), Material=Enum.Material.Grass, Parent=hub })
	label(entry, "🌍 WORLD 1: GRASSLAND ODYSSEY →", Color3.fromRGB(150,230,140), 280)

	-- ===== TELEPORT PAD (opens the world/zone teleport menu) =====
	local tpI=C+Vector3.new(0,-4,90); island(tpI, hub, 30)
	bridge(C+Vector3.new(0,0,66), tpI+Vector3.new(0,0,-26), hub)
	local tpPad=part({ Name="TeleportPad", Size=Vector3.new(14,1,14), Position=tpI+Vector3.new(0,4,0), Color=Color3.fromRGB(120,180,255), Material=Enum.Material.Neon, Parent=hub })
	tpPad:SetAttribute("TeleportMenu",true); CollectionService:AddTag(tpPad,"TeleportMenu")
	local tpPrompt=Instance.new("ProximityPrompt"); tpPrompt.ActionText="Travel"; tpPrompt.ObjectText="Fast Travel"
	tpPrompt.HoldDuration=0.1; tpPrompt.MaxActivationDistance=12; tpPrompt:SetAttribute("TeleportMenu",true); tpPrompt.Parent=tpPad
	label(tpPad,"🌀 Fast Travel",Color3.fromRGB(150,210,255))

	-- VIP + AFK islands
	local vipI=C+Vector3.new(-150,12,-150); island(vipI, hub, 26); bridge(C+Vector3.new(-50,0,-50), vipI, hub)
	local vip=part({ Name="VIPPad", Size=Vector3.new(14,1,14), Position=vipI+Vector3.new(0,4,0), Color=Color3.fromRGB(255,215,40), Material=Enum.Material.Neon, Parent=hub })
	vip:SetAttribute("VIPTeleport",true); CollectionService:AddTag(vip,"VIPPad"); label(vip,"👑 VIP Lounge",Color3.fromRGB(255,225,90))
	local afkI=C+Vector3.new(150,12,-150); island(afkI, hub, 26); bridge(C+Vector3.new(50,0,-50), afkI, hub)
	local afk=part({ Name="AFKZone", Size=Vector3.new(14,1,14), Position=afkI+Vector3.new(0,4,0), Color=Color3.fromRGB(120,200,255), Material=Enum.Material.Neon, Parent=hub })
	afk:SetAttribute("AFKZone",true); CollectionService:AddTag(afk,"AFKZone"); label(afk,"💤 AFK Grind",Color3.fromRGB(150,210,255))

	-- BOSS ARENA island (dramatic, behind center) — summon a scaling Duck Titan here
	local bossI=C+Vector3.new(0,8,-200); island(bossI, hub, 40)
	bridge(C+Vector3.new(0,0,-66), bossI+Vector3.new(0,0,38), hub)
	local arena=part({ Shape=Enum.PartType.Cylinder, Size=Vector3.new(2,60,60), Position=bossI+Vector3.new(0,4,0),
		Color=Color3.fromRGB(60,20,28), Material=Enum.Material.Slate, CFrame=CFrame.new(bossI+Vector3.new(0,4,0))*CFrame.Angles(0,0,math.pi/2), Parent=hub })
	local bossPad=part({ Name="BossPad", Size=Vector3.new(14,1,14), Position=bossI+Vector3.new(0,5,0), Color=Color3.fromRGB(200,40,50), Material=Enum.Material.Neon, Parent=hub })
	bossPad:SetAttribute("BossPad",true); CollectionService:AddTag(bossPad,"BossPad"); label(bossPad,"💀 SUMMON BOSS\n(harder each defeat)",Color3.fromRGB(255,110,120))
	for i=0,5 do local a=(i/6)*math.pi*2; Decor.lamp(bossI+Vector3.new(math.cos(a)*30,0,math.sin(a)*30), hub, Color3.fromRGB(255,70,50)) end

	-- floating clouds for ambiance
	for i=1,20 do
		local cl=part({ Shape=Enum.PartType.Ball, Size=Vector3.new(math.random(20,40),12,math.random(20,40)),
			Position=C+Vector3.new(math.random(-300,300), math.random(-40,40), math.random(-300,300)),
			Color=Color3.fromRGB(245,248,255), Material=Enum.Material.SmoothPlastic, Transparency=0.2, CanCollide=false, Parent=hub })
		cl.CanQuery=false
	end
end

return SkyLobby
