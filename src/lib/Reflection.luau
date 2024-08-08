-- Reflection typechecker
-- type = required type
-- type? = optional type

-- metatablecat 2024, part of Catwork

local ERROR = require("./Error")

local Reflection = {}

Reflection.NULL = 0
-- Reflection.OPTIONAL = 1 (implemented as a low is-odd bit)
Reflection.BOOLEAN = 2
Reflection.NUMBER = 4
Reflection.STRING = 6
Reflection.TABLE = 8
Reflection.FUNCTION = 10
Reflection.THREAD = 12
Reflection.USERDATA = 14
Reflection.VECTOR = 16
Reflection.BUFFER = 18

-- Optional Bindings
Reflection.OPT_BOOLEAN = 3
Reflection.OPT_NUMBER = 5
Reflection.OPT_STRING = 7
Reflection.OPT_TABLE = 9
Reflection.OPT_FUNCTION = 11
Reflection.OPT_THREAD = 13
Reflection.OPT_USERDATA = 15
Reflection.OPT_VECTOR = 17
Reflection.OPT_BUFFER = 19

local LUAU_NATIVE_TYPE = {
	-- Enum -> type() bindings

	[Reflection.BOOLEAN] = "boolean",
	[Reflection.NUMBER] = "number",
	[Reflection.STRING] = "string",
	[Reflection.TABLE] = "table",
	[Reflection.FUNCTION] = "function",
	[Reflection.THREAD] = "thread",
	[Reflection.USERDATA] = "userdata",
	[Reflection.VECTOR] = "vector",
	[Reflection.BUFFER] = "buffer",
}

local function reflectionCallbackHandler(ok, eID, ...)
	if ok then return end
	ERROR[eID](...)
end

function Reflection.ARG(argIdx: number, functionName: string, enum: number, incoming: any)
	if enum == 0 then
		-- fast-path, enum val is NIL
		if incoming ~= nil then ERROR.BAD_ARG(argIdx, functionName, "nil", type(incoming)) end

		return
	end

	local isOpt = bit32.band(enum, 1) == 1
	local typeVal = LUAU_NATIVE_TYPE[bit32.band(enum, 0b1111110)]

	if not typeVal then return end
	if isOpt and incoming == nil then return end

	local t = type(incoming)
	if t == typeVal then return end
	ERROR.BAD_ARG(argIdx, functionName, typeVal, t)
end

function Reflection.CUSTOM(
	argIdx: number,
	functionName: string,
	incoming: any,
	assertion: (any, string, number) -> (boolean, ...any)
)
	reflectionCallbackHandler(assertion(incoming, functionName, argIdx))
end

return Reflection
