-- || Services || --
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- || Dependencies || --
local Charm = require(ReplicatedStorage.Packages.charm)

-- || States/Atoms
local visible = Charm.atom(false)

-- || Actions
local actions = {}

return {
    visible = visible,
    actions = actions,
}