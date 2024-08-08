-- metatablecatgames 2024 - Licensed under the MIT License
--local RunService = game:GetService("RunService")
local Common = require("./lib/Common")
local Metakeys = require("./meta")
local Native = require("./lib/Native")
local Service = require("./lib/Service")
local Types = require("./lib/Types")

local ERROR = require("./lib/Error")
local REFLECTION = require("./lib/Reflection")

local Catwork
export type Object<Parameters> = Types.Object<Parameters>
export type Class<A> = Types.Class<A>
export type Service = Types.Service

Catwork = setmetatable({
	__VERSION = Common.Version,
	Plugin = if game then script:FindFirstAncestorOfClass("Plugin") else nil,
	meta = Metakeys.export,

	-- Constructors
	new = function<A>(params: A): Types.Object<A>
		REFLECTION.ARG(1, "Catwork.new", REFLECTION.TABLE, params)

		return Native.Object(params)
	end,

	Service = function(params: Types.ServiceCtorParams): Types.Service
		REFLECTION.ARG(1, "Catwork.Service", REFLECTION.TABLE, params)

		return Service(params)
	end,

	Class = function<A>(name: string, createFn: (Types.Object<A>) -> ()): <B>(B) -> Types.Object<A & B>
		REFLECTION.ARG(1, "Catwork.Class", REFLECTION.STRING, name)
		REFLECTION.ARG(2, "Catwork.Class", REFLECTION.FUNCTION, createFn)

		return Native.GetClassLike(name, createFn)
	end,
}, {
	__tostring = function(self) return `Module(Catwork v{self.__VERSION})` end,
})

table.freeze(Catwork)
type Catwork = typeof(Catwork)
if game and not Catwork.Plugin then print(Common.WelcomeMessage) end
return Catwork
