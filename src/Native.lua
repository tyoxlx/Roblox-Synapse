-- This module mostly exists for typing, as catwork's logic is defined implicitly
-- as the default Service behaviour

local Types = require(script.Parent.Types)
local Service = require(script.Parent.Service)

export type NativeFragment = Types.Fragment<{}>
type NativeService = Types.ClassicService<NativeFragment, {[string]: any}> --TODO: NativeServiceParams

local native: NativeService = Service.classicService {
	Name = "catwork",
}

-- Catwork.Fragment
return function(params)
	return native:Fragment(params)
end