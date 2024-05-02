local Template = require(script.Parent.lib.Template)
local Fragment = require(script.Parent.Fragment)
local Common = require(script.Parent.lib.Common)
local ERROR = require(script.Parent.lib.Error)

local SERVICE_PARAMS = {
	Name = "string",
	
	Spawning = "function?",
	CreateFragment = "function?",
	FragmentAdded = "function?",
	FragmentRemoved = "function?",
	TemplateAdded = "function?"
}

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

local function commonServiceCtor(params, enableTemplates)
	if Common.Services[params.Name] then
		ERROR.DUPLICATE_SERVICE(params.Name)
	end

	local raw = Common.validateTable(params, "Service", SERVICE_PARAMS)	
	raw[Common.ServiceHeader] = true

	local private = ServicePrivate(raw)
	private.EnableTemplates = if enableTemplates then enableTemplates else false
	params.EnableTemplates = nil
	
	function raw:GetFragment(id: string)
		if not self[Common.ServiceHeader] then ERROR.BAD_SELF_CALL("Service.GetFragment") end
		if type(id) ~= "string" then ERROR.BAD_ARG(2, "Catwork.GetFragment", "string", typeof(id)) end

		return ServicePrivate(self).Fragments[id]
	end
	
	function raw:GetFragments()
		if not self[Common.ServiceHeader] then ERROR.BAD_SELF_CALL("Service.GetFragment") end
		return table.clone(ServicePrivate(self).Fragments)
	end

	function raw:GetFragmentsOfName(name: string)
		if not self[Common.ServiceHeader] then ERROR.BAD_SELF_CALL("Service.GetFragmentsOfName") end
		if type(name) ~= "string" then ERROR.BAD_ARG(2, "Catwork.GetFragmentsOfName", "string", typeof(name)) end

		local nameStore = ServicePrivate(self).FragmentNameStore[name]
		return if nameStore then table.clone(nameStore) else {}		
	end

	function raw:Template(name, createFragment)
		if not self[Common.ServiceHeader] then ERROR.BAD_SELF_CALL("Service.Template") end
		if type(name) ~= "string" then ERROR.BAD_ARG(2, "Catwork.Template", "string", typeof(name)) end
		if type(createFragment) ~= "function" then ERROR.BAD_ARG(3, "Catwork.Template", "function", typeof(createFragment)) end

		return Template(self, name, createFragment)
	end

	function raw:CreateFragmentFromTemplate(template, initParams)
		if not self[Common.ServiceHeader] then ERROR.BAD_SELF_CALL("Service.CreateFragmentFromTemplate") end
		if initParams and type(initParams) ~= "table" then ERROR.BAD_ARG(3, "Service.CreateFragmentFromTemplate", "table?", typeof(params)) end
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
	end

	function raw:Fragment(params)
		if not self[Common.ServiceHeader] then ERROR.BAD_SELF_CALL("Service.Fragment") end
		if type(params) ~= "table" then ERROR.BAD_ARG(2, "Service.Fragment", "table", typeof(params)) end

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
				return `CatworkService({self.Name} Templates: {self.EnableTemplates})`
			end,
		})
	end
	
	table.freeze(raw)
	Common.Services[raw.Name] = raw
	Common._eServiceAdded:Fire(raw)
	
	return raw
end

return function(params)
	local useTemplateService = (params.TemplateAdded ~= nil) or params.EnableTemplates
	return commonServiceCtor(params, useTemplateService)
end