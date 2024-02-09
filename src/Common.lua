local Flags = require(script.Parent.Flags)
local Types = require(script.Parent.Types)

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

-- Headers
Common.ServiceHeader = newproxy(false)
Common.FragmentHeader = newproxy(false)
Common.TemplateHeader = newproxy(false)

-- Native Service
Common.NativeService = {} :: Types.Service

return Common