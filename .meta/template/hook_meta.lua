--# selene: allow(unused_variable)
--# selene: allow(unscoped_variables)
---@meta

---Return hook.continue (1) to stop running later handlers and report no override.
---Return hook.override (2) to stop running later handlers and report an override.
---Return nil to let the remaining handlers run.
---@alias HookReturn 1 | 2 | nil
---@alias HookNoOverride 1 | nil

---Called after the config file is (re)loaded.
---isReload is false on the first load after a runtime start and true afterwards.
---@alias hooks.ConfigLoaded fun(isReload: boolean): HookReturn

---Called every game logic tick.
---@alias hooks.Logic fun(): HookReturn

---Called during 3D world rendering. Use for renderer 3D drawing such as debug
---lines/boxes and renderer:renderObject.
---@alias hooks.Draw3D fun(): HookReturn

---Called when the game renders world models.
---@alias hooks.DrawModels fun(): HookReturn

---Called when a human is rendered.
---@alias hooks.DrawHuman fun(human: Human): HookReturn

---Called after a player name label has been drawn above a human.
---x/y are the label's screen position and size is the label's text size.
---@alias hooks.DrawHumanLabels fun(player: Player, x: number, y: number, size: number): HookReturn

---Called when map/minimap markers are drawn.
---originX/originY are the world-space origin of the projection (big map legend
---position, or the local human position for the minimap) and scale converts
---world units to map pixels.
---screenX/screenY, yaw and minimapSize are only passed for the rotated minimap.
---@alias hooks.DrawMapMarkers fun(originX: number, originY: number, scale?: number, screenX?: number, screenY?: number, yaw?: number, minimapSize?: number): HookReturn

---Called when the fullscreen map menu draws its text.
---@alias hooks.DrawMapMenu fun(): HookReturn

---Called when in-game menu items are drawn. Use for renderer.menu widgets.
---@alias hooks.DrawMenuItems fun(): HookReturn

---Called before the game draws a player's menus (world/team menus).
---The return value is ignored; the game's own menu drawing always runs.
---@alias hooks.DrawPlayerMenus fun(player: Player): HookReturn

---Called after the game has drawn a player's menus.
---@alias hooks.PostDrawPlayerMenus fun(player: Player): HookReturn

---Called when the in-game HUD is drawn. Use for renderer 2D drawing.
---@alias hooks.DrawUI fun(): HookReturn

---Called when the game is about to exit.
---@alias hooks.ExitGameCall fun(): HookReturn

---Called before the game's player control handling runs for the local player.
---Return hook.override to skip the game's own control handling.
---@alias hooks.PlayerControlHandler fun(player: Player): HookReturn

---Called after the game's player control handling ran for the local player.
---@alias hooks.PostPlayerControlHandler fun(player: Player): HookReturn

---Called before a frame is rendered.
---@alias hooks.RenderFrame fun(): HookReturn

---Called after a frame has been rendered.
---@alias hooks.PostRenderFrame fun(): HookReturn

---Called when the client is about to write its networked input/state data.
---Return hook.override to skip the game's own write.
---@alias hooks.WriteClientData fun(): HookReturn
