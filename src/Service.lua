local Service = {}
local Template = require(script.Parent.Template)
local Fragment = require(script.Parent.Fragment)
local Common = require(script.Parent.Common)
local ERROR = require(script.Parent.Error)

local SERVICE_PARAMS = {
	Name = "string",
	
	Spawning = "function?",
	Fragment = "function?",
	FragmentAdded = "function?",
	FragmentRemoved = "function?",
	TemplateAdded = "function?"
}

local function commonServiceCtor(params, enableTemplates)
	if Common.Services[params.Name] then
		ERROR.DUPLICATE_SERVICE(params.Name)
	end

	local raw = Common.validateTable(params, "Service", SERVICE_PARAMS)	
	raw[Common.ServiceHeader] = true

	raw.Fragments = {}
	raw.Templates = {}
	raw.FragmentNameStore = {} -- (mostly) internal table for finding local fragments
	raw.EnableTemplates = enableTemplates or false

	function raw:GetFragmentsOfName(name: string)
		if not self[Common.ServiceHeader] then ERROR.BAD_SELF_CALL("Service.GetFragmentsOfName") end
		if type(name) ~= "string" then ERROR.BAD_ARG(2, "Catwork.GetFragmentsOfName", "string", typeof(name)) end

		local nameStore = self.FragmentNameStore[name]
		return if nameStore then table.clone(nameStore) else {}		
	end

	function raw:Template(params)
		if not self[Common.ServiceHeader] then ERROR.BAD_SELF_CALL("Service.Template") end
		if type(params) ~= "table" then ERROR.BAD_ARG(2, "Catwork.Template", "table", typeof(params)) end

		return Template(params, self)
	end

	function raw:CreateFragmentFromTemplate(template, initParams)
		if not self[Common.ServiceHeader] then ERROR.BAD_SELF_CALL("Service.CreateFragmentFromTemplate") end
		if initParams and type(initParams) ~= "table" then ERROR.BAD_ARG(3, "Service.CreateFragmentFromTemplate", "table?", typeof(params)) end

		if not template[Common.TemplateHeader] and type(template) ~= "string" then
			ERROR.BAD_OBJECT(2, "Service.CreateFragmentFromTemplate", typeof(template), "Template")
		end

		if type(template) == "string" then
			local n = template
			template = self.Templates[n]
			
			if not template then ERROR.BAD_TEMPLATE(n, self) end
		end

		local params = initParams or {}
		params.Name = params.Name or template.Name
		template:CreateFragment(params)
		params.Template = template
		
		return self:Fragment(params)
	end

	if not raw.Spawning then
		function raw:Spawning(fragment)
			local i = fragment.Init

			if not i then
				ERROR.NO_INIT_CALLBACK(fragment.Name)
				return
			end

			i(fragment)
		end
	end

	if not raw.Fragment then
		function raw:Fragment(params)
			if not self[Common.ServiceHeader] then ERROR.BAD_SELF_CALL("Service.Fragment") end
			if type(params) ~= "table" then ERROR.BAD_ARG(2, "Service.Fragment", "table", typeof(params)) end
			return Service:CreateFragmentForService(params, self)
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

function Service:CreateFragmentForService(params, service)
	local f = Fragment(params, service)

	service.Fragments[f.ID] = f
	Common.Fragments[f.ID] = f

	Common.PushToNameStore(Common.FragmentNameStore, f.Name, f.ID, f)
	Common.PushToNameStore(service.FragmentNameStore, f.Name, f.ID, f)
	
	Common._eFragmentAdded:Fire(f)

	local fragAdded = service.FragmentAdded
	if fragAdded then task.spawn(fragAdded, service, f) end

	return f
end

function Service.service(params)
	local useTemplateService = params.TemplateAdded ~= nil
	return commonServiceCtor(params, useTemplateService)
end

return Service