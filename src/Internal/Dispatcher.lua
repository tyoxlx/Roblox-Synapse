-- better to handle this in its own module than try to weave it into Catwork
-- handles dispatching of objects

local ERROR = require(script.Parent.Error)

local Dispatcher = {}
local objectDispatchState = {}

local function safeAsyncHandler(err)
	ERROR.DISPATCHER_SPAWN_ERR(ERROR.traceback(err))
	return err
end

local function doServiceLoopForObject(object, service, state)
	while not state.Destroyed do
		local dt = task.wait()
		if state.Destroyed then break end -- fixes a bug where loops continue an extra tick after destruction
		service:Updating(object, dt)
	end
end

function Dispatcher.getObjectState(o)
	return objectDispatchState[o]
end

local function getObjectStateError(o)
	local state = Dispatcher.getObjectState(o)
	
	if not state then
		ERROR.DISPATCHER_DESTROYED_OBJECT(o)
	end

	return state
end

local function free(state, ok, err, o, service)
	state.Ready = true
	state.IsOK = ok
	state.ErrMsg = err

	for _, v in state.Dispatchers do
		task.spawn(v, ok, err)
	end

	for _, v in state.HeldThreads do
		task.spawn(v, ok, err)
	end
end

local function timeoutTracker(o, state): thread?
	if state.TimeoutDisabled then return end

	return task.spawn(function(self)
		task.wait(5)
		ERROR.DISPATCHER_TIMEOUT(self)
	end, o)
end

local function runObjectAction(
	o,
	spawnSignal,
	service,
	state
)
	state.Spawned = true
	state.Thread = coroutine.running()

	state.TimeoutThread = timeoutTracker(o, state)
	local ok, err = xpcall(spawnSignal, state.XPC, service, o)
	if state.TimeoutThread then coroutine.close(state.TimeoutThread) end
	state.TimeoutThread = nil

	free(state, ok, err, o, service)

	if service.Updating and o.Update then
		task.spawn(doServiceLoopForObject, o, service, state)
	end

	return ok, err
end

local function killThread(t: thread)
	local co = coroutine.running()
	if co ~= t then
		coroutine.close(t)
	else
		task.defer(coroutine.close, t)
		coroutine.yield()
	end
end

function Dispatcher.clearRunState(o)
	local state = Dispatcher.getObjectState(o)

	-- already destroyed checks
	if not state then return end
	if not Dispatcher.isSelfAsyncCall(o) then end

	-- not destroyed, kill running thread then free as false
	killThread(state.Thread)
	if state.TimeoutThread then killThread(state.TimeoutThread) end

	free(state, false, "Object has been destroyed before it could return")
end

local function spawnObject(object, service, state, asyncMode)
	local spawnSignal = service.Spawning

	if asyncMode then
		object:HandleAsync(asyncMode)
	end

	task.spawn(runObjectAction, object, spawnSignal, service, state)

	if not asyncMode then
		return object:Await()
	end

	return nil
end

function Dispatcher.spawnObject(o, fPrivate, xpcallHandler, asyncHandler)
	local state = getObjectStateError(o)
	state.TimeoutDisabled = fPrivate.TimeoutDisabled
	
	-- basically new logic for Spawn
	if state.Spawned then
		ERROR:DISPATCHER_ALREADY_SPAWNED(o)
	end

	if xpcallHandler then
		state.XPC = xpcallHandler
	end

	return spawnObject(o, fPrivate.Service, state, asyncHandler)
end

function Dispatcher.cleanObjectState(o)
	local state = Dispatcher.getObjectState(o)

	if not state then return end
	state.Destroyed = true
	objectDispatchState[o] = nil
end

function Dispatcher.slotAwait(o)
	local state = Dispatcher.getObjectState(o)
	if not state then return false, "The object was destroyed" end

	if state.ErrMsg then
		return false, state.ErrMsg
	elseif state.IsOK then
		return true
	end

	table.insert(state.HeldThreads, coroutine.running())
	return coroutine.yield()
end

function Dispatcher.slotHandleAsync(o, asyncHandler)
	local state = Dispatcher.getObjectState(o)
	if not state then task.spawn(asyncHandler, false, "The object was destroyed") end

	if state.ErrMsg then
		asyncHandler(false, state.ErrMsg)
	elseif state.IsOK then
		asyncHandler(true)
	else
		table.insert(state.Dispatchers, asyncHandler)
	end
end

function Dispatcher.isSelfAsyncCall(o)
	-- blocks self:Await calls while Init is running
	local state = Dispatcher.getObjectState(o)
	if not state then return false end -- object is destroyed, will never self-await here.

	local co = coroutine.running()
	
	if state.Spawned and co == state.Thread then
		return not state.Ready
	end
	
	return false
end

function Dispatcher.initObjectState(o)
	if objectDispatchState[o] then return objectDispatchState[o] end

	local state = {
		Spawned = false,
		IsOK = false,
		ErrMsg = nil,

		Thread = nil,
		TimeoutThread = nil,

		Ready = false,
		Destroyed = false,
		XPC = safeAsyncHandler,
		TimeoutDisabled = false,

		HeldThreads = {},
		Dispatchers = {}
	}
	objectDispatchState[o] = state

	return state
end

return Dispatcher