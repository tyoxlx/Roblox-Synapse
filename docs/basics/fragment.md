---
sidebar_position: 1
---

# Fragments

Fragments are the base encapsulation of runtime blocks that are triggered by
runtime managers called `Services`.

:::note Coming from Tabby?
If you already understand Fragments, a lot of stuff here will make sense
straight away, however, Catwork changes Fragments in a few ways that should
still be noted.
:::

:::important Add this script
If you dont have a custom runtime already, add this script to
ServerScriptService.

```lua
local ServerScriptService = game:GetService("ServerScriptService")
local Fragments = ServerScriptService:FindFirstChild("Fragments")
if not Fragments then return end

for _, v in Fragments:GetChildren() do
	if v:IsA("ModuleScript") then
		xpcall(task.spawn, warn, require, v)
	end
end
```

This script will load ModuleScripts inside `ServerScriptService.Fragments` where
all code is expected to be located.
:::

## Creating a Fragment

Fragments are created by using the `Catwork.Fragment` constructor, it takes
a single table with a list of paramters and callbacks that set how the Fragment
should behave.

### A simple clock script

Lets create a simple clock Fragment that updates a counter every second, we'll
also add a simple polling API from outside the Fragment for later.

Add a new ModuleScript named `Clock` inside the `ServerScriptService`'s Fragment
folder, and add this code:

```lua
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Catwork = reqauire(ReplicatedFirst.Catwork)
local clockCounter = 0

local Clock = Catwork.Fragment {
	Name = "Clock",

	Init = function(self)
		while true do
			task.wait(1)
			clockCounter += 1
			print(clockCounter)
		end
	end
}

local API = {} -- polling API, we'll implement this later

return Clock
```

If you press run, you'll see a number counting in the output.

:::danger Not working?
There can be a few reasons why this module is not loading, but here are some
common reasons and how to fix them

* ModuleScript is not running - Include the script at the top of this page, and
	make sure the ModuleScript is in `ServerScriptService.Fragments`
* Catwork cant be required - There should be a Catwork module in
	`ReplicatedFirst` for this code to work correctly.

If you're still having issues, [TODO]
:::

### Explanation of clock counter

Lets explain each line of this script and what it does
```lua
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Catwork = reqauire(ReplicatedFirst.Catwork)
```

These two lines simply import the `Catwork` module from `ReplicatedFirst`.
ReplicatedFirst was chosen as the storage location as it means all code can get
to it straight away, including client code.

```lua
local clockCounter = 0
```

Here, we define a `clockCounter`, this is used later in the script.

```lua
local Clock = Catwork.Fragment {
	Name = "Clock",
```

This is where the magic starts, here, we construct a new Fragment using the
`Catwork.Fragment` constructor, and give it the name `Clock`.

:::tip Services expand Fragments greatly
When you get into Services, you'll see just how powerful Fragments can be,
currently, we're using the native service Fragment which is nothing more than a
glorified `task.spawn`.
:::	

```lua
	Init = function(self)
		while true do
			task.wait(1)
			clockCounter += 1
			print(clockCounter)
		end
	end
```

This defines the Init callback, that is ran when the Service gets the Fragment
registered. This starts a loop that increments the `clockCounter` variable
every second. Fragments are asynchronous, so this will not block the execution
of any other code.

For now, we simply print the `clockCounter` variable as the polling API is not
ready yet.

```lua
local API = {} -- polling API, we'll implement this later

return Clock
```

This final chunk defines a polling API that we'll get back to later in the
tutorial, for now, we simply return the Fragment which is a convention when you
have nothing else to return.

:::tip You do not need to return fragments
Catwork *does not* require you to return the Fragment, it registers Fragments
from the `.Fragment` constructor. We're doing it here as a convention.
:::

## Interfacing with Fragments

Lets rework this module to allows us to poll the current clock counter elsewhere

First of all, lets remove that print statement, since we'll print this somewhere
else in the codebase.

```diff
	Init = function(self)
		while true do
			task.wait(1)
			clockCounter += 1
-			print(clockCounter)
		end
	end
```

Now, lets work on that polling API.

Lets bind the Fragment and add a method to get the current clock counter to the
API:

```lua
local API = {}
API.Fragment = Clock

function API:GetClockCounter()
	return ClockCounter
end
```

Finally, lets return the API instead of the fragment.

```diff
- return Clock
+ return API
```

### Reading the clock counter

Lets add one more script that reads the clock counter once, waits five seconds,
then prints it again.

```lua
local ServerScriptService = game:GetService("ServerScriptService")
local Clock = require(ServerScriptService.Fragments.Clock)

print(Clock:GetClockCounter())
task.wait(5)
print(Clock:GetClockCounter())
```

## Asynchronosity in Fragments

Although this tutorial did not use it since the interfacing script was a regular
old script. `Fragments` implement asynchronous runtime hooks that can be used to
control the loading order of Fragments.

If we instead wanted to use the clock counter in another fragment, the runtime
doesn't know which order to load these in, instead, you can utilise 
`Fragment.Await` and `Fragment.HandleAsync` to make a Fragment wait upon another
Fragment, or run asynchronously when loaded, respectively.

```lua
Catwork.Fragment {
	Name = "ClockCounterConsumer",

	Init = function(self)
		Clock.Fragment:Await()
		print(Clock:GetClockCounter())
	end
}
```

:::warning Don't cyclically wait for Fragments
There is currently no watchdog to automatically detect if Fragments are
cyclically waiting on each other, so take care when using these functions.
:::