-- Provides error reporting as well as some shape checks for object constructors

local CatworkRoot = if game then `^{script.Parent.Parent:GetFullName()}` else nil

local function findFirstNonCatworkFunc()
	-- travels up the trace until a non-Catwork func is found
	local depth = 1
	local trace = 2

	while true do
		local s = debug.info(trace, "s")
		trace += 1

		if not s then break end
		if s == "[C]" then continue end

		if CatworkRoot and string.find(s, CatworkRoot) then
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

local function traceback(msg)
	-- same as debug.traceback but strips messages involving Catwork
	local msgStack = { msg or "No output from Lua", "Traceback:" }
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
	BAD_OBJECT = e(
		"BAD_OBJECT",
		"Bad argument number %s to function %s. Type %s could not be converted into object %s.",
		"E"
	),
	BAD_CLASS = e("BAD_CLASS", "Class %s does not exist for Service %s.", "E"),
	BAD_TABLE_SHAPE = e(
		"BAD_TABLE_SHAPE",
		"Object %* cannot be converted to %s. Type of key %s is invalid. Expected %q, got %q.",
		"E"
	),
	GUID_IDS_NOT_ALLOWED = e("GUID_IDS_NOT_ALLOWED", "Cannot use Object ID %s, a new ID has been generated.", "W"),

	ANALYSIS_MODE_NOT_AVAILABLE = e("ANALYSIS_MODE_NOT_AVAILABLE", "Analysis mode cannot be used in %s", "E"),

	DISPATCHER_ALREADY_SPAWNED = e("DISPATCHER_ALREADY_SPAWNED", "Object %s has already been spawned.", "E"),
	DISPATCHER_SPAWN_ERR = e("DISPATCHER_SPAWN_ERR", "An object experienced an error while spawning: %s", "W"),
	DISPATCHER_TIMEOUT = e(
		"DISPATCHER_TIMEOUT",
		'Object %s is taking a long time to intialise. If this is intentional, disable with `[meta "TimeoutDisabled"] = true`',
		"W"
	),

	ACTION_OBJECT_NOT_READY = e(
		"ACTION_OBJECT_NOT_READY",
		"Action %s cannot run yet because its object is not ready.",
		"E"
	),
	ACTION_OBJECT_DESTROYED = e("ACTION_OBJECT_DESTROYED", "Action %s cannot be ran on a destroyed object.", "E"),

	OBJECT_DESTROYED = e("OBJECT_DESTROYED", "Method cannot be used because Object %* was destroyed..", "E"),
	OBJECT_SELF_AWAIT = e(
		"OBJECT_SELF_AWAIT",
		"Object %s is awaiting upon itself and will never resolve. Use HandleAsync instead.",
		"W"
	),

	SERVICE_NO_CLASSES = e("SERVICE_NO_CLASSES", "Service %s does not implement classes.", "E"),
	SERVICE_INVALID_OBJECT = e("SERVICE_INVALID_OBJECT", "Service %s cannot spawn object %s", "E"),
	SERVICE_UPDATING_DISABLED = e(
		"SERVICE_UPDATING_DISABLED",
		'Updating is not enabled on service %s, yet it implements Updating. This can be fixed by adding `[meta "EnableUpdating"] = true` to your service definition.',
		"W"
	),

	-- Remove in 0.5.1
	FRAGMENT_DEPRECATED_MIGRATION = e(
		"FRAGMENT_DEPRECATED_MIGRATION",
		"Catwork.Fragment is deprecated and no longer works, use Catwork.new instead.",
		"E"
	),

	DEPRECATED = e("DEPRECATED", "Function %q is deprecated. Use %q instead.", "W"),
	INTERNAL = e("INTERNAL", "Error: %*. This is likely a known internal error, please report it!", "E"),

	traceback = traceback,
	UNKNOWN = e("UNKNOWN", "Unknown Error", "E"),
}

type ErrorTable = typeof(setmetatable(
	{} :: typeof(ErrorBuffer),
	{} :: {
		__index: (ErrorTable, string) -> (...string) -> never,
	}
))

local Error: ErrorTable = setmetatable({} :: any, {
	__index = function(self, k) return ErrorBuffer[k] or ErrorBuffer.UNKNOWN end,
})

return Error
