local Service = {}
local Template = require(script.Parent.Template)
local Fragment = require(script.Parent.Fragment)
local Common = require(script.Parent.Common)

--[=[
	@class Service

	A service represents the top-level object for managing Fragments, also allows
	the creation of Templates which act as Fragment factories.

	:::caution Templates are only usable by TemplateServices
	ClassicServices do not allow templates for compatibility with pre-Catwork
	code migrated from Tabby. Template methods within Service will error if
	`Service.EnableTemplates` is set to false.
]=]--
local function commonServiceCtor(params, enableTemplates)
	local raw = table.clone(params)	

	--[=[
		@prop Fragments {[string]: Fragment}
		@within Service
	
		Holds fragments created by the service.
	]=]--
	raw.Fragments = {}

	--[=[
		@prop Templates {[string]: Template}
		@within Service
	
		Holds templates created by the service.
	]=]--
	raw.Templates = {}

	--[=[
		@prop FragmentNameStore {[string]: {[string]: Fragment}}
		@within Service
		@private
	
		Holds non-unique Fragment name bindings for `GetFragmentsOfName`

		:::danger Use `Service:GetFragmentsOfName`
		The shape of this table is unpredictable and may introduce unintended
		side-effects. Using the function returns a pure copy of the table.
	]=]--	
	raw.FragmentNameStore = {} -- (mostly) internal table for finding local fragments
	-- by name

	--[=[
		@prop EnableTemplates boolean
		@within Service
	
		Enables templates, effectively marking the service as a TemplateService.
	]=]--
	raw.EnableTemplates = enableTemplates

	--[=[
		@method GetFragmentsOfName
		@within Service
		@param name string -- A non-unique identifier to match against
		@return {[string]: Fragment}
	
		Returns all matches of Fragments with the given name within the service.
	]=]--
	function raw:GetFragmentsOfName(name: string)
		local nameStore = self.FragmentNameStore[name]
		return if nameStore then table.clone(nameStore) else {}		
	end

	--[=[
		@method Template
		@within Service
		@param params {[string]: any}
		@return Template
	
		Creates a new Template from the given parameters.

		:::caution Template names must be unique
		Template names must be unique, if a templates with the same name already
		exists within the Service, an error will be thrown.
		:::
	]=]--
	function raw:Template(params)
		return Template(params, self)
	end
	
	--[=[
		@method CreateFragmentFromTemplate
		@within Service
		@param template Template|string -- Either the template, or an identifier to it.
		@param initParams {[string]: any}? -- Initial parameters passed to the Template
		@return Fragment
	
		Creates a Fragment from the given template.
	]=]--
	function raw:CreateFragmentFromTemplate(template, initParams)
		if type(template) == "string" then
			template = self.Templates[template]
		end

		local params = initParams or {}
		template:CreateFragment(params)
		return self:Fragment(params)
	end

	--[=[
		@method Spawning
		@within Service
		@param fragment Fragment -- The fragment that is being spawned
	
		Defines the callback that is invoked by the dispatcher when spawning a
		`Fragment` of that `Service`.
	]=]--
	if not raw.Spawning then
		function raw:Spawning(fragment)
			local i = fragment.Init

			if not i then
				warn("Fragment does not implement Init")
				return
			end

			i(fragment)
		end
	end

	--[=[
		@method Fragment
		@within Service
		@param params {[string]: any} -- Params to construct the Fragment
	
		Defines the callback that is used to build a new Fragment. This should
		return a `Catwork:CreateFragmentForService` call, as this handles the
		majority of the internal logic for creating Fragments.

		Do not spawn the Fragment here, this callback is intended for creating
		Fragments, not dispatching them. Dispatch handling should be performed
		within `Service.FragmentAdded`.
	]=]--
	if not raw.Fragment then
		function raw:Fragment(params)
			return Service:CreateFragmentForService(params, self)
		end
	end

	--[=[
		@method FragmentAdded
		@within Service
		@param fragment Fragment -- The newly added Fragment
	
		Defines the callback that is invoked when a new Fragment has been created
		using this Service. This is where you should dispatch the Fragment using
		`Fragment:Spawn`.
	]=]--
	if not raw.FragmentAdded then
		function raw:FragmentAdded(fragment)
			fragment:Spawn()
		end
	end

	--[=[
		@method FragmentRemoved
		@within Service
		@param fragment Fragment -- The removed Fragment
	
		Defines the callback that is invoked when a Fragment is destroyed. Exists
		for external cleanup that Catwork doesn't know about internally.
	]=]--

	--[=[
		@method TemplateAdded
		@within Service
		@param template Template -- The newly defined Template
	
		Defines the callback that is invoked when a Template is defined with this
		service.
	]=]--

	if not Common.DONT_ASSIGN_OBJECT_MT then
		setmetatable(params, {
			__tostring = function(self)
				return `CatworkService({self.Name})`
			end,
		})
	end
	
	table.freeze(raw)
	Common.Services[raw.Name] = raw
	return raw
end

function Service:CreateFragmentForService(params, service, mutator)
	local f = Fragment(params, service, mutator)

	service.Fragments[f.ID] = f
	Common.Fragments[f.ID] = f

	Common.PushToNameStore(Common.FragmentNameStore, f.Name, f.ID, f)
	Common.PushToNameStore(service.FragmentNameStore, f.Name, f.ID, f)

	local fragAdded = service.FragmentAdded
	if fragAdded then task.spawn(fragAdded, service, f) end

	return f
end

function Service.classicService(params)
	return commonServiceCtor(params, false)
end

function Service.templateService(params)
	return commonServiceCtor(params, true)
end

return Service