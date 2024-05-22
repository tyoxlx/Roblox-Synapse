local Template = require(script.Parent.Template)
local Dispatcher = require(script.Parent.Parent.Internal.Dispatcher)
local Fragment = require(script.Parent.Fragment)
local Common = require(script.Parent.Parent.Common)
local ERROR = require(script.Parent.Parent.Internal.Error)
local REFLECTION = require(script.Parent.Parent.Types.Reflection)

local SERVICE_PARAMS = {
	Name = "string",
	
	Spawning = "function?",
	CreateFragment = "function?",
	FragmentAdded = "function?",
	FragmentRemoved = "function?",
	TemplateAdded = "function?"
}

local function SERVICE_REFLECTION_TEST(service, fName)
	return service and service[Common.ServiceHeader], "BAD_SELF_CALL", fName
end

local function TEMPLATE_REFLECTION_ASSERT(template, fName, idx)
	-- string|Template
	local oType = typeof(template)
	return template and template[Common.TemplateHeader], "BAD_OBJECT", idx, fName, oType, "Template"
end

local ServicePrivate = Common.private(function(a)
	return {
		Templates = {},
		EnableTemplates = false
	}
end)

local function createFragmentForService(params, service)
	local f = Fragment(params, service)

	if not Common.AnalysisMode then
		Dispatcher.initFragmentState(f)
		local fragAdded = service.FragmentAdded
		if fragAdded then task.spawn(fragAdded, service, f) end
	end

	return f
end

-- Constructor
return function(params)
	local enableTemplates = (params.TemplateAdded ~= nil) or params.EnableTemplates

	local raw = Common.validateTable(params, "Service", SERVICE_PARAMS)	
	raw[Common.ServiceHeader] = true

	local private = ServicePrivate(raw)
	private.EnableTemplates = if enableTemplates then enableTemplates else false
	params.EnableTemplates = nil

	function raw:Template(name, createFragment)
		REFLECTION.CUSTOM(1, "Service.Template", self, SERVICE_REFLECTION_TEST)
		REFLECTION.ARG(2, "Service.Template", REFLECTION.STRING, name)
		REFLECTION.ARG(3, "Service.Template", REFLECTION.FUNCTION, createFragment)

		return Template(self, ServicePrivate(self), name, createFragment)
	end

	function raw:CreateFragmentFromTemplate(template, initParams)
		REFLECTION.CUSTOM(1, "Service.CreateFragmentFromTemplate", self, SERVICE_REFLECTION_TEST)
		REFLECTION.CUSTOM(2, "Service.CreateFragmentFromTemplate", template, TEMPLATE_REFLECTION_ASSERT)
		REFLECTION.ARG(3, "Service.CreateFragmentFromTemplate", REFLECTION.OPT_TABLE, initParams)

		local private = ServicePrivate(self)
		if not private.EnableTemplates then ERROR.SERVICE_NO_TEMPLATES(self) end

		if private.Templates[template.Name] ~= template then
			ERROR.BAD_TEMPLATE(template.Name, self)
		end
		
		local params = initParams or {}
		params.Name = params.Name or template.Name
		template:CreateFragment(params)
		return self:Fragment(params)
	end

	function raw:Fragment(params)
		REFLECTION.CUSTOM(1, "Service.Fragment", self, SERVICE_REFLECTION_TEST)
		REFLECTION.ARG(2, "Service.Fragment", REFLECTION.TABLE, params)

		if self.CreateFragment then self:CreateFragment(params) end
		return createFragmentForService(params, self)
	end

	if not raw.Spawning then
		function raw:Spawning(fragment)
			local i = fragment.Init
			if not i then return end
			i(fragment)
		end
	end

	if not raw.FragmentAdded then
		function raw:FragmentAdded(fragment)
			fragment:Spawn()
		end
	end

	if not raw.Updating then
		function raw:Updating(fragment, dt)
			fragment:Update(dt)
		end
	end

	if not Common.Flags.DONT_ASSIGN_OBJECT_MT then
		setmetatable(raw, {
			__tostring = function(self)
				return `CatworkService({self.Name} Templates: {ServicePrivate(self).EnableTemplates})`
			end,
		})
	end
	
	table.freeze(raw)
	return raw
end