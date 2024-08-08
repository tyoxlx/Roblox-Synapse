if not task then task = require("@lune/task") end

local Class = require("./Class")
local Common = require("./Common")
local Dispatcher = require("./Dispatcher")
local ERROR = require("./Error")
local Metakeys = require("../meta")
local Object = require("./Object")
local REFLECTION = require("./Reflection")

local ENABLE_CLASSES_METAKEY = Metakeys.export("EnableClasses")

local OBJECT_PRIVATE = {}
local SERVICE_PARAMS = {
	Name = "string",
	StartService = "function?",
	Spawning = "function?",
	CreateObject = "function?",
	ObjectAdded = "function?",
	ObjectRemoved = "function?",
	ClassAdded = "function?",
	Updating = "function?",
}

local function SERVICE_REFLECTION_TEST(service, fName)
	return service and service[Common.ServiceHeader], "BAD_SELF_CALL", fName
end

local function CLASS_REFLECTION_ASSERT(class, fName, idx)
	-- string|Class
	local oType = typeof(class)
	return class and class[Common.ClassHeader], "BAD_OBJECT", idx, fName, oType, "Class"
end

local function OBJECT_REFLECTION_TEST(object, fName, idx)
	local oType = typeof(object)
	return object and object[Common.ObjectHeader], "BAD_OBJECT", idx, fName, oType, "Object"
end

local function createObjectForService(params, service)
	local o = Object(params, service, OBJECT_PRIVATE)

	Dispatcher.initObjectState(o)
	local objAdded = service.ObjectAdded
	if objAdded then task.spawn(objAdded, service, o) end

	return o
end

-- Constructor
return function(params)
	local raw, metakeys = Common.validateTable(params, "Service", SERVICE_PARAMS)

	local enableClasses = (params.ClassAdded ~= nil) or (metakeys.EnableClasses or false)

	raw[Common.ServiceHeader] = true
	raw[ENABLE_CLASSES_METAKEY] = enableClasses

	local enableUpdateLoop = if metakeys.EnableUpdating ~= nil then metakeys.EnableUpdating else true

	function raw:Class(name, createObject)
		REFLECTION.CUSTOM(1, "Service.Class", self, SERVICE_REFLECTION_TEST)
		REFLECTION.ARG(2, "Service.Class", REFLECTION.STRING, name)
		REFLECTION.ARG(3, "Service.Class", REFLECTION.FUNCTION, createObject)

		return Class(self, name, createObject)
	end

	function raw:CreateObjectFromClass(class, initParams)
		REFLECTION.CUSTOM(1, "Service.CreateObjectFromClass", self, SERVICE_REFLECTION_TEST)
		REFLECTION.CUSTOM(2, "Service.CreateObjectFromClass", class, CLASS_REFLECTION_ASSERT)
		REFLECTION.ARG(3, "Service.CreateObjectFromClass", REFLECTION.OPT_TABLE, initParams)
		if not self[ENABLE_CLASSES_METAKEY] then ERROR.SERVICE_NO_CLASSES(self.Name) end

		if class.Service ~= self then ERROR.BAD_CLASS(class.Name, self.Name) end

		local params = initParams or {}
		params.Name = params.Name or class.Name
		class.CreateObject(params)
		return self:Object(params)
	end

	function raw:Object(params)
		REFLECTION.CUSTOM(1, "Service.Object", self, SERVICE_REFLECTION_TEST)
		REFLECTION.ARG(2, "Service.Object", REFLECTION.TABLE, params)

		if self.CreateObject then self:CreateObject(params) end
		return createObjectForService(params, self)
	end

	function raw:SpawnObject(obj, xpcallHandler, asyncHandler)
		REFLECTION.CUSTOM(1, "Service.SpawnObject", self, SERVICE_REFLECTION_TEST)
		REFLECTION.CUSTOM(2, "Service.SpawnObject", obj, OBJECT_REFLECTION_TEST)
		REFLECTION.ARG(3, "Service.SpawnObject", REFLECTION.OPT_FUNCTION, xpcallHandler)
		REFLECTION.ARG(4, "Service.SpawnObject", REFLECTION.OPT_FUNCTION, asyncHandler)

		return Dispatcher.spawnObject(obj, self, OBJECT_PRIVATE[obj], xpcallHandler, asyncHandler)
	end

	if not raw.Spawning then
		function raw:Spawning(object)
			local i = object.Init
			if not i then return end
			i(object)
		end
	end

	if not raw.ObjectAdded then
		function raw:ObjectAdded(object) self:SpawnObject(object) end
	end

	if enableUpdateLoop then
		if not raw.Updating then
			function raw:Updating(object, dt) return object:Update(dt) end
		end
	elseif raw.Updating then
		ERROR.SERVICE_UPDATING_DISABLED(raw.Name)
		raw.Updating = nil
	end

	if not Common.Flags.DONT_ASSIGN_OBJECT_MT then
		setmetatable(raw, {
			__tostring = function(self) return `CatworkService({self.Name}; Classes: {self[ENABLE_CLASSES_METAKEY]})` end,
		})
	end

	table.freeze(raw)
	return raw
end
