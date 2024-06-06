local Dispatcher = require(script.Parent.Parent.Internal.Dispatcher)
local Common = require(script.Parent.Parent.Common)
local ERROR = require(script.Parent.Parent.Internal.Error)
local REFLECTION = require(script.Parent.Parent.Types.Reflection)

local OBJECT_PARAMS = {
	Name = "string?",
	ID = "string?",
	Destroying = "function?",
	Init = "function?",
	Updating = "function?",
	TimeoutDisabled = "boolean?"
}

local function OBJECT_REFLECTION_TEST(object, oName)
	return object and object[Common.ObjectHeader], "BAD_SELF_CALL", oName
end

local ObjectPrivate = Common.private(function()
	return {
		ID = "",
		FullID = "",
		Name = "",
		Service = nil,
		TimeoutDisabled = false
	}
end)

return function(params: {[string]: any}, service)
	local raw = Common.validateTable(params, "Object", OBJECT_PARAMS)
	local private = ObjectPrivate(raw)

	raw[Common.ObjectHeader] = true

	private.TimeoutDisabled = if params.TimeoutDisabled then params.TimeoutDisabled else false
	private.Name = params.Name or `CatworkObject`
	private.Service = service

	Common.assignObjectID(raw, private, service)
	raw.Name = nil
	
	function raw:Spawn(xpcallHandler, asyncHandler)
		if Common.AnalysisMode then return end

		REFLECTION.CUSTOM(1, "Object.Spawn", self, OBJECT_REFLECTION_TEST)
		REFLECTION.ARG(2, "Object.Spawn", REFLECTION.OPT_FUNCTION, xpcallHandler)
		REFLECTION.ARG(3, "Object.Spawn", REFLECTION.OPT_FUNCTION, asyncHandler)

		return Dispatcher.spawnObject(self, ObjectPrivate(self), xpcallHandler, asyncHandler)
	end
	
	function raw:Await()
		REFLECTION.CUSTOM(1, "Object.Await", self, OBJECT_REFLECTION_TEST)
		
		if Dispatcher.isSelfAsyncCall(self) then ERROR.OBJECT_SELF_AWAIT(self) end
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
		
		return full and ObjectPrivate(self).FullID or ObjectPrivate(self).ID
	end
	
	function raw:GetName()
		REFLECTION.CUSTOM(1, "Object.GetName", self, OBJECT_REFLECTION_TEST)
		
		return ObjectPrivate(self).Name
	end

	function raw:Destroy()
		REFLECTION.CUSTOM(1, "Object.Destroy", self, OBJECT_REFLECTION_TEST)
		
		if not self[Common.ObjectHeader] then ERROR.BAD_SELF_CALL("Object.Destroy") end
		local service = ObjectPrivate(self).Service
		local state = Dispatcher.getObjectState(self)

		if Dispatcher.getObjectState(self) then
			-- we need to run this in a parallel thread to stop this breaking if called within Init
			Dispatcher.cleanObjectState(self)

			local destroying = self.Destroying
			local fragRemoved = service.ObjectRemoved

			if destroying then task.spawn(destroying, self) end
			if fragRemoved then task.spawn(fragRemoved, service, self) end

			Dispatcher.stop(self, state)
		end
	end

	if not Common.Flags.DONT_ASSIGN_OBJECT_MT then
		setmetatable(raw, {
			__tostring = function(self)
				local private = ObjectPrivate(self)
				return `CatworkObject({private.Name}::{private.FullID})`
			end
		})
	end
	
	return raw
end