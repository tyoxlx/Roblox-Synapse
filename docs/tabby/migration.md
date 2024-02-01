---
sidebar_position: 1
---

# Migrating from Tabby to Catwork

:::tip Help migrate Tabby's baselib into a Catwork service!
We're working on a more complete migration service called `tabby-cwservice`.
You can contribute to this by clicking here!
:::

Catwork is a successor from Tabby but has some notable API differences, this
guide summarises changes that need to be made to convert Tabby fragments to
Catwork fragments.

## `Tabby.Fragment`

Use Catwork.Fragment instead, construction API here is completely different from
how it was done in Tabby. Most notably, you will no longer need a script linker
as Catwork drops the requirement for Fragments to be linked to their module.

Unlike before where construction was defined by adding lifecycle hooks to a
returned object, the Catwork constructor takes a table that maps properties
directly. Doing this allows us to drop a lot of restrictions that Tabby
implemented, most notably, the `NoYield` requirement.

```lua
Catwork.Fragment {
	Name = "The Cat!",

	Init = function(self)
		print(`hi my name is {self.Name}`)
	end
}
```

To migrate the `Tabby.Fragment` constructor to `Catwork.Fragment`, change the follwing
keys

### `Fragment.Init`

Replaced with Init:

```diff
Catwork.Fragment {
+	Init = function(self)
+		print("meow")
+	end
}
```

### `Fragment.Update`

Catwork does not implement an `Update` callback for performance reasons, if you
still require an Update signal, bind it directly inside the `Init` callback
using RunService

### `Fragment.Name`

This property is unchanged with new Fragments, but is not required, if you want
to have the script name as the Fragment's name, add a `Name` key in the
construction table

```diff
Catwork.Fragment {
+	Name = script.Name
}
```

### `Fragment.Plugin`

Use `Catwork.Plugin` instead. This key only exists if Catwork is running in a
Plugin context.

### Lifecycles

Lifecycles do not exist in Catwork, instead, services are used to control the
runtime behaviour of member Fragments.

## `Tabby.Runtime`

Runtime was an internal controller for dispatching `Fragment` objects from the
`Project.lua` file, `Service`s provide a more complete implementation of this.

## `Tabby.Plugin`

Unchanged, `Catwork.Plugin`

## Projects

There are no projects in Catwork since it does not come with a runtime, some
runtime controllers may include their own Project file though
