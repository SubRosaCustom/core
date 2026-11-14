---@diagnostic disable: lowercase-global

---@class FunctionData
---@field name string
---@field event_name string

---@class HookGlobal
---@field continue HookContinue
---@field override HookOverride
---@field plugins table<string, Plugin>
---@field persistentMode string
---@field add fun(eventName: "ConfigLoaded", name: string, func: hooks.ConfigLoaded)
---@field add fun(eventName: "Logic", name: string, func: hooks.Logic)
---@field add fun(eventName: "DrawUI", name: string, func: hooks.DrawUI)
---@field add fun(eventName: "RenderFrame", name: string, func: hooks.RenderFrame)
---@field add fun(eventName: "PostRenderFrame", name: string, func: function)
---@field add fun(eventName: "DrawMapMarkers", name: string, func: hooks.DrawMapMarkers)
---@field add fun(eventName: "DrawHuman", name: string, func: hooks.DrawHuman)
---@field add fun(eventName: "DrawHumanLabels", name: string, func: hooks.DrawHumanLabels)
---@field add fun(eventName: "DrawMapMenu", name: string, func: hooks.DrawMapMenu)
---@field add fun(eventName: "DrawMenuItems", name: string, func: hooks.DrawMenuItems)
---@field add fun(eventName: "PostDrawMenuItems", name: string, func: hooks.PostDrawMenuItems)
---@field add fun(eventName: "Draw3D", name: string, func: hooks.Draw3D)
---@field add fun(eventName: "DrawModels", name: string, func: hooks.DrawModels)
---@field add fun(eventName: "WriteClientData", name: string, func: hooks.WriteClientData)
---@field add fun(eventName: "ExitGameCall", name: string, func: hooks.ExitGameCall)
---@field add fun(eventName: "PlayerControlHandler", name: string, func: hooks.PlayerControlHandler)
---@field add fun(eventName: "PostPlayerControlHandler", name: string, func: hooks.PostPlayerControlHandler)
---@field add fun(eventName: string, name: string, func: function)
---@field once fun(eventName: string, func: function)
---@field remove fun(eventName: string, name: string)
---@field run fun(eventName: string, ...: any): boolean
---@field enable fun(eventName: string): boolean
---@field disable fun(eventName: string): boolean
---@field clear fun()
---@field resetCache fun()
---@field autoCompletePlugin fun(beginning: string, nameSpace?: string): string|nil, Plugin|nil
---@field getPluginByName fun(name: string, nameSpace?: string): Plugin|nil
---@field _function_data table<function, FunctionData>
---@field _generation integer
---@type HookGlobal
hook = hook or {}

local _hooks = {}
local _temp_hooks = {}
local _cache = {}
local _next_order = 0

-- Metadata must not keep removed hooks or callbacks from old plugin definitions alive.
hook._function_data = setmetatable({}, { __mode = "k", })
hook._generation = 0

hook.continue = 1
hook.override = 2
hook.plugins = hook.plugins or {}
hook.persistentMode = hook.persistentMode or (__src_persistent_mode or "")

function hook._next_order()
	_next_order = _next_order + 1
	return _next_order
end

function hook.resetCache()
	hook._generation = hook._generation + 1
	hook.clear()
	_cache = {}

	local enable = hook.enable

	for event_name, funcs in pairs(_hooks) do
		enable(event_name)
		_cache[event_name] = {}
		for _, func in pairs(funcs) do
			table.insert(_cache[event_name], func)
		end
	end

	local sorting_hooks = {}
	for _, plugin in pairs(hook.plugins) do
		if plugin.isEnabled then
			for event_name, func in pairs(plugin.hooks) do
				if _cache[event_name] == nil then
					enable(event_name)
					_cache[event_name] = {}
				end
				table.insert(_cache[event_name], func)
			end

			for event_name, infos in pairs(plugin.polyHooks) do
				if sorting_hooks[event_name] == nil then
					sorting_hooks[event_name] = {}
				end

				for _, info in ipairs(infos) do
					table.insert(sorting_hooks[event_name], info)
					hook._function_data[info.func] = {
						name = info.name,
						event_name = event_name,
					}
				end
			end
		end
	end

	for event_name, infos in pairs(sorting_hooks) do
		if _cache[event_name] == nil then
			enable(event_name)
			_cache[event_name] = {}
		end

		table.sort(infos, function(a, b)
			if a.priority == b.priority then
				return a.order < b.order
			end
			return a.priority < b.priority
		end)

		for _, info in ipairs(infos) do
			table.insert(_cache[event_name], info.func)
		end
	end
end

function hook.add(event_name, name, func)
	assert(type(event_name) == "string")
	assert(type(name) == "string")
	assert(type(func) == "function")

	if _hooks[event_name] == nil then
		_hooks[event_name] = {}
	end

	_hooks[event_name][name] = func
	hook._function_data[func] = {
		name = name,
		event_name = event_name,
	}
	hook.resetCache()
end

function hook.once(event_name, func)
	assert(type(event_name) == "string")
	assert(type(func) == "function")

	if _temp_hooks[event_name] == nil then
		_temp_hooks[event_name] = {}
	end

	table.insert(_temp_hooks[event_name], func)
	hook.enable(event_name)
end

function hook.remove(event_name, name)
	assert(type(event_name) == "string")
	if _hooks[event_name] == nil then
		return
	end

	_hooks[event_name][name] = nil
	hook.resetCache()
end

function hook.run(event_name, ...)
	local had_temp = false

	if _temp_hooks[event_name] ~= nil then
		local temp_override = false
		for _, temp_hook in ipairs(_temp_hooks[event_name]) do
			local result = temp_hook(...)

			if result == hook.override or result == true then
				temp_override = true
				break
			end
		end
		_temp_hooks[event_name] = nil
		if temp_override then
			return true
		end
		had_temp = true
	end

	local cache = _cache[event_name]
	if cache ~= nil then
		for _, hook_func in ipairs(cache) do
			local result = hook_func(...)

			if result == hook.continue then
				return false
			end
			if result == hook.override then
				return true
			end
		end
	elseif had_temp then
		hook.disable(event_name)
	end

	return false
end

function hook.autoCompletePlugin(beginning, name_space)
	beginning = beginning:lower()

	for _, plugin in pairs(hook.plugins) do
		if (not name_space or plugin.nameSpace == name_space) and plugin.fileName:lower():startsWith(beginning) then
			return plugin.fileName, plugin
		end
	end

	return nil, nil
end

function hook.getPluginByName(name, name_space)
	name = name:lower()

	for _, plugin in pairs(hook.plugins) do
		if (not name_space or plugin.nameSpace == name_space) and plugin.fileName:lower() == name then
			return plugin
		end
	end

	return nil
end

return hook
