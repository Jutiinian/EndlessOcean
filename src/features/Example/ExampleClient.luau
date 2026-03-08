-- || Services || --

-- || Dependencies || --

-- || Types || --
type Network = typeof(require(script.Parent.NetworkClient))

-- || Public API || --
local ExampleFeatureClient = {
	_network = (nil :: Network?) :: Network,
}

export type ExampleFeatureClient = typeof(ExampleFeatureClient)

function ExampleFeatureClient.Init(self: ExampleFeatureClient)
	self._network = require(script.Parent.NetworkClient)
end

return ExampleFeatureClient
