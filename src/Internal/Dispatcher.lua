-- better to handle this in its own module than try to weave it into Catwork
-- handles dispatching of Fragments

local Common = require(script.Parent.Parent.Common)
local ERROR = require(script.Parent.Error)

local Dispatcher = {}
local fragmentDispatchState = {}

local function safeAsyncHandler(err)
	ERROR.DISPATCHER_SPAWN_ERR(ERROR.traceback(err))
	return err
end

local function getFragmentState(f)
	local state = fragmentDispatchState[f]
	if not state then
		state = {
			Spawned = false,
			IsOK = false,
			ErrMsg = nil,
			Thread = nil,
			Ready = false,
			XPC = safeAsyncHandler,
			TimeoutDisabled = false,

			HeldThreads = {},
			Dispatchers = {}
		}

		fragmentDispatchState[f] = state
	end
	
	return state
end

local function timeoutTracker(f, state): thread?
	if state.TimeoutDisabled then return end
	
	return task.spawn(function(self)
		task.wait(60)
		ERROR.DISPATCHER_TIMEOUT(self)
	end, f)
end

local function runFragmentAction(
	f,
	spawnSignal,
	service,
	state
)
	state.Spawned = true
	state.Thread = coroutine.running()

	local thread = timeoutTracker(f, state)
	local ok, err = xpcall(spawnSignal, state.XPC, service, f)
	if thread then coroutine.close(thread) end
	
	state.Ready = true
	state.IsOK = ok
	state.ErrMsg = err

	for _, v in state.Dispatchers do
		task.spawn(v, ok, err)
	end

	for _, v in state.HeldThreads do
		task.spawn(v, ok, err)
	end
	
	return ok, err
end

local function spawnFragment(self, service, state, asyncMode)
	local spawnSignal = service.Spawning

	if asyncMode then
		self:HandleAsync(asyncMode)
	end

	task.spawn(runFragmentAction, self, spawnSignal, service, state)

	if not asyncMode then
		return self:Await()
	end

	return nil
end

function Dispatcher.spawnFragment(f, xpcallHandler, asyncHandler)
	local fPrivate = Common.getPrivate(f)
	if not Common.Fragments[fPrivate.FullID] then
		-- the fragment does not exist, most likely because it was destroyed
		ERROR:DISPATCHER_DESTROYED_FRAGMENT(f)
	end
	
	local state = getFragmentState(f)
	state.TimeoutDisabled = fPrivate.TimeoutDisabled
	
	-- basically new logic for Spawn
	if state.Spawned then
		ERROR:DISPATCHER_ALREADY_SPAWNED(f)
	end

	if xpcallHandler then
		state.XPC = xpcallHandler
	end

	return spawnFragment(f, fPrivate.Service, state, asyncHandler)
end

function Dispatcher.cleanFragmentState(f)
	fragmentDispatchState[f] = nil
end

function Dispatcher.slotAwait(f)
	local state = getFragmentState(f)

	if state.ErrMsg then
		return false, state.ErrMsg
	elseif state.IsOk then
		return true
	end

	table.insert(state.HeldThreads, coroutine.running())
	return coroutine.yield()
end

function Dispatcher.slotHandleAsync(f, asyncHandler)
	local state = getFragmentState(f)

	if state.ErrMsg then
		asyncHandler(false, state.ErrMsg)
	elseif state.IsOk then
		asyncHandler(true)
	else
		table.insert(state.Dispatchers, asyncHandler)
	end
end

function Dispatcher.isSelfAsyncCall(f)
	-- blocks self:Await calls while Init is running
	local state = getFragmentState(f)
	local co = coroutine.running()
	
	if state.Spawned and co == state.Thread then
		return not state.Ready
	end
	
	return false
end

return Dispatcher