-- src/server/Decor.lua  | reusable 3D prop builders: trees, bushes, flowers, rocks, lamps,
-- fences, fountains, arches, benches, barrels, lily pads, banners. All anchored, mobile-conscious.
local Decor = {}

local function p(props)
	local part = Instance.new("Part"); part.Anchored = true; part.CanCollide = false
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth; part.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do part[k] = v end
	return part
end

-- a leafy tree: trunk + 2-3 stacked leaf balls
function Decor.tree(pos, parent, scale, leafColor)
	scale = scale or 1
	leafColor = leafColor or Color3.fromRGB(60, 150, 70)
	local model = Instance.new("Model"); model.Name = "Tree"; model.Parent = parent
	local trunk = p({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(7 * scale, 2.2 * scale, 2.2 * scale),
		Color = Color3.fromRGB(105, 70, 40), Material = Enum.Material.Wood,
		CFrame = CFrame.new(pos + Vector3.new(0, 3.5 * scale, 0)) * CFrame.Angles(0, 0, math.pi / 2), Parent = model })
	for i = 0, 2 do
		p({ Shape = Enum.PartType.Ball, Size = Vector3.new((8 - i * 1.6) * scale, (8 - i * 1.6) * scale, (8 - i * 1.6) * scale),
			Color = leafColor:Lerp(Color3.new(1, 1, 1), i * 0.08), Material = Enum.Material.Grass,
			Position = pos + Vector3.new(0, (7 + i * 2.6) * scale, 0), Parent = model })
	end
	return model
end

-- a round bush
function Decor.bush(pos, parent, color)
	return p({ Shape = Enum.PartType.Ball, Size = Vector3.new(4, 3, 4),
		Color = color or Color3.fromRGB(70, 140, 75), Material = Enum.Material.Grass,
		Position = pos + Vector3.new(0, 1.2, 0), Parent = parent })
end

-- a flower: stem + colored head
function Decor.flower(pos, parent, headColor)
	local model = Instance.new("Model"); model.Name = "Flower"; model.Parent = parent
	p({ Size = Vector3.new(0.3, 2, 0.3), Color = Color3.fromRGB(70, 160, 80), Material = Enum.Material.Grass,
		Position = pos + Vector3.new(0, 1, 0), Parent = model })
	p({ Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2),
		Color = headColor or Color3.fromRGB(255, 120, 180), Material = Enum.Material.Neon,
		Position = pos + Vector3.new(0, 2.2, 0), Parent = model })
	return model
end

-- a rock cluster
function Decor.rock(pos, parent, scale)
	scale = scale or 1
	return p({ Shape = Enum.PartType.Block, Size = Vector3.new(4 * scale, 3 * scale, 4.5 * scale),
		Color = Color3.fromRGB(120, 120, 130), Material = Enum.Material.Slate,
		CFrame = CFrame.new(pos + Vector3.new(0, 1.4 * scale, 0)) * CFrame.Angles(math.rad(math.random(-12, 12)), math.rad(math.random(0, 360)), math.rad(math.random(-12, 12))),
		Parent = parent })
end

-- a glowing lamp post
function Decor.lamp(pos, parent, glowColor)
	local model = Instance.new("Model"); model.Name = "Lamp"; model.Parent = parent
	p({ Size = Vector3.new(0.6, 10, 0.6), Color = Color3.fromRGB(40, 40, 48), Material = Enum.Material.Metal,
		Position = pos + Vector3.new(0, 5, 0), Parent = model })
	local bulb = p({ Shape = Enum.PartType.Ball, Size = Vector3.new(2, 2, 2),
		Color = glowColor or Color3.fromRGB(255, 240, 180), Material = Enum.Material.Neon,
		Position = pos + Vector3.new(0, 10, 0), Parent = model })
	local light = Instance.new("PointLight"); light.Color = glowColor or Color3.fromRGB(255, 240, 180)
	light.Range = 18; light.Brightness = 2; light.Parent = bulb
	return model
end

