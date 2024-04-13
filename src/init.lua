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

Catwork.Fragments = Common.Fragments :: {[string]: Types.BlankFragment}
Catwork.Services = Common.Services :: {[string]: Service}
Catwork.Plugin = script:FindFirstAncestorOfClass("Plugin")

function Catwork:CreateFragmentForService<A>(
	params: A,
	service: Service
): Types.Fragment<A>
	if self ~= Catwork then ERROR.BAD_SELF_CALL("Catwork.CreateFragmentForService") end
	if type(params) ~= "table" then ERROR.BAD_ARG(2, "Catwork.CreateFragmentForService", "table", typeof(params)) end
	if not service[Common.ServiceHeader] then ERROR.BAD_OBJECT(3, "Catwork.CreateFragmentForService", typeof(params), "Service") end

	return Service:CreateFragmentForService(params, service)
end

function Catwork.Fragment<A>(params: A): Types.Fragment<A>
	if type(params) ~= "table" then ERROR.BAD_ARG(1, "Catwork.Fragment", "table", typeof(params)) end
	return Native(params)
end

function Catwork.Service(params: ServiceCtorParams): Service
	if type(params) ~= "table" then ERROR.BAD_ARG(1, "Catwork.Service", "table", typeof(params)) end
	return Service.service(params)
end

function Catwork:GetFragmentsOfName(name: string): {[string]: Types.BlankFragment}
	if self ~= Catwork then ERROR.BAD_SELF_CALL("Catwork.GetFragmentsOfName") end
	if type(name) ~= "string" then ERROR.BAD_ARG(2, "Catwork.GetFragmentsOfName", "string", typeof(name)) end

	local nameStore = Common.FragmentNameStore[name]
	return if nameStore then table.clone(nameStore) else {}
end

setmetatable(Catwork, {
	__tostring = function(self) return `Module(Catwork v{self.__VERSION})` end
})
table.freeze(Catwork)

if not Catwork.Plugin then
	print(Common.WelcomeMessage)
end

return Catwork