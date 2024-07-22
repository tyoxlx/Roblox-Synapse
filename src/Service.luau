local Catwork = require(".")
local Types = require("./lib/Types")

return function(params: Types.ServiceCtorParams): Types.Service
	return Catwork.Service(params)
end