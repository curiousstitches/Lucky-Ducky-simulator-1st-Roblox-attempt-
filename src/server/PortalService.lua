-- src/server/PortalService.lua  | world portals (teleport to World 1; others locked) + AFK passive earn.
local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local PlayerData       = require(script.Parent.PlayerData)
local CurrencyService  = require(script.Parent.CurrencyService)
local Remotes          = require(script.Parent.Remotes)

local PortalService = {}
local Notify
local debounce = {}

local function tp(player, pos)
	local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if r then r.CFrame = CFrame.new(pos) end
end

local function onPortal(portal, hit)
	local player = Players:GetPlayerFromCharacter(hit and hit.Parent); if not player then return end
	local key = player.UserId.."_portal"; if debounce[key] then return end
	debounce[key]=true; task.delay(1.5,function() debounce[key]=nil end)
	local idx = portal:GetAttribute("WorldIndex")
	if not portal:GetAttribute("Unlocked") then
		if Notify then Notify:FireClient(player,{ text="🔒 World "..idx.." is coming soon!", color=Color3.fromRGB(255,180,80) }) end
		return
	end
	if idx == 1 then
		local ZoneBuilder = require(script.Parent.ZoneBuilder)
		tp(player, ZoneBuilder.zoneCFrame(1) + Vector3.new(0,8,0))
		if Notify then Notify:FireClient(player,{ text="🌍 Welcome to Grassland Odyssey!", color=Color3.fromRGB(120,230,140) }) end
	end
end

function PortalService.Start()
	Notify = Remotes.event("Notify")
	local function hook(pt) if pt:IsA("BasePart") then pt.Touched:Connect(function(h) onPortal(pt,h) end) end end
	for _,pt in ipairs(CollectionService:GetTagged("WorldPortal")) do hook(pt) end
	CollectionService:GetInstanceAddedSignal("WorldPortal"):Connect(hook)

	-- AFK zone: passive Duck Droppings while standing on an AFKZone pad
	task.spawn(function()
		while true do
			task.wait(3)
			for _,pad in ipairs(CollectionService:GetTagged("AFKZone")) do
				if pad:IsA("BasePart") then
					for _,player in ipairs(Players:GetPlayers()) do
						local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
						if r and math.abs(r.Position.X-pad.Position.X)<10 and math.abs(r.Position.Z-pad.Position.Z)<10 then
							local p = PlayerData.Get(player)
							CurrencyService.Add(player, "DuckDroppings", 50 + math.floor((p and p.highestLevel or 1)*5))
						end
					end
				end
			end
		end
	end)
end

return PortalService
