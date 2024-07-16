# Example Service

The following guide explains how to create a simple RemoteEventHandler service,
and how to use it.

## Remote Handler

First, lets define our Service.

```lua
return Catwork.Service {
	Name = "RemoteEventHandler"
}
```

### Building the Fragment

Next, we'll create the `Fragment` constructor:

```lua
	Fragment = function(self, params)
		if not params.ID then
			error("Fragment requires a static identifier")
		end

		if not params.Event then
			error("Fragment requires a connectable event")
		end

		return Catwork:CreateFragmentForService(params, self)
	end
```

This `Fragment` constructor simply enforces that the Fragment has an ID, and an
Event callback.

We dont need to define any special logic for `FragmentAdded` here, since all
remaining logic escapes the declarative phase. Though, for example, if you
wanted to defer Spawning so another system can take over, you can simply add this:

```lua
	FragmentAdded = function(self, Fragment)
		RemoteDispatcher:queue(Fragment)
	end
```

Because we're overloading the default `FragmentAdded`, the Fragment wont spawn
unless we tell it to.

### Setting up the Remote

Within our `Spawning` callback, we create the remote, and hook it to the event:

```lua
	Spawning = function(self, Fragment)
		local remote = Instance.new("RemoteEvent")

		remote.Event = function(...)
			Fragment:Event(...)
		end

		remote.Name = Fragment.ID
		remote.Parent = ReplicatedStorage
	end
```

!!! note
	This assumes you've made a reference to `ReplicatedStorage`

### Using the Remote Handler

In another script, lets require in the RemoteHandler service, and create a Fragment:

```lua
local RemoteEventHandler = require(path.to.RemoteEventHandler)

RemoteEventHandler:Fragment {
	ID = "Meowitzer",

	Event = function(self, plr)
		print(`meows at {plr.Name} cutely`)
	end
}
```

If you run the game, a new Event should appear called `Meowitzer`, if you
`FireServer` it, it'll print the requested message.