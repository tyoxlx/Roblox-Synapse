---
sidebar_position: 2
---

# Services

Services are the bread and butter of Catwork, and where Catwork allows you to
really extend Catwork's basic logic from it's native service.

## Service types

There are two kinds of Service

1. ClassicService - created with `Catwork.Service`, a non-template enabled 
	service, that does not implement any Template code. Intended for simpler
	services that dont need templates to work.
2. TemplateService - created with `Catwork.TemplateService`, a service that
	has templates enabled and allows the creation of Template objects

## Creating services

Each service is created using the `Catwork.Service` or `Catwork.TemplateService`
constructor.

## A RemoteEvent handler

:::note
This tutorial assumes Catwork is already loaded into your ModuleScript
:::

Lets say you wanted to create Fragments that handle various `RemoteEvent`
objects, you could, for example, set up an initial template of this for each
RemoteEvent you want to implement:

```lua
Catwork.Fragment {
	Name = "KillPlayer",

	Init = function(self)
		local remote = Instance.new("RemoteEvent"),
		remote.Name = self.Name,
		
		remote.OnServerEvent:Connect(function(p, otherPlayer)
			local char = otherPlayer.Character
			local human = char and char:FindFirstChild("Humanoid")

			if human then
				human.Health = 0
			end
		end)

		remote.Parent = ReplicatedStorage
	end
}
```

But this is incredibly wasteful, mainly because the majority of your Fragments
would be boilerplate. What if we could hide away all the Remote logic into
a common constructor? This is where Services come into Catwork.

Lets instead, create a Service object that creates remotes from Fragments, in
a new ModuleScript named `RemoteHandler`, insert this code:
```lua
return Catwork.Service {
	Name = "RemoteHandler",

	Fragment = function(self, params)
		local e = Instance.new("RemoteEvent")
		e.Name = params.Name
		e.Parent = ReplicatedStorage

		params.Remote = e
		return Catwork:CreateFragmentForService(params, self)
	end,

	FragmentAdded = function(self, f)
		if f.OnServerEvent then
			f.Remote.OnServerEvent:Connect(f.OnServerEvent)
		end
	end
}
```

:::danger Do not include this ModuleScript in `ServerScriptService.Fragments`
This is not a fragment, it's a service. We dont want it running from the startup
script
:::

There's only two chunks here of interest, but lets first start by inspecting
this line.

```lua
return Catwork.Service {
	Name = "RemoteHandler",
```

**All** services require a unique name, unlike Fragments, they are explicitly
mapped to the Services table with this name

:::tip
Try indexing the `Catwork.Services` table with `catwork` and see what returns!
:::

The first callback, `Fragment`, defines how this service should create its
Fragments. This callback should be used to **modify** the params table before
passing it on to the global constructor.

```lua
	Fragment = function(self, params)
		local e = Instance.new("RemoteEvent")
		e.Name = params.Name
		e.Parent = ReplicatedStorage

		params.Remote = e
		return Catwork:CreateFragmentForService(params, self)
	end,
```

This callback creates a RemoteEvent, dumps it into ReplicatedStorage, then
calls `Catwork:CreateFragmentForService`, which constructs the Fragment from
the parameter table.

:::warning All `Service.Fragment` callbacks must call `CreateFragmentForService`
This method sets up internal bindings for the fragments, and usually, you
should return it directly.
:::

The other callback, `FragmentAdded`, defines what happens when a `Fragment`
is created. This callback should be used to **react** to the Fragment but not
neccessarily manipulate it.

```lua
	FragmentAdded = function(self, f)
		if f.OnServerEvent then
			f.Remote.OnServerEvent:Connect(f.OnServerEvent)
		end
	end
```

Here, we simply bind the remote event to a callback named `f.OnServerEvent`,
we did not do this in `Fragment`, as the Fragment had not been internally
initialised yet.

### Using the Service

Lets go back to our original code example, and refactor it to use the Service.

```lua
local RemoteHandler = require(ServerScriptService.RemoteHandler)

RemoteHandler:Fragment {
	Name = "KillPlayer",

	OnServerEvent = function(p, otherPlayer)
		local char = otherPlayer.Character
		local human = char and char:FindFirstChild("Humanoid")

		if human then
			human.Health = 0
		end
	end
}
```

We have considerably reduced the boilerplate, resulting in us only having to
define what happens when the event is fired, not how to set up that callback.

### Cleaning up Fragments

There is another callback, `FragmentRemoved`, which is called when we destroy a
Fragment.

If we were to destroy one of these `RemoteHandler` fragments, the remote would
continue to listen to events (oh no!). Lets add this callback to our service:

```lua
	FragmentRemoved = function(self, f)
		local e = f.Remote
		if e then e:Destroy() end
		f.Remote = nil
	end
```

This function simply destroys the remote and unassigns it from the Fragment. The
fragment will no longer process remote signals if we destroy it.

### Spawn, Spawning and Init

Catwork's internal dispatcher provides Fragment with a method, `Fragment:Spawn`.
This method can be used to spawn Fragment-specific code, normally, the 
Fragment's `Init` function.

You may have noticed, in the Clock fragment example, we didn't have to Spawn
anything? Catwork's native service spawns fragments upon creation, but if you
implement a `FragmentAdded` callback, this overloads that behaviour.

Services can also implement a callback, `Spawning`. This is what called when
`Fragment:Spawn` is called. If you do intended to overload this callback, it
should eventually call the `Init` callback.

:::tip
`Service.Spawning` is asynchronously ran, you do not need to use `task.spawn`
here.
:::

Here's psuedocode on how Catwork's own service implements Fragment spawning.

:::important Source Location
This pseudocode is implemented in `src/Service.lua`.
:::

```
declare function "Spawning" to Service with argument "Fragment"
	define "Fragment.Init" to variable "i"
	if i is undefined then
		throw a warning "Fragment does implement init"
		return nothing from fragment
	
	call method "Fragment.Init"

declare function "FragmentAdded" to Service with argument "Fragment"
	call method "Fragment.Spawn"

```

## Templates

TODO