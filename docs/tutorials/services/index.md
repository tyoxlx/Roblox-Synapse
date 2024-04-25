# Services

Services are singleton objects that control Fragments under them. For this guide,
we're going to explain how Fragments work under Services, then make a simple
`RemoteEvent` handler.

## Defining a Service

`Service`s are defined using `Catwork.Service`

```lua
Catwork.Service {
	Name = "RemoteHandler"
}
```

Each service requires a unique name, that is not taken up by another Service.

## Fragments

### Creating Fragment

`Fragment` objects are created through the `Fragment` callback, at this step,
you can manipulate the Fragment by adding new methods, or validating parameters.

```lua
	Fragment = function(self, params)
		return Catwork:CreateFragmentForService(params, self)
	end
```

!!! warning "You must call `CreateFragmentForService`"
	This is required as this tells Catwork it can create the Fragment internally.
	From this point, you should assume the Fragment is ready and shouldn't be touched
	further (outside of Spawning.)

For example, here, we add a simple method to the Fragment to print `meow`:

```lua hl_lines="2-4"
	Fragment = function(self, params)
		function params:Meow()
			print("meow!")
		end

		return Catwork:CreateFragmentForService(params, self)
	end
```

!!! tip "Created fragment is the same table as params"
	This means you can operate upon `params` as if it were the Fragment, though
	you should really do this in `FragmentAdded`

### Reacting to new Fragments

`FragmentAdded` is the callback that is invoked straight after `CreateFragmentForService`,
this defines behaviour that should react around the Fragment. Please note that
we still assume the Fragment is in a declarative phase at this point, so avoid
runtime logic.

!!! note
	`Fragment:Spawn` is the intended way for Fragments to escape the declarative
	state phase.

You can either `Spawn` directly from this callback, or defer it to another system.

```lua
	FragmentAdded = function(self, Fragment)
		print(`New Fragment: {fragment.Name}`)
		Fragment:Spawn()
	end
```

### Changing `Spawn` logic

When `Fragment:Spawn` is called, the internal Dispatcher looks for the Service's
spawning callback, which tells the Service that it should act upon this Fragment.

This function is asynchronous, and wont block the operation of other code. By
default, this simply just calls Init on the fragment, but at this point, the
Fragment has escaped its declarative state, and runtime code can now be operated
upon it.

```lua
	Spawning = function(self, Fragment)
		if Fragment.Init then
			Fragment:Init()
		end
	end
```

### Basic Lifecycle Graph

The following graph explains the default behaviour of a Fragment, from
`Service.Fragment` to `Fragment:Init`

``` mermaid
	flowchart TB
    A["Service.Fragment"]
    B["CreateFragmentForService"]
    C["FragmentAdded"]
    D["Fragment:Spawn"]
    E["Spawning"]
    F["Fragment:Init"]


    A--->B
    B---|Internal Fragment Constructor|C
    C--->D
    D---|Internal Dispatcher|E
    E--->F
```