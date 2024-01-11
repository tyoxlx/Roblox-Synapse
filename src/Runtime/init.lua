-- INTERNAL NOTE: replace this fit-in with Sprint, it has better runtime
-- control functionality, this is kept as a simpler script to not pollute
-- Catwork itself too much. The plugin will automatically import Sprint instead
-- of this, if you see this instead. PLEASE REPORT THIS.

-- This is a fit-in that runs completely detatched from Catwork externally
--
-- Under this module are three scripts that control runtime behaviour
--   Server: server execution
--   Client: client execution
--   Plugin: plugin execution (disabled by default, to run as a plugin, enable
--   this script and delete the other two)
--
-- To take advantage of ReplicatedFirst loading behaviour, please place this
-- fit in under ReplicatedFirst
--
-- metatablecatgames 2024 - Part of Catwork, all rights reserved

local CollectionService = game:GetService("CollectionService")
local ReplicatedFirst = game:GetService("ReplicatedFirst")

local isRF = script:IsDescendantOf(ReplicatedFirst)
local SHARED_TAG = "SharedFragment"
local SERVER_TAG = "ServerFragment"
local CLIENT_TAG = "ClientFragment"
local CLIENT_RF_TAG = "ClientStartupFragment"

local function loadModuleAsync(m)
	task.spawn(require, m)
end

local function loadPluginProject()
	local fragmentFolder = script.Parent.Parent.Fragments
	
	for _, v in fragmentFolder:GetChildren() do
		if v:IsA("ModuleScript") then loadModuleAsync(v) end
	end
end

local function dropModule(i)
	if i:IsA("ModuleScript") then
		loadModuleAsync(i)
	end
end

local function initTag(tagID)
	for _, i in CollectionService:GetTagged(tagID) do dropModule(i) end
	CollectionService:GetInstanceAddedSignal(tagID):Connect(dropModule)
end

return function(ctx: "Server"|"Client"|"Plugin")
	if ctx == "Plugin" then
		loadPluginProject() -- this fundamentally does something seperate
		-- because this would go very nuclear on CollectionService tags
		-- otherwise
	else
		initTag(SHARED_TAG)
		if ctx == "Server" then
			initTag(SERVER_TAG)
		else
			initTag(CLIENT_RF_TAG)
			
			if isRF then
				if not game:IsLoaded() then game.Loaded:Wait() end
			else
				warn("Catwork performs best under ReplicatedFirst, where it can take advantage of ReplicatedFirst loading.")
			end

			initTag(CLIENT_TAG)
		end
	end
end