# Fragment

The basic building block of all running Catwork code.

!!! note
	Due to the dynamic nature of Fragments, this documentation only describes
	the built-in logic.

## Properties

### Fragment.FullID

`string`

The full unique ID of the `Fragment`, this combines the `Fragment.ID` and
`Service.Name` properties in the format:

```
{serviceName}_{fragmentID}
```

### Fragment.ID

`string`

The unique ID of the Fragment. This will either be a GUID or a static fragment
ID. This ID is only unique to the `Service` the `Fragment` is contained in.

### Fragment.Name

`string`

A non-unique identifier for this Fragment.

### Fragment.Service

`Service`

A reference to the `Service` this `Fragment` is contained inside.

### Fragment.Template

`Template`

A reference to the `Template` (if any), this `Fragment` was created with.

## Callbacks

These are built-in lifecycle callbacks that you can define in your Fragment.
They are generally defined as the following syntax in `Catwork.Fragment`:

```lua
Catwork.Fragment {
	Init = function(self)

	end
}
```

### Fragment.Destroying

`Destroying = function(self)`

Invoked when `Fragment:Destroy` is called, this is fired after it has been
removed from all relevent tables, but before `Service.FragmentRemoved` is called.

### Fragment.Init

Defined as `Init = function(self)`

The callback that is invoked when a Fragment is spawned using `Fragment:Spawn`.

!!! caution
	This is the default behaviour when `Service.Spawning` isn't overloaded, if you
	have overloaded it, make sure that the Init callback is eventually called
	for feature parity with the native service. (If you want that of course)



## Methods

### Fragment:Await

`() -> (boolean, string?)`

Waits for the `Service.Spawning` callback to finish on the `Fragment`, then
returns the result of the wrapped `xpcall`.

!!! danger "Don't self-await"
	Be careful to not call self:Await directly or indirectly while `Init` is
	performing, this will cause the fragment to never resolve. This is bad!

	Future versions of Catwork should warn against this.

	=== "Bad"

		```lua
		Init = function(self)
			self:Await() -- this will never resolve
		end
		```

	=== "Better"

		```lua
		Init = function(self)
			self:HandleAsync(function(ok, err)
				-- this will resolve as it runs outside of the Init callback
			end)
		end

		```

### Fragment:Destroy

`() -> ()`

Destroys the Fragment. This clears it from all internal tables, fires
`Fragment.Destroying`, and finally `Service.FragmentRemoved`.

This method can be called multiple times, but will only operate once.

### Fragment:HandleAsync

`(asyncHandler: (boolean, string?) -> ()?) -> ()`

Waits for the Fragment to complete asynchronously, then calls the `asyncHandler`.

This method is safe to call inside `Fragment.Init` as it runs in a seperate thread
and does not block the execution of the Init call.

### Fragment:Spawn

`(xpcallHandler: ((string?) -> string)?) -> (boolean, string?)`

Spawns the Fragment, and uses `xpcallHandler` as the second arg inside `xpcall`.

Make sure to return a string in your xpcall handler, otherwise, no error will be
passed to the result handler.

!!! bug "This function doesn't return"
	Although this type is defined as `-> (boolean, string?)`, it does not
	return anything in `v0.4.4`, this is being fixed in future releases.