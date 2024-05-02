local Dispatcher = require(script.Parent.Parent.Internal.Dispatcher)
local Common = require(script.Parent.Parent.Common)
local ERROR = require(script.Parent.Parent.Internal.Error)
local Reflection = require(script.Parent.Parent.Types.Reflection)

local FRAGMENT_PARAMS = {
	Name = "string?",
	ID = "string?",
	Destroying = "function?",
	Init = "function?"
}

local function FRAGMENT_REFLECTION_TEST(fragment, fName)
	return fragment and fragment[Common.FragmentHeader], "BAD_SELF_CALL", fName
end

local FragmentPrivate = Common.private(function()
	return {
		ID = "",
		FullID = "",
		Name = "",
		Service = nil,
	}
end)

-- Reflection bindings
local FragmentReflection = {
	Spawn = Reflection("Spawn", function(self, xpcallHandler, asyncHandler)
		return Dispatcher.spawnFragment(self, xpcallHandler, asyncHandler)
	end, FRAGMENT_REFLECTION_TEST, "functiion?", "function?"),

	Await = Reflection("Await", function(self)
		if Dispatcher.isSelfAsyncCall(self) then ERROR.FRAGMENT_SELF_AWAIT(self) end
		return Dispatcher.slotAwait(self)
	end, FRAGMENT_REFLECTION_TEST),

	HandleAsync = Reflection("HandleAsync", function(self, asyncHandler)
		Dispatcher.slotHandleAsync(self, asyncHandler)
	end, FRAGMENT_REFLECTION_TEST, "function"),

	GetID = Reflection("GetID", function(self, full: boolean?)
		return full and FragmentPrivate(self).FullID or FragmentPrivate(self).ID
	end, FRAGMENT_REFLECTION_TEST, "boolean?"),

	GetName = Reflection("GetName", function(self)
		return FragmentPrivate(self).Name
	end, FRAGMENT_REFLECTION_TEST),

	Destroy = Reflection("Destroy", function(self)
		if not self[Common.FragmentHeader] then ERROR.BAD_SELF_CALL("Fragment.Destroy") end
		local privateObj = FragmentPrivate(self)

		local service = privateObj.Service
		local servicePrivate = Common.getPrivate(service)

		if servicePrivate.Fragments[privateObj.FullID] then
			Common.Fragments[privateObj.FullID] = nil
			servicePrivate.Fragments[privateObj.FullID] = nil

			Common.FlushNameStore(Common.FragmentNameStore, privateObj.Name, privateObj.FullID)
			Common.FlushNameStore(servicePrivate.FragmentNameStore, privateObj.Name, privateObj.FullID)
			Dispatcher.cleanFragmentState(self)

			local destroying = self.Destroying
			local fragRemoved = service.FragmentRemoved

			if destroying then task.spawn(destroying, self) end
			if fragRemoved then task.spawn(fragRemoved, service, self) end

			Common._eFragmentRemoved:Fire(self)
		end
	end, FRAGMENT_REFLECTION_TEST)
}

return function(params: {[string]: any}, service)
	local raw = Common.validateTable(params, "Fragment", FRAGMENT_PARAMS)
	local private = FragmentPrivate(raw)

	raw[Common.FragmentHeader] = true

	private.Name = params.Name or `CatworkFragment`
	private.Service = service

	Common.assignFragmentID(raw, service)
	raw.Name = nil
	
	raw.Spawn = FragmentReflection.Spawn
	raw.Await = FragmentReflection.Await
	raw.HandleAsync = FragmentReflection.HandleAsync
	raw.GetID = FragmentReflection.GetID
	raw.GetName = FragmentReflection.GetName
	raw.Destroy = FragmentReflection.Destroy

	if not Common.Flags.DONT_ASSIGN_OBJECT_MT then
		setmetatable(raw, {
			__tostring = function(self)
				local private = FragmentPrivate(self)
				return `CatworkFragment({private.Name}::{private.FullID})`
			end
		})
	end

	return raw
end