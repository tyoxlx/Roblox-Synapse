local Catwork = require(".")
local Types = require("./lib/Types")

return function<A>(name: string, createFn: (Types.Object<A>) -> ()): <B>(B) -> Types.Object<A & B>
	return Catwork.Class(name, createFn)
end