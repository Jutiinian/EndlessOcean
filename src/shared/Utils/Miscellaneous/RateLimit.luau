--!strict

-- || Variables || --
local taskDelay = task.delay

-- || Public API || --
--[[
    Creates a simple rate-limiter closure.
    - Returns a function that enforces a maximum number of allowed calls within a time interval
    - If a key is provided, rate-limit is tracked per unique Key
        - Useful for per-player, per-instance, or per-action limits
    - If no Key is provided, a single shared counter is used (global limiting)
]]
local function RateLimit<T>(limit: number, interval: number)
	assert(limit > 0, "Limit must be greater than 0")

	local countMap = {} :: { [T]: number }
	local countKeyless = 0

	return function(key: T?)
		if key then
			local count = countMap[key]

			if count == nil then
				count = 0

				taskDelay(interval, function()
					countMap[key] = nil
				end)
			end

			if count == limit then
				return false
			end

			countMap[key] = count + 1
		else
			if countKeyless == 0 then
				taskDelay(interval, function()
					countKeyless = 0
				end)
			end

			if countKeyless == limit then
				return false
			end

			countKeyless = countKeyless + 1
		end

		return true
	end
end

return RateLimit
