-- src/server/SystemSelfHealer.lua
-- Server-side watchdog: transient-failure recovery, error-spike detection, health sweeps.
local RunService        = game:GetService("RunService")
local ScriptContext     = game:GetService("ScriptContext")
local Stats             = game:GetService("Stats")
local DataStoreService  = game:GetService("DataStoreService")

local SystemSelfHealer = {}
SystemSelfHealer.__index = SystemSelfHealer

local DEFAULTS = {
	HeartbeatInterval = 30,   -- sec between health sweeps
	MemoryWarnMB      = 1500, -- server memory soft ceiling
	InstanceWarn      = 50000,-- descendant-count soft ceiling
	MaxRetries        = 4,    -- transient-op retry attempts
	BaseBackoff       = 0.5,  -- sec, exponential
	ErrorWindow       = 60,   -- rolling error-rate window (sec)
	ErrorSpike        = 10,   -- errors in window => alert
}

function SystemSelfHealer.new(config)
	local self = setmetatable({}, SystemSelfHealer)
	self.config    = setmetatable(config or {}, { __index = DEFAULTS })
	self.errors    = {}
	self.listeners = {}
	self.running   = false
	return self
end

-- Wrap any failure-prone call (DataStore/HTTP/etc). This is the actual "self-heal".
function SystemSelfHealer:Protect(label, fn, ...)
	local cfg, attempt, lastErr = self.config, 0, nil
	local packed = table.pack(...)
	while attempt < cfg.MaxRetries do
		local ok, res = pcall(function() return fn(table.unpack(packed, 1, packed.n)) end)
		if ok then return true, res end
		attempt += 1
		lastErr = res
		self:_record(("[%s] attempt %d failed: %s"):format(label, attempt, tostring(res)))
		task.wait(cfg.BaseBackoff * (2 ^ (attempt - 1)))
	end
	warn(("[SelfHealer] %s exhausted %d retries: %s"):format(label, cfg.MaxRetries, tostring(lastErr)))
	return false, lastErr
end

function SystemSelfHealer:_record(message, trace)
	table.insert(self.errors, { t = os.clock(), msg = message, trace = trace })
	local cutoff, recent = os.clock() - self.config.ErrorWindow, 0
	for i = #self.errors, 1, -1 do
		if self.errors[i].t < cutoff then table.remove(self.errors, i) else recent += 1 end
	end
	if recent >= self.config.ErrorSpike then
		self:_alert(("error spike: %d errors in %ds"):format(recent, self.config.ErrorWindow))
	end
end

function SystemSelfHealer:_alert(reason)
	warn("[SelfHealer][ALERT] " .. reason)
	for _, cb in ipairs(self.listeners) do task.spawn(cb, reason) end
end

function SystemSelfHealer:OnAlert(callback)
	table.insert(self.listeners, callback)
end

function SystemSelfHealer:_sweep()
	local cfg = self.config
	local memMB = Stats:GetTotalMemoryUsageMb()
	if memMB >= cfg.MemoryWarnMB then self:_alert(("memory high: %d MB"):format(math.floor(memMB))) end
	local count = #game:GetDescendants()
	if count >= cfg.InstanceWarn then self:_alert(("instance count high: %d"):format(count)) end
	-- datastore liveness probe (non-fatal; silently skipped in unpublished Studio)
	self:Protect("DataStoreProbe", function()
		local ok = pcall(function()
			DataStoreService:GetDataStore("__SelfHealerProbe"):UpdateAsync("ping", function(v) return (v or 0) + 1 end)
		end)
		if not ok then return end -- ignore in memory mode
	end)
end

function SystemSelfHealer:Start()
	if self.running then return end
	self.running = true
	self._errConn = ScriptContext.Error:Connect(function(message, trace) self:_record(message, trace) end)
	task.spawn(function()
		while self.running do
			local ok, err = pcall(function() self:_sweep() end)
			if not ok then warn("[SelfHealer] sweep error: " .. tostring(err)) end
			task.wait(self.config.HeartbeatInterval)
		end
	end)
	print("[SelfHealer] online")
end

function SystemSelfHealer:Stop()
	self.running = false
	if self._errConn then self._errConn:Disconnect() end
end

return SystemSelfHealer
