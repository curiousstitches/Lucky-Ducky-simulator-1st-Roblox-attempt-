-- src/server/World1Builder.lua  | builds Grassland Odyssey: 100 stages along a path with varied
-- terrain (hills/tunnel/water/sky-island/mixed), themed breakables, boundary walls, scaling gates,
-- shops/upgrade booths/merchants/minigames/secret rooms that improve per stage, and rebirth shrines.
local Workspace         = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared       = ReplicatedStorage:WaitForChild("Shared")
local W1           = require(Shared:WaitForChild("World1Config"))
local Terrain      = require(script.Parent.Terrain)
local Decor        = require(script.Parent.Decor)

local World1Builder = {}
-- World 1 lives far from the hub so it can later become its own place cleanly.
World1Builder.OriginX = 2000

local function part(props)
	local p=Instance.new("Part"); p.Anchored=true; p.Material=Enum.Material.SmoothPlastic
	for k,v in pairs(props) do p[k]=v end
	return p
end
local function label(pp,text,color,size)
	local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,size or 220,0,46); bb.StudsOffset=Vector3.new(0,4,0); bb.AlwaysOnTop=true; bb.Parent=pp
	local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBlack
	t.TextColor3=color or Color3.new(1,1,1); t.TextStrokeTransparency=0.3; t.TextScaled=true; t.Text=text; t.Parent=bb
end

function World1Builder.stageOrigin(stage)
	return Vector3.new(World1Builder.OriginX, 0, stage * W1.StageSpacing)
end

local function breakable(pos, parent, def, stats, currency)
	local hp = math.floor(stats.hp * def.hpMul)
	local reward = math.max(1, math.floor(stats.reward * def.rewardMul))
	local size = (def.kind=="tree") and Vector3.new(3,8,3) or (def.kind=="chest") and Vector3.new(4,3,5) or Vector3.new(4,4,4)
	local b=part({ Name=def.kind, Size=size, Position=pos+Vector3.new(0,size.Y/2,0), Color=def.color, Material=def.mat, CanCollide=false, Parent=parent })
	b:SetAttribute("MaxHP",hp); b:SetAttribute("Reward",reward); b:SetAttribute("Currency",currency)
	CollectionService:AddTag(b,"Breakable")
end

-- an enemy duck that attacks pets/players (handled by EnemyEventService-style combat via tag)
local function enemyDuck(pos, parent, stats)
	local e=part({ Name="EnemyDuck", Size=Vector3.new(4,5,4), Position=pos+Vector3.new(0,3,0), Color=Color3.fromRGB(200,70,70), Material=Enum.Material.Neon, CanCollide=false, Parent=parent })
	e:SetAttribute("HP",stats.enemyHp); e:SetAttribute("MaxHP",stats.enemyHp); e:SetAttribute("Damage",stats.enemyDmg)
	e:SetAttribute("Reward",math.floor(stats.reward*4))
	CollectionService:AddTag(e,"EnemyDuck")
	label(e,"🦆 Rogue Duck",Color3.fromRGB(255,120,120),120)
	return e
end

-- a scaling facility booth (shop/upgrade/merchant/minigame/secret). tier improves with stage.
local function facility(pos, parent, kind, tier, stage)
	local colors={ shop=Color3.fromRGB(90,200,120), upgrade=Color3.fromRGB(120,180,255), merchant=Color3.fromRGB(255,170,80),
		minigame=Color3.fromRGB(255,120,160), secret=Color3.fromRGB(255,215,60) }
	local names={ shop="🏪 Gear Shop", upgrade="⬆️ Upgrade Booth", merchant="🛒 Merchant", minigame="🎡 Mini Game", secret="❓ Secret Stash" }
	local c=colors[kind] or Color3.fromRGB(200,200,200)
	local booth=part({ Name="Facility_"..kind, Size=Vector3.new(7,8,7), Position=pos+Vector3.new(0,4,0), Color=c, Material=Enum.Material.Neon, CanCollide=false, Parent=parent })
	booth:SetAttribute("Facility",kind); booth:SetAttribute("Tier",tier); booth:SetAttribute("Stage",stage)
	CollectionService:AddTag(booth,"Facility")
	local prompt=Instance.new("ProximityPrompt"); prompt.ActionText=(kind=="secret" and "Loot") or "Open"
	prompt.ObjectText=(names[kind] or kind).." (T"..tier..")"; prompt.HoldDuration=0.15; prompt.MaxActivationDistance=12
	prompt:SetAttribute("Facility",kind); prompt:SetAttribute("Tier",tier); prompt:SetAttribute("Stage",stage); prompt.Parent=booth
	label(booth,(names[kind] or kind).."\nTier "..tier,c)
