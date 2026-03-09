-- || Services || --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- || Dependencies || --
local OceanCameraClient = require(ReplicatedStorage.Features.OceanCamera.OceanCameraClient)
local OceanClient = require(ReplicatedStorage.Features.Ocean.OceanClient)

-- || Initializer || --
OceanClient:Init()
OceanCameraClient:Init()
