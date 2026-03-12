# Sub Rosa: Custom Core

The standard implementation of Sub Rosa: Custom for clients including a plugin/gamemode system.

Requires [RosaServer](https://github.com/jpxs-intl/RosaServer) and [Sub Rosa: Custom](https://github.com/SubRosaCustom/client).

# Getting Started

## Configuration

Copy `config.sample.yml` to `config.yml` and modify to your heart's content.

## Scripting

The easiest way to start working is to create either a plugin or a gamemode. They work the same, except only one gamemode can be enabled at a time.

## Types

If you use VS Code, you can get IntelliSense working using [this Lua extension](https://marketplace.visualstudio.com/items?itemName=sumneko.lua).

IntelliJ IDEA also has better support, using [this plugin](https://github.com/EmmyLua/IntelliJ-EmmyLua).

All the RosaServer types/globals are laid out in `.meta/template` for this reason. It's also useful as documentation.

# Technical Description
