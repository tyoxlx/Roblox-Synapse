local Types = require(script.Parent.Types)
local Event = require(script.Parent.Event)
local ERROR = require(script.Parent.Error)
local HttpService = game:GetService("HttpService")

local GUID_PATTERN = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"

local Common = {}

-- Flags
Common.Flags = {
	DONT_ASSIGN_OBJECT_MT = false,
	ENABLE_STATIC_FRAGMENTS = true
}

-- Storage
Common.WelcomeMessage = `Catwork🐈 Loaded. API Version - {script.Parent.VERSION.Value}. meow :3`
Common.Fragments = {}
Common.Services = {}
Common.FragmentNameStore = {}

-- Events
Common._eFragmentAdded = Event() :: Event.Event<Types.BlankFragment>
Common._eFragmentRemoved = Event() :: Event.Event<Types.BlankFragment>
Common._eServiceAdded = Event() :: Event.Event<Types.Service>
Common._eTemplateAdded = Event() :: Event.Event<Types.Template>

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

function Common.assignFragmentID(f: Types.Fragment<any>)
	local id = f.ID

	if Common.Flags.ENABLE_STATIC_FRAGMENTS and id then
		if string.match(id, GUID_PATTERN) then
			ERROR.GUID_IDS_NOT_ALLOWED(id)
			f.ID = HttpService:GenerateGUID(false)
		end
	else
		f.ID = HttpService:GenerateGUID(false)
	end

	f.FullID = `{f.Service.Name}_{f.ID}`

	if Common.Fragments[id] then
		ERROR.DUPLICATE_FRAGMENT(id)
	end
end

-- Headers
Common.ServiceHeader = newproxy(false)
Common.FragmentHeader = newproxy(false)
Common.TemplateHeader = newproxy(false)

-- Native Service
Common.NativeService = {} :: Types.Service

return Common