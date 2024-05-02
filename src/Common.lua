local Types = require(script.Parent.Types)
local Event = require(script.Parent.Event)
local ERROR = require(script.Parent.Error)
local HttpService = game:GetService("HttpService")

local VERSION = "0.5.0"
local GUID_PATTERN = "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$"

local Common = {}
local PrivateStore = setmetatable({}, {__mode = "k"})

-- Flags
Common.Flags = {
	DONT_ASSIGN_OBJECT_MT = false,
}

-- Storage
Common.WelcomeMessage = `Catwork🐈 Loaded. API Version - {VERSION}. meow :3`
Common.Fragments = {}
Common.Services = {}
Common.FragmentNameStore = {}
Common.Version = VERSION

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

function Common.assignFragmentID(f: Types.Fragment<any>, service)
	local id = f.ID
	f.ID = nil
	local private = Common.getPrivate(f)

	if id then
		if string.match(id, GUID_PATTERN) then
			ERROR.GUID_IDS_NOT_ALLOWED(id)
			private.ID = HttpService:GenerateGUID(false)
		end
	else
		private.ID = HttpService:GenerateGUID(false)
	end

	private.FullID = `{service.Name}_{private.ID}`

	if Common.Fragments[id] then
		ERROR.DUPLICATE_FRAGMENT(id)
	end
end

function Common.private<A,B>(generator: (A) -> B): (A) -> B
	return function(obj: A): B
		local privateObj = PrivateStore[obj]
		if not privateObj then
			privateObj = generator(obj)
			PrivateStore[obj] = privateObj
		end

		return privateObj
	end
end

function Common.getPrivate(obj)
	return PrivateStore[obj]
end

-- Headers
Common.ServiceHeader = newproxy(false)
Common.FragmentHeader = newproxy(false)
Common.TemplateHeader = newproxy(false)

-- Native Service
Common.NativeService = {} :: Types.Service

return Common
