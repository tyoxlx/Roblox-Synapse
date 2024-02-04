local Common = require(script.Parent.Common)

--[=[
	@class Template

	A Template acts as a factory for Fragments from a given service. Templates act
	as middleware that can modify the incoming parameters when the service intends
	to create a Fragment.
]=]--
return function(params, service)
	-- just clones the template params and pushes it to the service if its nil
	local raw = table.clone(params)

	if not service.EnableTemplates then
		error(`service {service.Name} does not implement templates.`)
	end

	if service.Templates[params.Name] then
		error(`template {params.Name} already exists for service {service.Name}.`)
	end

	if not Common.DONT_ASSIGN_OBJECT_MT then
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