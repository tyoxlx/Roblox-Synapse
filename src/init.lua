-- metatablecatgames 2024 - Licensed under the MIT License
local Common = require(script.Common)
local Service = require(script.Objects.Service)
local Native = require(script.Internal.Native)
local Types = require(script.Types.Types)
local Reflection = require(script.Types.Reflection)

local Catwork
local function CatworkSelfCallTest(self, fName)
	return self == Catwork, "BAD_SELF_CALL", fName
end

export type Fragment<Parameters> = Types.Fragment<Parameters>
export type Template = Types.Template
export type Service = Types.Service

Catwork = setmetatable({
	__VERSION = Common.Version,
	Plugin = script:FindFirstAncestorOfClass("Plugin"),
	
	-- Events
	FragmentAdded = Common._eFragmentAdded.Signal,
	FragmentRemoved = Common._eFragmentRemoved.Signal,
	ServiceAdded = Common._eServiceAdded.Signal,
	TemplateAdded = Common._eTemplateAdded.Signal,
	
	-- Constructors
	Fragment = Reflection("Fragment", function(params)
		return Native(params)
	end, "table") :: <A>(A) -> Fragment<A>,
	
	Service = Reflection("Service", function(params)
		return Service(params)
	end, "table") :: (Types.ServiceCtorParams) -> Service,
	
	-- Methods
	GetFragment = Reflection("GetFragment", function(self, id)
		return Common.Fragments[id]
	end, CatworkSelfCallTest, "string") :: (Catwork, string) -> Types.BlankFragment,
	
	GetFragments = Reflection("GetFragments", function(self)
		return table.clone(Common.Fragments)
	end, CatworkSelfCallTest) :: (Catwork) -> {[string]: Types.BlankFragment},
	
	GetFragmentsOfName = Reflection("GetFragmentsOfName", function(self, name)
		local nameStore = Common.FragmentNameStore[name]
		return if nameStore then table.clone(nameStore) else {}
	end, CatworkSelfCallTest, "string") :: (Catwork, string) -> {[string]: Types.BlankFragment},
	
	GetService = Reflection("GetService", function(self, name)
		return Common.Services[name]
	end, CatworkSelfCallTest, "string") :: (Catwork, string) -> Types.Service,
	
	GetServices = Reflection("GetServices", function(self)
		return table.clone(Common.Services)
	end, CatworkSelfCallTest)
},{
	__tostring = function(self) return `Module(Catwork v{self.__VERSION})` end
})

table.freeze(Catwork)
type Catwork = typeof(Catwork)
if not Catwork.Plugin then print(Common.WelcomeMessage) end
return Catwork