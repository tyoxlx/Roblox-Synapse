-- This module mostly exists for typing, as catwork's logic is defined implicitly
-- as the default Service behaviour

local Service = require(script.Parent.Service)
local Common = require(script.Parent.Common)
local ERROR = require(script.Parent.Error)

Service.native {
	Name = "catwork",
}

-- This 
return function(params)
	local native = Common.NativeService

	if not native then
		ERROR.INTERNAL("No native service for construction")
	end

	return native:Fragment(params)
end