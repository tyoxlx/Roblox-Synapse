-- This module mostly exists for typing, as catwork's logic is defined implicitly
-- as the default Service behaviour

local Service = require("./Service")
local meta = require("../meta").export

local native = Service({
	[meta("EnableClasses")] = true,
	Name = "catwork",
})

local nativeAPI = {}

function nativeAPI.Object(params) return native:Object(params) end

function nativeAPI.GetClassLike(name, createFn)
	local template = native:Class(name, createFn)

	return function(params) return native:CreateObjectFromClass(template, params) end
end

return nativeAPI
