--!strict

-- || Services || --

-- || Dependencies || --
local Configurations = require(script.Parent.Configurations)
local SinCosLookUp = require(script.Parent.SinCosLookUp)

-- || Variables || --
local GRAVITY = 9.81

local RESCAN_ANGLE_THRESHOLD = math.rad(4) -- trigger rescan after ~4° of rotation
local RESCAN_MOVE_THRESHOLD = 4 -- trigger rescan after 4 studs of movement

local SCREEN_MARGIN = 0.20 -- 20% beyond each screen edge

-- || Types || --
type BakedWave = {
	k: number, -- wave-number: k = 2π / WaveLength
	omega: number, -- angular frequency: ω = sqrt(g·k) × WaveSpeed
	dX: number, -- normalised direction X
	dZ: number, -- normalised direction Z  (Direction.Y → world Z)
	A: number, -- amplitude
	curl: number, -- horizontal displacement scale = clamp(Steepness,0,1) × A
}

-- || Private Functions || --

-- || Public API || --
local Bones = {}
Bones.__index = Bones

export type Bones = typeof(setmetatable(
	{} :: {
		_camera: Camera,
		_frame: number,
		_time: number,

		_allBones: { Bone }, -- every registered bone
		_detected: { Bone }, -- bones within max render range (timer-gated)
		_inRange: { [Bone]: number }, -- bone → LOD level (timer-gated)

		_lastScanCFrame: CFrame?,
		_lastRangeScan: number,
		_lastVisibilityScan: number,

		_heightScale: Vector3,
		_bakedWaves: { BakedWave },
	},
	Bones
))

function Bones.new(camera: Camera): Bones
	local self = setmetatable({}, Bones)

	self._camera = camera
	self._frame = 0
	self._time = 0

	self._allBones = {}
	self._detected = {}
	self._inRange = {}

	self._lastScanCFrame = nil :: CFrame?
	self._lastRangeScan = -math.huge
	self._lastVisibilityScan = -math.huge

	self._heightScale = Vector3.new(1, Configurations.WaveHeightMultiplier, 1)

	-- Pre-bake all wave constants so _evaluateWaves only does arithmetic
	local baked = {}

	for _, wave in Configurations.WaveData do
		local k = (2 * math.pi) / wave.WaveLength
		local d = wave.Direction.Unit
		baked[#baked + 1] = {
			k = k,
			omega = math.sqrt(GRAVITY * k) * Configurations.WaveSpeed,
			dX = d.X,
			dZ = d.Y, -- maps to world Z axis
			A = wave.Amplitude,
			curl = math.clamp(wave.Steepness, 0, 1) * wave.Amplitude,
		}
	end

	self._bakedWaves = baked

	return self
end

function Bones.Register(self: Bones, bone: Bone)
	self._allBones[#self._allBones + 1] = bone
end

function Bones.GetHeight(self: Bones, position: Vector3): number
	-- TODO: Implement later
	return Configurations.SeaLevel
end

function Bones.Update(self: Bones, time: number)
	self._time = time
	self._frame += 1

	self:_scanRange()
	self:_updateVisibility()
	self:_updateTransforms()
end

-- Sum all Gerstner waves at a world XZ position and return XYZ displacement.
function Bones._evaluateWaves(self: Bones, position: Vector3): Vector3
	local t = self._time
	local tx, ty, tz = 0, 0, 0

	for _, w in self._bakedWaves do
		local phase = w.k * (w.dX * position.X + w.dZ * position.Z) - w.omega * t
		local cosP = SinCosLookUp.fastCos(phase)
		local sinP = SinCosLookUp.fastSin(phase)

		tx += w.dX * w.curl * cosP -- horizontal X curl
		ty += w.A * sinP -- vertical Y [-A, +A]
		tz += w.dZ * w.curl * cosP -- horizontal Z curl
	end

	return Vector3.new(tx, ty, tz)
end

-- Find all bones within BoneCloseRange of the camera.
function Bones._scanRange(self: Bones)
	-- Full bone list is only iterated occasionally
	if self._time < self._lastRangeScan + Configurations.BoneRangeScanRate then
		return
	end

	local camPos = self._camera.CFrame.Position
	local maxRange = Configurations.BoneCloseRange
	local detected = self._detected
	table.clear(detected)

	for _, bone in self._allBones do
		if (bone.WorldPosition - camPos).Magnitude <= maxRange then
			detected[#detected + 1] = bone
		end
	end

	self._lastRangeScan = self._time
end

function Bones._updateVisibility(self: Bones)
	local camCFrame = self._camera.CFrame
	local camPos = camCFrame.Position

	-- Detect significant camera changes since the last scan
	local forceScan = false
	local lastCam = self._lastScanCFrame
	if lastCam then
		local angleDelta = math.acos(math.clamp(camCFrame.LookVector:Dot(lastCam.LookVector), -1, 1))
		local moveDelta = (camPos - lastCam.Position).Magnitude
		forceScan = angleDelta >= RESCAN_ANGLE_THRESHOLD or moveDelta >= RESCAN_MOVE_THRESHOLD
	else
		forceScan = true -- scan on first run
	end

	-- viewport checks and distance math run occasionally, not every frame
	if not forceScan and self._time < self._lastVisibilityScan + Configurations.BoneVisibilityScanRate then
		return
	end

	local gfxSettings = UserSettings().GameSettings.SavedQualityLevel.Value
	--local camPos = self._camera.CFrame.Position
	local closeRange = Configurations.BoneCloseRange
	local midRange = Configurations.BoneMidRange
	-- Higher graphics quality extends render distance, lower quality shrinks it
	local qualMult = 0.5 + gfxSettings * 0.5

	local inRange = self._inRange
	table.clear(inRange)

	local lo = -SCREEN_MARGIN
	local hi = 1 + SCREEN_MARGIN

	for _, bone in self._detected do
		-- skip bones not visible in the viewport and not within margin
		local viewportPoint, onScreen = self._camera:WorldToViewportPoint(bone.WorldPosition)

		if not onScreen then
			local vpSize = self._camera.ViewportSize

			if viewportPoint.Z <= 0 then
				continue
			end

			local nx = viewportPoint.X / vpSize.X
			local ny = viewportPoint.Y / vpSize.Y

			if nx < lo or nx > hi or ny < lo or ny > hi then
				continue
			end
		end

		local dist = (bone.WorldPosition - camPos).Magnitude

		if dist <= closeRange * qualMult then
			-- every frame at high quality, every 3rd at low quality
			inRange[bone] = (gfxSettings >= 7) and 1 or 3
		elseif gfxSettings > 3 and dist <= midRange * qualMult then
			-- every 8th frame
			inRange[bone] = 8
		end
	end

	self._lastScanCFrame = camCFrame
	self._lastVisibilityScan = self._time
end

-- Apply wave displacement to every visible bone, gated by each bone's LOD level.
function Bones._updateTransforms(self: Bones)
	local frame = self._frame
	local heightScale = self._heightScale

	for bone, lod in self._inRange do
		-- Only update on frames that align with this bone's LOD interval
		if frame % lod == 0 then
			local disp = self:_evaluateWaves(bone.WorldPosition)
			bone.Transform = CFrame.new(disp * heightScale)
		end
	end
end

return Bones
