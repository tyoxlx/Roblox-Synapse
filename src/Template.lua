local Common = require(script.Parent.Common)
local ERROR = require(script.Parent.Error)


return function(service, name, createFragment)
	-- just clones the template params and pushes it to the service if its nil
	local private = Common.getPrivate(service)
	local params = {}
	params.Name = name
	params.CreateFragment = createFragment
	params[Common.TemplateHeader] = true

	if not private.EnableTemplates then
		ERROR.SERVICE_NO_TEMPLATES(service)
	end

	if private.Templates[name] then
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
	private.Templates[name] = params

	if service.TemplateAdded then
		service:TemplateAdded(params)
	end

	Common._eTemplateAdded:Fire(params)
	return params
end