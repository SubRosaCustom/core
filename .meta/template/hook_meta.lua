--# selene: allow(unused_variable)
--# selene: allow(unscoped_variables)
---@meta

---@alias HookReturn 1 | 2 | nil
---@alias HookNoOverride 1 | nil

---@alias hooks.ConfigLoaded fun(isReload: boolean): HookReturn
---@alias hooks.Draw3D fun(): HookReturn
---@alias hooks.DrawModels fun(): HookReturn
---@alias hooks.DrawHuman fun(human: Human): HookReturn
---@alias hooks.DrawHumanLabels fun(human: Human): HookReturn
---@alias hooks.DrawMapMarkers fun(): HookReturn
---@alias hooks.DrawMapMenu fun(): HookReturn
---@alias hooks.DrawMenuItems fun(): HookReturn
---@alias hooks.DrawUI fun(): HookReturn
---@alias hooks.ExitGameCall fun(): HookReturn
---@alias hooks.Logic fun(): HookReturn
---@alias hooks.PlayerControlHandler fun(): HookReturn
---@alias hooks.PostPlayerControlHandler fun(): HookReturn
---@alias hooks.PostRenderFrame fun(): HookReturn
---@alias hooks.RenderFrame fun(): HookReturn
---@alias hooks.WriteClientData fun(): HookReturn

---@alias hooks.SRC_InitItemType fun(): HookReturn
