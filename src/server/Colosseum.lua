-- src/server/Colosseum.lua  | tiered colosseum spawn lobby: 10 world portals on the top ring,
-- shops/eggs/machines on the mid ring, VIP lounge + AFK zone in the center pit.
-- World 1 portal teleports into World1Builder.stageOrigin(1); worlds 2-10 are locked.
local Workspace         = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Lighting          = game:GetService("Lighting")
local Decor             = require(script.Parent.Decor)

local Colosseum = {}
local CENTER = Vector3.new(0,0,0)

local function p(props)
	local part=Instance.new("Part"); part.Anchored=true; part.Material=Enum.Material.SmoothPlastic
	part.TopSurface=Enum.SurfaceType.Smooth; part.BottomSurface=Enum.SurfaceType.Smooth
	for k,v in pairs(props) do part[k]=v end
	return part
end
local function label(pp,text,color,size)
	local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,size or 200,0,44); bb.StudsOffset=Vector3.new(0,4,0)
	bb.AlwaysOnTop=true; bb.Adornee=pp; bb.Parent=pp
	local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBlack
	t.TextColor3=color or Color3.new(1,1,1); t.TextStrokeTransparency=0.3; t.TextScaled=true; t.Text=text; t.Parent=bb
end

local WORLD_NAMES = {
	"Grassland Odyssey","Muddy Bayou","Canopy Deepwood","Steamgear Factory","Neon Underbelly",
	"Hurricane Ridge","Obsidian Magma Basin","Stratosphere Aerie","Cyber Grid","Chrono-Gauntlet",
}

