---
sidebar_position: 1
---

# Introduction to Catwork

Catwork is a small Fragment/Service based framework for Roblox. It works by
encapsulating runtime logic into objects called `Fragment`s that can be handled
by user-created, or the native Catwork `Service`.

## Runtime

Catwork does not natively include a runtime controller to reduce the size of the
codebase, and because we understand that everyone may need to slightly tune it
differently.

A basic runtime can be created by simply loading up `ModuleScript` objects in
different context related services. Load the `Fragment` modules, not the
`Service` modules, since these will be started by Fragments that use it anyway.

<!-- Uncomment this when Sprint is actually ready for external use
hi contributor, we'll release it, when IT WORKS.
:::tip Try Sprint!
Sprint is a runtime we use internally to run most of our modern codebases, you
can check it out [here](https://github.com/metatablecatgames/sprint)
:::
-->

:::note Coming from Tabby?
Catwork is a successor to Tabby with a more open API for usage in areas besides
just a plugin context. See the [Migrating from Tabby to Catwork](tabby/migration)
guide for more information.
:::

## API Reference
The API reference found under `API` uses the native behaviour when defining the
API behind `Fragment` and `Template`, however Services are allowed to manipulate
fragments into whatever they want.

:::tip Help contribute!
This documentation is maintained by open-source contributors, you can help
contribute on the GitHub by opening a pull request!
:::