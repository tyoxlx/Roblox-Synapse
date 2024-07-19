if not script then script = require("./lib/RelativeString") end
local Catwork = require(script.Parent.Catwork)
local Types = require(script.Parent.lib.Types)

return function(params: Types.ServiceCtorParams): Types.Service
	return Catwork.Service(params)
end