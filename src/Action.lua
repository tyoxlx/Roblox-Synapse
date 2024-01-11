-- metatablecatgames 2024 - Part of Catwork, all rights reserved
-- extracted from Tabby; https://github.com/metatablecatgames/tabby

--!strict
-- Action

export type Action<I..., O...> = {
	_signal: (I...) -> O...,
	_threads: {[thread]: thread},
	Name: string,
	await: (Action<I..., O...>, I...) -> (boolean, O...),
	cancel: (Action<I..., O...>, optmsg: string?) -> (),

	handleAsync: (Action<I..., O...>, func: (boolean, O...) -> (), I...) -> ()
}
type ErrorType = "LuaError"|"Cancelled"
-- AwaitHandler (not AsyncHandler, thats a little nicer)
local function handler<I..., O...>(action: Action<I..., O...>, f, ...)
	local srcThread = coroutine.running()

	local coThread: thread; coThread = coroutine.create(function(...)
		local function responder(ok, ...)
			-- we can use the state of srcThread to check where it is in terms of execution
			-- normal = hasn't yielded yet
			-- suspended = yielded
			action._threads[srcThread] = nil
			if coroutine.status(srcThread) == "suspended" then
				if not ok then
					coroutine.resume(srcThread, false, "LuaError", ...)
				else
					coroutine.resume(srcThread, true, ...)
				end

				return
			end

			if not ok then
				return false, "LuaError", ...
			end
			return true, ...
		end

		action._threads[srcThread] = coThread
		return responder(pcall(f, ...))
	end)

	local function executeThread(ok, ...)
		if coroutine.status(coThread) == "dead" then
			if not ok then
				-- thread failed to spawn, very likely an internal error
				action._threads[srcThread] = nil
				local msg = (...)
				return false, "LuaError", msg
			end

			-- thread completed in first resumption
			return ...
		end

		-- thread did not resume, wait for response
		return coroutine.yield()
	end

	return executeThread(coroutine.resume(coThread, ...))
end

return function<I..., O...>(actionName: string, callback: (I...) -> O...): Action<I..., O...>
	--[=[
		@class Action

		Action is a parallel execution class, it can be used to run and manage
		multiple threads in sequence.

		### Code Example
		```lua
		local HttpRequest = Action("HttpRequest", function(req)
			-- HttpResult is a Result object from Result
			return HttpResult:FromPcall(HttpService.RequestAsync, HttpResult, req)
		end)

		HttpRequest:await {
			Url = "https://www.example.com",
			Method = "GET"
		}
		```
	]=]--
	local Action = {}

	--[=[
		@prop Name string
		@within Action
		@readonly

		The name assigned to the action at construction.
	]=]--
	Action.Name = actionName

	--[=[
		@prop _signal (I...) -> O...
		@within Action
		@readonly
		@private
		
		The internal callback that is used when running the action.
	]=]--
	Action._signal = callback

		--[=[
		@prop _threads {[thread] = thread}
		@within Action
		@readonly
		@private
		
		Threads are being paused to wait for a response from the internal function.
	]=]--
	Action._threads = {}

	--[=[
		@method await
		@within Action
		@param arguments I... -- A variadic value that is based on the provided callback
		@return boolean -- Indicates whether the function was successful
		@return O... -- A variadic return if the function worked, returns a string with the Lua error if not

		Executes the action and yields the current thread until the action
		completes or is cancelled
	]=]--
	function Action.await(
		self: Action<I..., O...>,
		...: I...
	): (boolean, O...)
		return handler(self, self._signal, ...)
	end

	--[=[
		@method cancel
		@within Action
		@param optMsg string -- An optional message to pass when cancelling

		Cancels all running actions, and resumes any waiting threads. Can be given
		a custom fail out message. This function will cause all waiting threads and handlers to return `false, optMsg` or
		if optMsg is omitted, `false, Thread was cancelled.`
	]=]--
	function Action.cancel(
		self: Action<I..., O...>,
		optMsg: string?
	)
		for srcThread, coThread in self._threads do
			task.cancel(coThread)
			coroutine.resume(srcThread, false, "Cancelled", optMsg or "Thread was cancelled.")
		end

		self._threads = {}
	end

		--[=[
		@method handleAsync
		@within Action
		@param cb (boolean, O...) -> () -- A handler callback that consumes the result of the async function
		@param ... I... -- A variadic value that is based on the provided callback

		Runs the action in an asynchronous thread, this function runs when a value is available from the underlying async
		function.
	]=]--
	function Action.handleAsync(
		self: Action<I..., O...>,
		cb: (boolean, O...) -> (),
		...: I...
	)
		task.spawn(function(...)
			cb(self:await(...))
		end, ...)
	end

	table.freeze(Action)
	return Action
end