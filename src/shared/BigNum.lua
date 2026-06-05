-- src/shared/BigNum.lua  | safe handling + clean formatting for very large currency values.
-- Luau doubles stay exact to ~2^53 (~9e15); beyond that, display gets fuzzy. This module keeps
-- values as plain numbers (fast, simple) but formats them cleanly with suffixes well past 1e15,
-- and clamps to avoid inf/overflow. For a duck simulator this is the right balance of simple + safe.
local BigNum = {}

-- short-scale suffixes; extends far enough for extreme inflation
local SUFFIXES = {
	"", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No",
	"Dc", "UDc", "DDc", "TDc", "QaDc", "QiDc", "SxDc", "SpDc", "OcDc", "NoDc",
	"Vg", "UVg", "DVg", "TVg", "QaVg", "QiVg", "SxVg", "SpVg", "OcVg", "NoVg", "Tg",
}

local MAX = 1e300  -- hard clamp well below math.huge to prevent inf

-- clamp a value into a safe range (no inf, no NaN, no negative wallet)
function BigNum.safe(n)
	if type(n) ~= "number" or n ~= n then return 0 end -- NaN guard
	if n == math.huge then return MAX end
	if n < 0 then return 0 end
	return math.min(n, MAX)
end

-- format a number to a short suffix string: 1234 -> "1.23K", 5e9 -> "5B"
function BigNum.format(n)
	n = BigNum.safe(n)
	if n < 1000 then
		-- whole numbers show clean; small decimals trimmed
		return tostring(math.floor(n + 0.5))
	end
	local idx = math.floor(math.log(n, 1000))
	idx = math.clamp(idx, 1, #SUFFIXES - 1)
	local scaled = n / (1000 ^ idx)
	local suffix = SUFFIXES[idx + 1]
	-- beyond our suffix table, fall back to scientific notation
	if idx >= #SUFFIXES - 1 and n >= 1000 ^ (#SUFFIXES) then
		return string.format("%.2e", n)
	end
	-- 1-2 decimals depending on size, trimmed of trailing zeros
	local s = string.format("%.2f", scaled):gsub("%.?0+$", "")
	return s .. suffix
end

-- format with commas for mid-size numbers (optional alt display)
function BigNum.commas(n)
	n = math.floor(BigNum.safe(n))
	local s = tostring(n)
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return out
end

-- safe add/mul that never overflow
function BigNum.add(a, b) return BigNum.safe((a or 0) + (b or 0)) end
function BigNum.mul(a, b) return BigNum.safe((a or 0) * (b or 1)) end

return BigNum
