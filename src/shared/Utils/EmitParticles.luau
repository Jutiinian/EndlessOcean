--!strict

-- || Public API || --
--[[
    Emits particles from one or more ParticleEmitters
    - Accepts:
        - A single ParticleEmitter
        - Any Instance (searches descendants for ParticleEmitters)
        - A list of ParticleEmitters
    - Respects EmitDelay (delay before emission)
    - Respects EmitCount (number of particles to emit)
]]
local function EmitParticles(particles: Instance | { ParticleEmitter })
	local emitters = {} :: { ParticleEmitter }

	if typeof(particles) == "Instance" then
		if particles:IsA("ParticleEmitter") then
			table.insert(emitters, particles)
		else
			for _, obj in ipairs(particles:GetDescendants()) do
				if obj:IsA("ParticleEmitter") then
					table.insert(emitters, obj)
				end
			end
		end
	else
		emitters = particles
	end

	for _, emitter in ipairs(emitters) do
		local delayTime = emitter:GetAttribute("EmitDelay") or 0
		local emitCount = emitter:GetAttribute("EmitCount") or 15

		task.delay(delayTime :: number, function()
			emitter:Emit(emitCount :: number)
		end)
	end
end

return EmitParticles
