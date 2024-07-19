-- Lune fix, ref: centau/vide

local function dir(directory: string)
	return setmetatable({} :: { [string]: any },
	{ __index = function(_, path) return directory .. path end })
end

local script = dir ""
script.lib = dir "lib/"
script.Parent = dir "./"
script.Parent.lib = dir "./lib/"
script.Parent.Parent = dir "../"

return script