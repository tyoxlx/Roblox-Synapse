local HttpService = game:GetService("HttpService")
local Dispatcher = require(script.Parent.Dispatcher)
local Common = require(script.Parent.Common)
local ERROR = require(script.Parent.Error)

local FRAGMENT_PARAMS = {
	Name = "string?",
	Destroying = "function?",
	Init = "function?"
}

return function(params: {[string]: any}, service)
	local raw = Common.validateTable(params, "Fragment", FRAGMENT_PARAMS)
	raw[Common.FragmentHeader] = true

	raw.ID = HttpService:GenerateGUID(false)
	raw.Name = params.Name or `CatworkFragment`
	raw.Service = service

	function raw:Spawn(asyncHandler)
		if not self[Common.FragmentHeader] then ERROR.BAD_SELF_CALL("Fragment.Spawn") end
		if asyncHandler and type(asyncHandler) ~= "function" then ERROR.BAD_ARG(2, "Fragment.Spawn", "function?", typeof(asyncHandler)) end
		
		return Dispatcher.spawnFragment(self, asyncHandler)
	end

	function raw:Await()
		if not self[Common.FragmentHeader] then ERROR.BAD_SELF_CALL("Fragment.Await") end
		return Dispatcher.slotAwait(self)
	end

	function raw:HandleAsync(asyncHandler)
		if not self[Common.FragmentHeader] then ERROR.BAD_SELF_CALL("Fragment.HandleAsync") end
		if asyncHandler and type(asyncHandler) ~= "function" then ERROR.BAD_ARG(2, "Fragment.HandleAsync", "function?", typeof(asyncHandler)) end	

		Dispatcher.slotHandleAsync(self, asyncHandler)
	end

	function raw:Destroy()
		if not self[Common.FragmentHeader] then ERROR.BAD_SELF_CALL("Fragment.Destroy") end

		local service = self.Service
		if service.Fragments[self.ID] then
			Common.Fragments[self.ID] = nil
			service.Fragments[self.ID] = nil

			Common.FlushNameStore(Common.FragmentNameStore, self.Name, self.ID)
			Common.FlushNameStore(service.FragmentNameStore, self.Name, self.ID)
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
				return `CatworkFragment({self.Name}::{self.ID})`
			end
		})
	end

	return raw
end