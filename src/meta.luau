-- Defines metakey values
local Types = require("./lib/Types")
local MetakeySymbolic = newproxy(false)

local function metakey<A>(key): Types.Metakey<A>
	return setmetatable({
		[MetakeySymbolic] = true,
		Key = key,
	}, {
		__tostring = function(self) return `Metakey<{self.Key}>` end,
	})
end

local MetakeyMemoization = {}

return {
	export = function(rhs: Types.MetakeyWellKnown | string): Types.Metakey<any>
		local key = MetakeyMemoization[rhs]
		if not key then
			key = metakey(rhs)
			MetakeyMemoization[rhs] = key
		end

		return key
	end,

	Symbol = MetakeySymbolic,
}
