if not script then script = require("./lib/RelativeString") end
local Catwork = require(script.Parent.Catwork)
local Types = require(script.Parent.lib.Types)

return function<A>(name: string, createFn: (Types.Object<A>) -> ()): <B>(B) -> Types.Object<A & B>
	return Catwork.Class(name, createFn)
end