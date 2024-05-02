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

	function Signal.Connect(self: Signal<A...>, func: (A...) -> ()): () -> ()
		self.ConnectedFunctions[func] = true

		return function()
			self.ConnectedFunctions[func] = nil
		end
	end

	function Signal.Wait(self: Signal<A...>): A...
		local co = coroutine.running()
		table.insert(self.WaitingThreads, co)
		return coroutine.yield(co)
	end

	return Signal
end

return function<A...>(): Event<A...>
	local Event = {}
	Event.Signal = Signal() :: Signal<A...>

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