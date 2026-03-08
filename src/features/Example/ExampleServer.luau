-- || Services || --

-- || Dependencies || --

-- || Types || --
type Network = typeof(require(script.Parent.NetworkServer))

-- || Public API || --
local ExampleFeatureServer = {
	_network = (nil :: Network?) :: Network,
}

export type ExampleFeatureServer = typeof(ExampleFeatureServer)

function ExampleFeatureServer.Init(self: ExampleFeatureServer)
	self._network = require(script.Parent.NetworkServer)
end

return ExampleFeatureServer
