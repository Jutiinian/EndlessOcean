-- || Services || --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- || Dependencies || --
local React = require(ReplicatedStorage.Packages.react)
local React_Roblox = require(ReplicatedStorage.Packages["react-roblox"])

-- || Mount || --
return function(parent: Instance): () -> ()
    local interface = Instance.new("ScreenGui")
    interface.Name = `{script.Parent.Parent.Name}Interface`
    interface.IgnoreGuiInset = true
    interface.ResetOnSpawn = false
    interface.Parent = parent

    local interfaceRoot = React_Roblox.createRoot(interface)
    interfaceRoot:render(React.createElement(React.Fragment, nil, {

    }))

    return function()
        interfaceRoot:unmount()
        interface:Destroy()
    end
end
