-- src/server/Bootstrap.server.lua  | boots every server system in order
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players           = game:GetService("Players")
local Workspace         = game:GetService("Workspace")

local Shared        = ReplicatedStorage:WaitForChild("Shared")
local DuckGenerator = require(Shared.DuckGenerator)

local PlayerData          = require(script.Parent.PlayerData)
local CurrencyService     = require(script.Parent.CurrencyService)
local InventoryService    = require(script.Parent.InventoryService)
local MonetizationService = require(script.Parent.MonetizationService)
local ProgressionService  = require(script.Parent.ProgressionService)
local RebirthService      = require(script.Parent.RebirthService)
local DispenserService    = require(script.Parent.DispenserService)
local IdlerService        = require(script.Parent.IdlerService)
local ForgeService        = require(script.Parent.ForgeService)
local JeepService         = require(script.Parent.JeepService)
local TradeService        = require(script.Parent.TradeService)
local SeasonService       = require(script.Parent.SeasonService)
local EventService        = require(script.Parent.EventService)
local EngagementService   = require(script.Parent.EngagementService)
local CodesService        = require(script.Parent.CodesService)
local LeaderboardService  = require(script.Parent.LeaderboardService)
local FarmService         = require(script.Parent.FarmService)
local WorldBuilder        = require(script.Parent.WorldBuilder)
local LevelBuilder        = require(script.Parent.LevelBuilder)
local LobbyMachines       = require(script.Parent.LobbyMachines)
local MachineService      = require(script.Parent.MachineService)
local ZoneBuilder         = require(script.Parent.ZoneBuilder)
local HatcherService      = require(script.Parent.HatcherService)
local DexService          = require(script.Parent.DexService)
local PowerupService      = require(script.Parent.PowerupService)
local MinigameService     = require(script.Parent.MinigameService)
local VoidProtection      = require(script.Parent.VoidProtection)
local TeleportService2    = require(script.Parent.TeleportService2)
local SeasonsFX           = require(script.Parent.SeasonsFX)
local LaunchPolish        = require(script.Parent.LaunchPolish)
local SkyLobby            = require(script.Parent.SkyLobby)
local PortalService       = require(script.Parent.PortalService)
local HubBuilder          = require(script.Parent.HubBuilder)
local EggService          = require(script.Parent.EggService)
local GateService         = require(script.Parent.GateService)
local AbilityService      = require(script.Parent.AbilityService)
local GiftService         = require(script.Parent.GiftService)
local EnemyEventService   = require(script.Parent.EnemyEventService)
local ModeService         = require(script.Parent.ModeService)
local IndexService        = require(script.Parent.IndexService)
local SpinService         = require(script.Parent.SpinService)
local ClanService         = require(script.Parent.ClanService)
local DuckLevelService    = require(script.Parent.DuckLevelService)
local AchievementService  = require(script.Parent.AchievementService)
local CosmeticService     = require(script.Parent.CosmeticService)
local FishingService      = require(script.Parent.FishingService)
local BossService         = require(script.Parent.BossService)
local QoLService          = require(script.Parent.QoLService)
local LaunchService       = require(script.Parent.LaunchService)
local SystemSelfHealer    = require(script.Parent.SystemSelfHealer)

-- 1) watchdog online first
SystemSelfHealer.new():Start()

-- remove Studio's default Baseplate/SpawnLocation so the sky world isn't sitting on a grid
pcall(function()
	for _, n in ipairs({ "Baseplate", "SpawnLocation" }) do
		local b = Workspace:FindFirstChild(n)
		if b then b:Destroy() end
	end
end)

-- enable built-in streaming so 100 zones stay smooth on mobile (auto loads/unloads distant parts)
pcall(function()
	Workspace.StreamingEnabled = true
	Workspace.StreamingMinRadius = 256
	Workspace.StreamingTargetRadius = 512
end)

-- 2) build the world AFTER services start, wrapped so a build hiccup can't block remotes
local function safeBuild(name, fn)
	local ok, err = pcall(fn)
	if not ok then warn("[Build] "..name.." failed: "..tostring(err)) end
end
local function safeStart(name, fn)
	local ok, err = pcall(fn)
	if not ok then warn("[Start] "..name.." failed: "..tostring(err)) end
end

-- 3) data + services
safeStart("PlayerData", PlayerData.Start)
safeStart("CurrencyService", CurrencyService.Start)
safeStart("InventoryService", InventoryService.Start)
safeStart("MonetizationService", MonetizationService.Start)
safeStart("ProgressionService", ProgressionService.Start)
safeStart("RebirthService", RebirthService.Start)
safeStart("DispenserService", DispenserService.Start)
safeStart("IdlerService", IdlerService.Start)
safeStart("ForgeService", ForgeService.Start)
safeStart("JeepService", JeepService.Start)
safeStart("TradeService", TradeService.Start)
safeStart("EventService", EventService.Start)
safeStart("SeasonService", SeasonService.Start)
safeStart("EngagementService", EngagementService.Start)
safeStart("CodesService", CodesService.Start)
safeStart("LeaderboardService", LeaderboardService.Start)
safeStart("EggService", EggService.Start)
safeStart("GateService", GateService.Start)
safeStart("AbilityService", AbilityService.Start)
safeStart("GiftService", GiftService.Start)
safeStart("EnemyEventService", EnemyEventService.Start)
safeStart("ModeService", ModeService.Start)
safeStart("IndexService", IndexService.Start)
safeStart("SpinService", SpinService.Start)
safeStart("ClanService", ClanService.Start)
safeStart("DuckLevelService", DuckLevelService.Start)
safeStart("AchievementService", AchievementService.Start)
safeStart("CosmeticService", CosmeticService.Start)
safeStart("FishingService", FishingService.Start)
safeStart("BossService", BossService.Start)
safeStart("QoLService", QoLService.Start)
safeStart("MachineService", MachineService.Start)
-- World1Service/World1Builder replaced by ZoneBuilder; no longer started.
safeStart("HatcherService", HatcherService.Start)
safeStart("DexService", DexService.Start)
safeStart("PowerupService", PowerupService.Start)
safeStart("MinigameService", MinigameService.Start)
safeStart("VoidProtection", VoidProtection.Start)
safeStart("TeleportService2", TeleportService2.Start)
safeStart("SeasonsFX", SeasonsFX.Start)
safeStart("LaunchPolish", LaunchPolish.Start)
safeStart("PortalService", PortalService.Start)
safeStart("LaunchService", LaunchService.Start)

-- now build the world (services already created their remotes, so clients won't infinite-yield)
safeBuild("SkyLobby", SkyLobby.Build)
safeBuild("Zones", ZoneBuilder.Build)

-- 4) spawn-hook: free starter duck the first time a player joins
local function ensureStarter(player)
	local profile = PlayerData.Get(player)
	if not profile then return end
	-- ducks now come from the one-time starter wheel (LaunchUI). No auto-grant here.
	CurrencyService.PushBalance(player)
	InventoryService.Push(player)
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(function()
		local tries = 0
		while not PlayerData.Get(player) and tries < 50 do task.wait(0.1); tries += 1 end
		ensureStarter(player)
	end)
end)
for _, p in ipairs(Players:GetPlayers()) do task.spawn(ensureStarter, p) end

-- 5) core farm loop
safeStart("FarmService", FarmService.Start)

print("[Jeepers-Get-DUCKED] server online")
