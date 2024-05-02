-- This module mostly exists for typing, as catwork's logic is defined implicitly
-- as the default Service behaviour

local Service = require(script.Parent.Parent.Objects.Service)

local native = Service {
	Name = "catwork",
}

return function(params)
	return native:Fragment(params)
end