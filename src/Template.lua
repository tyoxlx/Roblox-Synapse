local Common = require(script.Parent.Common)
local ERROR = require(script.Parent.Error)

local TEMPLATE_PARAMS = {
	Name = "string",
	CreateFragment = "function",
}

return function(params, service)
	-- just clones the template params and pushes it to the service if its nil
	local raw = Common.validateTable(params, "Template", TEMPLATE_PARAMS)
	raw[Common.TemplateHeader] = true

	if not service.EnableTemplates then
		ERROR.SERVICE_NO_TEMPLATES(service)
	end

	if service.Templates[params.Name] then
		ERROR.SERVICE_DUPLICATE_TEMPLATE(params.Name)
	end
	
	raw.Service = service

	if not Common.Flags.DONT_ASSIGN_OBJECT_MT then
		setmetatable(raw, {
			__tostring = function(self)
				return `ServiceTemplate({self.Name})`
			end,
		})
	end

	table.freeze(raw)
	service.Templates[params.Name] = raw

	if service.TemplateAdded then
		service:TemplateAdded(raw)
	end

	Common._eTemplateAdded:Fire(raw)
	return raw
end