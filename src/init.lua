-- metatablecatgames 2024 - Licensed under the MIT License
local Common = require(script.lib.Common)
local Service = require(script.Service)
local Native = require(script.lib.Native)
local Types = require(script.lib.Types)
local ERROR = require(script.lib.Error)

export type Fragment<Parameters> = Types.Fragment<Parameters>
export type Template = Types.Template
export type Service = Types.Service

type ServiceCtorParams = {
	Name: string,

	EnableTemplates: boolean?,
	
	Spawning: (Service, Types.BlankFragment) -> ()?,
	Fragment: (<A>(Service, A) -> Fragment<A>)?,
	FragmentAdded: (Service, Types.BlankFragment) -> ()?,
	FragmentRemoved: (Service, Types.BlankFragment) -> ()?,
	TemplateAdded: (Service, Template) -> ()?,
	
	[string]: any
}

local Catwork = {
	__VERSION = Common.Version,
}

Catwork.FragmentAdded = Common._eFragmentAdded.Signal
Catwork.FragmentRemoved = Common._eFragmentRemoved.Signal
Catwork.ServiceAdded = Common._eServiceAdded.Signal
Catwork.TemplateAdded = Common._eTemplateAdded.Signal
Catwork.Plugin = script:FindFirstAncestorOfClass("Plugin")

-- Constructors

function Catwork.Fragment<A>(params: A): Types.Fragment<A>
	if type(params) ~= "table" then ERROR.BAD_ARG(1, "Catwork.Fragment", "table", typeof(params)) end
	return Native(params)
end

function Catwork.Service(params: ServiceCtorParams): Service
	if type(params) ~= "table" then ERROR.BAD_ARG(1, "Catwork.Service", "table", typeof(params)) end
	return Service(params)
end

-- Object Getters

function Catwork:GetFragmentsOfName(name: string): {[string]: Types.BlankFragment}
	if self ~= Catwork then ERROR.BAD_SELF_CALL("Catwork.GetFragmentsOfName") end
	if type(name) ~= "string" then ERROR.BAD_ARG(2, "Catwork.GetFragmentsOfName", "string", typeof(name)) end

	local nameStore = Common.FragmentNameStore[name]
	return if nameStore then table.clone(nameStore) else {}
end

function Catwork:GetFragment(id: string): Types.BlankFragment
	if self ~= Catwork then ERROR.BAD_SELF_CALL("Catwork.GetFragment") end
	if type(id) ~= "string" then ERROR.BAD_ARG(2, "Catwork.GetFragment", "string", typeof(id)) end

	return Common.Fragments[id]
end

function Catwork:GetFragments(): {[string]: Types.BlankFragment}
	if self ~= Catwork then ERROR.BAD_SELF_CALL("Catwork.GetFragments") end

	return table.clone(Common.Fragments)
end

function Catwork:GetService(name: string): Types.Service
	if self ~= Catwork then ERROR.BAD_SELF_CALL("Catwork.GetService") end
	if type(name) ~= "string" then ERROR.BAD_ARG(2, "Catwork.GetService", "string", typeof(name)) end

	return Common.Services[name]
end

function Catwork:GetServices(): {[string]: Types.Service}
	if self ~= Catwork then ERROR.BAD_SELF_CALL("Catwork.GetServices") end

	return table.clone(Common.Services)
end

setmetatable(Catwork, {
	__tostring = function(self) return `Module(Catwork v{self.__VERSION})` end
})
table.freeze(Catwork)

if not Catwork.Plugin then
	print(Common.WelcomeMessage)
end

return Catwork