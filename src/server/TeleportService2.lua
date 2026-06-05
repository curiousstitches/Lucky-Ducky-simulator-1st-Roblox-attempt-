-- src/server/TeleportService2.lua  | fast-travel within the single-place zone line.
-- Players can jump to any zone they've cleared (highestLevel). End-of-world auto-teleports to the
-- next world's first zone (+ a visible end portal). Named TeleportService2 to avoid the Roblox
-- service name collision.
local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ZoneConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ZoneConfig"))
local PlayerData = require(script.Parent.PlayerData)
local Remotes    = require(script.Parent.Remotes)
local RemoteGuard = require(script.Parent.RemoteGuard)

local TP = {}
local Notify
local ZoneBuilder

local function tp(player, pos)
	local p = PlayerData.Get(player); if p then p._tpGrace = os.clock() + 2 end
	local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if r then r.CFrame = CFrame.new(pos); r.AssemblyLinearVelocity = Vector3.zero end
end

-- menu data: which worlds/zones the player can fast-travel to (cleared zones only)
function TP.Menu(player)
	local p = PlayerData.Get(player); if not p then return {} end
	local highest = p.highestLevel or 1
	local worlds = {}
	for _, w in ipairs(ZoneConfig.Worlds) do
		local firstZone = (w.n-1)*10 + 1
		worlds[#worlds+1] = {
			n = w.n, name = w.name, firstZone = firstZone,
			unlocked = highest >= firstZone,   -- reached this world's start
		}
	end
	return { worlds = worlds, highest = highest }
end

-- jump to a specific zone (must be <= highest cleared)
function TP.Jump(player, zone)
	local p = PlayerData.Get(player); if not p then return { ok=false } end
	zone = math.clamp(tonumber(zone) or 1, 1, ZoneConfig.TotalZones)
	if zone > (p.highestLevel or 1) then return { ok=false, reason="You haven't reached Zone "..zone.." yet" } end
	ZoneBuilder = ZoneBuilder or require(script.Parent.ZoneBuilder)
	tp(player, ZoneBuilder.zoneCFrame(zone) + Vector3.new(0,8,0))
	if Notify then Notify:FireClient(player,{ text="🌀 Teleported to Zone "..zone.."!", color=Color3.fromRGB(150,210,255) }) end
	return { ok=true }
end

-- jump to a world's first zone
function TP.JumpWorld(player, worldN)
	local firstZone = (math.clamp(tonumber(worldN) or 1,1,10)-1)*10 + 1
	return TP.Jump(player, firstZone)
end

function TP.Start()
	Notify = Remotes.event("Notify")
	ZoneBuilder = require(script.Parent.ZoneBuilder)
	Remotes.func("GetTeleportMenu").OnServerInvoke = function(pl) return TP.Menu(pl) end
	RemoteGuard.func(Remotes.func("TeleportZone"),"tpz",4,6,function(pl,z) return TP.Jump(pl,z) end,{ok=false})
	RemoteGuard.func(Remotes.func("TeleportWorld"),"tpw",4,6,function(pl,w) return TP.JumpWorld(pl,w) end,{ok=false})

	-- END-OF-WORLD portals: at each world's last zone (10,20,...,90), a portal forward.
	-- When a player clears the last gate of a world they auto-advance; the visible portal also works.
	local function hookEndPortal(pt)
		if pt:IsA("BasePart") then
			pt.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit and hit.Parent); if not player then return end
				local nextZone = pt:GetAttribute("NextZone")
				local p = PlayerData.Get(player)
				if p and (p.highestLevel or 1) >= nextZone then
					TP.Jump(player, nextZone)
				elseif Notify then
					Notify:FireClient(player,{ text="🔒 Clear this world's final gate first!", color=Color3.fromRGB(255,170,80) })
				end
			end)
		end
	end
	for _, pt in ipairs(CollectionService:GetTagged("EndPortal")) do hookEndPortal(pt) end
	CollectionService:GetInstanceAddedSignal("EndPortal"):Connect(hookEndPortal)
end

return TP
