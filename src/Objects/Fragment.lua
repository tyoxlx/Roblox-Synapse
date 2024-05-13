local Dispatcher = require(script.Parent.Parent.Internal.Dispatcher)
local Common = require(script.Parent.Parent.Common)
local ERROR = require(script.Parent.Parent.Internal.Error)
local REFLECTION = require(script.Parent.Parent.Types.Reflection)

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

return function(params: {[string]: any}, service)
	local raw = Common.validateTable(params, "Fragment", FRAGMENT_PARAMS)
	local private = FragmentPrivate(raw)

	raw[Common.FragmentHeader] = true

	private.Name = params.Name or `CatworkFragment`
	private.Service = service

	Common.assignFragmentID(raw, service)
	raw.Name = nil
	
	function raw:Spawn(xpcallHandler, asyncHandler)
		if Common.AnalysisMode then return end

		REFLECTION.CUSTOM(1, "Fragment.Spawn", self, FRAGMENT_REFLECTION_TEST)
		REFLECTION.ARG(2, "Fragment.Spawn", REFLECTION.OPT_FUNCTION, xpcallHandler)
		REFLECTION.ARG(3, "Fragment.Spawn", REFLECTION.OPT_FUNCTION, asyncHandler)

		return Dispatcher.spawnFragment(self, xpcallHandler, asyncHandler)
	end
	
	function raw:Await()
		REFLECTION.CUSTOM(1, "Fragment.Await", self, FRAGMENT_REFLECTION_TEST)
		
		if Dispatcher.isSelfAsyncCall(self) then ERROR.FRAGMENT_SELF_AWAIT(self) end
		return Dispatcher.slotAwait(self)
	end
	
	function raw:HandleAsync(asyncHandler)
		REFLECTION.CUSTOM(1, "Fragment.HandleAsync", self, FRAGMENT_REFLECTION_TEST)
		REFLECTION.ARG(2, "Fragment.HandleAsync", REFLECTION.FUNCTION, asyncHandler)
		
		Dispatcher.slotHandleAsync(self, asyncHandler)
	end
	
	function raw:GetID(full: boolean?)
		REFLECTION.CUSTOM(1, "Fragment.GetID", self, FRAGMENT_REFLECTION_TEST)
		REFLECTION.ARG(2, "Fragment.GetID", REFLECTION.OPT_BOOLEAN, full)		
		
		return full and FragmentPrivate(self).FullID or FragmentPrivate(self).ID
	end
	
	function raw:GetName()
		REFLECTION.CUSTOM(1, "Fragment.GetName", self, FRAGMENT_REFLECTION_TEST)
		
		return FragmentPrivate(self).Name
	end

	function raw:Destroy()
		REFLECTION.CUSTOM(1, "Fragment.Destroy", self, FRAGMENT_REFLECTION_TEST)
		
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
	end

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