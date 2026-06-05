-- src/server/Terrain.lua  | non-flat textured ground builders + animated water/trees + boundary walls.
-- All anchored, mobile-conscious. Swaying trees & flowing water are driven by a light client effect
-- via tags (CollectionService): "SwayTree" and "FlowWater".
local CollectionService = game:GetService("CollectionService")
local Terrain = {}

local function p(props)
	local part = Instance.new("Part"); part.Anchored = true; part.CanCollide = true
	part.TopSurface = Enum.SurfaceType.Smooth; part.BottomSurface = Enum.SurfaceType.Smooth
	for k,v in pairs(props) do part[k]=v end
	return part
end

-- a chunk of rolling ground: many wedge/blocks of varied height for a hilly, textured look.
-- baseHeight keeps the top high enough that nothing clips (floors sit at y=0 top).
function Terrain.hills(center, parent, size, color, mat, amplitude, roadHalf)
	amplitude = amplitude or 6
	roadHalf = roadHalf or 11   -- keep this center lane flat for the road
	local model = Instance.new("Model"); model.Name="Hills"; model.Parent=parent
	-- solid thick base; top sits at y = -0.2 so the road (placed above) never z-fights with it
	p({ Size=Vector3.new(size.X, 30, size.Z), Position=center - Vector3.new(0,15.2,0), Color=color:Lerp(Color3.new(0,0,0),0.2), Material=mat, Parent=model })
	-- mounds on top, but NEVER in the center road lane
	local step = 10
	for x=-size.X/2, size.X/2, step do
		for z=-size.Z/2, size.Z/2, step do
			if math.abs(x) > roadHalf + 2 then  -- skip the road channel
				local h = amplitude * (0.5 + 0.5*math.sin(x*0.08)*math.cos(z*0.08)) + math.random()*2
				local mound = p({ Size=Vector3.new(step+1, h+2, step+1), Position=center+Vector3.new(x, h/2 - 0.2, z),
					Color=color:Lerp(Color3.new(1,1,1), math.random()*0.08), Material=mat, Parent=model })
				mound.CanCollide = true
			end
		end
	end
	return model
end

-- a flowing water pool (animated via tag). Sits in a carved basin.
function Terrain.water(center, parent, size, color)
	local model=Instance.new("Model"); model.Name="Water"; model.Parent=parent
	-- basin rim
	p({ Size=Vector3.new(size.X+8,4,size.Z+8), Position=center-Vector3.new(0,2,0), Color=Color3.fromRGB(90,80,60), Material=Enum.Material.Sand, Parent=model })
	local water=p({ Name="WaterSurface", Size=Vector3.new(size.X,2,size.Z), Position=center, Color=color or Color3.fromRGB(70,170,220),
		Material=Enum.Material.Glass, Transparency=0.25, CanCollide=false, Parent=model })
	CollectionService:AddTag(water,"FlowWater")
	return model
end

-- a swaying tree (tagged so client tweens it)
function Terrain.swayTree(pos, parent, scale, leaf)
	scale=scale or 1
	local model=Instance.new("Model"); model.Name="SwayTree"; model.Parent=parent
	local trunk=p({ Shape=Enum.PartType.Cylinder, Size=Vector3.new(8*scale,2.4*scale,2.4*scale), Color=Color3.fromRGB(105,70,40),
		Material=Enum.Material.Wood, CFrame=CFrame.new(pos+Vector3.new(0,4*scale,0))*CFrame.Angles(0,0,math.pi/2), CanCollide=false, Parent=model })
	for i=0,2 do
		p({ Shape=Enum.PartType.Ball, Size=Vector3.new((9-i*1.8)*scale,(9-i*1.8)*scale,(9-i*1.8)*scale),
			Color=(leaf or Color3.fromRGB(70,160,80)):Lerp(Color3.new(1,1,1),i*0.07), Material=Enum.Material.Grass,
			Position=pos+Vector3.new(0,(8+i*2.6)*scale,0), CanCollide=false, Parent=model })
	end
	model.PrimaryPart = trunk
	for _, d in ipairs(model:GetDescendants()) do if d:IsA("BasePart") then d.CanQuery = false end end
	CollectionService:AddTag(model,"SwayTree")
	return model
end

-- a covered tunnel section (arched roof + walls) the path runs through
function Terrain.tunnel(center, parent, length, color, mat)
	local model=Instance.new("Model"); model.Name="Tunnel"; model.Parent=parent
	for _,side in ipairs({-1,1}) do
		p({ Size=Vector3.new(3,20,length), Position=center+Vector3.new(side*14,10,0), Color=color, Material=mat, Parent=model })
	end
	p({ Size=Vector3.new(34,3,length), Position=center+Vector3.new(0,20,0), Color=color:Lerp(Color3.new(0,0,0),0.2), Material=mat, Parent=model })
	-- dingy interior lighting
	local glow=p({ Shape=Enum.PartType.Ball, Size=Vector3.new(1.5,1.5,1.5), Position=center+Vector3.new(0,17,0), Color=Color3.fromRGB(255,180,90), Material=Enum.Material.Neon, CanCollide=false, Parent=model })
	local lt=Instance.new("PointLight"); lt.Color=Color3.fromRGB(255,170,80); lt.Range=22; lt.Brightness=1.4; lt.Parent=glow
	return model
