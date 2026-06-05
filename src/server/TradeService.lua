-- src/server/TradeService.lua  | same-server trading: invite -> add -> both lock -> atomic swap
-- Security model: server is the only authority. Ownership is re-validated at execution, both
-- inventories are frozen mid-trade, and both profiles are force-saved immediately after the swap.
-- NOTE: same-server only by design (no cross-server dupe surface). ProfileStore session-locking
-- is the recommended production upgrade before high-volume trading.
local Players          = game:GetService("Players")
local PlayerData       = require(script.Parent.PlayerData)
local InventoryService = require(script.Parent.InventoryService)
local Remotes          = require(script.Parent.Remotes)
local RemoteGuard      = require(script.Parent.RemoteGuard)

local TradeService = {}
local MAX_OFFER = 12

-- one active trade per pair. sessions keyed by a stable id "lowId-highId"
local sessions = {}      -- [sid] = { a, b, offer={[uid]={ids}}, locked={[uid]=bool} }
local playerSid = {}     -- [userId] = sid
local TradeEvent

local function sidFor(u1, u2)
	local a, b = math.min(u1, u2), math.max(u1, u2)
	return a .. "-" .. b
end

local function busy(userId) return playerSid[userId] ~= nil end

local function push(session)
	for _, uid in ipairs({ session.a, session.b }) do
		local p = Players:GetPlayerByUserId(uid)
		if p and TradeEvent then
			local other = (uid == session.a) and session.b or session.a
			TradeEvent:FireClient(p, "update", {
				yourOffer = session.offer[uid], theirOffer = session.offer[other],
				youLocked = session.locked[uid] or false, theyLocked = session.locked[other] or false,
				otherName = (Players:GetPlayerByUserId(other) and Players:GetPlayerByUserId(other).Name) or "?",
			})
		end
	end
end

local function endTrade(sid, reason)
	local s = sessions[sid]; if not s then return end
	for _, uid in ipairs({ s.a, s.b }) do
		playerSid[uid] = nil
		local p = Players:GetPlayerByUserId(uid)
		if p and TradeEvent then TradeEvent:FireClient(p, "closed", { reason = reason or "Trade closed" }) end
	end
	sessions[sid] = nil
end

local function owns(profile, id)
	for _, d in ipairs(profile.ducks) do if d.id == id then return d end end
end

local function execute(s)
	local pa = Players:GetPlayerByUserId(s.a)
	local pb = Players:GetPlayerByUserId(s.b)
	if not (pa and pb) then return endTrade(sidFor(s.a, s.b), "A player left") end
	local profA, profB = PlayerData.Get(pa), PlayerData.Get(pb)
	if not (profA and profB) then return endTrade(sidFor(s.a, s.b), "Data not ready") end

	-- re-validate ownership of every offered duck RIGHT NOW (anti-dupe)
	local moveA, moveB = {}, {}
	for _, id in ipairs(s.offer[s.a] or {}) do
		local d = owns(profA, id); if not d then return endTrade(sidFor(s.a, s.b), "Ownership changed") end
		table.insert(moveA, d)
	end
	for _, id in ipairs(s.offer[s.b] or {}) do
		local d = owns(profB, id); if not d then return endTrade(sidFor(s.a, s.b), "Ownership changed") end
		table.insert(moveB, d)
	end

	local setA = {}; for _, d in ipairs(moveA) do setA[d.id] = true end
	local setB = {}; for _, d in ipairs(moveB) do setB[d.id] = true end
	InventoryService.RemoveDucks(pa, setA)
	InventoryService.RemoveDucks(pb, setB)
	for _, d in ipairs(moveA) do InventoryService.AddDuck(pb, d) end
	for _, d in ipairs(moveB) do InventoryService.AddDuck(pa, d) end

	-- persist immediately so a crash can't rewind the swap
	PlayerData.ForceSave(pa); PlayerData.ForceSave(pb)
	endTrade(sidFor(s.a, s.b), "✅ Trade complete!")
end

local function handle(player, action, arg)
	local uid = player.UserId
	if action == "invite" then
		local target = Players:GetPlayerByUserId(tonumber(arg) or 0)
		if not target or target == player then return end
		if busy(uid) or busy(target.UserId) then
			TradeEvent:FireClient(player, "closed", { reason = "Someone's already trading" }); return
		end
		local sid = sidFor(uid, target.UserId)
		sessions[sid] = { a = uid, b = target.UserId, offer = { [uid] = {}, [target.UserId] = {} }, locked = {} }
		playerSid[uid] = sid; playerSid[target.UserId] = sid
		push(sessions[sid])
		return
	end

	local sid = playerSid[uid]; local s = sid and sessions[sid]; if not s then return end

	if action == "offer" then
		if type(arg) ~= "table" then return end
		local profile = PlayerData.Get(player); if not profile then return end
		local clean, seen = {}, {}
		for _, id in ipairs(arg) do
			if type(id) == "string" and not seen[id] and owns(profile, id) then
				seen[id] = true; table.insert(clean, id)
				if #clean >= MAX_OFFER then break end
			end
		end
		s.offer[uid] = clean
		s.locked = {} -- any change unlocks both, so nobody gets rugged
		push(s)
	elseif action == "lock" then
		s.locked[uid] = true; push(s)
		if s.locked[s.a] and s.locked[s.b] then execute(s) end
	elseif action == "unlock" then
		s.locked[uid] = nil; push(s)
	elseif action == "cancel" then
		endTrade(sid, "Trade cancelled")
	end
end

function TradeService.Start()
	TradeEvent = Remotes.event("Trade")
	RemoteGuard.event(TradeEvent, "trade", 8, 12, handle)
	Players.PlayerRemoving:Connect(function(player)
		local sid = playerSid[player.UserId]
		if sid then endTrade(sid, "Other player left") end
	end)
end

return TradeService
