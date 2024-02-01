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

A service at minimum requires a unique name that has not been used by any other
service in the context.

```lua
Catwork.Service {
	Name = "A New Service"
}
```

### Fragment creation logic

Services should generally implement the two callbacks `Fragment` and
`FragmentAdded`.

For `Fragment`, the function **MUST** contain a call to
`Catwork:CreateFragmentForService`, this is so Catwork can internally bind the
Fragment to the Service. Parameters are directly parsed to the Fragment
constructor.

This callback should **manipulate** incoming paramters from an external call,
remember, you call this function to create new fragments. **Do not spawn
Fragments here, do that in FragmentAdded.**

```lua
Fragment = function(self, params)
	params.SayFunnyMessage = false
	params.AutoSpawn = true
	
	return Catwork:CreateFragmentForParams(params, self)
end
```

:::caution The `Destory` and `Spawn` keys are ignored.
These two methods contain a lot of internal logic that cant be defined
externally, and will always be ignored by the `Catwork.CreateFragmentForService`
callback.
:::

:::danger Do not use `mutator`. Use FragmentAdded instead
This is an obsolete parameter, and does the same thing as FragmentAdded, do not
pass it, otherwise you will run two callbacks instead of one.
:::

To handle when a fragment has been created, use the `FragmentAdded` callback.

This callback should be used to **consume** a Fragment's parameters and
usually (but you dont have to), spawn it.

```lua
FragmentAdded = function(self, fragment)
	if fragment.SayFunnyMessage then
		print("meow!!!")
	end

	if fragment.AutoSpawn then
		fragment:Spawn()
	end
end
```

## Service Lifecycle

There are a few functions that should be noted here on the lifecycle of:

### Service:Fragment

The callback should initially manipulate parameters, then pass that to
`Catwork.CreateFragmentForService`, from here, Catwork will signal
`FragmentAdded` if it's defined.

### Fragment:Spawn

While this method (and the next one) both belong to Fragment, most of their
logic relates to services. When this is spawned, the Dispatcher will try to find
a `Spawning` signal defined in the service the Fragment was created from.

The dispatcher creates a new thread that runs the `Service.Spawning` function
in a pcall. This is so we get asynchronous code, and any code that waits on this
Fragment doesn't get stuck in an infinite yield.

Once this whole process is completed (or fails), any thread that is waiting upon
the Fragment is resumed with the result of the pcall.

### Fragment:Destrouy

After cleaning itself up internally from Catwork, this method simply calls
Fragment.Destroying and Service.FragmentRemoved for you to handle extra cleanup

---

:::note TODO
The following objects still needs to be documented here:
* TemplateService