end

-- a floating sky island (platform + supports + grass top)
function Terrain.skyIsland(center, parent, size, color, mat)
	local model=Instance.new("Model"); model.Name="SkyIsland"; model.Parent=parent
	p({ Size=Vector3.new(size,6,size), Position=center, Color=color, Material=mat, Parent=model })
	-- tapering underside rock
	p({ Size=Vector3.new(size*0.7,8,size*0.7), Position=center-Vector3.new(0,6,0), Color=Color3.fromRGB(110,100,90), Material=Enum.Material.Slate, Parent=model })
	p({ Size=Vector3.new(size*0.4,8,size*0.4), Position=center-Vector3.new(0,12,0), Color=Color3.fromRGB(90,82,74), Material=Enum.Material.Slate, Parent=model })
	return model
end

-- a visible path/road segment (raised slightly above ground so it reads as a trail)
function Terrain.road(center, parent, width, length, color, mat)
	-- sits at y=0.6 (base top is at -0.2) so it reads as a raised trail with no z-fighting
	local road = p({ Name="Road", Size=Vector3.new(width, 1.6, length), Position=center+Vector3.new(0,0.6,0),
		Color=color or Color3.fromRGB(150,130,95), Material=mat or Enum.Material.Cobblestone, Parent=parent })
	road.CanQuery=false
	-- edging stones
	for _,s in ipairs({-1,1}) do
		local edge=p({ Size=Vector3.new(1.5,2.2,length), Position=center+Vector3.new(s*(width/2+0.5),0.9,0),
			Color=Color3.fromRGB(110,95,70), Material=Enum.Material.Slate, Parent=parent })
		edge.CanQuery=false
	end
	return road
end

-- a short branch trail leading off the main road toward a hidden spot (hints a secret)
function Terrain.branchPath(fromPos, toPos, parent, color)
	local mid=(fromPos+toPos)/2
	local dir=(toPos-fromPos); local len=dir.Magnitude
	if len < 1 then return end
	local cf=CFrame.lookAt(mid, toPos)
	local trail=p({ Name="BranchPath", Size=Vector3.new(6,1.6,len), CFrame=cf*CFrame.new(0,0.8,0),
		Color=color or Color3.fromRGB(135,118,86), Material=Enum.Material.Ground, Parent=parent })
	trail.CanQuery=false
	-- a couple of curiosity markers (lanterns) so the eye follows it
	local lantern=p({ Shape=Enum.PartType.Ball, Size=Vector3.new(1.4,1.4,1.4), Position=toPos+Vector3.new(0,3,0),
		Color=Color3.fromRGB(255,200,120), Material=Enum.Material.Neon, CanCollide=false, Parent=parent })
	lantern.CanQuery=false
	local lt=Instance.new("PointLight"); lt.Color=Color3.fromRGB(255,190,110); lt.Range=14; lt.Brightness=1.2; lt.Parent=lantern
	return trail
end

-- boundary walls with a DOORWAY gap in the middle of the far (+Z) end so stages connect
function Terrain.corridor(center, parent, length, halfWidth, doorWidth, color)
	local model=Instance.new("Model"); model.Name="Corridor"; model.Parent=parent
	for _,side in ipairs({-1,1}) do
		-- long side walls (invisible, solid, camera-transparent)
		local w=p({ Size=Vector3.new(3,60,length), Position=center+Vector3.new(side*halfWidth,28,0),
			Color=color or Color3.fromRGB(120,160,120), Material=Enum.Material.SmoothPlastic, Transparency=1, Parent=model })
		w.CanQuery=false
	end
	-- back wall pieces with a centered doorway gap (so you can only pass through the gate opening)
	doorWidth = doorWidth or 18
	local seg=(halfWidth*2 - doorWidth)/2
	for _,side in ipairs({-1,1}) do
		local w=p({ Size=Vector3.new(seg,60,3), Position=center+Vector3.new(side*(doorWidth/2+seg/2),28,length/2),
			Color=color or Color3.fromRGB(120,160,120), Material=Enum.Material.SmoothPlastic, Transparency=1, Parent=model })
		w.CanQuery=false
	end
	return model
end

-- lampposts lining the road at intervals
function Terrain.roadLamps(center, parent, length, halfRoad)
	for z=-length/2+20, length/2-20, 40 do
		for _,s in ipairs({-1,1}) do
			local base=p({ Size=Vector3.new(0.8,9,0.8), Position=center+Vector3.new(s*(halfRoad+2),5,z), Color=Color3.fromRGB(50,45,40), Material=Enum.Material.Metal, CanCollide=false, Parent=parent })
			base.CanQuery=false
			local bulb=p({ Shape=Enum.PartType.Ball, Size=Vector3.new(1.6,1.6,1.6), Position=center+Vector3.new(s*(halfRoad+2),9.5,z), Color=Color3.fromRGB(255,235,170), Material=Enum.Material.Neon, CanCollide=false, Parent=parent })
			bulb.CanQuery=false
			local lt=Instance.new("PointLight"); lt.Color=Color3.fromRGB(255,225,160); lt.Range=16; lt.Brightness=1.1; lt.Parent=bulb
		end
	end
