local Template = require(script.Parent.Template)
local Fragment = require(script.Parent.Fragment)
local Common = require(script.Parent.Parent.Common)
local ERROR = require(script.Parent.Parent.Internal.Error)
local Reflection = require(script.Parent.Parent.Types.Reflection)

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

	Common.Fragments[fPrivate.FullID] = f
	private.Fragments[fPrivate.FullID] = f
	
	Common.PushToNameStore(Common.FragmentNameStore, fPrivate.Name, fPrivate.FullID, f)
	Common.PushToNameStore(private.FragmentNameStore, fPrivate.Name, fPrivate.FullID, f)
	
	Common._eFragmentAdded:Fire(f)

	local fragAdded = service.FragmentAdded
	if fragAdded then task.spawn(fragAdded, service, f) end

	return f
end

-- Reflection
local ServiceReflection = {
	GetFragment = Reflection("GetFragment", function(self, id)
		return ServicePrivate(self).Fragments[id]
	end, SERVICE_REFLECTION_TEST, "string"),

	GetFragments = Reflection("GetFragments", function(self)
		return table.clone(ServicePrivate(self).Fragments)
	end, SERVICE_REFLECTION_TEST),

	GetFragmentsOfName = Reflection("GetFragmentsOfName", function(self, name)
		local nameStore = ServicePrivate(self).FragmentNameStore[name]
		return if nameStore then table.clone(nameStore) else {}	
	end, SERVICE_REFLECTION_TEST, "string"),

	Template = Reflection("Template", function(self, name, createFragment)
		return Template(self, name, createFragment)
	end, SERVICE_REFLECTION_TEST, TEMPLATE_REFLECTION_ASSERT, "function"),

	CreateFragmentFromTemplate = Reflection("CreateFragmentFromTemplate", function(self, template, initParams)
		local private = ServicePrivate(self)

		if not template[Common.TemplateHeader] and type(template) ~= "string" then
			ERROR.BAD_OBJECT(2, "Service.CreateFragmentFromTemplate", typeof(template), "Template")
		end

		if not private.EnableTemplates then ERROR.SERVICE_NO_TEMPLATES(self) end

		if type(template) == "string" then
			local n = template
			print(private)
			template = private.Templates[n]

			if not template then ERROR.BAD_TEMPLATE(n, self) end
		elseif private.Templates[template.Name] ~= template then
			ERROR.BAD_TEMPLATE(template.Name, self)
		end
		
		local params = initParams or {}
		params.Name = params.Name or template.Name
		template:CreateFragment(params)
		params.Template = template

		return self:Fragment(params)
	end, SERVICE_REFLECTION_TEST, "any", "table?"), -- TODO: assert template

	Fragment = Reflection("Fragment", function(self, params)
		if self.CreateFragment then self:CreateFragment(params) end
		return createFragmentForService(params, self)
	end, SERVICE_REFLECTION_TEST, "table")
}

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
	
	raw.GetFragment = ServiceReflection.GetFragment
	raw.GetFragments = ServiceReflection.GetFragments
	raw.GetFragmentsOfName = ServiceReflection.GetFragmentsOfName
	raw.Template = ServiceReflection.Template
	raw.CreateFragmentFromTemplate = ServiceReflection.CreateFragmentFromTemplate
	raw.Fragment = ServiceReflection.Fragment

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
				return `CatworkService({self.Name} Templates: {self.EnableTemplates})`
			end,
		})
	end
	
	table.freeze(raw)
	Common.Services[raw.Name] = raw
	Common._eServiceAdded:Fire(raw)
	
	return raw
end