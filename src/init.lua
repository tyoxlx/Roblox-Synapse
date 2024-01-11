-- metatablecatgames 2024 - Part of Catwork, all rights reserved

local HttpService = game:GetService("HttpService")
local Action = require(script.Action)
local Types = require(script.Types)

-- type hell, :D
export type Service<A, B> = Types.ClassicService<A, B>
export type ServiceMinimal<A> = Service<A, {[string]: unknown}>
export type ServiceBlank = ServiceMinimal<Fragment<any>>

export type TemplateService<A, B, C, D> = Types.TemplateService<A, B, C, D>
export type TemplateServiceMinimal<A, B> = TemplateService<A, B, {[string]: unknown}, {[string]: unknown}>
export type TemplateServiceBlank = TemplateServiceMinimal<Fragment<any>, Template<any, any>>

export type Fragment<A> = Types.Fragment<A>

export type Template<A, F> = Types.Template<A, F>
export type TemplateMinimal<A> = Types.Template<A, {[string]: any}>

type NativeFragment = Types.Fragment<{}>
type NativeService = ServiceMinimal<NativeFragment> --TODO: NativeServiceParams

-- you may now rest easily knowing the type hell is gone

local native: NativeService
local Catwork = {}
local fragmentNameStore: {[string]: {[string]: Types.Fragment<unknown>}} = {}

Catwork.Fragments = {} :: {[string]: Fragment<unknown>}
Catwork.Services = {} :: {[string]: ServiceMinimal<unknown>}

local function pushToNameStore<A>(
	nameStoreTable: {[string]: {[string]: A}},
	nameStoreKey: string,
	k: string, v: A
)
	local t = nameStoreTable[nameStoreKey]
	if not t then
		t = {}
		nameStoreTable[nameStoreKey] = t
	end
	
	t[k] = v
end

local function flushNameStore<A>(
	nameStoreTable: {[string]: {[string]: A}},
	nameStoreKey: string,
	k: string
)
	local t = nameStoreTable[nameStoreKey]
	if not t then return end
	
	t[k] = nil
	if not next(t) then
		nameStoreTable[nameStoreKey] = nil
	end
end

local RunFragmentAction = Action("cw.RunFragment", function(fragment, service, spawnSignal)
	spawnSignal(service, fragment)
end)

local function spawnFragment(self: Fragment<any>, asyncHandler)
	local service = self.Service
	local spawnSignal = service.Spawning

	if asyncHandler then
		RunFragmentAction:handleAsync(asyncHandler, self, service, spawnSignal)
		return nil
	else
		return RunFragmentAction:await(self, service, spawnSignal)
	end
end

local function Fragment(
	params: {[string]: any},
	service: Types.Service,
	mutator
)
	
	params.ID = HttpService:GenerateGUID(false)
	params.Name = params.Name or `CatworkFragment`
	params.Service = service
	params.Spawn = spawnFragment
	
	function params:Destroy()
		local service = self.Service
		if service.Fragments[self.ID] then
			Catwork.Fragments[self.ID] = nil
			service.Fragments[self.ID] = nil
			
			flushNameStore(fragmentNameStore, self.Name, self.ID)
			flushNameStore(service.FragmentNameStore, self.Name, self.ID)
			
			local destroying = self.Destroying
			local fragRemoved = service.FragmentRemoved

			if destroying then task.spawn(destroying, self) end
			if fragRemoved then task.spawn(fragRemoved, service, self) end
		end
	end
	
	setmetatable(params, {
		__tostring = function(self)
			return `CatworkFragment({self.Name}::{self.ID})`
		end
	})
	
	if mutator then mutator(params) end
	return params
end

local function Template<A, B>(
	params: {[string]: any},
	service: TemplateServiceMinimal<A, B>
): TemplateMinimal<B>
	-- just clones the template params and pushes it to the service if its nil

	if not service.EnableTemplates then
		error(`service {service.Name} does not implement templates.`)
	end

	if service.Templates[params.Name] then
		error(`template {params.Name} already exists for service {service.Name}.`)
	end

	setmetatable(params, {
		__tostring = function(self)
			return `ServiceTemplate({self.Name})`
		end,
	})
	service.Templates[params.Name] = params
	
	if service.TemplateAdded then
		service:TemplateAdded(params)
	end
	
	return params
end

function Catwork:CreateFragmentForService(
	params: {[string]: any},
	service: Types.Service,
	mutator
)
	
	local f = Fragment(params, service, mutator)
	
	service.Fragments[f.ID] = f
	Catwork.Fragments[f.ID] = f
	
	pushToNameStore(fragmentNameStore, f.Name, f.ID, f)
	pushToNameStore(service.FragmentNameStore, f.Name, f.ID, f)

	local fragAdded = service.FragmentAdded
	if fragAdded then task.spawn(fragAdded, service, f) end
	
	return f
end

function Catwork.Fragment<A...>(
	params: {[string]: any}
): NativeFragment
	
	return native:Fragment(params)
end

local function commonServiceCtor(params, enableTemplates)
	local raw = table.clone(params)	
	raw.Fragments = {}
	raw.Templates = {}
	raw.FragmentNameStore = {} -- (mostly) internal table for finding local fragments
	-- by name
	raw.EnableTemplates = enableTemplates

	function raw:GetFragmentsOfName(name: string)
		local nameStore = self.FragmentNameStore[name]
		return if nameStore then table.clone(nameStore) else {}		
	end

	function raw:Template(params)
		return Template(params, self)
	end

	function raw:CreateFragmentFromTemplate(template, initParams)
		if type(template) == "string" then
			template = self.Templates[template]
		end

		local params = initParams or {}
		template:CreateFragment(params)
		return self:Fragment(params)
	end

	if not raw.Spawning then
		function raw:Spawning(fragment)
			local i = fragment.Init

			if not i then
				warn("Fragment does not implement Init")
				return i
			end

			return i(fragment)
		end
	end
	
	if not raw.Fragment then
		function raw:Fragment(params)
			return Catwork:CreateFragmentForService(params, self)
		end
	end

	table.freeze(raw)
	Catwork.Services[raw.Name] = raw
	return raw
end

function Catwork.Service<A, B>(
	params: Types.CServiceCreatorParams<A, B>
): Service<A, B>
	
	return commonServiceCtor(params, false)
end

function Catwork.TemplateService<A, B, C, D>(
	params: Types.TServiceCreatorParams<A, B, C, D>
): TemplateService<A, B, C, D>

	return commonServiceCtor(params, true)
end

function Catwork:GetFragmentsOfName(name: string): {[string]: Fragment<any>}
	local nameStore = fragmentNameStore[name]
	return if nameStore then table.clone(nameStore) else {}
end

native = Catwork.Service {
	Name = "catwork"
}

return Catwork