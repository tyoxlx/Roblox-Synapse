if not task then task = require("@lune/task") end

local Common = require("./Common")
local Dispatcher = require("./Dispatcher")
local ERROR = require("./Error")
local REFLECTION = require("./Reflection")

local OBJECT_PARAMS = {
	Name = "string?",
	ID = "string?",
	Destroying = "function?",
	Init = "function?",
	Updating = "function?",
}

local function OBJECT_REFLECTION_TEST(object, oName)
	return object and object[Common.ObjectHeader], "BAD_SELF_CALL", oName
end

return function(params: { [string]: any }, service, OBJECT_PRIVATE)
	local raw, metakeys = Common.validateTable(params, "Object", OBJECT_PARAMS)

	local private = {
		ID = "",
		FullID = "",
		Service = service,
		TimeoutDisabled = if metakeys.TimeoutDisabled then metakeys.TimeoutDisabled else false,
		AwaitFor = metakeys.AwaitFor or {},
	}

	OBJECT_PRIVATE[raw] = private
	raw[Common.ObjectHeader] = true
	Common.assignObjectID(raw, private, service)
	raw.Name = params.Name or `CatworkAsyncObject`

	function raw:Spawn(xpcallHandler, asyncHandler) ERROR.DEPRECATED("Object.Spawn", "Service.SpawnObject") end

	function raw:Await()
		REFLECTION.CUSTOM(1, "Object.Await", self, OBJECT_REFLECTION_TEST)

		return Dispatcher.slotAwait(self)
	end

	function raw:HandleAsync(asyncHandler)
		REFLECTION.CUSTOM(1, "Object.HandleAsync", self, OBJECT_REFLECTION_TEST)
		REFLECTION.ARG(2, "Object.HandleAsync", REFLECTION.FUNCTION, asyncHandler)

		Dispatcher.slotHandleAsync(self, asyncHandler)
	end

	function raw:GetID(full: boolean?)
		REFLECTION.CUSTOM(1, "Object.GetID", self, OBJECT_REFLECTION_TEST)
		REFLECTION.ARG(2, "Object.GetID", REFLECTION.OPT_BOOLEAN, full)

		local private = OBJECT_PRIVATE[self]
		if not private then ERROR.OBJECT_DESTROYED(self) end

		return full and OBJECT_PRIVATE[self].FullID or OBJECT_PRIVATE[self].ID
	end

	function raw:Destroy()
		REFLECTION.CUSTOM(1, "Object.Destroy", self, OBJECT_REFLECTION_TEST)

		if not self[Common.ObjectHeader] then ERROR.BAD_SELF_CALL("Object.Destroy") end
		local state = Dispatcher.getObjectState(self)

		if state then
			Dispatcher.cleanObjectState(self)
			local service = OBJECT_PRIVATE[self].Service
			OBJECT_PRIVATE[self] = nil

			local destroying = self.Destroying
			local fragRemoved = service.ObjectRemoved

			if destroying then task.spawn(destroying, self) end
			if fragRemoved then task.spawn(fragRemoved, service, self) end

			Dispatcher.stop(self, state)
		end
	end

	function raw:GetState()
		REFLECTION.CUSTOM(1, "Object.GetState", self, OBJECT_REFLECTION_TEST)

		return Dispatcher.getStateString(self)
	end

	if not Common.Flags.DONT_ASSIGN_OBJECT_MT then
		setmetatable(raw, {
			__tostring = function(self)
				local private = OBJECT_PRIVATE[self]
				return `CatworkAsyncObject({self.Name}::{private.FullID})`
			end,
		})
	end

	return raw
end
