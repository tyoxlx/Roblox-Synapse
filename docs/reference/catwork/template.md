# Template

Templates are small factory objects that create Fragments. Unlike other objects,
they are incredibly simple.

## Properties

### Template.Name

`string`

The unique identifier for the template, each Service may only have one template
of the given name.

### Template.Service

`Service`

The service this template originates from, and should be the only service you
create it with.

## Methods

### Template:CreateFragment

`<A>(A) -> Fragment<A>`

Builds a Fragment using the template and given parameters, returns the Fragment
after being created.