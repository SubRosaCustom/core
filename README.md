# Sub Rosa: Custom Core

The standard Lua runtime for Sub Rosa: Custom on the client.

This repository is the client-side scripting layer that runs on top of the native `client` module. It provides the plugin system, mode loading, config loading, input dispatch, blips, enums, shared helpers, and the client/server event bridge exposed to Lua.

Requires:

- [Sub Rosa: Custom Client](https://github.com/SubRosaCustom/client)
- [RosaServer](https://github.com/jpxs-intl/RosaServer) if you also want server-backed sync through `rs_integration`

# Getting Started

## Layout

- `main/` contains the runtime entrypoint and core libraries.
- `plugins/` contains client plugins.
- `modes/` contains client gamemodes.

The runtime starts from `main/init.lua`.

## Configuration

Configuration is read from `config.yml` through `loadConfig()`. If the file is missing, the runtime falls back to an empty config with `plugins = {}`.

Useful fields already consumed by the runtime:

- `plugins`
- `defaultGameMode`

If `hook.persistentMode` is not already set, `defaultGameMode` becomes the initial mode.

## Scripting Model

This tree behaves much closer to `RosaServerCore` than to a loose script dump:

- plugins are loaded through `main/plugins.lua`
- plugins can register hooks, enable handlers, disable handlers, and hot-reload state
- modes live separately from plugins
- the core exposes client-side helpers such as `hook`, `input`, `blips`, `enum`, `gameUtil`, and typed data helpers

## Events

The runtime exposes a bidirectional event bridge:

- `onServerEvent(name, fn)`
- `emitServerEvent(name, data, bin)`

That bridge is consumed by `rs_integration` on the server side and by the native `client` module on the transport side.

# Technical Notes

## What This Repo Owns

This repo is responsible for:

- loading and reloading client Lua code
- plugin and mode orchestration
- config parsing
- client-side utility APIs
- dispatching server-originated events into Lua

This repo is not responsible for:

- native hooks or rendering internals
- transport, file sync, or TCP lifecycle
- server administration or account/gameplay authority

Those concerns live in `client/` and `rs_integration/`.

## Important Files

- `main/init.lua` boots the runtime and config flow
- `main/plugins.lua` implements plugin discovery, lifecycle, and reload behavior
- `main/blips.lua` owns Lua-side blip state
- `main/input.lua` owns keybind/input dispatch
- `main/hook.lua` owns the hook bus used by plugins and modes

# Development

## Plugins

Drop plugin entry files under `plugins/` and load them through the existing plugin runtime. The showcase plugin in `plugins/showcase.lua` is the practical reference point in this tree.

## Modes

Drop mode files under `modes/`. `config.defaultGameMode` or `hook.persistentMode` selects the active mode.

## IntelliSense

If you want editor support, use the same Lua tooling people already use for RosaServer projects:

- VS Code with Lua Language Server
- IntelliJ with EmmyLua support

There is no point pretending this repo currently ships a polished `.meta` setup like JPXS `RosaServerCore`; it does not.
