--!strict

-- || Servicies || --
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- || Dependencies || --
local OceanClient = require(ReplicatedStorage.Features.Ocean.OceanClient)

local CreateTween = require(ReplicatedStorage.Shared.Utils.CreateTween)

-- || Public API || --
local OceanCameraClient = {
	_camera = (nil :: any) :: Camera,
	_cameraUnderwater = false,

	_blurEffect = (nil :: any) :: BlurEffect,
	_colorCorrection = (nil :: any) :: ColorCorrectionEffect,
}

export type OceanCameraClient = typeof(OceanCameraClient)

function OceanCameraClient.Init(self: OceanCameraClient)
	local camera = workspace.CurrentCamera
	self._camera = camera

	local BlurEffect = Instance.new("BlurEffect")
	BlurEffect.Size = 0
	BlurEffect.Parent = camera
	self._blurEffect = BlurEffect

	local ColorCorrectionEffect = Instance.new("ColorCorrectionEffect")
	ColorCorrectionEffect.Parent = camera
	self._colorCorrection = ColorCorrectionEffect

	RunService.RenderStepped:Connect(function()
		self:_manageCameraUnderwater()
	end)
end

function OceanCameraClient._manageCameraUnderwater(self: OceanCameraClient)
	local cameraPosition = self._camera.CFrame.Position
	local waveHeight = OceanClient:GetHeight(cameraPosition)
	if cameraPosition.Y <= waveHeight and not self._cameraUnderwater then
		self._cameraUnderwater = true
		self:_applyUnderwaterFX(true)
	elseif cameraPosition.Y > waveHeight and self._cameraUnderwater then
		self._cameraUnderwater = false
		self:_applyUnderwaterFX(false)
	end
end

function OceanCameraClient._applyUnderwaterFX(self: OceanCameraClient, isUnderwater: boolean)
	local properties = if isUnderwater
		then {
			Blur = { Size = 9 },
			ColorCorrection = { TintColor = Color3.fromRGB(46, 128, 222), Contrast = 0, Saturation = 0.5 },
		}
		else {
			Blur = { Size = 0 },
			ColorCorrection = { TintColor = Color3.fromRGB(255, 255, 255), Contrast = 0, Saturation = 0 },
		}

	CreateTween(self._blurEffect, TweenInfo.new(0.25), properties.Blur):Play()
	CreateTween(self._colorCorrection, TweenInfo.new(0.25), properties.ColorCorrection):Play()
end

return OceanCameraClient
