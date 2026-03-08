--!strict

-- || Types || --
export type WaveDescriptor = {
	WaveLength: number, -- Distance between crests in studs
	Amplitude: number, -- Half-height in studs — max Y per wave = Amplitude
	Steepness: number, -- Crest sharpness [0, 1] — only affects horizontal curl, never height
	Direction: Vector2, -- Travel direction (does not need to be normalised)
}

export type Configuration = {
	-- World
	SeaLevel: number,
	WaveSpeed: number, -- 1 = physically correct deep-water speed
	WaveHeightMultiplier: number, -- Extra Y scale applied after wave summation

	-- Bone grid
	BoneSpacing: number, -- Studs between adjacent bones
	BoneGridSize: number, -- Number of bones per tile edge (e.g. 9 = 9×9 = 81 bones)

	-- Plane grid
	PlaneGridSize: number, -- N×N tile footprint around the camera

	-- Bone render culling
	BoneCloseRange: number, -- Studs — LOD 1/3 zone
	BoneMidRange: number, -- Studs — LOD 8 zone
	BoneRangeScanRate: number, -- Seconds between full bone list scans
	BoneVisibilityScanRate: number, -- Seconds between LOD assignment updates

	-- Waves
	WaveData: { WaveDescriptor },
}

-- || Module || --
local Configurations: Configuration = {

	-- World
	SeaLevel = 16,
	WaveSpeed = 1.0,
	WaveHeightMultiplier = 1.0,

	-- Bone grid
	BoneSpacing = 65,
	BoneGridSize = 9, -- 9×9 = 81 bones per tile

	-- Plane grid
	PlaneGridSize = 12, -- 12×12 = 144 tiles around the camera

	-- Bone render culling
	BoneCloseRange = 350,
	BoneMidRange = 700,
	BoneRangeScanRate = 1.0,
	BoneVisibilityScanRate = 1.0,

	--[[
		Each wave contributes at most ±Amplitude studs of vertical displacement.
		Steepness [0, 1] only controls how peaked/curled the crest is — it does
		not affect height. Adjust Amplitude values to change the height budget.
	]]
	--[[WaveData = {

		{ WaveLength = 260, Amplitude = 2.0, Steepness = 0.50, Direction = Vector2.new(1.00, -0.40) },

		{ WaveLength = 180, Amplitude = 1.5, Steepness = 0.40, Direction = Vector2.new(0.95, -0.45) },

		{ WaveLength = 110, Amplitude = 2.0, Steepness = 0.30, Direction = Vector2.new(1.05, -0.35) },

		{ WaveLength = 140, Amplitude = 1.8, Steepness = 0.35, Direction = Vector2.new(1.00, -0.50) },

		{ WaveLength = 60, Amplitude = 1.2, Steepness = 0.20, Direction = Vector2.new(0.90, -0.40) },

		{ WaveLength = 340, Amplitude = 1.5, Steepness = 0.45, Direction = Vector2.new(1.00, -0.38) },
	},]]

	WaveData = {
		-- Primary ocean swell — dominant storm direction, long and tall
		{ WaveLength = 420, Amplitude = 6.0, Steepness = 0.65, Direction = Vector2.new(1.00, -0.20) },

		-- Secondary swell — slightly cross-wind, creates interference peaks
		{ WaveLength = 300, Amplitude = 4.5, Steepness = 0.60, Direction = Vector2.new(0.80, -0.55) },

		-- Cross swell — opposing angle, responsible for choppy "colliding" look
		{ WaveLength = 250, Amplitude = 3.5, Steepness = 0.55, Direction = Vector2.new(-0.30, -1.00) },

		-- Mid-frequency chop — adds body between large swells
		{ WaveLength = 160, Amplitude = 2.8, Steepness = 0.50, Direction = Vector2.new(1.10, -0.40) },

		-- Wind chop — short and steep, the surface "texture" of a storm
		{ WaveLength = 80, Amplitude = 1.8, Steepness = 0.45, Direction = Vector2.new(0.75, -0.65) },

		-- Counter-chop — slight opposing direction breaks up visual repetition
		{ WaveLength = 65, Amplitude = 1.4, Steepness = 0.40, Direction = Vector2.new(-0.60, -0.80) },

		-- Fine surface turbulence — high frequency noise feel
		{ WaveLength = 35, Amplitude = 0.9, Steepness = 0.35, Direction = Vector2.new(1.20, -0.30) },

		-- Residual chop — fills in the micro-detail between everything else
		{ WaveLength = 22, Amplitude = 0.5, Steepness = 0.30, Direction = Vector2.new(0.50, -1.10) },
	},
}

return Configurations
