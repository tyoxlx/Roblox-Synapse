# Errors

This is a reference document for all errors.

!!! todo
	This should be referenced to in the ERROR module

## BAD_ARG

* Message : `Bad argument number %s to function %q. Expected %s, got %s`
* Severity: `Error`

An argument was passed to a function that doesn't match an expected type.

```lua
Catwork.Fragment("cat") -- Not OK
Catwork.Fragment {} -- OK
```

## BAD_OBJECT

* Message: `Bad argument number %s to function %s. Type %s could not be converted into object %s.`
* Severity: `Error`

Catwork uses internal headers to identify what tables you're passing to
functions. This error emits when an incorrect object was passed.

```lua
Catwork:CreateFragmentForService({}, {}) -- Not OK, expects Service on second arg
Catwork:CreateFragmentForService({}, SomeService) -- OK
```

## BAD_SELF_CALL

* Message: `Bad self call to %q, did you mean to use : instead of .?`
* Severity: `Error`

For some methods, we can evaluate specifically if you've sent the correct
object as `self` in the method. When you do `:` calling, this isn't an issue,
however, if you call with `.`, for example, inside a pcall, you must also
pass the table as `self`

[More information on method call sugar syntax](https://appgurueu.github.io/2023/07/26/lua-syntactic-sugar.html#calls)

!!! note
	You should generally use `:` syntax where possible on methods where it is
	defined, because its actually slightly faster. You should only fallback to
	`.`, if you're trying to index the function, for example, inside a pcall

	```lua
	pcall(Catwork.GetFragmentsOfName, Catwork, "cat")
	```

```lua
Catwork.GetFragmentsOfName("cat") -- Not OK, self was not passed
Catwork.GetFragmentsOfName({}, "cat") -- Not OK, wrong object was not passed
Catwork.GetFragmentsOfName(Catwork, "cat") -- OK, catwork passed as self
Catwork:GetFragmentsOfName("cat") -- OK, method call syntax
```

## BAD_TABLE_SHAPE

* Message: `Object %* cannot be converted to %s. Type of key %s is invalid. Expected %q, got %q.`
* Severity: `Error`

The `Catwork.Fragment` and `Catwork.Service` constructors validate their shape,
Fragments are loosely checked since they can be expanded, but Service is strictly
checked.

If you get this error, it means you've defined a key with the wrong type.

```lua
Catwork.Fragment {
	Name = 0 -- < this causes an error

	---
	Name = "Cat" -- < this is ok
}
```

## BAD_TEMPLATE

* Message: `Template %s does not exist for Service %*.`
* Severity: `Error`

This error is emitted when you call `Service:CreateFragmentFromTemplate` using a
string key representing a template that doesn't exist.

!!! tip "Use Templates directly where possible"
	Its safer to use templates directly, as referencing them by string can result
	in the template not being defined.

	Many services abstract the CreateFragmentFromTemplate function behind some
	other constructor, as this mechanism is fairly internal.

## DEPRECATED

* Message: `Function %q is deprecated. Use %q instead.`
* Severity: `Warn`

The method is deprecated, and the alternative should be used.

## DISPATCHER_ALREADY_SPAWNED

* Message: `Fragment %* has already been spawned.`
* Severity: `Error`

This appears when you try to spawn a Fragment multiple times, if you're trying
to capture the result of a Spawn call, use `Await` or `HandleAsync` instead.

## DISPATCHER_DESTROYED_FRAGMENT

* Message: `Fragment %* cannot be spawned because it has been destroyed.`
* Severity: `Error`

This error is invoked when you try to spawn a destroyed Fragment, because
destroyed Fragments dont appear in any of Catwork's internal storage tables,
they cant be spawned.

## DISPATCHER_SPAWN_ERR

* Message: `A fragment experienced an error while spawning: %s`
* Severity: `Error`

Shown as a fail-state of the `xpcall` that `Service.Spawning` is wrapped into,
you should try to track down this error in your own code.

## DUPLICATE_FRAGMENT

* Message: `Fragment %s is already defined`
* Severity: `Error`

When using a static ID, they must be unique per service. You may have multiple
Fragments with the same ID as long as they are not in the same Service.

## DUPLICATE_SERVICE

* Message: `Service %s is already defined.`
* Severity: `Error`

Service names must be unique, this error is shown when you try to create an
already existing Service.

## FRAGMENT_SELF_AWAIT

> Future addition, not currently implemented

* Message: `Fragment %* is awaiting upon itself and will never resolve. Use HandleAsync instead.`
* Severity: `Warn`

This is warned when you call `self:Await` inside an Init callback directly or
indirectly, you should instead use `self:HandleAsync`

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


## GUID_IDS_NOT_ALLOWED

* Message: `Cannot use Fragment ID %s, a new ID has been generated.`
* Severity: `Warn`

GUIDs cannot be used as static IDs, as this is the fallback state for non-static
fragments. If you want to statically use a GUID identifier, add a prefix char
such as `_`.

## INTERNAL

* Message: `Error: %*. This is likely a known internal error, please report it!`
* Severity: `Error`

This only appears when a known internal error occurs, if this does appear, please
report it and what you're doing, as it likely means we're trying to track down
a bug.

## SERVICE_DUPLICATE_TEMPLATE

* Message: `Template %s already exists`
* Severity: `Error`

Services store templates with string identifiers, and only one Template may
exist per identifier.

## SERVICE_NO_TEMPLATES

* Message: `Service %* does not implement templates.`
* Severity: `Error`

The service is not a TemplateService, and as such, `Service.Template` cannot
be used on it.

!!! tip
	If you're trying to create a TemplateService, you can auto-enable them either
	through the existence of a `TemplateAdded` callback, or you can explicitly
	enable it with `EnableTemplates`

	```lua
	return Catwork.Service {
		EnableTemplates = true -- explicit definition

		TemplateAdded = function() -- implicit definition
	}
	```

## UNKNOWN

* Message: `Unknown Error`
* Severity: `Error`

The internal error emitter was called with an invalid identifier. Please report
this if it happens.