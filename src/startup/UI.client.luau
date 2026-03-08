-- || Services || --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- || Variables || --
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")
local Features = ReplicatedStorage:WaitForChild("Features")

local MOUNT_MODULE_NAME = "mount"
local UI_FOLDER_NAME = "UI"
local WARN_ON_ERROR = true

-- || Private Functions || --
local function tryMountFeature(featureFolder: Instance): boolean
    local featureName = featureFolder.Name

    local uiFolder = featureFolder:FindFirstChild(UI_FOLDER_NAME)
    if not uiFolder then
        return false
    end

    local mountModule = uiFolder:FindFirstChild(MOUNT_MODULE_NAME)
    if not mountModule or not mountModule:IsA("ModuleScript") then
        return false
    end

    local success, result = pcall(function()
        local mount = require(mountModule)
        
        if type(mount) ~= "function" then
            error(`Mount module must return a function, got {type(mount)}`)
        end
        
        mount(PlayerGui)
    end)
    
    if not success then
        if WARN_ON_ERROR then
            warn(`Failed to mount feature '{featureName}': {result}`)
        end
        return false
    end
    
    return true
end

-- || Mounter || --
local mountedCount = 0
local totalFeatures = #Features:GetChildren()

for _, featureFolder in ipairs(Features:GetChildren()) do
    if not featureFolder:IsA("Folder") then
        continue
    end
    
    if tryMountFeature(featureFolder) then
        mountedCount += 1
    end
end

-- Optional: Log mount summary
if mountedCount > 0 then
    print(`Mounted {mountedCount}/{totalFeatures} UI features`)
end