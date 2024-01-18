-- IMPORTS
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local CollectionService = game:GetService("CollectionService")
local Catwork = require(ReplicatedFirst.Catwork)

-- TYPE DEFS
export type Fragment = Catwork.Fragment<{
	Instance: Instance,
	ObjectConfig: {ExtraConfigs: Instance?, [string]: any},
	[string]: any
}>

type FragmentParams = {
	Instance: Instance,
	ObjectConfig: {ExtraConfigs: Instance?, [string]: any},
	
	Name: string?,
	Destroying: (Fragment) -> ()?,
	Init: (Fragment) -> (),
	[string]: any
}

export type Template = Catwork.Template<{}, FragmentParams>

type TemplateParams = {
	Name: string,
	CreateFragment: (TemplateParams, params: FragmentParams) -> ()
}

-- BASE CODE
local ObjectHandler: Catwork.TemplateService<
	Fragment, Template,
	FragmentParams, TemplateParams
>
local instanceFragmentStore: {[Instance]: Fragment} = {}

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
	instanceFragmentStore[i] = f

	f:Spawn(function(ok, _, err)
		if not ok then
			warn(`{i}: {err}`)
		end
	end)
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

ObjectHandler = Catwork.TemplateService {
	Name = "ObjectHandler",
	
	TemplateAdded = function(self, template: TemplateParams)
		registerTemplate(template)
	end,
	
	Fragment = function(self, params)
		local i = params.Instance
		if not i then
			error("params is missing instance link and cant be used")
		end

		return Catwork:CreateFragmentForService(params, self)
	end,
}

return ObjectHandler