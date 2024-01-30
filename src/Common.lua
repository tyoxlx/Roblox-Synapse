local Flags = require(script.Parent.Flags)
local Common = Flags -- a little hacky but you shouldn't be accessing the Flags table directly

-- Storage
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

return Common