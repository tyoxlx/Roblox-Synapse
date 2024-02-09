local Common = require(script.Parent.Common)
local ERROR = require(script.Parent.Error)

local TEMPLATE_PARAMS = {
	Name = "string",
	CreateFragment = "function",
}

--[=[
	@class Template

	A Template acts as a factory for Fragments from a given service. Templates act
	as middleware that can modify the incoming parameters when the service intends
	to create a Fragment.
]=]--
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

	if not Common.Flags.DONT_ASSIGN_OBJECT_MT then
		setmetatable(params, {
			__tostring = function(self)
				return `ServiceTemplate({self.Name})`
			end,
		})
	end

	--[=[
		@prop Name string
		@within Template
		
		A unique identifier for the Template
	]=]--

	--[=[
		@method CreateFragment
		@within Template
		@param params {[string]: any} -- Incoming properties for Fragment creation
		
		Defines the callback that acts as middleware when constructing a Fragment.
	]=]--

	service.Templates[params.Name] = raw

	if service.TemplateAdded then
		service:TemplateAdded(raw)
	end

	return raw
end