local HttpService = game:GetService("HttpService")
local Dispatcher = require(script.Parent.Dispatcher)
local Common = require(script.Parent.Common)

--[=[
	@class Fragment

	A Fragment represents a spawnable chunk of code that can be consumed and
	operated upon by Services.

	:::tip Fragments are not frozen
	Unlike most objects created by Catwork, Fragments are not frozen upon
	creation, this is done for support with Templates that may modify the shape
	of a Fragment at runtime or creation.
]=]--
return function(params: {[string]: any}, service, mutator)
	--[=[
		@prop ID string
		@within Fragment

		The globally unique identifier for this specific Fragment.
	]=]--
	params.ID = HttpService:GenerateGUID(false)

	--[=[
		@prop Name string
		@within Fragment

		A non-unique identifier for the Fragment. Multiple fragments can have the
		same name.
	]=]--
	params.Name = params.Name or `CatworkFragment`

	--[=[
		@prop Service Service
		@within Fragment

		The Service this Fragment was created with.
	]=]--
	params.Service = service

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
	params.Spawn = Dispatcher.spawnFragment

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
	params.Await = Dispatcher.slotAwait

	--[=[
		@method HandleAsync
		@within Fragment
		@param asyncHandler (boolean, string) -> ()? -- An optional response handler.

		Queues a callback asynchronously until the Fragment finishes spawning or
		errors. The callback will run immediately if this has already happened.
	]=]--
	params.HandleAsync = Dispatcher.slotHandleAsync

	--[=[
		@method Destroy
		@within Fragment

		Destroys the Fragment and removes it from the Service.
	]=]--
	function params:Destroy()
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

	if not Common.DONT_ASSIGN_OBJECT_MT then
		setmetatable(params, {
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

	if mutator then mutator(params) end
	return params
end