-- IMPORTS
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local CollectionService = game:GetService("CollectionService")
local Catwork = require(ReplicatedFirst.Catwork)


-- BASE CODE
local ObjectHandler
local instanceFragmentStore: {[Instance]: Catwork.Fragment<any>} = {}

local function deriveObjectConfig(i)
	local attr = i:GetAttributes()
	attr.ExtraConfigs = i:FindFirstChild("ObjectConfig")
	return attr
end

local function registerObject(i: Instance, template)
	local f = ObjectHandler:CreateFragmentFromTemplate(template, {
		Instance = i,
		ObjectConfig = deriveObjectConfig(i)
	})
end

local function dropObject(i: Instance)
	local f = instanceFragmentStore[i]
	if not f then return end
	instanceFragmentStore[i] = nil

	f:Destroy()
end

local function registerTemplate(template)
	local name = template.Name

	for _, i in CollectionService:GetTagged(name) do
		registerObject(i, template)
	end

	CollectionService:GetInstanceAddedSignal(name):Connect(function(i)
		registerObject(i, template)
	end)

	CollectionService:GetInstanceRemovedSignal(name):Connect(dropObject)
end

ObjectHandler = Catwork.Service {
	Name = "ObjectHandler",

	TemplateAdded = function(self, template)
		registerTemplate(template)
	end,

	Fragment = function(self, params)
		local i = params.Instance
		if not i then
			error("params is missing instance link and cant be used")
		end

		return Catwork:CreateFragmentForService(params, self)
	end,

	FragmentAdded = function(self, f)
		local i = f.Instance
		instanceFragmentStore[i] = f

		f:Spawn(function(ok, _, err)
			if not ok then
				warn(`{i}: {err}`)
			end
		end)
	end
}

return ObjectHandler