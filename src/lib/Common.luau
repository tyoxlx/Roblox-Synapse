local ERROR = require("./Error")
local Metakeys = require("../meta")
local Types = require("./Types")

local HttpService = if game
	then game:GetService("HttpService")
	else {
		GenerateGUID = function(self, withBrackets)
			local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
			if withBrackets then template = `\{{template}\}` end

			return string.gsub(template, "[xy]", function(c)
				local v = (c == "x") and math.random(0, 15) or math.random(8, 11)
				return string.format("%x", v)
			end)
		end,
	}

local VERSION = "0.5.0"
local GUID_PATTERN = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"

local Common = {}
-- Flags
Common.Flags = {
	DONT_ASSIGN_OBJECT_MT = false,
}

-- Storage
Common.WelcomeMessage = `Catwork🐈 Loaded. API Version - {VERSION}. meow :3`
Common.Version = VERSION

-- Misc functions

local OPT_PAT = "(.-)%?$"

local function getMetakeysAsStrings(tab)
	local metakeys = {}
	for key: Types.Metakey<any>, value in tab do
		if type(key) == "table" and key[Metakeys.Symbol] then
			-- key is symbol
			metakeys[key.Key] = value
		end
	end

	return metakeys
end

function Common.validateTable(tab, oName, rules: { [string]: string })
	for key, typof in rules do
		local optional = string.match(typof, OPT_PAT)
		typof = if optional then optional else typof

		local value = tab[key]
		if not value and optional then continue end

		local typeis = typeof(value)
		if typeis ~= typof then ERROR.BAD_TABLE_SHAPE(tab, oName, key, typof, typeis) end
	end

	return tab, getMetakeysAsStrings(tab)
end

function Common.assignObjectID(f: Types.Object<any>, fPrivate, service)
	local id = f.ID
	f.ID = nil

	if id then
		if string.match(id, GUID_PATTERN) then
			ERROR.GUID_IDS_NOT_ALLOWED(id)
			fPrivate.ID = HttpService:GenerateGUID(false)
		else
			fPrivate.ID = id
		end
	else
		fPrivate.ID = HttpService:GenerateGUID(false)
	end

	fPrivate.FullID = `{service.Name}_{fPrivate.ID}`
end

-- Headers
Common.ServiceHeader = newproxy(false)
Common.ObjectHeader = newproxy(false)
Common.ClassHeader = newproxy(false)

-- Native Service
Common.NativeService = {} :: Types.Service

return Common
