<div align="center">
<img>put an image here when we have one</img>
<h1>Catwork</h1>
The Cat framework for Roblox! 🐈
<br>
<a href="https://metatablecatgames.github.io/catwork">Documentation</a>
</div>

# Installation

Catwork can be installed simply by downloading the RBXM in the Releases folder, and then dragged into Studio.
If you use Rojo or similar toolchain, you can simply clone the code into your local project.

> [!NOTE]
> Catwork works best in `ReplicatedFirst`, especially since you can then utilise `ReplicatedFirst` loading behaviour.
> Server code can access code in ReplicatedFirst.

Catwork does not natively come packaged with a runtime, although `Script` instances can safely access the `Catwork`
module. You'll need some way of starting `ModuleScript` instances if you wish to take full advantage of the motivations
behind `Fragment`s though.

# Usage

This Fragment simply greets the player when they join:

```lua
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local Catwork = require(ReplicatedFirst.Catwork)

Catwork.Fragment {
  Init = function(self)
    Players.PlayerAdded:Connect(function(p)
      print(`Hello {p.Name}!`)
    end)
  end
}
```

This only scratches the true function of what Catwork can do, `Service` and `TemplateService` considerably increases the power of
Catwork! See the documentation for more information.

# License

Catwork is licensed under the MIT License. 2024 metatablecatgames
