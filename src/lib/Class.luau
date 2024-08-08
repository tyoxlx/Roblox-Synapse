local Common = require("./Common")
local ERROR = require("./Error")
local Metakeys = require("../meta")
local ENABLE_CLASSES_METAKEY = Metakeys.export("EnableClasses")

return function(service, name, createObject)
	-- just clones the template params and pushes it to the service if its nil
	local params = {}
	params.Service = service
	params.Name = name
	params.CreateObject = createObject
	params[Common.ClassHeader] = true

	if not service[ENABLE_CLASSES_METAKEY] then ERROR.SERVICE_NO_CLASSES(service.Name) end

	if not Common.Flags.DONT_ASSIGN_OBJECT_MT then
		setmetatable(params, {
			__tostring = function(self) return `ServiceTemplate({self.Name})` end,
		})
	end

	table.freeze(params)
	return params
end