-- a fence segment
function Decor.fence(pos, parent, length, rot)
	local model = Instance.new("Model"); model.Name = "Fence"; model.Parent = parent
	length = length or 12
	local rail = CFrame.new(pos) * CFrame.Angles(0, math.rad(rot or 0), 0)
	for _, h in ipairs({ 1.6, 3.2 }) do
		p({ Size = Vector3.new(length, 0.4, 0.4), Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.Wood,
			CFrame = rail * CFrame.new(0, h, 0), Parent = model })
	end
	for off = -length / 2, length / 2, length / 3 do
		p({ Size = Vector3.new(0.5, 4, 0.5), Color = Color3.fromRGB(120, 85, 55), Material = Enum.Material.Wood,
			CFrame = rail * CFrame.new(off, 2, 0), Parent = model })
	end
	return model
end

-- a decorative fountain
function Decor.fountain(pos, parent)
	local model = Instance.new("Model"); model.Name = "Fountain"; model.Parent = parent
	p({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 14, 14), Color = Color3.fromRGB(140, 140, 150),
		Material = Enum.Material.Marble, CFrame = CFrame.new(pos + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.pi / 2), Parent = model })
	p({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.2, 10, 10), Color = Color3.fromRGB(90, 200, 230),
		Material = Enum.Material.Glass, Transparency = 0.25, CFrame = CFrame.new(pos + Vector3.new(0, 1.6, 0)) * CFrame.Angles(0, 0, math.pi / 2), Parent = model })
	local spout = p({ Size = Vector3.new(1.5, 6, 1.5), Color = Color3.fromRGB(140, 140, 150), Material = Enum.Material.Marble,
		Position = pos + Vector3.new(0, 4, 0), Parent = model })
	local emit = Instance.new("ParticleEmitter"); emit.Texture = "rbxassetid://243660364"
	emit.Rate = 30; emit.Lifetime = NumberRange.new(0.8, 1.4); emit.Speed = NumberRange.new(6, 9)
	emit.SpreadAngle = Vector2.new(20, 20); emit.Color = ColorSequence.new(Color3.fromRGB(150, 220, 255))
	emit.Acceleration = Vector3.new(0, -20, 0); emit.Parent = spout
	return model
end

-- a stone archway (gateway between rooms)
function Decor.arch(pos, parent, color, text)
	local model = Instance.new("Model"); model.Name = "Arch"; model.Parent = parent
	color = color or Color3.fromRGB(150, 150, 160)
	for _, dx in ipairs({ -7, 7 }) do
		p({ Size = Vector3.new(2.5, 16, 2.5), Color = color, Material = Enum.Material.Marble,
			Position = pos + Vector3.new(dx, 8, 0), Parent = model })
	end
	local top = p({ Size = Vector3.new(18, 3, 2.5), Color = color, Material = Enum.Material.Marble,
		Position = pos + Vector3.new(0, 17, 0), Parent = model })
	if text then
		local bb = Instance.new("BillboardGui"); bb.Size = UDim2.new(0, 240, 0, 44); bb.StudsOffset = Vector3.new(0, 3, 0)
		bb.AlwaysOnTop = true; bb.Parent = top
		local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1
		t.Font = Enum.Font.GothamBlack; t.TextScaled = true; t.TextStrokeTransparency = 0.3
		t.TextColor3 = Color3.fromRGB(255, 235, 150); t.Text = text; t.Parent = bb
	end
	return model
end

-- a wooden bench
function Decor.bench(pos, parent, rot)
	local model = Instance.new("Model"); model.Name = "Bench"; model.Parent = parent
	local base = CFrame.new(pos) * CFrame.Angles(0, math.rad(rot or 0), 0)
	p({ Size = Vector3.new(8, 0.5, 2.5), Color = Color3.fromRGB(150, 110, 70), Material = Enum.Material.Wood,
		CFrame = base * CFrame.new(0, 2, 0), Parent = model })
	p({ Size = Vector3.new(8, 2.5, 0.5), Color = Color3.fromRGB(130, 95, 60), Material = Enum.Material.Wood,
		CFrame = base * CFrame.new(0, 3.2, -1), Parent = model })
	return model
end

