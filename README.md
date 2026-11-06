# Sub Rosa: Custom Core

`core` is the standard client-side Lua implementation for SRC.

It is optional, but it is the sane default. Think of it as the SRC-side equivalent of `RosaServerCore`: not strictly required for the platform to function, but the standard baseline implementation you actually want to build on.

`core` is not the native client mod. It is Lua code that runs on top of `client`, and it is typically sent to players by the server through `rs_integration`.

## What It Does

`core` provides the standard client Lua layer for SRC, including:

- plugin loading
- mode loading
- config loading
- input dispatch
- blip management
- shared helpers and enums
- typed data helpers
- the Lua-facing client/server event bridge

This is the repository you build on when you want standard client-side gameplay/UI logic in Lua instead of writing everything from scratch.

## Project Layout

- `main/init.lua` boots the runtime
- `main/plugins.lua` owns plugin lifecycle
- `main/hook.lua` owns the Lua hook bus
- `main/input.lua` owns input dispatch
- `main/blips.lua` owns blip state and helpers
- `modes/` contains client modes
- `plugins/` contains client plugins

## Runtime Role

Typical deployment looks like this:

- `client` runs locally in the game process
- `rs_integration` runs on the server
- `core` lives under the server's synced client root
- `rs_integration` sends `core` to the client
- `client` loads and runs it

That means `core` is optional in a technical sense, but in practice it is the standard implementation layer for SRC.

## Configuration

`core` reads `config.yml` through its Lua startup path.

Current runtime behavior uses config such as:

- `plugins`
- `defaultGameMode`

If no persistent mode is already set, `defaultGameMode` becomes the initial mode.
`rs_integration` resolves this fallback from the captured client `config.yml` before
selecting mode assets. Core receives that effective mode through the existing
persistent-mode field and starts it instead of choosing a different local default.

Plugin enablement persistence follows the RosaServerCore pattern:

- synced plugin disable state is read from `disabledPlugins.json`
- `rs_integration` can update that file and trigger an immediate SRC refresh
- plugin-specific settings still live under `config.yml`

Plugin identities come from `plugins/<name>.lua` or `plugins/<name>/init.lua`.
Names are case-sensitive and may contain only ASCII letters, digits, `_`, and `-`.
A directory entry takes precedence if both forms exist, and entries load in sorted
name order. Asset owners use this filename/directory name, not `plugin.name`.
`disabledPlugins.json` must be a JSON array of those names; invalid updates leave
the previous disable state in effect.

Disabled plugins and inactive modes are discovered without evaluating their entry
files. Their code runs when enabled. A patch applies its disable state before
loading entries, and a failed reload leaves that plugin disabled until a successful
retry. Only the mode named by `hook.persistentMode` (or the initial
`defaultGameMode`) loads initially.

## Scope

`core` owns client Lua behavior.

It does not own:

- native hooks
- the TCP transport
- file transfer
- low-level rendering hooks
- server authority or RosaServer integration

Those concerns belong to `client` and `rs_integration`.

## Checks

Run the focused Lua checks from this repository root:

```sh
lua test/input_menu.lua
lua test/plugin_scope.lua
```

## Related Repositories

- [`client`](https://github.com/SubRosaCustom/client): native client mod that hosts this Lua runtime, not public as of writing this as to prevent cheat development
- [`rs_integration`](https://github.com/SubRosaCustom/rs_integration): server-side integration that syncs this repository to clients
- [`RosaServerCore`](https://github.com/jpxs-intl/RosaServerCore): the closest upstream conceptual equivalent on the server side

## Developer examples

`modes/src_example/init.lua` handles navigation and lifecycle. Each `pageN.lua`
contains its own lesson: menu functions, local camera controls, a CMO in a 2D
panel, or world-to-screen projection. Set `defaultGameMode: src_example` in the
synced client configuration for a fresh runtime without a persistent mode, then
open the game menu and use the four page buttons. Existing persistent mode state
wins over that setting. Page 3 defaults to `custom_ball.cmo`, which already exists
at `src_test_mode/subrosacustom/assets/custom_ball.cmo` in this workspace. Use the
example with that existing synced test bundle, or enter the exact path of a CMO
in your own synced assets. This mode does not copy or supply an asset. Leaving a
page clears its state and restores any captured camera state. The native CMO
cache has no per-model unload API and lasts until runtime teardown.

The admin example consists of exactly two implementation files:
`plugins/srcAdminExample.lua` here and
`rs_integration/plugins/srcAdminExample.lua` on the server. They use the existing
runtime JSON library and SRC event APIs. Enable both through the usual plugin
configuration and press Delete during play; it opens the native tab-menu panel
and cursor directly. Press Delete again to close it. Closing or disabling the
plugin restores the previous local tab and cursor state. Delete is SDL scancode
76. The toggle ignores foreign tab menus, pause menus and non-game screens;
this panel contains no text inputs. Lua has no native text-focus query, so an
unrelated plugin drawing a text field on the same custom tab remains a conflict.
Core key binds do not consume game input. Refresh the player list, choose a player and action,
confirm, then apply. Every successful action consumes its server snapshot, so
refresh before applying another action.

The server requires the existing `Player.isAdmin` permission on every request.
Actions include go-to, bring, kick, a 1–1440 minute account ban, and explicit god
mode on/off. Teleports require both players' active, living humans outside vehicles and move
beside the destination; the example does not search for safe ground. Kick uses the existing
`srcutils` connection-timeout convention. Ban updates and saves the account
before disconnecting. There is no mute action or permission-granting control.
