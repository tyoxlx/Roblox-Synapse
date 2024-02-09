local Flags = require(script.Parent.Flags)
local Types = require(script.Parent.Types)
local ERROR = require(script.Parent.Error)

local Common = {}

-- Storage
Common.Flags = Flags
Common.Fragments = {}
Common.Services = {}
Common.FragmentNameStore = {}

-- Misc functions
function Common.PushToNameStore(nameStoreTable, nameStoreKey, k, v)
	local t = nameStoreTable[nameStoreKey]
	if not t then
		t = {}
		nameStoreTable[nameStoreKey] = t
	end

	t[k] = v
end

function Common.FlushNameStore(nameStoreTable, nameStoreKey, k)
	local t = nameStoreTable[nameStoreKey]
	if not t then return end

	t[k] = nil
	if not next(t) then
		nameStoreTable[nameStoreKey] = nil
	end
end

local OPT_PAT = "(.-)%?$"
function Common.validateTable(tab, oName, rules: {[string]: string})
	for key, typof in rules do
		local optional = string.match(typof, OPT_PAT)
		typof = if optional then optional else typof 

		local value = tab[key]
		if not value and optional then continue end

		local typeis = typeof(value)
		if typeis ~= typof then
			ERROR.BAD_TABLE_SHAPE(tab, oName, key, typof, typeis)
		end
	end

	return table.clone(tab)
end

-- Headers
Common.ServiceHeader = newproxy(false)
Common.FragmentHeader = newproxy(false)
Common.TemplateHeader = newproxy(false)

-- Native Service
Common.NativeService = {} :: Types.Service

return Common