function Colosseum.Build()
	local world=Workspace:FindFirstChild("World") or Instance.new("Folder"); world.Name="World"; world.Parent=Workspace
	local col=Instance.new("Folder"); col.Name="Colosseum"; col.Parent=world

	-- warm ambiance
	Lighting.Brightness=2.2; Lighting.OutdoorAmbient=Color3.fromRGB(130,130,150)
	local atmos=Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmos.Density=0.3; atmos.Haze=1.2; atmos.Color=Color3.fromRGB(215,222,235); atmos.Parent=Lighting

	-- ===== TIERED RINGS (concentric cylinders, descending into a center pit) =====
	-- outer top ring (portals), mid ring (shops), center pit (VIP/AFK)
	local function ring(radius, y, height, color, mat)
		-- build as a thick ring using a big cylinder minus visual; simpler: a flat annulus floor
		local floor=p({ Shape=Enum.PartType.Cylinder, Size=Vector3.new(2, radius*2, radius*2), Position=CENTER+Vector3.new(0,y,0),
			Color=color, Material=mat or Enum.Material.Marble, CFrame=CFrame.new(CENTER+Vector3.new(0,y,0))*CFrame.Angles(0,0,math.pi/2), Parent=col })
		return floor
	end
	ring(200, -0.5, 2, Color3.fromRGB(180,170,150))          -- top ring (portals)
	ring(140,  -8, 2, Color3.fromRGB(170,160,140))           -- mid ring (shops)
	ring( 80, -16, 2, Color3.fromRGB(150,140,120))           -- center pit floor (VIP/AFK)

	-- ramps/steps down between tiers (4 stairways)
	for i=0,3 do
		local a=(i/4)*math.pi*2
		for tier,info in ipairs({{from=200,to=140,y1=-0.5,y2=-8},{from=140,to=80,y1=-8,y2=-16}}) do
			local r=(info.from+info.to)/2
			local ramp=p({ Size=Vector3.new(18,2,math.abs(info.from-info.to)+10), Color=Color3.fromRGB(160,150,130), Material=Enum.Material.Marble,
				CFrame=CFrame.new(CENTER+Vector3.new(math.cos(a)*r,(info.y1+info.y2)/2,math.sin(a)*r))*CFrame.Angles(math.rad(18),a+math.pi/2,0), Parent=col })
		end
	end

	-- spawn in the center pit
	local spawn=Instance.new("SpawnLocation"); spawn.Anchored=true; spawn.Size=Vector3.new(12,1,12)
	spawn.Position=CENTER+Vector3.new(0,-15,0); spawn.Color=Color3.fromRGB(255,221,51); spawn.Material=Enum.Material.Neon; spawn.Neutral=true; spawn.Parent=col

	-- ===== CENTER PIT: VIP + AFK =====
	local vip=p({ Name="VIPPad", Size=Vector3.new(16,1,16), Position=CENTER+Vector3.new(-30,-15,0), Color=Color3.fromRGB(255,215,40), Material=Enum.Material.Neon, Parent=col })
	vip:SetAttribute("VIPTeleport",true); CollectionService:AddTag(vip,"VIPPad"); label(vip,"👑 VIP Lounge",Color3.fromRGB(255,225,90))
	local afk=p({ Name="AFKZone", Size=Vector3.new(16,1,16), Position=CENTER+Vector3.new(30,-15,0), Color=Color3.fromRGB(120,200,255), Material=Enum.Material.Neon, Parent=col })
	afk:SetAttribute("AFKZone",true); CollectionService:AddTag(afk,"AFKZone"); label(afk,"💤 AFK Grind Zone",Color3.fromRGB(150,210,255))
	Decor.fountain(CENTER+Vector3.new(0,-16,0), col)

	-- ===== MID RING: shops / eggs / machines (use ProximityPrompts so they're tappable) =====
	local stations={
		{name="🥚 Egg Hatchery", color=Color3.fromRGB(255,200,80),  action="eggs"},
		{name="🏪 Item Shop",    color=Color3.fromRGB(90,200,120),  action="shop"},
		{name="🐾 Pet Shop",     color=Color3.fromRGB(255,170,80),  action="shop"},
		{name="🌈 Style Shop",   color=Color3.fromRGB(180,120,255), action="shop"},
		{name="⚙️ Merge Machine",color=Color3.fromRGB(120,200,255), action="forge"},
		{name="🟡 Gold Machine", color=Color3.fromRGB(255,200,50),  action="gold"},
		{name="⬜ Platinum",     color=Color3.fromRGB(210,225,235), action="platinum"},
		{name="🌈 Rainbow",      color=Color3.fromRGB(255,90,160),  action="rainbow"},
		{name="🎡 Spin Wheel",   color=Color3.fromRGB(255,170,60),  action="spin"},
		{name="🎲 Lucky Dice",   color=Color3.fromRGB(255,120,120), action="dice"},
		{name="🎁 Daily Chest",  color=Color3.fromRGB(200,160,90),  action="chest"},
		{name="🔮 Enchant",      color=Color3.fromRGB(150,110,255), action="enchant"},
	}
	for i,s in ipairs(stations) do
		local a=((i-1)/#stations)*math.pi*2
		local pos=CENTER+Vector3.new(math.cos(a)*130,-7,math.sin(a)*130)
		local booth=p({ Name="Station_"..i, Size=Vector3.new(8,9,8), Position=pos+Vector3.new(0,4.5,0), Color=s.color, Material=Enum.Material.Neon, Parent=col })
		label(booth,s.name,s.color)
		local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="Open"; prompt.ObjectText=s.name
		prompt.HoldDuration=0.12; prompt.MaxActivationDistance=12; prompt:SetAttribute("MachineAction",s.action); prompt.Parent=booth
		CollectionService:AddTag(prompt,"Machine")
	end

	-- ===== TOP RING: 10 WORLD PORTALS =====
	for i=1,10 do
		local a=((i-1)/10)*math.pi*2
		local pos=CENTER+Vector3.new(math.cos(a)*185,0,math.sin(a)*185)
		local unlocked=(i==1)
		local portal=p({ Name="Portal_"..i, Size=Vector3.new(14,22,3), Position=pos+Vector3.new(0,11,0),
			Color=unlocked and Color3.fromRGB(90,220,255) or Color3.fromRGB(70,70,80),
			Material=unlocked and Enum.Material.Neon or Enum.Material.Slate, Transparency=unlocked and 0.2 or 0.1, Parent=col })
		portal:SetAttribute("WorldIndex",i); portal:SetAttribute("Unlocked",unlocked)
		CollectionService:AddTag(portal,"WorldPortal")
		label(portal, ("🌍 %d. %s%s"):format(i, WORLD_NAMES[i], unlocked and "" or "\n🔒 Coming Soon"), unlocked and Color3.fromRGB(150,230,255) or Color3.fromRGB(150,150,160))
		Decor.arch(pos+Vector3.new(0,0,4), col, unlocked and Color3.fromRGB(90,220,255) or Color3.fromRGB(90,90,100))
	end

	-- colosseum outer wall (tall, ringed) so you can't see the void
	for i=0,35 do
		local a=(i/36)*math.pi*2
		p({ Size=Vector3.new(20,60,6), Position=CENTER+Vector3.new(math.cos(a)*205,28,math.sin(a)*205),
			Color=Color3.fromRGB(190,180,160), Material=Enum.Material.Marble,
			CFrame=CFrame.new(CENTER+Vector3.new(math.cos(a)*205,28,math.sin(a)*205))*CFrame.Angles(0,a,0), Parent=col })
	end
end

return Colosseum
