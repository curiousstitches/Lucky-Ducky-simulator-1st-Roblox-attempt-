-- src/shared/DuckModelBuilder.lua  | assembles a 3D duck from its rolled parts (mobile-light, ~6 parts)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DuckSchema = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("DuckSchema"))

local DuckModelBuilder = {}

local SHIMMER_MATERIAL = {
	Matte = Enum.Material.SmoothPlastic, Glossy = Enum.Material.Plastic,
	Metallic = Enum.Material.Metal, Holographic = Enum.Material.Glass,
	Prismatic = Enum.Material.Neon, Galaxy = Enum.Material.Neon,
	["Liquid Chrome"] = Enum.Material.Metal,
}

local BODY_SCALE = {
	Classic = Vector3.new(2, 2, 2.6), Chonk = Vector3.new(2.8, 2.4, 3),
	Tiny = Vector3.new(1.2, 1.2, 1.6), Tall = Vector3.new(1.8, 3, 2.2),
	Slime = Vector3.new(2.4, 1.6, 2.8), Crystal = Vector3.new(2, 2.4, 2.4),
	Mecha = Vector3.new(2.2, 2.2, 2.8), Ghost = Vector3.new(2, 2.2, 2.6),
	["Golden Idol"] = Vector3.new(2.2, 2.6, 2.6),
}

local function makePart(name, size, color, material, parent)
	local p = Instance.new("Part")
	p.Name = name; p.Size = size; p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true; p.CanCollide = false; p.CanQuery = false; p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function weld(a, b, offset)
	b.CFrame = a.CFrame * offset
	local w = Instance.new("WeldConstraint"); w.Part0 = a; w.Part1 = b; w.Parent = a
end

-- duck: { rarity, parts = {Body,Head,Face,Color,Shimmer,Particle}, shiny }
function DuckModelBuilder.build(duck)
	local model = Instance.new("Model"); model.Name = "DuckModel"
	local colorOpt = DuckSchema.findOption("Color", duck.parts.Color)
	local color = (colorOpt and colorOpt.hex) or Color3.fromRGB(255, 221, 51)
	local material = SHIMMER_MATERIAL[duck.parts.Shimmer] or Enum.Material.SmoothPlastic
	local scale = BODY_SCALE[duck.parts.Body] or BODY_SCALE.Classic

	-- body (chunky + rounded, PS99 style — slightly squashed sphere)
	local body = makePart("Body", scale, color, material, model)
	body.Shape = Enum.PartType.Ball
	body.Size = Vector3.new(scale.X * 1.15, scale.Y * 1.05, scale.Z * 1.15)
	model.PrimaryPart = body

	-- big rounded head
	local head = makePart("Head", Vector3.new(scale.X * 0.78, scale.Y * 0.78, scale.Z * 0.78), color, material, model)
	head.Shape = Enum.PartType.Ball
	weld(body, head, CFrame.new(0, scale.Y * 0.5, -scale.Z * 0.32))

	-- chunky beak
	local beak = makePart("Beak", Vector3.new(0.7, 0.45, 1.0), Color3.fromRGB(255, 150, 0), Enum.Material.SmoothPlastic, model)
	weld(head, beak, CFrame.new(0, -0.05, -head.Size.Z * 0.55))

	-- BIG cute dot eyes (white base + black pupil + tiny shine) — the PS99 cuteness
	if duck.parts.Face == "Cool Shades" then
		local bar = makePart("Shades", Vector3.new(head.Size.X * 0.85, 0.3, 0.25), Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, model)
		weld(head, bar, CFrame.new(0, head.Size.Y * 0.12, -head.Size.Z * 0.5))
	else
		for _, dx in ipairs({ -0.34, 0.34 }) do
			local white = makePart("EyeW", Vector3.new(0.42, 0.42, 0.3), Color3.fromRGB(255,255,255), Enum.Material.SmoothPlastic, model)
			white.Shape = Enum.PartType.Ball
			weld(head, white, CFrame.new(dx * head.Size.X, head.Size.Y * 0.15, -head.Size.Z * 0.46))
			local pupil = makePart("Eye", Vector3.new(0.24, 0.24, 0.24), Color3.fromRGB(20, 20, 25), Enum.Material.SmoothPlastic, model)
			pupil.Shape = Enum.PartType.Ball
			weld(head, pupil, CFrame.new(dx * head.Size.X, head.Size.Y * 0.15, -head.Size.Z * 0.54))
			local shine = makePart("Shine", Vector3.new(0.1,0.1,0.1), Color3.fromRGB(255,255,255), Enum.Material.Neon, model)
			shine.Shape = Enum.PartType.Ball
			weld(head, shine, CFrame.new(dx * head.Size.X + 0.06, head.Size.Y * 0.2, -head.Size.Z * 0.58))
		end
	end

	-- head attachment
	local hp = duck.parts.Head
	if hp and hp ~= "None" then
		local hatColor = (hp == "Crown" or hp == "Halo") and Color3.fromRGB(255, 215, 40)
			or (hp == "Jeep Roof Rack") and Color3.fromRGB(40, 40, 40)
			or Color3.fromRGB(90, 70, 50)
		local hatMat = (hp == "Crown" or hp == "Halo") and Enum.Material.Neon or Enum.Material.SmoothPlastic
		local hat = makePart("Hat", Vector3.new(head.Size.X * 0.9, 0.5, head.Size.Z * 0.9), hatColor, hatMat, model)
		weld(head, hat, CFrame.new(0, head.Size.Y * 0.55, 0))
	end

	-- glow / particle
	local part = duck.parts.Particle
	if (part and part ~= "None") or duck.shiny then
		local light = Instance.new("PointLight")
		light.Color = duck.shiny and Color3.fromRGB(255, 255, 200) or color
		light.Range = 8; light.Brightness = duck.shiny and 2 or 1; light.Parent = body
		local emit = Instance.new("ParticleEmitter")
		emit.Texture = "rbxassetid://243660364" -- soft sparkle (built-in)
		emit.Rate = duck.shiny and 18 or 8
		emit.Lifetime = NumberRange.new(0.6, 1.1)
		emit.Speed = NumberRange.new(0.5, 1.5)
		emit.Size = NumberSequence.new(0.4)
		emit.Color = ColorSequence.new(duck.shiny and Color3.fromRGB(255, 255, 200) or color)
		emit.Parent = body
	end

	return model
end

return DuckModelBuilder