end

-- a stage signpost by the road
function Terrain.signpost(pos, parent, text, color)
	local post=p({ Size=Vector3.new(0.6,7,0.6), Position=pos+Vector3.new(0,3.5,0), Color=Color3.fromRGB(110,80,50), Material=Enum.Material.Wood, CanCollide=false, Parent=parent })
	post.CanQuery=false
	local board=p({ Size=Vector3.new(8,3,0.4), Position=pos+Vector3.new(0,7,0), Color=Color3.fromRGB(150,110,70), Material=Enum.Material.WoodPlanks, CanCollide=false, Parent=parent })
	board.CanQuery=false
	local sg=Instance.new("SurfaceGui"); sg.Face=Enum.NormalId.Front; sg.Parent=board
	local t=Instance.new("TextLabel"); t.Size=UDim2.fromScale(1,1); t.BackgroundTransparency=1; t.Font=Enum.Font.GothamBlack
	t.TextScaled=true; t.TextColor3=color or Color3.fromRGB(255,240,200); t.Text=text; t.Parent=sg
	return board
end

-- ===== CORRIDOR WALL STRUCTURES (shaped like buildings/ruins/fences, with scenery gaps) =====
-- builds along one side of a zone (side = -1 or 1), at x = side*halfWidth, spanning the zone length.
function Terrain.wallStructures(origin, parent, side, halfWidth, length, style, color, accent)
	local x = side * halfWidth
	local n = 2
	for i = 0, n - 1 do
		local z = -length/2 + (i + 0.5) * (length / n)
		local pos = origin + Vector3.new(x, 0, z)
		if style == "building" then
			-- a little house: body + roof + window glow; gaps between buildings show scenery
			local h = math.random(16, 26)
			local b = p({ Size=Vector3.new(6, h, 18), Position=pos+Vector3.new(-side*3, h/2, 0), Color=color, Material=Enum.Material.SmoothPlastic, Parent=parent }); b.CanQuery=false
			local roof = p({ Size=Vector3.new(8, 3, 20), Position=pos+Vector3.new(-side*3, h+1.5, 0), Color=accent, Material=Enum.Material.SmoothPlastic, Parent=parent }); roof.CanQuery=false
			local win = p({ Size=Vector3.new(0.5, 4, 4), Position=pos+Vector3.new(-side*0.2, h*0.5, 0), Color=Color3.fromRGB(255,235,170), Material=Enum.Material.Neon, Parent=parent }); win.CanQuery=false
		elseif style == "ruins" then
			-- broken pillars of varying height
			for k=-1,1 do
				local h = math.random(10, 24)
				local col = p({ Shape=Enum.PartType.Cylinder, Size=Vector3.new(h, 4, 4), Position=pos+Vector3.new(-side*2, h/2, k*5),
					Color=color, Material=Enum.Material.Slate, CFrame=CFrame.new(pos+Vector3.new(-side*2, h/2, k*5))*CFrame.Angles(0,0,math.pi/2), Parent=parent }); col.CanQuery=false
			end
		else -- fence
			local rail = origin + Vector3.new(x - side*1, 0, z)
			for _,hh in ipairs({2,4}) do
				local r=p({ Size=Vector3.new(0.5,0.5,length/n-2), Position=rail+Vector3.new(0,hh,0), Color=color, Material=Enum.Material.Wood, Parent=parent }); r.CanQuery=false
			end
			local post=p({ Size=Vector3.new(0.8,5,0.8), Position=rail+Vector3.new(0,2.5,0), Color=accent, Material=Enum.Material.Wood, Parent=parent }); post.CanQuery=false
		end
	end
	-- a tall invisible safety wall behind the structures so players can't slip through gaps into void
	local guard = p({ Size=Vector3.new(2,60,length), Position=origin+Vector3.new(side*(halfWidth+3),28,0), Color=color, Material=Enum.Material.SmoothPlastic, Transparency=1, Parent=parent }); guard.CanQuery=false
end

-- scenery visible THROUGH the gaps (themed backdrop silhouettes)
function Terrain.backdrop(origin, parent, side, halfWidth, length, color, prop)
	for i=1,3 do
		local z = -length/2 + i*(length/4)
		local pos = origin + Vector3.new(side*(halfWidth+25), 0, z)
		local sil = p({ Size=Vector3.new(8, math.random(20,45), 8), Position=pos+Vector3.new(0,15,0), Color=color:Lerp(Color3.new(0,0,0),0.3), Material=Enum.Material.SmoothPlastic, Parent=parent }); sil.CanQuery=false
	end
end

return Terrain
