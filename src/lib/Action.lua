-- Action

local Dispatcher = require(script.Parent.Dispatcher)
local ERROR = require(script.Parent.Error)
local REFLECTION = require(script.Parent.Reflection)

-- AwaitHandler (not AsyncHandler, thats a little nicer)
local function handler<S, I..., O...>(action, s, f, ...)
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
		return responder(pcall(f, s, ...))
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

--[[
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
]]

local function STATE_ASSERT(object)
	local state = Dispatcher.getObjectState(object._sender)
	if not state then ERROR.ACTION_OBJECT_DESTROYED(object.Name) end
	if not state.Ready then ERROR.ACTION_OBJECT_NOT_READY(object.Name) end
end

return function(sender, actionName, callback)
	local Action = {
		Name = actionName,
		_signal = callback,
		_threads = {},
		_sender = sender,

		--[[
			Executes the action and yields the current thread until the action
			completes or is cancelled
		]]
		await = function(self, ...)
			STATE_ASSERT(self)
			return handler(self, self._sender, self._signal, ...)
		end,

		--[[
			Cancels all running actions, and resumes any waiting threads. Can be given
			a custom fail out message
		]]
		cancel = function(self, optMsg)
			for srcThread, coThread in self._threads do
				task.cancel(coThread)
				coroutine.resume(srcThread, false, "Cancelled", optMsg or "Thread was cancelled.")
			end

			self._threads = {}
		end,

		--[[
			Executes the action in a seperate thread, but does not yield the currently
			running thread. Result of action is passed into the callback
		]]
		handleAsync = function(
			self,
			cb,
			...
		)

			task.spawn(function(self, cb, ...)
				cb(self:await(...))
			end, self, cb, ...)
		end,
	}

	return Action
end