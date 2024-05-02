-- Reflection generator
-- type = required type
-- type? = optional type

local ERROR = require(script.Parent.Parent.Internal.Error)

type ReflectionArg = {
	Optional: boolean,
	Type: string?,
	CustomAssert: ((any, string, number) -> boolean)
}

local function ASSERTION_REFLECTION_TEST(ok, eType, ...)
	if not ok then
		ERROR[eType](...)
	end
end

local function REFLECTION_TEST(obj: any, arg: ReflectionArg, idx, fName)
	if arg.Type then
		if arg.Type == "any" then return end
		
		-- classic type assert
		local objType = typeof(obj)
		if obj == nil and arg.Optional then return end
		
		if objType ~= arg.Type then ERROR.BAD_ARG(idx, fName, arg.Type, objType) end
		return
	end
	
	ASSERTION_REFLECTION_TEST(arg.CustomAssert(obj, fName, idx))
end

local function REFLECTION(intended: {ReflectionArg}, given, fName: string)
	for idx, obj in intended do
		local other = given[idx]
		REFLECTION_TEST(other, obj, idx, fName)
	end
end

local function Reflection<A..., R...>(fName, f: (A...) -> R..., ...): (A...) -> R...
	local reflectionArgs = {}
	
	for i, v in {...} do
		local isFunctional = type(v) == "function"
		local isOpt = if not isFunctional then string.sub(v, -1) == "?" else false
		
		reflectionArgs[i] = {
			Optional = isOpt,
			Type = if not isFunctional then if isOpt	then string.sub(v, 1, -2) else v else nil,
			CustomAssert = if isFunctional then v else nil	
		}
	end
	
	return function(...)
		REFLECTION(reflectionArgs, {...}, fName)
		return f(...)
	end
end

return Reflection