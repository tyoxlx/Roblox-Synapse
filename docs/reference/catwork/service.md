# Service

Services are singletons that let you change how Fragments behave.

??? tip "TemplateServices are now implicit"
	Catwork previously had an explicit method called `Catwork.TemplateService`,
	this has since been removed. You now simply need to use one of two methods
	to enable templates

	=== "Explicit"
		```lua
		return Catwork.Service {
			EnableTemplates = true
		}
		```
	=== "Implicit"
		```lua
		return Catwork.Service {
			TemplateAdded = function(self, template)

			end
		}
		```

## Properties

### Service.EnableTemplates

`boolean`

Dictates if the service is a TemplateService, and that methods such as `Template`
can be used.

!!! warning "Assume template methods are undefined if this property is `false`"
	This setting disables all template logic, however, some objects may be left
	over such as the `Service.Templates` table.

### Service.Fragments

`{[string]: Fragment<any>}`

A table representing which fragments belong to this specific Service, these
are stored the same way as Catwork.Fragments(1).
{ .annotate}

1. Fragments are stored using the format
   `{Fragment.Service.Name}_{Fragment.ID}`

### Service.FragmentNameStore

`{[string]: {[string]: Fragment<any>}}`

An internal storage tree for `Service.GetFragmentsOfName`.

!!! danger "Do not use this property externally"
	This table is unpredictable, it is safer to use `GetFragmentsOfName` as this
	returns an immutable chunk of this data

### Service.Templates

`{[string]: Template}`

A storage table of this service's templates.

## Callbacks

These are built-in lifecycle callbacks that you can define in your Service.
They are generally defined as the following syntax in `Catwork.Service`:

```lua
Catwork.Service {
	Fragment = function(self, params)

	end
}
```

### Service.Fragment

Defined as `Fragment = function(self, params)`

The main method for constructing fragments out of the service. This method
is provided with a list of parameters that are then built into a Fragment.

```lua
Fragment = function(self, params)
	function params:Meow()
		return "meow!!!"
	end

	return Catwork:CreateFragmentForService(params, self)
end
```

This is eventually transformed into the method `Service:Fragment`.

!!! warning "You MUST call `CreateFragmentForService`"
	This method links up everything internal related to the fragment, and must
	be called **once** in your `Fragment` callback definition.

### Service.FragmentAdded

Defined as `FragmentAdded = function(self, Fragment<any>)`

This method is invoked just after a `CreateFragmentForService` call, and
represents the actual Fragment, and not just a tree of constructed parameters.

This callback is intended for setting up code around the fragment, instead of
enforcing it's shape.

### Service.FragmentRemoved

Defined as `FragmentRemoved = function(self, Fragment<any>)`

Invoked after a Fragment has been destroyed, this method should be used for
definining internal cleanup logic.

### Service.Spawning

Defined as `Spawning = function(self, Fragment<any>)`

The asynchronous entry point that is called when `Fragment:Spawn` is called.
Since this callback executed asynchronously, it is safe to perform stateful code
here as it's escaped from the declarative callbacks of `Fragment` and `FragmentAdded`.

??? question "Fragment, FragmentAdded or Spawning?"
	`Service.Fragment` should be used for setting up the Fragment itself, but
	should not perform any runtime behaviour.

	`Service.FragmentAdded` should react to constructed fragments, and may perform
	simple runtime actions that do not require state. FragmentAdded should also (but
	does not have to) call `Spawn`.

	`Service.Spawning` runs in an asynchronous thread, and stateful runtime behaviour
	should be performed here.

### Service.TemplateAdded

Defined as `TemplateAdded = function(self, Template)`

Invoked when a new Template is added through `Service:Template`. The definition
of this key implicitly enables `TemplateServices`.


## Methods

## Service:CreateFragmentFromTemplate

`<A>(Template|string, A) -> Fragment<A>`

Creates a fragment from a given template, or template identifier. This function
will error if the template identifier is nil.

!!! danger "Dont give this templates from other services"
	This creates undefined behaviour, keep templates to their own service.

## Service:GetFragmentsOfName

`(name: string) -> {[string]: Fragment<A>}`

Returns an immutable chunk from `Service.FragmentNameStore`, of all fragments
defined with the given name. Keys of the return table are full fragment IDs(1)
of each fragment.
{.annotate}

1. Fragments are stored using the format
   `{Fragment.Service.Name}_{Fragment.ID}`

## Service:Template

`(TemplateParams) -> Template`

Builds a template from the given params table.

```lua
Service:Template {
	Name = "CatGenerator",
	CreateFragment = function(self, fragment)

	end
}
```