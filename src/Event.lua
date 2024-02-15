export type Signal<A...> = {
	Connect: (Signal<A...>, func: (A...) -> ()) -> () -> (),
	ConnectedFunctions: {[(A...) -> ()]: boolean},
	Wait: (Signal<A...>) -> A...,
	WaitingThreads: {thread}
}

export type Event<A...> = {
	Signal: Signal<A...>,
	Fire: (Event<A...>, A...) -> (),
}

local function Signal<A...>(): Signal<A...>
	local Signal = {}

	Signal.ConnectedFunctions = {}
	Signal.WaitingThreads = {}

	--[[
		Connects to the event and receieves signals asynchronously when it fires

		Returns a function for disconnecting the event
	]]
	function Signal.Connect(self: Signal<A...>, func: (A...) -> ()): () -> ()
		self.ConnectedFunctions[func] = true

		return function()
			self.ConnectedFunctions[func] = nil
		end
	end

	--[[
		Yiels the running thread until the event fires
	]]
	function Signal.Wait(self: Signal<A...>): A...
		local co = coroutine.running()
		table.insert(self.WaitingThreads, co)
		return coroutine.yield(co)
	end

	return Signal
end

--[[
	Creates an `RBXScriptSignal` like object

	### Code Example
	```lua
	local PartTouchedEvent: Event<Part> = Event()
	return PartTouchedEvent.Signal
	```
]]
return function<A...>(): Event<A...>
	local Event = {}

	--[[
		Base object for connections
	]]--
	Event.Signal = Signal() :: Signal<A...>

	--[[
		Fires the event

		### Code Example
		```lua
		local MeowSignal: Event<string> = Event()

		MeowSignal.Signal:Connect(print)
		MeowSignal:Fire("cat") --> "cat"
		```
	]]
	function Event.Fire(self: Event<A...>, ...: A...)
		local sig = self.Signal
		-- first, handoff callbacks
		-- then release threads
		-- do not rely on this order as it's an implementation detail
		for callback: (A...) -> () in sig.ConnectedFunctions do
			task.spawn(callback, ...)
		end

		for _, thread in sig.WaitingThreads do
			coroutine.resume(thread, ...)
		end

		sig.WaitingThreads = {}
	end

	return Event
end