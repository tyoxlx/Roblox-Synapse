local Catwork = require(".")
local Types = require("./lib/Types")

return function<A>(params: A): Types.Object<A>
	return Catwork.new(params)
end