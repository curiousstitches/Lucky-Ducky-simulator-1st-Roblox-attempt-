-- src/server/ZoneBuilder.lua  | builds 100 continuous zones in a straight line (Z=0..~11000).
-- Theme + currency changes every 10 zones (10 worlds). Each zone: themed floor, side walls,
-- breakable field, a progression gate at the end, an egg-hatcher line, and scaling enemies.
-- Zones are placed in Workspace.Zones.Zone_N folders so the streaming script can hide far ones.
local Workspace         = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ZoneConfig"))
local Terrain    = require(script.Parent.Terrain)
local Decor      = require(script.Parent.Decor)

local ZoneBuilder = {}
ZoneBuilder.OriginX = 0   -- the line runs along +Z at X=0
ZoneBuilder.BaseY = 250   -- build at sky-lobby height so World 1 connects by a level bridge
ZoneBuilder.StartZOffset = 80 -- zone 1 starts just past the lobby's front so a bridge links them

local function part(props)
	local p=Instance.new("Part"); p.Anchored=true; p.Material=Enum.Material.SmoothPlastic
	for k,v in pairs(props) do p[k]=v end
	return p
end
local function label(pp,text,color,size)
	local bb=Instance.new("BillboardGui"); bb.Size=UDim2.new(0,size or 200,0,44); bb.StudsOffset=Vector3.new(0,4,0)
	bb.AlwaysOnTop=true; bb.Adornee=pp; bb.Parent=pp
	local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBlack
	t.TextColor3=color or Color3.new(1,1,1); t.TextStrokeTransparency=0.3; t.TextScaled=true; t.Text=text; t.Parent=bb
end

local function breakable(pos,parent,reward,hp,color,mat,currency)
	local b=part({ Name="Breakable", Size=Vector3.new(4,4,4), Position=pos+Vector3.new(0,2,0), Color=color, Material=mat, CanCollide=false, Parent=parent })
	b:SetAttribute("MaxHP",hp); b:SetAttribute("Reward",reward); b:SetAttribute("Currency",currency)
	CollectionService:AddTag(b,"Breakable")
end

local function enemyDuck(pos,parent,stats,currency)
	local e=part({ Name="EnemyDuck", Size=Vector3.new(4,5,4), Position=pos+Vector3.new(0,3,0), Color=Color3.fromRGB(200,70,70), Material=Enum.Material.Neon, CanCollide=false, Parent=parent })
	e:SetAttribute("HP",stats.enemyHp); e:SetAttribute("MaxHP",stats.enemyHp); e:SetAttribute("Damage",stats.enemyDmg)
	e:SetAttribute("Reward",math.floor(stats.reward*4)); e:SetAttribute("Currency",currency)
	CollectionService:AddTag(e,"EnemyDuck"); label(e,"🦆 Rogue Duck",Color3.fromRGB(255,120,120),120)
end

-- a small themed prop near the borders for flavor
local function themedProp(kind, pos, parent, accent)
	if kind=="bubble" then local b=part({Shape=Enum.PartType.Ball,Size=Vector3.new(3,3,3),Position=pos+Vector3.new(0,2,0),Color=Color3.fromRGB(200,235,255),Material=Enum.Material.Glass,Transparency=0.4,CanCollide=false,Parent=parent}); b.CanQuery=false
	elseif kind=="tire" then local b=part({Shape=Enum.PartType.Cylinder,Size=Vector3.new(1.5,4,4),Position=pos+Vector3.new(0,2,0),Color=Color3.fromRGB(30,30,34),Material=Enum.Material.SmoothPlastic,CanCollide=false,Parent=parent}); b.CanQuery=false
	elseif kind=="block" then local b=part({Size=Vector3.new(4,4,4),Position=pos+Vector3.new(0,2,0),Color=accent,Material=Enum.Material.SmoothPlastic,CanCollide=false,Parent=parent}); b.CanQuery=false
	elseif kind=="canister" then local b=part({Shape=Enum.PartType.Cylinder,Size=Vector3.new(5,3,3),Position=pos+Vector3.new(0,2.5,0),Color=Color3.fromRGB(220,60,40),Material=Enum.Material.Metal,CanCollide=false,Parent=parent}); b.CanQuery=false
	elseif kind=="pipe" then local b=part({Shape=Enum.PartType.Cylinder,Size=Vector3.new(8,1.5,1.5),Position=pos+Vector3.new(0,1,0),Color=Color3.fromRGB(120,120,130),Material=Enum.Material.Metal,CanCollide=false,Parent=parent}); b.CanQuery=false
	elseif kind=="hologram" then local b=part({Size=Vector3.new(3,6,0.3),Position=pos+Vector3.new(0,3,0),Color=accent,Material=Enum.Material.Neon,Transparency=0.4,CanCollide=false,Parent=parent}); b.CanQuery=false
	elseif kind=="chandelier" then local b=part({Shape=Enum.PartType.Ball,Size=Vector3.new(4,4,4),Position=pos+Vector3.new(0,9,0),Color=Color3.fromRGB(255,225,120),Material=Enum.Material.Neon,CanCollide=false,Parent=parent}); b.CanQuery=false; local l=Instance.new("PointLight");l.Range=14;l.Color=accent;l.Parent=b
	elseif kind=="barrel" then local b=part({Shape=Enum.PartType.Cylinder,Size=Vector3.new(4,3,3),Position=pos+Vector3.new(0,2,0),Color=Color3.fromRGB(120,200,60),Material=Enum.Material.Neon,Transparency=0.1,CanCollide=false,Parent=parent}); b.CanQuery=false
	elseif kind=="gempillar" then local b=part({Size=Vector3.new(3,12,3),Position=pos+Vector3.new(0,6,0),Color=Color3.fromRGB(255,225,90),Material=Enum.Material.Neon,CanCollide=false,Parent=parent}); b.CanQuery=false
	elseif kind=="asteroid" then local b=part({Shape=Enum.PartType.Ball,Size=Vector3.new(5,5,5),Position=pos+Vector3.new(0,6,0),Color=Color3.fromRGB(90,80,110),Material=Enum.Material.Slate,CanCollide=false,Parent=parent}); b.CanQuery=false
	end
