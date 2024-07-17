if not game then
	script = require("./RelativeString")
	task = require("@lune/task")
end

local Class = require(script.Parent.Class)
local Dispatcher = require(script.Parent.Dispatcher)
local Object = require(script.Parent.Object)
local Common = require(script.Parent.Common)
local ERROR = require(script.Parent.Error)
local REFLECTION = require(script.Parent.Reflection)
local Metakeys = require(script.Parent.Metakeys)

local ENABLE_CLASSES_METAKEY = Metakeys.export "EnableClasses"

local SERVICE_PARAMS = {
	Name = "string",
	StartService = "function?",
	Spawning = "function?",
	CreateObject = "function?",
	ObjectAdded = "function?",
	ObjectRemoved = "function?",
	ClassAdded = "function?",
	Updating = "function?"
}

local function SERVICE_REFLECTION_TEST(service, fName)
	return service and service[Common.ServiceHeader], "BAD_SELF_CALL", fName
end

local function CLASS_REFLECTION_ASSERT(class, fName, idx)
	-- string|Class
	local oType = typeof(class)
	return class and class[Common.ClassHeader], "BAD_OBJECT", idx, fName, oType, "Class"
end

local function createObjectForService(params, service)
	local o = Object(params, service)

	if not Common.AnalysisMode then
		Dispatcher.initObjectState(o)
		local objAdded = service.ObjectAdded
		if objAdded then task.spawn(objAdded, service, o) end
	end

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

		if class.Service ~= self then
			ERROR.BAD_CLASS(class.Name, self.Name)
		end
		
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

	if not raw.Spawning then
		function raw:Spawning(object)
			local i = object.Init
			if not i then return end
			i(object)
		end
	end

	if not raw.ObjectAdded then
		function raw:ObjectAdded(object)
			object:Spawn()
		end
	end

	if enableUpdateLoop then
		if not raw.Updating then
			function raw:Updating(object, dt)
				return object:Update(dt)
			end
		end
	elseif raw.Updating then
		ERROR.SERVICE_UPDATING_DISABLED(raw.Name)
		raw.Updating = nil
	end

	if not Common.Flags.DONT_ASSIGN_OBJECT_MT then
		setmetatable(raw, {
			__tostring = function(self)
				return `CatworkService({self.Name}; Classes: {self[ENABLE_CLASSES_METAKEY]})`
			end,
		})
	end
	
	table.freeze(raw)
	return raw
end