end

function World1Builder.Build()
	local world=Workspace:FindFirstChild("World") or Instance.new("Folder"); world.Name="World"; world.Parent=Workspace
	local folder=Instance.new("Folder"); folder.Name=W1.Id; folder.Parent=world
	local pal=W1.Palette
	local PS=W1.PlatformSize; local half=PS/2

	for stage=1, W1.Stages do
		local origin=World1Builder.stageOrigin(stage)
		local stats=W1.stageStats(stage)
		local layout=W1.layout(stage)
		local heavy=(stage<=20) or (stage%6==0)
		-- size variation: mostly LARGE, a few MEDIUM showcase stages (never small/cramped)
		local sizeMul = (stage % 7 == 0) and 0.82 or (stage % 13 == 0 and 1.25 or 1.0)
		local PSv = math.floor(PS * sizeMul)
		local halfv = PSv/2

		-- base ground: never flat — always hills, with layout-specific extras
		Terrain.hills(origin, folder, Vector3.new(PSv, 0, W1.StageSpacing), pal.grass, Enum.Material.Grass, layout=="flat" and 2 or 7, 9)
		-- corridor walls WITH a doorway at the +Z end so stages connect into one continuous path
		Terrain.corridor(origin, folder, W1.StageSpacing, halfv, 20, pal.grassDk)
		-- a visible road running the length of the stage, guiding you forward through the doorway
		Terrain.road(origin, folder, 14, W1.StageSpacing, pal.dirt, Enum.Material.Cobblestone)
		Terrain.roadLamps(origin, folder, W1.StageSpacing, 9)
		-- a signpost at the start of the stage showing the number
		Terrain.signpost(origin+Vector3.new(11,2,-W1.StageSpacing/2+16), folder, "STAGE\n"..stage, pal.accent)
		-- a small arch gateway at the stage entrance for a "next area" feel
		Decor.arch(origin+Vector3.new(0,2,-W1.StageSpacing/2+6), folder, pal.accent)

		if layout=="water" then
			Terrain.water(origin+Vector3.new(0,1,0), folder, Vector3.new(PSv-20, 0, 40), pal.water)
		elseif layout=="tunnel" then
			Terrain.tunnel(origin, folder, W1.StageSpacing-10, pal.rock, Enum.Material.Slate)
		elseif layout=="skyisland" then
			Terrain.skyIsland(origin+Vector3.new(0,28,0), folder, PSv*0.6, pal.grass, Enum.Material.Grass)
			-- bridge up
			part({ Size=Vector3.new(6,1,40), Position=origin+Vector3.new(0,14,-10), Color=pal.dirt, Material=Enum.Material.WoodPlanks, Parent=folder })
		elseif layout=="mixed" then
			Terrain.skyIsland(origin+Vector3.new(halfv-14,22,10), folder, 18, pal.grass, Enum.Material.Grass)
			Terrain.water(origin+Vector3.new(-halfv+16,1,-10), folder, Vector3.new(20,0,20), pal.water)
		end

		-- theme entrance arch at stage 1
		if stage==1 then Decor.arch(origin+Vector3.new(0,2,-W1.StageSpacing/2+4), folder, pal.accent, W1.Name.."  (Lv 1)") end

		-- GATE to next stage
		if stage < W1.Stages then
			local gate=part({ Name="Gate_"..stage, Size=Vector3.new(20,18,2), Position=origin+Vector3.new(0,9,W1.StageSpacing/2),
				Color=Color3.fromRGB(40,50,40), Material=Enum.Material.ForceField, Transparency=0.35, Parent=folder })
			gate:SetAttribute("GateLevel",stage+1); gate:SetAttribute("GateCost",stats.gateCost); gate:SetAttribute("GateCurrency",W1.Currency)
			CollectionService:AddTag(gate,"LevelGate")
			label(gate,("⛩️ STAGE %d\n%d Droppings"):format(stage+1,stats.gateCost),pal.accent)
		end

		-- REBIRTH shrine every 20
		if stage%20==0 then
			local sh=part({ Name="RebirthShrine_"..stage, Shape=Enum.PartType.Cylinder, Size=Vector3.new(3,10,10),
				Position=origin+Vector3.new(halfv-8,5,0), Color=pal.accent, Material=Enum.Material.Neon,
				CFrame=CFrame.new(origin+Vector3.new(halfv-8,5,0))*CFrame.Angles(0,0,math.pi/2), Parent=folder })
			sh:SetAttribute("RebirthShrine",true); CollectionService:AddTag(sh,"RebirthShrine")
			label(sh,"🔄 REBIRTH",pal.accent)
			local lt=Instance.new("PointLight"); lt.Color=pal.accent; lt.Range=20; lt.Brightness=2; lt.Parent=sh
		end

		-- a facility on feature stages, tier scales with progress
		local feat=W1.feature(stage)
		if feat and feat~="start" and feat~="rebirth" then
			local fpos=origin+Vector3.new(-halfv+12,2,18)
			Terrain.branchPath(origin+Vector3.new(0,2,18), fpos, folder, pal.dirt)
			facility(fpos, folder, feat, W1.shopTier(stage), stage)
		end

		if heavy then
			-- themed breakables scattered (trees, rocks, crates, chests, bushes)
			local n=math.clamp(8+math.floor(stage/8),8,20)
			for i=1,n do
				local def=W1.Breakables[math.random(1,#W1.Breakables)]
				local x=math.random(-halfv+10, halfv-10); local z=math.random(-W1.StageSpacing/2+12, W1.StageSpacing/2-16)
				breakable(origin+Vector3.new(x,2,z), folder, def, stats, W1.Currency)
			end
			-- swaying trees + flowers + flowing accents
			for i=1,6 do
				local side=(i%2==0) and 1 or -1
				Terrain.swayTree(origin+Vector3.new(side*(halfv-6),2,math.random(-40,40)), folder, 0.8+math.random()*0.7, pal.grassDk)
			end
			for i=1,6 do
				Decor.flower(origin+Vector3.new(math.random(-halfv+8,halfv-8),2,math.random(-40,40)), folder, pal.flower[math.random(1,#pal.flower)])
			end
			-- enemy ducks from stage 3+
			if stage>=3 then for i=1,math.clamp(math.floor(stage/15),1,4) do
				enemyDuck(origin+Vector3.new(math.random(-halfv+14,halfv-14),2,math.random(-30,30)), folder, stats)
			end end
			-- a dark/dingy corner with a richer reward crate
			local darkPos=origin+Vector3.new(halfv-10,2,-W1.StageSpacing/2+14)
			-- a side trail off the main road hints at this hidden dark room
			Terrain.branchPath(origin+Vector3.new(0,2,-W1.StageSpacing/2+14), darkPos, folder, pal.dirt)
			part({ Size=Vector3.new(16,16,16), Position=darkPos+Vector3.new(0,8,0), Color=Color3.fromRGB(30,34,30), Material=Enum.Material.Slate, Transparency=0.1, Parent=folder })
			breakable(darkPos, folder, { kind="chest", color=Color3.fromRGB(200,160,70), mat=Enum.Material.Wood, hpMul=3, rewardMul=5 }, stats, W1.Currency)

			-- a SECOND, well-hidden secret on some stages: tucked behind the hill line off a faint trail,
			-- holds Shimmer Splats + a luck-boosted duck (rewards scale with stage)
			if stage % 3 == 0 then
				local hidePos = origin + Vector3.new(-halfv+8, 2, W1.StageSpacing/2-16)
				Terrain.branchPath(origin+Vector3.new(0,2,W1.StageSpacing/2-16), hidePos, folder, pal.dirt)
				local cache = part({ Name="HiddenCache", Size=Vector3.new(3.5,3.5,3.5), Position=hidePos+Vector3.new(0,2,0),
					Color=Color3.fromRGB(255,120,200), Material=Enum.Material.Neon, Transparency=0.05, Parent=folder })
				cache:SetAttribute("Stage", stage); CollectionService:AddTag(cache,"HiddenCache")
				local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="Loot"; prompt.ObjectText="✨ Hidden Cache"
				prompt.HoldDuration=0.3; prompt.MaxActivationDistance=10; prompt:SetAttribute("Facility","secret")
				prompt:SetAttribute("Tier", W1.shopTier(stage)); prompt:SetAttribute("Stage", stage+1000); prompt.Parent=cache
				local em=Instance.new("ParticleEmitter"); em.Texture="rbxassetid://243660364"; em.Rate=8
				em.Lifetime=NumberRange.new(1,1.6); em.Color=ColorSequence.new(Color3.fromRGB(255,180,220)); em.Parent=cache
			end
		end
	end
end

return World1Builder