-- a barrel (decorative)
function Decor.barrel(pos, parent)
	return p({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, 3, 3), Color = Color3.fromRGB(120, 80, 45),
		Material = Enum.Material.Wood, CFrame = CFrame.new(pos + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.pi / 2), Parent = parent })
end

-- a lily pad (for ponds)
function Decor.lilypad(pos, parent)
	local model = Instance.new("Model"); model.Name = "Lily"; model.Parent = parent
	p({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 4, 4), Color = Color3.fromRGB(70, 160, 90),
		Material = Enum.Material.Grass, CFrame = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.pi / 2), Parent = model })
	if math.random() < 0.5 then
		p({ Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), Color = Color3.fromRGB(255, 150, 200),
			Material = Enum.Material.Neon, Position = pos + Vector3.new(0, 1, 0), Parent = model })
	end
	return model
end

-- a hanging banner on a pole
function Decor.banner(pos, parent, color, text)
	local model = Instance.new("Model"); model.Name = "Banner"; model.Parent = parent
	p({ Size = Vector3.new(0.5, 14, 0.5), Color = Color3.fromRGB(60, 50, 40), Material = Enum.Material.Wood,
		Position = pos + Vector3.new(0, 7, 0), Parent = model })
	local cloth = p({ Size = Vector3.new(6, 8, 0.3), Color = color or Color3.fromRGB(255, 200, 50),
		Material = Enum.Material.Fabric, Position = pos + Vector3.new(2.8, 9, 0), Parent = model })
	if text then
		local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.Parent = cloth
		local t = Instance.new("TextLabel"); t.Size = UDim2.fromScale(1, 1); t.BackgroundTransparency = 1
		t.Font = Enum.Font.GothamBlack; t.TextScaled = true; t.TextColor3 = Color3.fromRGB(60, 40, 20); t.Text = text; t.Parent = sg
	end
	return model
end

-- scatter helper: place N of a prop fn randomly within a radius ring around center
function Decor.scatter(center, parent, count, innerR, outerR, fn)
	for _ = 1, count do
		local ang = math.random() * math.pi * 2
		local r = innerR + math.random() * (outerR - innerR)
		fn(center + Vector3.new(math.cos(ang) * r, 0, math.sin(ang) * r), parent)
	end
end

-- ===== THEMED PROPS =====
function Decor.crystal(pos, parent, color)
	local m = Instance.new("Model"); m.Name="Crystal"; m.Parent=parent
	for i=1,3 do
		local h=4+math.random()*4
		p({ Size=Vector3.new(1.4,h,1.4), Color=color or Color3.fromRGB(140,200,255), Material=Enum.Material.Glass,
			Transparency=0.15, CFrame=CFrame.new(pos+Vector3.new(math.random(-2,2),h/2,math.random(-2,2)))*CFrame.Angles(math.rad(math.random(-15,15)),0,math.rad(math.random(-15,15))), Parent=m })
	end
	local lt=Instance.new("PointLight"); lt.Color=color or Color3.fromRGB(140,200,255); lt.Range=12; lt.Brightness=1.5; lt.Parent=m:GetChildren()[1]
	return m
end

function Decor.mushroom(pos, parent, capColor)
	local m=Instance.new("Model"); m.Name="Mushroom"; m.Parent=parent
	local s=0.7+math.random()*1.2
	p({ Size=Vector3.new(1.4*s,4*s,1.4*s), Color=Color3.fromRGB(235,225,200), Material=Enum.Material.SmoothPlastic, Position=pos+Vector3.new(0,2*s,0), Parent=m })
	p({ Shape=Enum.PartType.Ball, Size=Vector3.new(5*s,3.5*s,5*s), Color=capColor or Color3.fromRGB(230,70,80), Material=Enum.Material.SmoothPlastic, Position=pos+Vector3.new(0,4.4*s,0), Parent=m })
	return m
end

