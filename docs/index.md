---
  template: home.html
  title: Catwork
  hide:
    - toc
    - navigation
---

<div id="catworkdoc-home" markdown>
<p id="catworkdoc-contentgradient" />
<div id="catworkdoc-lower-bg" markdown>
<div id="catworkdoc-margin" markdown>
<div id="catworkdoc-homeInner" markdown>
<h1 id="catworkdoc-noMarginBig" markdown>Catwork :cat2:</h1>
<b id="catworkdoc-noMarginBig">The cat framework, written by cats, for cats!</b>
<p id="catworkdoc-noMargin">Catwork is a tiny, ergonomic, declarative framework for creating runtime code.</p>
</div>

[:fontawesome-solid-cat: Download Catwork](https://github.com/metatablecatgames/catwork/releases/download/v0.4.4/catwork.rbxm){ .md-button .md-button--primary}

---

<div align="center" markdown>
:octicons-arrow-down-16: Learn what Catwork has to offer! :octicons-arrow-down-16:
</div>

</div>
</div>
</div>

<div id="catworkdoc-content" markdown>
## Weave dependencies with asynchronous design patterns.

Catwork implements all of its code through Fragments! These allow you to manage
dependencies in a simple and easy to understand way!

```lua title="MeowService.lua"
return Catwork.Fragment {
	Init = function(self)
		task.wait(1)
		self.Value = "cat"
	end,

	ConsumeValue = function(self)
		print(self.Value)
	end
}
```

```lua
local MeowService = require(script.MeowService)

MeowService:Await() -- waits for the service to initialise before grabbing the value

-- If we called this without awaiting, it'd print nothing, Catwork wraps messy
-- asynchronous design behind `Await` and `HandleAsync`
MeowService:ConsumeValue()
```

---

## You build the framework!

Catwork exports an object called a `Service`, this lets you add almost any
behaviour to Fragments beyond what Catwork originally allows.

```lua title="RemoteService.lua"
return Catwork.Service {
	Name = "RemoteService",

	Fragment = function(self, params)
		params.Remote = makeRemote(params)
		return Catwork:CreateFragmentForService(params, self)
	end,

	Spawning = function(self, f)
		if f.RemoteConnection then
			f.Remote.OnServer:Connect(f.RemoteConnection)
		end
	end
}
```

```lua

local MeowRemote = RemoteService:Fragment {
	Name = "MeowRemote",
	
	RemoteConnection = function(plr)
		print(`meows as {plr.Name} cutely`)
	end
}
```

---

## Run Fragments, anywhere.

Catwork doesn't care about what you return, only that you call one of it's
constructors.

This means as long as the code is executed, you can create a Fragment just about
anywhere, a ModuleScript? A Script? Go for it!

```lua title="LocalScript in ReplicatedFirst"
local Catwork = require(ReplicaedFirst.Catwork)

local LoadingScreenManager = Catwork.Fragment {
	Name = "LoadingScreenManager",

	Init = function()
		ReplicatedFirst:RemoveDefaultLoadingScreen()
		-- code to execute guis or whatever
	end
}
```

</div>

<div id="catworkdoc-secondary-bg" markdown>
<div id="catworkdoc-margin" markdown>
<div id="catworkdoc-content" markdown>

<h1 style="color: #fff">Lets go on an adventure together</h1>

<p style="margin-bottom: 0; color:#ffffffb3">Ready to start with Catwork? Then lets go into the tutorials!</p>
</div>
</div>
</div>
