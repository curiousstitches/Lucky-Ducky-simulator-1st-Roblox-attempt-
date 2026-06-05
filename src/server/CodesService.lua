-- src/server/CodesService.lua  | redeemable promo codes (edit CODES to add more)
local PlayerData      = require(script.Parent.PlayerData)
local CurrencyService = require(script.Parent.CurrencyService)
local Remotes         = require(script.Parent.Remotes)

local CodesService = {}
local Notify

local CODES = {
	WELCOME      = { currency = "ShimmerSplats", amount = 25 },
	QUACK        = { currency = "DuckDroppings", amount = 1000 },
	DUCKDUCKJEEP = { currency = "ShimmerSplats", amount = 50 },
	SHIMMER      = { currency = "ShimmerSplats", amount = 15 },
	GETDUCKED    = { currency = "DuckDroppings", amount = 5000 },
	LAUNCH       = { currency = "ShimmerSplats", amount = 100 },
	TIKTOK       = { currency = "DuckDroppings", amount = 2500 },
	DISCORD      = { currency = "ShimmerSplats", amount = 30 },
	RUBBERDUCKY  = { currency = "DuckDroppings", amount = 7500 },
	HARDCORE     = { currency = "ShimmerSplats", amount = 60 },
}

function CodesService.Start()
	Notify = Remotes.event("Notify")
	local redeem = Remotes.func("RedeemCode")
	redeem.OnServerInvoke = function(player, raw)
		local p = PlayerData.Get(player); if not p then return { ok = false, reason = "loading" } end
		if type(raw) ~= "string" then return { ok = false, reason = "bad code" } end
		local code = string.upper((raw:gsub("%s+", "")))
		local reward = CODES[code]
		if not reward then
			if Notify then Notify:FireClient(player, { text = "❌ Invalid code", color = Color3.fromRGB(255, 90, 90) }) end
			return { ok = false, reason = "Invalid code" }
		end
		p.redeemedCodes = p.redeemedCodes or {}
		if p.redeemedCodes[code] then
			if Notify then Notify:FireClient(player, { text = "⚠️ Code already redeemed", color = Color3.fromRGB(255, 150, 0) }) end
			return { ok = false, reason = "Already redeemed" }
		end
		p.redeemedCodes[code] = true
		CurrencyService.Add(player, reward.currency, reward.amount)
		if Notify then Notify:FireClient(player, {
			text = ("🎟️ Code redeemed! +%d %s"):format(reward.amount, reward.currency),
			color = Color3.fromRGB(80, 230, 120) }) end
		return { ok = true }
	end
end

return CodesService
