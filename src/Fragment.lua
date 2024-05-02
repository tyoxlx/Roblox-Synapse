local Dispatcher = require(script.Parent.lib.Dispatcher)
local Common = require(script.Parent.lib.Common)
local ERROR = require(script.Parent.lib.Error)

local FRAGMENT_PARAMS = {
	Name = "string?",
	ID = "string?",
	Destroying = "function?",
	Init = "function?"
}

local FragmentPrivate = Common.private(function()
	return {
		ID = "",
		FullID = "",
		Name = "",
		Service = nil,
		Template = nil
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
		if not self[Common.FragmentHeader] then ERROR.BAD_SELF_CALL("Fragment.Spawn") end
		if xpcallHandler and type(xpcallHandler) ~= "function" then ERROR.BAD_ARG(2, "Fragment.Spawn", "function?", typeof(xpcallHandler)) end
		if asyncHandler and type(asyncHandler) ~= "function" then ERROR.BAD_ARG(3, "Fragment.Spawn", "function?", typeof(asyncHandler)) end
		
		return Dispatcher.spawnFragment(self, xpcallHandler, asyncHandler)
	end

	function raw:Await()
		if not self[Common.FragmentHeader] then ERROR.BAD_SELF_CALL("Fragment.Await") end
		if Dispatcher.isSelfAsyncCall(self) then ERROR.FRAGMENT_SELF_AWAIT(self) end
		return Dispatcher.slotAwait(self)
	end

	function raw:HandleAsync(asyncHandler)
		if not self[Common.FragmentHeader] then ERROR.BAD_SELF_CALL("Fragment.HandleAsync") end
		if asyncHandler and type(asyncHandler) ~= "function" then ERROR.BAD_ARG(2, "Fragment.HandleAsync", "function?", typeof(asyncHandler)) end	

		Dispatcher.slotHandleAsync(self, asyncHandler)
	end
	
	function raw:GetID(full: boolean?)
		if not self[Common.FragmentHeader] then ERROR.BAD_SELF_CALL("Fragment.GetID") end
		if full ~= nil and type(full) ~= "boolean" then ERROR.BAD_ARG(2, "Fragment.GetID", "boolean?", typeof(full)) end
		
		return full and FragmentPrivate(self).FullID or FragmentPrivate(self).ID
	end
	
	function raw:GetName()
		return FragmentPrivate(self).Name
	end

	function raw:Destroy()
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
				return `CatworkFragment({self.Name}::{self.FullID})`
			end
		})
	end

	return raw
end