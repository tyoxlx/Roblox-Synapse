-- Provides error reporting as well as some shape checks for object constructors
local Flags = require(script.Parent.Flags) -- bypass Common because common loads this
local CatworkRoot = `^{script.Parent:GetFullName()}`

local function findFirstNonCatworkFunc()
	-- travels up the trace until a non-Catwork func is found
	local depth = 1
	local trace = 2
	
	while true do
		local s = debug.info(trace, "s")
		trace += 1

		if not s then break end
		if s == "[C]" then continue end

		if string.find(s, CatworkRoot) then
			depth += 1
			continue
		end

		break
	end

	return depth
end

local function e(id, msg, severity)
	
	-- if you're clicking through to this from the error, try finding the first
	-- script in the stack trace that is not a Catwork-related module. That's the
	-- script where this error originates from.
	
	return function(...)
		local m = `[Catwork:{id}] {string.format(msg, ...)}`
		if severity == "E" then
			error(m, if id == "INTERNAL" then -1 else findFirstNonCatworkFunc())
		elseif not Flags.SILENCE_WARNINGS then
			warn(m)
		end
	end
end

local ErrorBuffer = {
	BAD_SELF_CALL = e("BAD_SELF_CALL", "Bad self call to %q, did you mean to use : instead of .?", "E"),
	BAD_ARG = e("BAD_ARG", "Bad argument number %s to function %q. Expected %s, got %s", "E"),
	BAD_OBJECT = e("BAD_OBJECT", "Bad argument number %s to function %s. Type %s could not be converted into object %s.", "E"),
	BAD_TEMPLATE = e("BAD_TEMPLATE", "Template %s does not exist for Service %*.", "E"),
	BAD_TABLE_SHAPE = e("BAD_TABLE_SHAPE", "Object %* cannot be converted to %s. Type of key %s is invalid. Expected %q, got %q.", "E"),
	DUPLICATE_SERVICE = e("DUPLICATE_SERVICE", "Service %s is already defined.", "E"),
	
	DISPATCHER_ALREADY_SPAWNED = e("DISPATCHER_ALREADY_SPAWNED", "Fragment %* has already been spawned.", "E"),
	DISPATCHER_DESTROYED_FRAGMENT = e("DISPATCHER_DESTROYED_FRAGMENT", "Fragment %* cannot be spawned because it has been destroyed.", "E"),

	SERVICE_NO_TEMPLATES = e("SERVICE_NO_TEMPLATES", "Service %* does not implement templates.", "E"),
	SERVICE_DUPLICATE_TEMPLATE = e("SERVICE_DUPLICATE_TEMPLATE", "Template %s already exists", "E"),

	DEPRECATED = e("DEPRECATED", "Function %q is deprecated. Use %q instead.", "W"),
	NO_INIT_CALLBACK = e("NO_INIT_CALLBACK", "Fragment %* does not implement Init.", "W"),
	INTERNAL = e("INTERNAL", "Error: %*. This is likely a known internal error, please report it!", "E")
}

local unknown = e("UNKNOWN", "Unknown Error", "E")

type ErrorTable = typeof(
	setmetatable(
		{}::typeof(ErrorBuffer), 
		{}::{
			__index: (ErrorTable, string) -> (...string) -> never
		}
	)
)

local Error: ErrorTable = setmetatable({}, {
	__index = function(self, k)
		return ErrorBuffer[k] or unknown
	end
})

return Error