---
  title: 0.5.0 Migration
---

# Migrating to 0.5.0

!!! note
	This migration guide is hosted here during the release candidate phases of
	development, but will be moved into the main documentation site once 0.5.0
	docs are fully baked.

## Fragment -> CatworkAsyncObject

Fragment has been renamed to CatworkAsyncObject, this has changed several APIs.
This change was made to better reflect how these objects work, since the name
`Fragment` is a leftover from the Tabby days.

### Constructing objects

This is simply a rename from `Catwork.Fragment` to `Catwork.new`, to construct
objects from services, use the newly added `Service.CreateObject` method, which
replaces `Service.Fragment`.

### Service Callbacks regarding CatworkAsyncObject

Service callbacks and methods have simply been renamed from `Fragment[X]` to
`Object[X]`

These are:

* `Service.Fragment` -> `Service.Object`
* `Service.CreateFragmentFromObject` -> `Service.CreateObjectFromClass`
	* See also; `Template -> Class`
* `Service.FragmentAdded` -> `Service.ObjectAdded`
* `Service.FragmentRemoved` -> `Service.ObjectRemoved`

## Template -> Class

Templates have been renamed to Classes, the only callback within services here
that needs to be changed is `Service.Template` to `Service.Class`, its worth
noting that this function has a different signature.

!!! info "Converting templates to classes"
	=== "Old Template Construction"

		```lua
		return TemplateService:Template {
			Name = "Meowitzer",
			CreateFragment = function(fragment)
				function fragment:Init()
					print("meow!")
				end
			end
		}
		```

	=== "New Class Construction"

		```lua
		return TemplateService:Class("Meowitzer", function(object)
			function object:Init()
				print("meow!")
			end
		end)
		```

## Changes to `TimeoutDisabled` and similar keys

Catwork will now define these keys using the newly added `meta` function, this
was done to better isolate internal Catwork keys.

!!! info "Old"
	=== "Old"

		```lua
		return Catwork.Fragment {
			TimeoutDisabled = true
		}
		```

	=== "New"

		```lua
		return Catwork.new {
			[meta "TimeoutDisabled"] = true
		}
		```

All keys which have been converted to use the `meta` function are listed here

```
EnableClasses
TimeoutDisabled

# these are new metakeys but added here regardless
AwaitFor
EnableUpdating
PluginMetadata
```