local Common = require(script.Parent.Parent.Common)
local ERROR = require(script.Parent.Parent.Internal.Error)


return function(service, sPrivate, name, createObject)
	-- just clones the template params and pushes it to the service if its nil
	local params = {}
	params.Name = name
	params.CreateClass = createObject
	params[Common.ClassHeader] = true

	if not sPrivate.EnableTemplates then
		ERROR.SERVICE_NO_TEMPLATES(service)
	end

	if sPrivate.Templates[name] then
		ERROR.SERVICE_DUPLICATE_TEMPLATE(name)
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
		sPrivate.Templates[name] = params
		if service.TemplateAdded then
			service:TemplateAdded(params)
		end
	end

	return params
end