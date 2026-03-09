--!strict
-- || Services || --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- || Dependencies || --
local Janitor = require(ReplicatedStorage.Packages.janitor)

local Bones = require(script.Parent.Bones)
local Configurations = require(script.Parent.Configurations)

-- || Private Functions || --

-- Snaps a world coordinate to the closest tile index
local function worldToTile(value: number, tileSize: number): number
	return math.floor(value / tileSize + 0.5)
end

local function tileKey(gx: number, gz: number): string
	return gx .. "," .. gz
end

-- || Variables || --
local PlaneMesh = ReplicatedStorage.Assets:WaitForChild("WaterPlane") :: MeshPart

-- || Public API || --
local Planes = {}
Planes.__index = Planes

export type Planes = typeof(setmetatable(
	{} :: {
		_tileSize: number,

		_offsets: { [number]: { dx: number, dz: number } },
		_requiredList: { [number]: { gx: number, gz: number } },

		_camera: Camera,
		_bones: Bones.Bones,
		_janitor: Janitor.Janitor,

		_active: { [string]: MeshPart },
		_pool: { MeshPart },
		_required: { [string]: { gx: number, gz: number } },
		_lastTileX: number?,
		_lastTileZ: number?,
	},
	Planes
))

function Planes.new(camera: Camera, bones: Bones.Bones, janitor: Janitor.Janitor): Planes
	local self = setmetatable({}, Planes)

	self._tileSize = Configurations.BoneSpacing * (Configurations.BoneGridSize - 1)

	self._camera = camera
	self._bones = bones
	self._janitor = janitor

	self._active = {}
	self._pool = {}
	self._required = {}

	-- Precompute offsets since grid size never changes at run-time
	-- (prevent recomputing same offsets every frame)
	local offsets = {}
	local half = math.floor(Configurations.PlaneGridSize / 2)
	for dx = -half, half - 1 do
		for dz = -half, half - 1 do
			offsets[#offsets + 1] = { dx = dx, dz = dz }
		end
	end
	self._offsets = offsets

	-- Pre-allocate required tile-tables since number of tiles also never change at run-time
	-- (prevent new table on every frame)
	local required = {}
	for _, _ in self._offsets do
		required[#required + 1] = { gx = 0, gz = 0 }
	end
	self._requiredList = required

	return self
end

function Planes.Update(self: Planes)
	self:_updateRequired()

	-- Return out-of-range planes to the pool.
	for id, plane in self._active do
		if not self._required[id] then
			plane.Parent = nil -- remove from scene graph while pooled
			self._active[id] = nil
			self._pool[#self._pool + 1] = plane
		end
	end

	-- Spawn or recycle any tiles that are required but don't exist yet.
	for id, tile in self._required do
		if not self._active[id] then
			self:_spawnOrRecycle(tile.gx, tile.gz, id)
		end
	end
end

function Planes._updateRequired(self: Planes)
	-- Convert the camera's world position to tile-grid coordinates
	local camPos = self._camera.CFrame.Position
	local camTileX = worldToTile(camPos.X, self._tileSize)
	local camTileZ = worldToTile(camPos.Z, self._tileSize)

	-- Skip rebuild if camera has not crossed into new tile
	if self._lastTileX == camTileX and self._lastTileZ == camTileZ then
		return
	end

	table.clear(self._required)

	for i, offset in self._offsets do
		local gx = camTileX + offset.dx
		local gz = camTileZ + offset.dz
		local tile = self._requiredList[i]
		tile.gx = gx
		tile.gz = gz
		self._required[tileKey(gx, gz)] = tile
	end

	-- Cache current tile to detect movement next frame
	self._lastTileX = camTileX
	self._lastTileZ = camTileZ
end

function Planes._spawnOrRecycle(self: Planes, gx: number, gz: number, id: string)
	local cf = CFrame.new(gx * self._tileSize, Configurations.SeaLevel, gz * self._tileSize)
	local plane: MeshPart

	if #self._pool > 0 then
		plane = table.remove(self._pool) :: MeshPart
		plane.Parent = self._camera
		plane.CFrame = cf
	else
		plane = PlaneMesh:Clone()
		plane.Size = Vector3.new(self._tileSize, 0, self._tileSize)
		plane.CFrame = cf
		plane.Parent = self._camera

		-- Layout and register all bones on this new tile.
		local bones: { Bone } = {}
		for _, child in plane:GetChildren() do
			if child:IsA("Bone") then
				bones[#bones + 1] = child :: Bone
			end
		end

		self:_modifyBoneLayout(bones)

		for _, bone in bones do
			self._bones:Register(bone)
		end

		self._janitor:Add(plane, "Destroy")
	end

	plane.Name = id
	self._active[id] = plane
end

function Planes._modifyBoneLayout(_self: Planes, bones: { Bone })
	local spacing = Configurations.BoneSpacing

	-- Have to rely on position instead since bones are not spatially ordered (not numbered left to right and top to bottom)
	table.sort(bones, function(a, b)
		--return (tonumber(a.Name) or 0) < (tonumber(b.Name) or 0)
		return a.Position.Z < b.Position.Z or (a.Position.Z == b.Position.Z and a.Position.X < b.Position.X)
	end)

	-- Get column count from total bone count
	local columns = math.ceil(math.sqrt(#bones))

	-- Assign each bone a grid position in local space.
	-- i - 1 converts from 1-based Lua index to 0-based grid index.
	for i, bone in ipairs(bones) do
		local col = (i - 1) % columns
		local row = math.floor((i - 1) / columns)
		bone.Position = Vector3.new(col * spacing, 0, row * spacing)
	end
end

return Planes
