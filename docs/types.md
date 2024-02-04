---
sidebar_position: 3
---

# Types

Catwork does support Luau typing, however, it gets a little funky around
Fragments because auto-inference cant be ascertained for most of this script.
(Blame Luau's typing engine for this.)

## A simple template
This template should work in most places, if you need typing.

:::note
Keep fragment to single scripts if you're going to use this template, it
gets quite messy.

This template contains a *lot* of type boilerplate, and if Luau would just fix
its typing engine already we could remove the majority of this.
:::

```lua
local Catwork = require(path.to.Catwork)

type FragmentParams = {
	Name: "Fragment",
	Init = (self: Fragment) -> ()
	-- add other macros and functions as needed
}
export type Fragment = Catwork.Fragment<FragmentParams>

local Fragment: FragmentParams = {
	Name = "Fragment",
	Init = function(self)

	end
}

return Catwork.Fragment(Fragment)
```

Change `Fragment` to your object's name as you see fit, using the sample from
the [Fragment Tutorial](basics/fragment), this would be:

```lua
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Catwork = require(ReplicatedFirst.Catwork)

type ClockParams = {
	Name: "Clock",
	ClockCounter: number,

	Init: (self: Clock) -> (),
	GetClockCounter: (self: Clock) -> number
}
export type Clock = Catwork.Fragment<ClockParams>

local Clock: ClockParams = {
	Name = "Clock",
	ClockCounter = 0,

	Init = function(self)
		while true do
			task.wait(1)
			self.ClockCounter += 1
		end
	end,

	GetClockCounter = function(self)
		return self.ClockCounter
	end
}

return Catwork.Fragment(Clock)
```