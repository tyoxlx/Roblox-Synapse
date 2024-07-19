if not script then script = require("./lib/RelativeString") end
local Catwork = require(script.Parent.Catwork)
local Types = require(script.Parent.lib.Types)

return function<A>(params: A): Types.Object<A>
	return Catwork.new(params)
end