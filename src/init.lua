-- metatablecatgames 2024 - Licensed under the MIT License
local Common = require(script.Common)
local Types = require(script.Types)
local Service = require(script.Service)
local Native = require(script.Native)

-- type hell, :D
export type Fragment<A> = Types.Fragment<A>

export type Service<A, B> = Types.ClassicService<A, B>
export type ServiceMinimal<A> = Service<A, {[string]: any}>
export type ServiceBlank = ServiceMinimal<Fragment<unknown>>

export type Template<A, F> = Types.Template<A, F>
export type TemplateMinimal<A> = Types.Template<A, {[string]: any}>

export type TemplateService<A, B, C, D> = Types.TemplateService<A, B, C, D>
export type TemplateServiceMinimal<A, B> = TemplateService<A, B, {[string]: any}, {[string]: any}>
export type TemplateServiceBlank = TemplateServiceMinimal<Fragment<unknown>, Template<unknown, unknown>>

type ServiceUnion<A, B> = ServiceMinimal<A> | TemplateServiceMinimal<A, B>

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
	__VERSION = script.VERSION.Value
}

--[=[
	@prop Fragments {[string]: Fragment}
	@within Catwork

	Common container for all Fragment objects, stored using the Fragment's unique
	ID. Use Catwork:GetFragmentsOfName to get all fragments of a certain name.
]=]--
Catwork.Fragments = Common.Fragments :: {[string]: Fragment<unknown>}

--[=[
	@prop Services {[string]: Service}
	@within Catwork

	Common container for all Services objects (includes TemplateServices)
]=]--
Catwork.Services = Common.Services :: {[string]: ServiceUnion<unknown, unknown>}

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
	@param mutator (Fragment) -> ()? -- OBSOLETE. Use Service.FragmentAdded instead.
	@return Fragment -- The constructed fragment

	Creates a new Fragment object for the given service.

	:::note Intended for use inside Service.Fragment
	This function is intended to act as a helper function when creating Fragments
	inside services, use the Service.Fragment constructor directly, or
	Catwork.Fragment to create fragments outside of services.
	:::

	:::danger Do not use `mutator`. Use FragmentAdded instead
	This is an obsolete parameter, and does the same thing as FragmentAdded, do not
	pass it, otherwise you will run two callbacks instead of one.
	:::
]=]--
Catwork.CreateFragmentForService = Service.CreateFragmentForService :: <A>(
	Catwork,
	params: {[string]: any},
	service: ServiceUnion<A, unknown>,
	mutator: (A) -> ()?
) -> A

--[=[
	@function Fragment
	@within Catwork
	@param params {[string]: any} -- Parameters passed to the Fragment constructor
	@return Fragment

	Creates a Fragment from the native Catwork service. This does **not** create
	service specific fragments, use `Service.Fragment` for that.
]=]--
Catwork.Fragment = Native :: (
	params: {[string]: any}	
) -> Native.NativeFragment

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

Catwork.Service = Service.classicService :: <A, B>(
	params: Types.CServiceCreatorParams<A, B>
) -> Service<A, B>

--[=[
	@function TemplateService
	@within Catwork
	@param params {[string]: any} -- Parameters passed to the Service constructor
	@return Service
	
	Creates a template enabled service.

	:::caution Service names must be unique
	Service names must be unique, if a service with the same name already exists
	an error will be thrown.
]=]--
Catwork.TemplateService = Service.templateService :: <A, B, C, D>(
	params: Types.TServiceCreatorParams<A, B, C, D>
) -> TemplateService<A, B, C, D>

--[=[
	@method GetFragmentsOfName
	@within Catwork
	@param name string -- A non-unique identifier to match against
	@return {[string]: Fragment}

	Returns all matches of Fragments with the given name.
]=]--
function Catwork:GetFragmentsOfName(name: string): {[string]: Fragment<unknown>}
	local nameStore = Common.FragmentNameStore[name]
	return if nameStore then table.clone(nameStore) else {}
end

table.freeze(Catwork)
type Catwork = typeof(Catwork)
return Catwork