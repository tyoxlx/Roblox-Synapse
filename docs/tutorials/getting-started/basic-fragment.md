# Basic Fragment

Lets go into a basic fragment, and explain how the model works.

## Importing Catwork

Each Fragment should first import Catwork.

```lua
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Catwork = require(ReplicatedFirst.Catwork)
```

!!! note
	This tutorial expects Catwork to be in `ReplicatedFirst`, make sure its
	there before following this tutorial

	Future tutorials will assume you're importing this.

## A clock counter

For this tutorial, we're going to slowly build an API for interfacing with a
simple real-time clock system.

Add `Lighting` as an import after your `Catwork` import:

```lua
local Lighting = game:GetService("Lighting") -- required for this tutorial
```

### Adding Basic Logic

Lets create a basic Fragment that iterates the current Lighting time. To do
this, we call the `Catwork.Fragment` constructor:

```lua
return Catwork.Fragment {
	Name = "LightingClockTime",

	Init = function(self)
		while true do
			task.wait(1)
			Lighting.ClockTime += 1/60
		end
	end,
}
```

If you run this script, you'll notice the clock slowly ticks forward.

??? bug "Not Working?"
	Here's some possible reasons for your code not working.

	1. You've not imported Catwork, Lighting or ReplicatedFirst.
	2. You didn't include a Runtime, refer to Installation for that.
	3. There's a typo in your script.

Lets explain how this constructor works.

First, we give it the name `LightingClockTime`, this doesn't do much internally
as Fragments use a different method for being uniquely identified, however, it
helps us identify which Fragment we're working with.

```lua
	Name = "LightingClockTime
```

After that, we add an Init callback, which indicates what should happen when the
Fragment is ready to go.

```lua
	Init = function(self)
		while true do
			task.wait(1)
			Lighting.ClockTime += 1/60
		end
	end,
```

### Adding an API

The `Catwork.Fragment` constructor lets you define any logic you want to on the
object, and have it passed to other code using it.

Lets add a API to get the current clock time, and set a timezone offset. To do
this, add two new methods directly to the constructor

```lua hl_lines="11-17"
return Catwork.Fragment {
	Name = "LightingClockTime",

	Init = function(self)
		while true do
			task.wait(1)
			Lighting.ClockTime += 1/60
		end
	end,

	GetClockTime = function(self)

	end,

	SetTimeZoneOffset = function(self, offset)

	end
}
```

We're also going to add an in-built timer, and offset, to the fragment as a property:

```lua hl_lines="4 5"
return Catwork.Fragment {
	Name = "LightingClockTime",

	Time = os.time(),
	TimeZoneOffset = 0
```

Now, lets implement our two new methods, firstly, `GetClockTime`. This method
should just return `self.Time`:

```lua
	GetClockTime = function(self)
		return self.Time
	end
```

And, for `SetTimeZoneOffset`, this should change `self.TimeZoneOffset`

```lua
	SetTimeZoneOffset = function(self, offset)
		self.TimeZoneOffset = offset
	end
```

### Updating Init

If you run the project, and interface with the Fragment, you may notice that nothing
happens. This is because we haven't updated our `Init` callback.

Here's the updated Init callback:
```lua
	Init = function(self)
		while true do
			Lighting.ClockTime = ((self.Time / 3600) % 24) + self.TimeZoneOffset
			task.wait(1)
		end
	end
```

If you run the game now, the time in-game should match near to your local
computer time. (If you computer is set to UTC.).

## Using the API

If you used a ModuleScript, you can now require your script within *another* script,
and interface with the clock counter. Here's a script that requires in the ClockCounter
script, and prints out the clock time every second:

```lua
local ClockCounter = require(path.to.ClockCounter)

while true do
	print(ClockCounter:GetClockTime())
	task.wait(1)
end
```

## Asynchronous design

Catwork utilises a simple asynchronous dependency system, through `Fragment:Await`
and `Fragment:HandleAsync`.

This works by waiting until a Fragment's `Init` function completes (returns) then
resumes any code waiting for it complete. You may notice an issue with our
`Init` callback, in that it **never** returns, and so any code waiting on it will
also never resume.

Lets fix our Init callback to address this. We're going to use `task.spawn` to
create a new thread within our `Init` callback, that runs independently of any
code waiting upon it.

```lua
	Init = function(self)
		task.spawn(function()
			while true do
				Lighting.ClockTime = ((self.Time / 3600) % 24) + self.TimeZoneOffset
				task.wait(1)
			end
		end)
	end
```

You should always `Await`/`HandleAsync` on Fragments, because you cannot guarantee
that they are ready. The Service tutorial explains the Fragment:Spawn lifecycle
more in depth.

```lua hl_lines="2"
local ClockCounter = require(path.to.ClockCounter)
ClockCounter:Await()

while true do
	print(ClockCounter:GetClockTime())
	task.wait(1)
end
```