end

function ZoneBuilder.zoneCFrame(zone)
	return Vector3.new(ZoneBuilder.OriginX, ZoneBuilder.BaseY, ZoneConfig.zoneOriginZ(zone) + ZoneConfig.ZoneLength/2 + ZoneBuilder.StartZOffset)
end

function ZoneBuilder.Build()
	local world=Workspace:FindFirstChild("World") or Instance.new("Folder"); world.Name="World"; world.Parent=Workspace
	local zonesRoot=Instance.new("Folder"); zonesRoot.Name="Zones"; zonesRoot.Parent=Workspace
	local W=ZoneConfig.ZoneWidth; local L=ZoneConfig.ZoneLength; local half=W/2

	for zone=1, ZoneConfig.TotalZones do
		local wd=ZoneConfig.worldForZone(zone)
		local stats=ZoneConfig.stats(zone)
		local cz=ZoneConfig.zoneOriginZ(zone)+L/2 + ZoneBuilder.StartZOffset
		local origin=Vector3.new(0,ZoneBuilder.BaseY,cz)
		local folder=Instance.new("Folder"); folder.Name="Zone_"..zone; folder.Parent=zonesRoot

		local art = ZoneConfig.artForZone(zone)
		-- themed floor (raised so nothing clips), with a darker base; use art ground material
		part({ Name="Floor", Size=Vector3.new(W,4,L), Position=origin+Vector3.new(0,-2,0), Color=wd.floor, Material=art.ground or wd.floorMat, Parent=folder })
		-- corridor wall STRUCTURES (buildings/ruins/fences) with scenery gaps, both sides
		for _,s in ipairs({-1,1}) do
			local style = art.walls[((zone + (s==1 and 0 or 1)) % #art.walls)+1]
			Terrain.wallStructures(origin, folder, s, half, L, style, wd.border, wd.accent)
			Terrain.backdrop(origin, folder, s, half, L, wd.border, wd.prop)
		end
		-- floating animated bits (drifting particles + slow-floating chunks)
		do
			local em=Instance.new("ParticleEmitter"); em.Texture="rbxassetid://243660364"
			em.Rate=6; em.Lifetime=NumberRange.new(3,6); em.Speed=NumberRange.new(1,3); em.Size=NumberSequence.new(art.mood=="dark" and 0.5 or 0.8)
			em.Color=ColorSequence.new(wd.accent); em.SpreadAngle=Vector2.new(180,180)
			local emPart=part({ Size=Vector3.new(1,1,1), Position=origin+Vector3.new(0,20,0), Transparency=1, CanCollide=false, Parent=folder })
			emPart.CanQuery=false; em.Parent=emPart
		end

		-- world entrance banner at the first zone of each world
		if (zone-1)%10==0 then
			local sign=part({ Size=Vector3.new(40,10,1), Position=origin+Vector3.new(0,12,-L/2+4), Color=Color3.fromRGB(30,30,38), Parent=folder })
			label(sign, ("WORLD %d\n%s"):format(wd.n, wd.name), wd.accent, 260)
			Decor.arch(origin+Vector3.new(0,0,-L/2+6), folder, wd.accent)
		end

		-- breakable field (themed)
		local n=8 + math.floor(zone/12)
		for i=1,n do
			local x=math.random(-half+12, half-12); local z=math.random(-L/2+12, L/2-20)
			breakable(origin+Vector3.new(x,0,z), folder, stats.reward, stats.hp, wd.floor:Lerp(Color3.new(0,0,0),0.3), wd.floorMat, wd.currency)
		end
		-- themed border props
		for i=1,6 do
			local s=(i%2==0) and 1 or -1
			themedProp(wd.prop, origin+Vector3.new(s*(half-6), 0, math.random(-L/2+10,L/2-10)), folder, wd.accent)
		end
		-- (roaming/zone enemies removed — combat now happens at the scaling Boss Arena)

		-- PROGRESSION GATE at the end (Z = +L/2), with a doorway gap
		local doorW=22
		local seg=(W-doorW)/2
		for _,s in ipairs({-1,1}) do
			local gw=part({ Size=Vector3.new(seg,30,4), Position=origin+Vector3.new(s*(doorW/2+seg/2),15,L/2), Color=wd.border, Material=Enum.Material.SmoothPlastic, Parent=folder })
			gw.CanQuery=false
		end
		if zone < ZoneConfig.TotalZones then
			local gate=part({ Name="Gate_"..zone, Size=Vector3.new(doorW,24,3), Position=origin+Vector3.new(0,12,L/2), Color=wd.accent, Material=Enum.Material.ForceField, Transparency=0.35, Parent=folder })
			gate:SetAttribute("GateLevel",zone+1); gate:SetAttribute("GateCost",stats.unlockCost); gate:SetAttribute("GateCurrency",wd.currency)
			CollectionService:AddTag(gate,"LevelGate")
			label(gate, ("🧱 ZONE %d\n%d %s"):format(zone+1, stats.unlockCost, wd.curName), wd.accent)
		end

		-- EGG HATCHER LINE against the right side of the gate (a row of jeep pods)
		for e=1,3 do
			local podPos = origin+Vector3.new(half-12-(e-1)*8, 4, L/2-12)
			local pod=part({ Name="Hatcher_"..zone.."_"..e, Shape=Enum.PartType.Ball, Size=Vector3.new(7,9,7), Position=podPos, Color=wd.accent, Material=Enum.Material.Neon, Transparency=0.05, Parent=folder })
			pod:SetAttribute("HatchZone",zone); pod:SetAttribute("EggCost",stats.eggCost); pod:SetAttribute("Currency",wd.currency)
			CollectionService:AddTag(pod,"Hatcher")
			-- pedestal + glow light + sparkle for that PS99 pop
			part({ Shape=Enum.PartType.Cylinder, Size=Vector3.new(2,6,6), Position=podPos-Vector3.new(0,5,0), Color=Color3.fromRGB(230,230,240), Material=Enum.Material.Marble, CFrame=CFrame.new(podPos-Vector3.new(0,5,0))*CFrame.Angles(0,0,math.pi/2), Parent=folder })
			local lt=Instance.new("PointLight"); lt.Color=wd.accent; lt.Range=14; lt.Brightness=1.4; lt.Parent=pod
			local em=Instance.new("ParticleEmitter"); em.Texture="rbxassetid://243660364"; em.Rate=10; em.Lifetime=NumberRange.new(0.8,1.4); em.Speed=NumberRange.new(1,2); em.Size=NumberSequence.new(0.6); em.Color=ColorSequence.new(wd.accent); em.Parent=pod
			local prompt=Instance.new("ProximityPrompt"); prompt.ActionText="Hatch"; prompt.ObjectText="🚙 Jeep Egg "..zone
			prompt.HoldDuration=0.15; prompt.MaxActivationDistance=12
			prompt:SetAttribute("HatchZone",zone); prompt:SetAttribute("EggCost",stats.eggCost); prompt:SetAttribute("Currency",wd.currency); prompt.Parent=pod
			if e==2 then label(pod, ("🥚 Hatch: %d %s"):format(stats.eggCost, wd.curName), wd.accent) end
		end

		-- END-OF-WORLD portal at each world's last zone (10,20,...,90) -> next world's first zone
		if zone % 10 == 0 and zone < ZoneConfig.TotalZones then
			local ep=part({ Name="EndPortal_"..zone, Size=Vector3.new(16,20,3), Position=origin+Vector3.new(0,12,L/2-6),
				Color=Color3.fromRGB(150,90,255), Material=Enum.Material.Neon, Transparency=0.2, Parent=folder })
			ep:SetAttribute("NextZone",zone+1); CollectionService:AddTag(ep,"EndPortal")
			label(ep, ("✨ WORLD %d → %d\nstep through!"):format(wd.n, wd.n+1), Color3.fromRGB(190,140,255))
		end

		-- a rebirth shrine every 20 zones (kept from your ladder)
		if zone%20==0 then
			local sh=part({ Name="RebirthShrine_"..zone, Shape=Enum.PartType.Cylinder, Size=Vector3.new(3,10,10),
				Position=origin+Vector3.new(-half+10,5,0), Color=Color3.fromRGB(255,215,40), Material=Enum.Material.Neon,
				CFrame=CFrame.new(origin+Vector3.new(-half+10,5,0))*CFrame.Angles(0,0,math.pi/2), Parent=folder })
			sh:SetAttribute("RebirthShrine",true); CollectionService:AddTag(sh,"RebirthShrine")
			label(sh,"🔄 REBIRTH",Color3.fromRGB(255,230,120))
		end
	end
end

return ZoneBuilder
