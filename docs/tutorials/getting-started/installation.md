# Installation

Catwork can be installed either as a Roblox model, or within a larger project
inside your editor of choice.


---

The following guide is different for within Roblox Studio, and within external editors.

=== "Roblox Studio"

	The RBXM can be obtained below. Its best to drag the module into `ReplicatedFirst`,
	unless you intend to use the tool as a plugin (which has its own section.)

	The tutorials expect Catwork to be placed in `ReplicatedFirst`.

	[:fontawesome-solid-cat: Download Catwork](https://github.com/metatablecatgames/catwork/releases/download/v0.4.4/catwork.rbxm){ .md-button .md-button--primary}

=== "External"

	If you intend to use Catwork externally, the sourcecode can be found on the
	Releases page on the GitHub repository

	[GitHub Releases](https://github.com/metatablecatgames/catwork/releases/){ .md-button .md-button--primary}

	!!! info "Expected for Studio"
		The tutorials expect you to use Catwork within Studio, but can somewhat
		be followed in your editor of choice, if you setup the project correctly.

## Obtaining a Runtime

Catwork does not come bundled with a Runtime, which is an intentional choice for the time being.

!!! abstract "CollectionService Runtime (RECOMENDED)"
	This runtime loads ModuleScripts with a given tag based on the context it is running
	in.

	=== "Game Context"

		```lua
		local CollectionService = game:GetService("CollectionService")
		local RunService = game:GetService("RunService")

		local TAG_SHARED = "SharedFragment"
		local TAG_LOCAL = if RunService:IsClient() then "ClientFragment" else "ServerFragment"
		local passed, failed = 0, 0

		local function safeRequire(module)
			local success, result = pcall(require, module)
			if success then
				passed += 1
				return result
			else
				warn("Error when requiring", module, ":", result)
				failed += 1
				return nil
			end
		end

		local function loadGroup(tag)
			local m = CollectionService:GetTagged(tag)
			for _, mod in m do
				if mod:IsA("ModuleScript") then
					safeRequire(mod)
				end
			end
		end
			
		local t = os.clock()
		loadGroup(TAG_LOCAL)
		loadGroup(TAG_SHARED)
		local f = os.clock() - t

		print(`🐈 CatworkRun. {passed} modules required, {failed} modules failed. Load time: {math.round(f * 1000)}ms`)
		```

	=== "Plugin Context"

		```lua
		local CollectionService = game:GetService("CollectionService")
		if not plugin then return end

		local TAG = "PluginFragment"

		local function safeRequire(module)
			local success, result = pcall(require, module)
			if success then
				return result
			else
				warn("Error when requiring", module, ":", result)
				return nil
			end
		end

		local function loadGroup(tag)
			local m = CollectionService:GetTagged(tag)
			for _, mod in m do
				if mod:IsDescendentOf(plugin) and mod:IsA("ModuleScript") then
					safeRequire(mod)
				end
			end
		end

		loadGroup(TAG)
		```		

	You should generally use this runtime where possible as it's configured from CollectionService tags, and doesn't
	require you to fiddle with the script.

