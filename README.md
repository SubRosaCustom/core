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

## Scope

`core` owns client Lua behavior.

It does not own:

- native hooks
- the TCP transport
- file transfer
- low-level rendering hooks
- server authority or RosaServer integration

Those concerns belong to `client` and `rs_integration`.

## Related Repositories

- [`client`](https://github.com/SubRosaCustom/client): native client mod that hosts this Lua runtime
- [`rs_integration`](https://github.com/SubRosaCustom/rs_integration): server-side integration that syncs this repository to clients
- [`RosaServerCore`](https://github.com/jpxs-intl/RosaServerCore): the closest upstream conceptual equivalent on the server side
