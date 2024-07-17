-- Lune fix, ref: centau/vide

local function dir(directory: string)
	return setmetatable({} :: { [string]: any },
	{ __index = function(_, path) return directory .. path end })
end

local script = dir ""
script.Parent = dir "./"

return script