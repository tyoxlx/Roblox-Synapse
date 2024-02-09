-- This module mostly exists for typing, as catwork's logic is defined implicitly
-- as the default Service behaviour

local Service = require(script.Parent.Service)
local Common = require(script.Parent.Common)

Service.native {
	Name = "catwork",
}

-- This 
return function(params)
	local native = Common.NativeService

	if not native then
		error("No native service for construction. This is likely an internal error. Please report it")
	end

	return native:Fragment(params)
end