-- src/client/ThemeAtmosphere.client.lua  | as you walk the zone line, smoothly shifts the sky color,
-- atmosphere, lighting brightness/mood, and ambient sound to match the current world's theme.
local Players   = game:GetService("Players")
local Lighting  = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local ZoneConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ZoneConfig"))
local ZONE_LEN = ZoneConfig.ZoneLength
local LOBBY_Y = 250

-- ensure a Sky + Atmosphere + ColorCorrection exist to drive
local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
sky.Parent = Lighting
local atmos = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atmos.Parent = Lighting
local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
cc.Parent = Lighting

-- ambient sound (single looping sound we retarget per world)
local ambient = Instance.new("Sound")
ambient.Name = "ThemeAmbient"; ambient.Looped = true; ambient.Volume = 0.3; ambient.Parent = SoundService

local currentWorld = -1

local function applyWorld(wn)
	if wn == currentWorld then return end
	currentWorld = wn
	local art = ZoneConfig.Art[wn]; if not art then return end
	-- sky tint via clouds/atmosphere color (real skybox images can be dropped onto `sky` later)
	atmos.Color = art.sky[1]
	atmos.Decay = art.sky[2]
	atmos.Density = (art.mood=="dark" or art.mood=="murky") and 0.42 or 0.3
	atmos.Haze = art.mood=="dark" and 2.4 or 1.2
	-- brightness + mood color grade
	TweenService:Create(Lighting, TweenInfo.new(1.5), { Brightness = art.bright, OutdoorAmbient = art.sky[1] }):Play()
	local tint = (art.mood=="dark") and Color3.fromRGB(180,180,210)
		or (art.mood=="murky") and Color3.fromRGB(210,215,190)
		or (art.mood=="dim") and Color3.fromRGB(210,205,215)
		or Color3.fromRGB(255,255,255)
	TweenService:Create(cc, TweenInfo.new(1.5), { TintColor = tint, Brightness = (art.mood=="dark" and -0.05 or 0.03) }):Play()
	-- ambient sound swap
	if art.sound and ambient.SoundId ~= art.sound then
		ambient.SoundId = art.sound
		pcall(function() ambient:Play() end)
	end
end

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	acc += dt; if acc < 0.4 then return end; acc = 0
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	-- only theme when actually in the zone line (built at lobby Y, Z>0); else default lobby sky
	if math.abs(root.Position.Y - LOBBY_Y) < 60 and root.Position.Z > 60 then
		local zone = math.clamp(math.floor(root.Position.Z / ZONE_LEN) + 1, 1, ZoneConfig.TotalZones)
		applyWorld(math.clamp(math.floor((zone-1)/10)+1, 1, 10))
	else
		-- lobby: bright neutral sky
		if currentWorld ~= 0 then
			currentWorld = 0
			atmos.Color = Color3.fromRGB(220,230,245); atmos.Density = 0.28; atmos.Haze = 1
			TweenService:Create(Lighting, TweenInfo.new(1.5), { Brightness = 2.4 }):Play()
			TweenService:Create(cc, TweenInfo.new(1.5), { TintColor = Color3.fromRGB(255,255,255), Brightness = 0.03 }):Play()
		end
	end
end)
