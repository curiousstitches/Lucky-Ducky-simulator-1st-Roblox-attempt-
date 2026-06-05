-- src/server/RemoteGuard.lua  | token-bucket rate limiting per player+key, to blunt remote spam
local Players = game:GetService("Players")
local RemoteGuard = {}

local buckets = {} -- [userId] = { [key] = { tokens, last } }

Players.PlayerRemoving:Connect(function(p) buckets[p.UserId] = nil end)

-- returns true if allowed, false if the player is over budget for this key
-- rate = refills/sec, burst = max stored
function RemoteGuard.check(player, key, rate, burst)
	rate = rate or 5; burst = burst or 5
	local now = os.clock()
	local b = buckets[player.UserId]; if not b then b = {}; buckets[player.UserId] = b end
	local s = b[key]
	if not s then s = { tokens = burst, last = now }; b[key] = s end
	s.tokens = math.min(burst, s.tokens + (now - s.last) * rate)
	s.last = now
	if s.tokens >= 1 then s.tokens -= 1; return true end
	return false
end

-- wrap a RemoteEvent handler with rate limiting
function RemoteGuard.event(remote, key, rate, burst, handler)
	remote.OnServerEvent:Connect(function(player, ...)
		if RemoteGuard.check(player, key, rate, burst) then handler(player, ...) end
	end)
end

-- wrap a RemoteFunction handler; returns onReject value when throttled
function RemoteGuard.func(remote, key, rate, burst, handler, onReject)
	remote.OnServerInvoke = function(player, ...)
		if RemoteGuard.check(player, key, rate, burst) then return handler(player, ...) end
		return onReject
	end
end

return RemoteGuard
