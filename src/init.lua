-- metatablecatgames 2024 - Licensed under the MIT License
local RunService = game:GetService("RunService")
local Common = require(script.Common)
local Service = require(script.Objects.Service)
local Native = require(script.Internal.Native)
local Types = require(script.Types.Types)

local REFLECTION = require(script.Types.Reflection)
local ERROR = require(script.Internal.Error)

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
	Fragment = function<A>(params: A): Types.Fragment<A>
		REFLECTION.ARG(1, "Catwork.Fragment", REFLECTION.TABLE, params)

		return Native(params)
	end,
	
	Service = function(params: Types.ServiceCtorParams): Types.Service
		REFLECTION.ARG(1, "Catwork.Service", REFLECTION.TABLE, params)

		return Service(params)
	end,
	
	-- Methods
	GetFragment = function(self: Catwork, id: string): Types.BlankFragment
		REFLECTION.CUSTOM(1, "Catwork.GetFragment", self, CatworkSelfCallTest)
		REFLECTION.ARG(2, "Catwork.GetFragment", REFLECTION.STRING, id)

		return Common.Fragments[id]
	end,
	
	GetFragments = function(self: Catwork): {[string]: Types.BlankFragment}
		REFLECTION.CUSTOM(1, "Catwork.GetFragments", self, CatworkSelfCallTest)
		
		return table.clone(Common.Fragments)
	end,
	
	GetFragmentsOfName = function(self: Catwork, name: string): {[string]: Types.BlankFragment}
		REFLECTION.CUSTOM(1, "Catwork.GetFragmentsOfName", self, CatworkSelfCallTest)
		REFLECTION.ARG(2, "Catwork.GetFragmentsOfName", REFLECTION.STRING, name)

		local nameStore = Common.FragmentNameStore[name]
		return if nameStore then table.clone(nameStore) else {}
	end,
	
	GetService = function(self: Catwork, name: string): Types.Service
		REFLECTION.CUSTOM(1, "Catwork.GetService", self, CatworkSelfCallTest)
		REFLECTION.ARG(2, "Catwork.GetService", REFLECTION.STRING, name)

		return Common.Services[name]
	end,
	
	GetServices = function(self: Catwork): {[string]: Types.Service}
		REFLECTION.CUSTOM(1, "Catwork.GetServices", self, CatworkSelfCallTest)

		return table.clone(Common.Services)
	end,

	EnableAnalysis = function(self: Catwork)
		if RunService:IsRunning() then ERROR.ANALYSIS_MODE_NOT_AVAILABLE("Run Mode") end
		if self.Plugin then ERROR.ANALYSIS_MODE_NOT_AVAILABLE("Plugin") end
	end
},{
	__tostring = function(self) return `Module(Catwork v{self.__VERSION})` end
})

table.freeze(Catwork)
type Catwork = typeof(Catwork)
if not Catwork.Plugin then print(Common.WelcomeMessage) end
return Catwork