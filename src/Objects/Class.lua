local Common = require(script.Parent.Parent.Common)
local ERROR = require(script.Parent.Parent.Internal.Error)

local Metakeys= require(script.Parent.Parent.Types.Metakeys)
local ENABLE_CLASSES_METAKEY = Metakeys.export "EnableClasses"

return function(service, name, createObject)
	-- just clones the template params and pushes it to the service if its nil
	local params = {}
	params.Service = service
	params.Name = name
	params.CreateObject = createObject
	params[Common.ClassHeader] = true

	if not service[ENABLE_CLASSES_METAKEY] then
		ERROR.SERVICE_NO_CLASSES(service.Name)
	end
	
	if not Common.Flags.DONT_ASSIGN_OBJECT_MT then
		setmetatable(params, {
			__tostring = function(self)
				return `ServiceTemplate({self.Name})`
			end,
		})
	end

	table.freeze(params)

	if not Common.AnalysisMode then
		if service.ClassAdded then
			service:ClassAdded(params)
		end
	end

	return params
end