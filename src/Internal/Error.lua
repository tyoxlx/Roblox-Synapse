-- Provides error reporting as well as some shape checks for object constructors

local CatworkRoot = `^{script.Parent.Parent:GetFullName()}`

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
		else
			warn(m)
		end
	end
end

local errorFuncs = {}

function errorFuncs.traceback(msg)
	-- same as debug.traceback but strips messages involving Catwork
	local msgStack = {msg or "No output from Lua", "Traceback:"}
	local depth = 1

	while true do
		local s, n, l = debug.info(depth, "snl")
		depth += 1

		if not s then break end
		if s == "[C]" then continue end
		if string.find(s, CatworkRoot) then
			depth += 1
			continue
		end

		if n then
			table.insert(msgStack, `  {s}:{l} function {n}`)
		else
			table.insert(msgStack, `  {s}:{l}`)
		end
	end

	return table.concat(msgStack, "\n")
end

local ErrorBuffer = {
	BAD_SELF_CALL = e("BAD_SELF_CALL", "Bad self call to %q, did you mean to use : instead of .?", "E"),
	BAD_ARG = e("BAD_ARG", "Bad argument number %s to function %q. Expected %s, got %s", "E"),
	BAD_OBJECT = e("BAD_OBJECT", "Bad argument number %s to function %s. Type %s could not be converted into object %s.", "E"),
	BAD_TEMPLATE = e("BAD_TEMPLATE", "Template %s does not exist for Service %*.", "E"),
	BAD_TABLE_SHAPE = e("BAD_TABLE_SHAPE", "Object %* cannot be converted to %s. Type of key %s is invalid. Expected %q, got %q.", "E"),
	GUID_IDS_NOT_ALLOWED = e("GUID_IDS_NOT_ALLOWED", "Cannot use Fragment ID %s, a new ID has been generated.", "W"),

	DUPLICATE_SERVICE = e("DUPLICATE_SERVICE", "Service %s is already defined.", "E"),
	DUPLICATE_FRAGMENT = e("DUPLICATE_FRAGMENT", "Fragment %s is already defined", "E"),

	ANALYSIS_MODE_NOT_AVAILABLE = e("ANALYSIS_MODE_NOT_AVAILABLE", "Analysis mode cannot be used in %s", "E"),

	DISPATCHER_ALREADY_SPAWNED = e("DISPATCHER_ALREADY_SPAWNED", "Fragment %* has already been spawned.", "E"),
	DISPATCHER_DESTROYED_FRAGMENT = e("DISPATCHER_DESTROYED_FRAGMENT", "Fragment %* cannot be spawned because it has been destroyed.", "E"),
	DISPATCHER_SPAWN_ERR = e("DISPATCHER_SPAWN_ERR", "A fragment experienced an error while spawning: %s", "W"),
	DISPATCHER_TIMEOUT = e("DISPATCHER_TIMEOUT", "Fragment %* is taking a long time to intialise. If this is intentional, disable with `TimeoutDisabled = true`", "W"),
	
	FRAGMENT_SELF_AWAIT = e("FRAGMENT_SELF_AWAIT", "Fragment %* is awaiting upon itself and will never resolve. Use HandleAsync instead.", "W"),

	SERVICE_NO_TEMPLATES = e("SERVICE_NO_TEMPLATES", "Service %* does not implement templates.", "E"),
	SERVICE_DUPLICATE_TEMPLATE = e("SERVICE_DUPLICATE_TEMPLATE", "Template %s already exists", "E"),

	DEPRECATED = e("DEPRECATED", "Function %q is deprecated. Use %q instead.", "W"),
	INTERNAL = e("INTERNAL", "Error: %*. This is likely a known internal error, please report it!", "E")
}

local unknown = e("UNKNOWN", "Unknown Error", "E")

type ErrorTable = typeof(
	setmetatable(
		{}::typeof(ErrorBuffer) & typeof(errorFuncs), 
		{}::{
			__index: (ErrorTable, string) -> (...string) -> never
		}
	)
)

local Error = setmetatable(errorFuncs, {
	__index = function(self, k)
		return ErrorBuffer[k] or unknown
	end
})

return Error::ErrorTable