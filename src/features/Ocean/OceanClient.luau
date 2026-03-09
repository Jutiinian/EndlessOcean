--!strict

-- || Services || --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- || Dependencies || --
local Janitor = require(ReplicatedStorage.Packages.janitor)

local Bones = require(script.Parent.Bones)
local Planes = require(script.Parent.Planes)

-- || Types || --

-- || Public API || --
local OceanClient = {
	_janitor = (nil :: any) :: Janitor.Janitor,

	_planes = (nil :: any) :: Planes.Planes,
	_bones = (nil :: any) :: Bones.Bones,
}

export type OceanClient = typeof(OceanClient)

function OceanClient.Init(self: OceanClient)
	local camera = workspace.CurrentCamera

	self._janitor = Janitor.new()

	self._bones = Bones.new(camera)
	self._planes = Planes.new(camera, self._bones, self._janitor)

	self._janitor:Add(
		RunService.RenderStepped:Connect(function()
			self:_onUpdate(workspace:GetServerTimeNow())
		end),
		"Disconnect"
	)
end

function OceanClient.GetHeight(self: OceanClient, position: Vector3): number
	return self._bones:GetHeight(position)
end

function OceanClient.Cleanup(self: OceanClient)
	self._janitor:Destroy()
end

function OceanClient._onUpdate(self: OceanClient, sampleTime: number)
	self._bones:Update(sampleTime)
	self._planes:Update()
end

return OceanClient
