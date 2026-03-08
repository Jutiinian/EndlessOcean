--!strict

-- || Variables || --
type ClockOptions = {
	showDays: boolean?,
	showHours: boolean?,
	showMinutes: boolean?,
	zeroPad: boolean?,
}

-- || Public API || --
local FormatUtil = {}

--[[
    Abbreviates a number into a human-readable format.
    - decimalPlaces: optional, defaults to 2.
]]
function FormatUtil.AbbreviateNumber(number: number, decimalPlaces: number?): string
	decimalPlaces = decimalPlaces or 2
	local absNumber = number >= 0 and number or -number
	local sign = number < 0 and "-" or ""
	local suffixes = require(script.Suffixes)

	for i = #suffixes, 1, -1 do
		local threshold = 10 ^ (i * 3)
		if absNumber >= threshold then
			local value = absNumber / threshold
			local formatted = ("%." .. decimalPlaces :: number .. "f"):format(value)
			formatted = formatted:gsub("%.?0+$", "")
			return sign .. formatted .. suffixes[i]
		end
	end

	local formatted = ("%." .. decimalPlaces :: number .. "f"):format(absNumber)
	formatted = formatted:gsub("%.?0+$", "")
	return sign .. formatted
end

--[[
    Converts seconds into a human-readable time string.
    - Returns days, hours, minutes, and seconds as needed.
]]
function FormatUtil.FormatTimeReadable(seconds: number): string
	local s = math.floor(seconds)
	local days = math.floor(s / 86400)
	s -= days * 86400
	local hours = math.floor(s / 3600)
	s -= hours * 3600
	local minutes = math.floor(s / 60)
	s -= minutes * 60

	local parts = {} :: { string }
	if days > 0 then
		parts[#parts + 1] = days .. "d"
	end
	if hours > 0 then
		parts[#parts + 1] = hours .. "h"
	end
	if minutes > 0 then
		parts[#parts + 1] = minutes .. "m"
	end
	if s > 0 or #parts == 0 then
		parts[#parts + 1] = s .. "s"
	end

	return table.concat(parts, " ")
end

--[[
    Converts seconds into a customizable clock-style string.
    - options:
        - showDays (boolean): whether to include days as hours > 24
        - showHours (boolean): whether to always show hours (otherwise hides if 0)
        - showMinutes (boolean): whether to always show minutes
        - zeroPad (boolean): pad numbers with leading zeros
]]
function FormatUtil.FormatTimeClock(seconds: number, options: ClockOptions?): string
	options = options or {} :: ClockOptions

	local zeroPad = (options :: ClockOptions).zeroPad ~= false -- default true

	local s = math.floor(seconds)
	local days = math.floor(s / 86400)
	s -= days * 86400
	local hours = math.floor(s / 3600)
	s -= hours * 3600
	local minutes = math.floor(s / 60)
	s -= minutes

	-- If showDays, add days to hours
	if (options :: ClockOptions).showDays then
		hours += days * 24
		days = 0
	end

	local timeParts: { string } = {}

	-- Days/hours
	if (options :: ClockOptions).showHours or hours > 0 then
		timeParts[#timeParts + 1] = if zeroPad then string.format("%02d", hours) else tostring(hours)
	end

	-- Minutes
	if (options :: ClockOptions).showMinutes or #timeParts > 0 then
		timeParts[#timeParts + 1] = if zeroPad then string.format("%02d", minutes) else tostring(minutes)
	end

	-- Seconds
	timeParts[#timeParts + 1] = if zeroPad then string.format("%02d", s) else tostring(s)

	return table.concat(timeParts, ":")
end

--[[
    Converts a decimal number to a percentage string.
    - decimalPlaces: optional, defaults to 2
]]
function FormatUtil.FormatPercent(decimal: number, decimalPlaces: number?): string
	decimalPlaces = decimalPlaces or 2
	local percent = decimal * 100
	local formatted = ("%." .. decimalPlaces :: number .. "f"):format(percent)
	formatted = formatted:gsub("%.?0+$", "")
	return formatted .. "%"
end

--[[
    Formats a number with commas as thousands separators.
    - Handles negative numbers and optional decimal parts.
    - Example: 1234567.89 → "1,234,567.89"
]]
function FormatUtil.AddCommasToNumber(num: number): string
	local formatted = tostring(num)

	local integer_part, decimal_part = formatted:match("^(%d+)(%.?%d*)$")

	while true do
		local new_integer_part, k = string.gsub(integer_part :: string, "(-?%d+)(%d%d%d)", "%1,%2")
		if k == 0 then
			break
		end
		integer_part = new_integer_part
	end

	if decimal_part then
		return (integer_part :: string) .. decimal_part
	else
		return integer_part :: string
	end
	--[[local formatted = tostring(num):reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return formatted:gsub("^,", "")]]
end

--[[
    Converts bytes into a human-readable format.
    - Supports B, KB, MB, GB, TB, PB.
    - decimalPlaces: optional, defaults to 2
]]
function FormatUtil.FormatBytes(bytes: number, decimalPlaces: number?): string
	decimalPlaces = decimalPlaces or 2
	local absBytes = bytes >= 0 and bytes or -bytes
	local sign = bytes < 0 and "-" or ""
	local suffixes = { "B", "KB", "MB", "GB", "TB", "PB" }
	local i = 1

	while absBytes >= 1024 and i < #suffixes do
		absBytes /= 1024
		i += 1
	end

	local formatted = ("%." .. decimalPlaces :: number .. "f"):format(absBytes)
	formatted = formatted:gsub("%.?0+$", "")
	return sign .. formatted .. " " .. suffixes[i]
end

return FormatUtil
