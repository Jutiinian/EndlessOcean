--!strict

-- || Variables || --
local clock = os.clock

-- || Public API || --
--[[
    Returns a throttled version of the given function.
    - Ensures the function cannot be called more often than once every `seconds`.
    - If called again before the cooldown finishes, it will wait until the time has passed.
    - Only the most recent call made during the cooldown is executed; earlier calls are discarded.
]]
local function Throttle<F>(func: F, seconds: number): F
	local lastCalled = 0
	local callNumber = 0

	return (
		function(...: any): any
			callNumber += 1
			local currentCallNumber = callNumber

			if clock() - lastCalled < seconds then
				task.wait(seconds - (clock() - lastCalled))

				if callNumber ~= currentCallNumber then
					return
				end
			end

			lastCalled = clock()
			return (func :: any)(...)
		end
	) :: any
end

return Throttle
