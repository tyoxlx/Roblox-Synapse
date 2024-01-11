-- metatablecatgames 2024 - Part of Catwork, all rights reserved

-- mostly put here for type defs, and to not pollute the Catwork lib itself
-- too much
local Types = require(script.Parent.Types)
local Action = require(script.Parent.Action)

export type Fragment = Types.Fragment<{
	Init: (Fragment) -> (),
	Spawn: (Fragment, asyncHandler: (boolean, string?) -> ()) -> (boolean, string?)?
}>

export type CreatorParams = {
	Name: string?,
	Init: (Fragment) -> (),
	Destroying: (Fragment) -> ()?,
}

local RunFragmentAction = Action("cw.RunFragment", function(fragment, service, spawnSignal)
	spawnSignal(service, fragment)
end)

local function spawnFragment(self: Fragment, asyncHandler)
	local service = self.Service
	local spawnSignal = service.Spawning

	if asyncHandler then
		RunFragmentAction:handleAsync(asyncHandler, self, service, spawnSignal)
		return nil
	else
		return RunFragmentAction:await(self, service, spawnSignal)
	end
end

export type self = Types.Service<Fragment, CreatorParams>

return function(catwork)
	return catwork.Service {
		Name = "catwork",
		
		Fragment = function(self, params)
			params.Spawn = spawnFragment
			
			return catwork:CreateFragmentForService(params, self)
		end,
		
		Spawning = function(self, fragment)
			local i = fragment.Init
			
			if not i then
				warn("Fragment does not implement Init")
				return i
			end
			
			return i(fragment)
		end
	}
end