function Decor.coral(pos, parent, color)
	local m=Instance.new("Model"); m.Name="Coral"; m.Parent=parent
	local cols={Color3.fromRGB(255,120,150),Color3.fromRGB(255,170,80),Color3.fromRGB(150,120,255),Color3.fromRGB(80,220,200)}
	color=color or cols[math.random(1,#cols)]
	for i=1,4 do
		local h=3+math.random()*5
		p({ Size=Vector3.new(1,h,1), Color=color, Material=Enum.Material.Neon,
			CFrame=CFrame.new(pos+Vector3.new(math.random(-3,3),h/2,math.random(-3,3)))*CFrame.Angles(math.rad(math.random(-25,25)),0,math.rad(math.random(-25,25))), Parent=m })
	end
	return m
end

function Decor.cactus(pos, parent)
	local m=Instance.new("Model"); m.Name="Cactus"; m.Parent=parent
	local g=Color3.fromRGB(70,150,80)
	p({ Size=Vector3.new(2.5,8,2.5), Color=g, Material=Enum.Material.Grass, Position=pos+Vector3.new(0,4,0), Parent=m })
	p({ Size=Vector3.new(1.4,3,1.4), Color=g, Material=Enum.Material.Grass, Position=pos+Vector3.new(2,5,0), Parent=m })
	p({ Size=Vector3.new(1.4,3,1.4), Color=g, Material=Enum.Material.Grass, Position=pos+Vector3.new(-2,6,0), Parent=m })
	return m
end

function Decor.star(pos, parent, color)
	local b=p({ Shape=Enum.PartType.Ball, Size=Vector3.new(2.5,2.5,2.5), Color=color or Color3.fromRGB(255,240,150),
		Material=Enum.Material.Neon, Position=pos+Vector3.new(0,4+math.random()*6,0), Parent=parent })
	local lt=Instance.new("PointLight"); lt.Color=b.Color; lt.Range=10; lt.Brightness=2; lt.Parent=b
	return b
end

function Decor.candy(pos, parent)
	local m=Instance.new("Model"); m.Name="Candy"; m.Parent=parent
	local cols={Color3.fromRGB(255,90,160),Color3.fromRGB(120,200,255),Color3.fromRGB(255,210,70)}
	p({ Size=Vector3.new(1,9,1), Color=Color3.fromRGB(255,255,255), Material=Enum.Material.SmoothPlastic, Position=pos+Vector3.new(0,4.5,0), Parent=m })
	p({ Shape=Enum.PartType.Ball, Size=Vector3.new(4,4,4), Color=cols[math.random(1,#cols)], Material=Enum.Material.SmoothPlastic, Position=pos+Vector3.new(0,9,0), Parent=m })
	return m
end

function Decor.gear(pos, parent, color)
	return p({ Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.8,5,5), Color=color or Color3.fromRGB(120,130,140),
		Material=Enum.Material.Metal, CFrame=CFrame.new(pos+Vector3.new(0,3,0))*CFrame.Angles(0,0,math.pi/2), Parent=parent })
end

function Decor.bone(pos, parent)
	local m=Instance.new("Model"); m.Name="Bone"; m.Parent=parent
	p({ Size=Vector3.new(0.8,5,0.8), Color=Color3.fromRGB(235,228,210), Material=Enum.Material.SmoothPlastic,
		CFrame=CFrame.new(pos+Vector3.new(0,1,0))*CFrame.Angles(0,0,math.rad(70)), Parent=m })
	return m
end

-- dispatch by theme prop name
function Decor.themed(name, pos, parent, accent)
	if name=="crystal" then return Decor.crystal(pos,parent,accent)
	elseif name=="mushroom" then return Decor.mushroom(pos,parent)
	elseif name=="coral" then return Decor.coral(pos,parent)
	elseif name=="cactus" then return Decor.cactus(pos,parent)
	elseif name=="star" then return Decor.star(pos,parent,accent)
	elseif name=="candy" then return Decor.candy(pos,parent)
	elseif name=="gear" then return Decor.gear(pos,parent,accent)
	elseif name=="bone" then return Decor.bone(pos,parent)
	elseif name=="rock" then return Decor.rock(pos,parent,0.8+math.random())
	else return Decor.tree(pos,parent,0.8+math.random()*0.7) end
end

return Decor
