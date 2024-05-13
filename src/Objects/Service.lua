local Template = require(script.Parent.Template)
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
	if oType == "string" then return true end
	return template and template[Common.TemplateHeader], "BAD_OBJECT", idx, fName, oType, "Template"
end

local ServicePrivate = Common.private(function(a)
	return {
		Fragments = {},
		Templates = {},
		FragmentNameStore = {},
		EnableTemplates = false
	}
end)

local function createFragmentForService(params, service)
	local f = Fragment(params, service)
	local private = ServicePrivate(service)
	local fPrivate = Common.getPrivate(f)
	
	if not Common.AnalysisMode then
		Common.Fragments[fPrivate.FullID] = f
		private.Fragments[fPrivate.FullID] = f
		Common.PushToNameStore(Common.FragmentNameStore, fPrivate.Name, fPrivate.FullID, f)
		Common.PushToNameStore(private.FragmentNameStore, fPrivate.Name, fPrivate.FullID, f)
		
		Common._eFragmentAdded:Fire(f)

		local fragAdded = service.FragmentAdded
		if fragAdded then task.spawn(fragAdded, service, f) end
	end

	return f
end

-- Constructor
return function(params)
	local enableTemplates = (params.TemplateAdded ~= nil) or params.EnableTemplates
	
	if Common.Services[params.Name] then
		ERROR.DUPLICATE_SERVICE(params.Name)
	end

	local raw = Common.validateTable(params, "Service", SERVICE_PARAMS)	
	raw[Common.ServiceHeader] = true

	local private = ServicePrivate(raw)
	private.EnableTemplates = if enableTemplates then enableTemplates else false
	params.EnableTemplates = nil
	
	function raw:GetFragment(id)
		REFLECTION.CUSTOM(1, "Service.GetFragment", self, SERVICE_REFLECTION_TEST)
		REFLECTION.ARG(2, "Service.GetFragment", REFLECTION.STRING, id)

		return ServicePrivate(self).Fragments[id]
	end

	function raw:GetFragments()
		REFLECTION.CUSTOM(1, "Service.GetFragments", self, SERVICE_REFLECTION_TEST)

		return table.clone(ServicePrivate(self).Fragments)
	end

	function raw:GetFragmentsOfName(name)
		REFLECTION.CUSTOM(1, "Service.GetFragmentsOfName", self, SERVICE_REFLECTION_TEST)
		REFLECTION.ARG(2, "Service.GetFragmentsOfName", REFLECTION.STRING, name)

		local nameStore = ServicePrivate(self).FragmentNameStore[name]
		return if nameStore then table.clone(nameStore) else {}	
	end

	function raw:Template(name, createFragment)
		REFLECTION.CUSTOM(1, "Service.Template", self, SERVICE_REFLECTION_TEST)
		REFLECTION.ARG(2, "Service.Template", REFLECTION.STRING, name)
		REFLECTION.ARG(3, "Service.Template", REFLECTION.FUNCTION, createFragment)

		return Template(self, name, createFragment)
	end

	function raw:CreateFragmentFromTemplate(template, initParams)
		REFLECTION.CUSTOM(1, "Service.CreateFragmentFromTemplate", self, SERVICE_REFLECTION_TEST)
		REFLECTION.CUSTOM(2, "Service.CreateFragmentFromTemplate", template, TEMPLATE_REFLECTION_ASSERT)
		REFLECTION.ARG(3, "Service.CreateFragmentFromTemplate", REFLECTION.OPT_TABLE, initParams)

		local private = ServicePrivate(self)

		if not template[Common.TemplateHeader] and type(template) ~= "string" then
			ERROR.BAD_OBJECT(2, "Service.CreateFragmentFromTemplate", typeof(template), "Template")
		end

		if not private.EnableTemplates then ERROR.SERVICE_NO_TEMPLATES(self) end

		if type(template) == "string" then
			local n = template
			template = private.Templates[n]

			if not template then ERROR.BAD_TEMPLATE(n, self) end
		elseif private.Templates[template.Name] ~= template then
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

	if not Common.Flags.DONT_ASSIGN_OBJECT_MT then
		setmetatable(raw, {
			__tostring = function(self)
				return `CatworkService({self.Name} Templates: {ServicePrivate(self).EnableTemplates})`
			end,
		})
	end
	
	table.freeze(raw)

	if not Common.AnalysisMode then
		Common.Services[raw.Name] = raw
		Common._eServiceAdded:Fire(raw)
	end
	
	return raw
end