--!strict

-- || Services || --
local TweenService = game:GetService("TweenService")

-- || Public API || --
--[[
    Creates a Tween for the given instance with the specified TweenInfo and properties.
    - Automatically destroys the tween once it completes to prevent memory leaks,
      since tweens do not clean themselves up by default.
    - Returns the Tween instance so it can be played or manipulated before completion.
]]
local function CreateTween(instance: Instance, tweenInfo: TweenInfo, properties: { [string]: any }): Tween
	local tween = TweenService:Create(instance, tweenInfo, properties)

	tween.Completed:Once(function()
		tween:Destroy()
	end)

	return tween
end

return CreateTween
