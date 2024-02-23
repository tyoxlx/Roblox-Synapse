-- metatablecatgames 2024 - Licensed under the MIT License
local Common = require(script.Common)
local Service = require(script.Service)
local Native = require(script.Native)
local Types = require(script.Types)
local ERROR = require(script.Error)

export type Fragment<Parameters> = Types.Fragment<Parameters>
export type Template = Types.Template
export type Service = Types.Service

type ServiceCtorParams = {
	Name: string,
	EnableTemplates: boolean?,
	
	Spawning: (Service, Types.BlankFragment) -> ()?,
	Fragment: <A>(Service, A) -> Fragment<A>?,
	FragmentAdded: (Service, Types.BlankFragment) -> ()?,
	FragmentRemoved: (Service, Types.BlankFragment) -> ()?,
	TemplateAdded: (Service, Template) -> ()?,
	
	[string]: any
}

--[=[
	@class Catwork

	Catwork is the base library that all other code derives from
]=]--
local Catwork = {
	--[=[
		@prop Version string
		@within Catwork

		A semantic versioning string stating the current version of Catwork
	]=]--
	__VERSION = script.VERSION.Value,
	
	FragmentAdded = Common._eFragmentAdded.Signal,
	FragmentRemoved = Common._eFragmentRemoved.Signal,
	ServiceAdded = Common._eServiceAdded.Signal
}

--[=[
	@prop Fragments {[string]: Fragment}
	@within Catwork

	Common container for all Fragment objects, stored using the Fragment's unique
	ID. Use Catwork:GetFragmentsOfName to get all fragments of a certain name.
]=]--
Catwork.Fragments = Common.Fragments :: {[string]: Types.BlankFragment}

--[=[
	@prop Services {[string]: Service}
	@within Catwork

	Common container for all Services objects (includes TemplateServices)
]=]--
Catwork.Services = Common.Services :: {[string]: Service}

--[=[
	@prop Plugin Plugin
	@within Catwork

	A Plugin identifier for when using Catwork as a plugin.
]=]--
Catwork.Plugin = script:FindFirstAncestorOfClass("Plugin")

--[=[
	@method CreateFragmentForService
	@within Catwork
	@param params {[string]: any} -- Parameters passed to the Fragment constructor
	@param service Service -- Service used to construct the fragment against
	@return Fragment -- The constructed fragment

	Creates a new Fragment object for the given service.

	:::note Intended for use inside Service.Fragment
	This function is intended to act as a helper function when creating Fragments
	inside services, use the Service.Fragment constructor directly, or
	Catwork.Fragment to create fragments outside of services.
	:::
]=]--
function Catwork:CreateFragmentForService<A>(
	params: A,
	service: Service
): Types.Fragment<A>
	if self ~= Catwork then ERROR.BAD_SELF_CALL("Catwork.CreateFragmentForService") end
	if type(params) ~= "table" then ERROR.BAD_ARG(2, "Catwork.CreateFragmentForService", "table", typeof(params)) end
	if not service[Common.ServiceHeader] then ERROR.BAD_OBJECT(3, "Catwork.CreateFragmentForService", typeof(params), "Service") end

	return Service:CreateFragmentForService(params, service)
end

--[=[
	@function Fragment
	@within Catwork
	@param params {[string]: any} -- Parameters passed to the Fragment constructor
	@return Fragment

	Creates a Fragment from the native Catwork service. This does **not** create
	service specific fragments, use `Service.Fragment` for that.
]=]--
function Catwork.Fragment<A>(params: A): Types.Fragment<A>
	if type(params) ~= "table" then ERROR.BAD_ARG(1, "Catwork.Fragment", "table", typeof(params)) end
	return Native(params)
end

--[=[
	@function Service
	@within Catwork
	@param params {[string]: any} -- Parameters passed to the Service constructor
	@return ClassicService

	Creates a classic non-template enabled service.

	:::caution Service names must be unique
	Service names must be unique, if a service with the same name already exists
	an error will be thrown.
]=]--

function Catwork.Service(params: ServiceCtorParams): Service
	if type(params) ~= "table" then ERROR.BAD_ARG(1, "Catwork.Service", "table", typeof(params)) end
	return Service.service(params)
end

--[=[
	@method GetFragmentsOfName
	@within Catwork
	@param name string -- A non-unique identifier to match against
	@return {[string]: Fragment}

	Returns all matches of Fragments with the given name.
]=]--
function Catwork:GetFragmentsOfName(name: string): {[string]: Types.BlankFragment}
	if self ~= Catwork then ERROR.BAD_SELF_CALL("Catwork.GetFragmentsOfName") end
	if type(name) ~= "string" then ERROR.BAD_ARG(2, "Catwork.GetFragmentsOfName", "string", typeof(name)) end

	local nameStore = Common.FragmentNameStore[name]
	return if nameStore then table.clone(nameStore) else {}
end

table.freeze(Catwork)
type Catwork = typeof(Catwork)

print(Common.WelcomeMessage)
return Catwork