# Catwork

Catwork refers to the root object that is returned when the module is required

```lua
require(path.to.catwork)
```

## Properties

### Catwork.Fragments

`{[string]: Fragment<any>}`

A table of fragments currently loaded inside the Catwork module. Destroyed
fragments do not appear in this table.

### Catwork.Services

`{[string]: Service}`

A table of services currently loaded inside the Catwork module.

### Catwork.Plugin

`Plugin?`

A reference to the plugin if applicable, this key is only defined if Catwork
is running in a plugin context.

### Catwork.__VERSION

`string`

The current Catwork version.

## Constructors

### Catwork.Fragment

`<A>(params: A) -> Fragment<A>`

Creates a new Fragment from the given parameters.

**Code Example:**

```lua
return Catwork.Fragment {
	Name = "MeowService",

	Init = function(self)
		print("meow!")
	end
}
```

!!! tip

	From `0.4.4` onwards, you are able to define the ID explicitly using the `ID`
	key. These are known internally as `StaticFragments`.

	```lua
	Catwork.Fragment {
		ID = "MeowServiceStatic"
	}
	```

### Catwork.Service

`(params) -> Service`

Creates a service from a given parameter table. For more information, refer to
the Services tutorial.

## Methods

### Catwork:CreateFragmentForService

`<A>(params: A, service: Service) -> Fragment<A>`

Builds a Fragment for a given service, then returns it to the service's FragmentAdded
callback.

!!! warning
	Always call this method in a `Service.Fragment` definition, otherwise the
	fragment will never initialise.

### Catwork:GetFragmentsOfName

`(name: string) -> {[string]: Fragment<any>}`

Returns a list of fragments, or an empty table, of Fragments matching the given
name.

## Events

!!! note
	These events are designed for tracking object creation in debugging tools.

### Catwork.FragmentAdded

`Event<Fragment<any>>`

Fired when a Fragment is created through `CreateFragmentForService`.

### Catwork.FragmentRemoved

`Event<Fragment<any>>`

Fired when a Fragment is destroyed.

### Catwork.ServiceAdded

`Event<Service>`

Fired when a new service is created.

### Catwork.TemplateAdded

`Event<Template>`

Fired when a new template is created.
