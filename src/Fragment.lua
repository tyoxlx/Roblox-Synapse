local HttpService = game:GetService("HttpService")
local Dispatcher = require(script.Parent.Dispatcher)
local Common = require(script.Parent.Common)
local ERROR = require(script.Parent.Error)

--[=[
	@class Fragment

	A Fragment represents a spawnable chunk of code that can be consumed and
	operated upon by Services.

	:::tip Fragments are not frozen
	Unlike most objects created by Catwork, Fragments are not frozen upon
	creation, this is done for support with Templates that may modify the shape
	of a Fragment at runtime or creation.
]=]--
return function(params: {[string]: any}, service)
	local raw = table.clone(params)
	raw[Common.FragmentHeader] = true

	--[=[
		@prop ID string
		@within Fragment

		The globally unique identifier for this specific Fragment.
	]=]--
	raw.ID = HttpService:GenerateGUID(false)

	--[=[
		@prop Name string
		@within Fragment

		A non-unique identifier for the Fragment. Multiple fragments can have the
		same name.
	]=]--
	raw.Name = params.Name or `CatworkFragment`

	--[=[
		@prop Service Service
		@within Fragment

		The Service this Fragment was created with.
	]=]--
	raw.Service = service

	--[=[
		@method Spawn
		@within Fragment
		@param asyncHandler (boolean, string) -> ()? -- An optional response handler.
		@return boolean? -- If the fragment spawned successfully.
		@return string? -- An error emitted by a `pcall` if the spawn failed.
		@yields

		Spawns a Fragment through a Service using `Service.Spawning`, if an async
		handler is defined, this method runs asynchronously and **does not return**, 
		otherwise, this method yields and returns the result of the `Init` callback.

		:::danger Fragment.Init may only run once
		Fragments can only be spawned once for safety reasons. Place your Fragment
		in a Template if you intend to spawn multiple. If you need to capture a
		response from the spawn, use `Fragment:Await` or `Fragment:HandleAsync`
		instead, as this method is intended primarily for Services.
	]=]--
	function raw:Spawn(asyncHandler)
		if not self[Common.FragmentHeader] then ERROR.BAD_SELF_CALL("Fragment.Spawn") end
		if asyncHandler and type(asyncHandler) ~= "function" then ERROR.BAD_ARG(2, "Fragment.Spawn", "function?", typeof(asyncHandler)) end
		
		return Dispatcher.spawnFragment(self, asyncHandler)
	end

	--[=[
		@method Await
		@within Fragment
		@return boolean -- If the fragment spawned successfully.
		@return string? -- An error emitted by a `pcall` if the spawn failed.
		@yields

		Yields against the Fragment until it finishes spawning or errors. This
		method will not yield if this has already happened, and will return either
		`true`, or `false` and a cached error message.
	]=]--
	function raw:Await()
		if not self[Common.FragmentHeader] then ERROR.BAD_SELF_CALL("Fragment.Await") end
		return Dispatcher.slotAwait(self)
	end

	--[=[
		@method HandleAsync
		@within Fragment
		@param asyncHandler (boolean, string) -> ()? -- An optional response handler.

		Queues a callback asynchronously until the Fragment finishes spawning or
		errors. The callback will run immediately if this has already happened.
	]=]--
	function raw:HandleAsync(asyncHandler)
		if not self[Common.FragmentHeader] then ERROR.BAD_SELF_CALL("Fragment.HandleAsync") end
		if asyncHandler and type(asyncHandler) ~= "function" then ERROR.BAD_ARG(2, "Fragment.HandleAsync", "function?", typeof(asyncHandler)) end	

		Dispatcher.slotHandleAsync(self, asyncHandler)
	end

	--[=[
		@method Destroy
		@within Fragment

		Destroys the Fragment and removes it from the Service.
	]=]--
	function raw:Destroy()
		if not self[Common.FragmentHeader] then ERROR.BAD_SELF_CALL("Fragment.Destroy") end

		local service = self.Service
		if service.Fragments[self.ID] then
			Common.Fragments[self.ID] = nil
			service.Fragments[self.ID] = nil

			Common.FlushNameStore(Common.FragmentNameStore, self.Name, self.ID)
			Common.FlushNameStore(service.FragmentNameStore, self.Name, self.ID)

			local destroying = self.Destroying
			local fragRemoved = service.FragmentRemoved

			if destroying then task.spawn(destroying, self) end
			if fragRemoved then task.spawn(fragRemoved, service, self) end
		end
	end

	if not Common.Flags.DONT_ASSIGN_OBJECT_MT then
		setmetatable(raw, {
			__tostring = function(self)
				return `CatworkFragment({self.Name}::{self.ID})`
			end
		})
	end

	--[=[
		@method Init
		@within Fragment

		Invoked when the Fragment is being spawned. This method should be defined
		when you create the Fragment using `Catwork.Fragment` or `Service.Fragment`.
	]=]--
	--[=[
		@method Destroying
		@within Fragment

		Invoked as the Fragment is being destroyed, allows you to define cleanup
		logic.
	]=]--

	return raw
end