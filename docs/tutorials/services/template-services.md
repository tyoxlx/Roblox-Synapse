# TemplateService

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

TemplateServices are an extension to Services that allow them to create Templates.
Templates are small objects that can be used to create lots of Fragments with
a similar shape.

!!! note
	The name `TemplateService` refers to an older implementation of this feature,
	Template methods are now simply mounted directly to a Service object if it
	detects that it is one.

## Template
### Defining a Template

Templates can be defined with the `Service:Template` constructor

```lua
Service:Template {
	Name = "Template",
	CreateFragment = function(_, self)

	end
}
```

This creates a unique `Template` for the service, the `CreateFragment` callback
is fired when creating a new `Fragment` against the `Template`.

### Creating a Template

To create a Template, you use `Service:CreateFragmentFromTemplate`, although, many
Services omit this externally, opting to use an abstraction.

```lua
Service:CreateFragmentFromTemplate(template, {
	-- initial parameters
})
```

!!! danger "Dont give this templates from other services"
	This creates undefined behaviour, keep templates to their own service.

The following graph explains the lifecycle of Template construction:

``` mermaid
	flowchart LR
    A["Service:CreateFragmentFromTemplate"]
    B["CreateFragment"]
    C["Service.Fragment"]
    D["Fragment Construction"]

    A--->B
    B--->C
    C-.->D
```

## TemplateAdded

To react to when new Templates are created, you can add a `TemplateAdded` callback
to your Service:

```lua hl_lines="4-6"
Catwork.Service {
	...

	TemplateAdded = function(self, Template)
		print(`new template: {Template.Name}`)
	end
}
```

The existence of this callback tells Catwork this is a TemplateService, though
you can also explicitly tell it that the Service is one through `EnableTemplates`

```lua hl_lines="3"
Catwork.Service {
	Name = "SomeService",
	EnableTemplates = true
}
```