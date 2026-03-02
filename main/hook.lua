---@diagnostic disable: lowercase-global

---@class FunctionData
---@field name string
---@field eventName string

---@class HookRunInfo
---@field time number
---@field name string

---@class HookInfo
---@field time number
---@field runs HookRunInfo[]

---@class HookGlobal
---@field continue HookContinue
---@field override HookOverride
---@field plugins table<string, Plugin>
---@field persistentMode string
---@field add fun(eventName: "ConfigLoaded", name: string, func: hooks.ConfigLoaded)
---@field add fun(eventName: "Logic", name: string, func: hooks.Logic)
---@field add fun(eventName: "DrawUI", name: string, func: hooks.DrawUI)
---@field add fun(eventName: "RenderFrame", name: string, func: hooks.RenderFrame)
---@field add fun(eventName: "DrawMapMarkers", name: string, func: hooks.DrawMapMarkers)
---@field add fun(eventName: "DrawHuman", name: string, func: hooks.DrawHuman)
---@field add fun(eventName: "DrawHumanLabels", name: string, func: hooks.DrawHumanLabels)
---@field add fun(eventName: "DrawMapMenu", name: string, func: hooks.DrawMapMenu)
---@field add fun(eventName: "DrawMenuItems", name: string, func: hooks.DrawMenuItems)
---@field add fun(eventName: "Draw3D", name: string, func: hooks.Draw3D)
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
---@field _functionData table<function, FunctionData>
---@field _lastRunInfo table<string, HookInfo>
---@type HookGlobal
hook = hook or {}

local _hooks = {}
local _tempHooks = {}
local _cache = {}
local _knownEngineEvents = {
	Logic = true,
	DrawHuman = true,
	RenderFrame = true,
	DrawUI = true,
	WriteClientData = true,
	DrawMapMenu = true,
	DrawMenuItems = true,
	Draw3D = true,
	ExitGameCall = true,
	PlayerControlHandler = true,
	PostPlayerControlHandler = true,
	DrawMapMarkers = true,
	DrawHumanLabels = true,
}
local _enabledEngineEvents = {}

hook._functionData = {}
hook._lastRunInfo = {}

hook.continue = 1
hook.override = 2
hook.plugins = hook.plugins or {}
hook.persistentMode = hook.persistentMode or (__src_persistent_mode or "")

function hook.enable(eventName)
	if _knownEngineEvents[eventName] then
		_enabledEngineEvents[eventName] = true
		return true
	end

	return false
end

function hook.disable(eventName)
	if _knownEngineEvents[eventName] then
		_enabledEngineEvents[eventName] = nil
		return true
	end

	return false
end

function hook.clear()
	_enabledEngineEvents = {}
end

function hook.resetCache()
	hook.clear()
	_cache = {}

	local enable = hook.enable

	for eventName, funcs in pairs(_hooks) do
		enable(eventName)
		_cache[eventName] = {}
		for _, func in pairs(funcs) do
			table.insert(_cache[eventName], func)
		end
	end

	local sortingHooks = {}
	for _, plugin in pairs(hook.plugins) do
		if plugin.isEnabled then
			for eventName, func in pairs(plugin.hooks) do
				if _cache[eventName] == nil then
					enable(eventName)
					_cache[eventName] = {}
				end
				table.insert(_cache[eventName], func)
			end

			for eventName, infos in pairs(plugin.polyHooks) do
				if sortingHooks[eventName] == nil then
					sortingHooks[eventName] = {}
				end

				for _, info in ipairs(infos) do
					table.insert(sortingHooks[eventName], info)
					hook._functionData[info.func] = {
						name = info.name,
						eventName = eventName,
					}
				end
			end
		end
	end

	for eventName, infos in pairs(sortingHooks) do
		if _cache[eventName] == nil then
			enable(eventName)
			_cache[eventName] = {}
		end

		table.sort(infos, function(a, b)
			return a.priority < b.priority
		end)

		for _, info in ipairs(infos) do
			table.insert(_cache[eventName], info.func)
		end
	end
end

function hook.add(eventName, name, func)
	assert(type(eventName) == "string")
	assert(type(name) == "string")
	assert(type(func) == "function")

	if _hooks[eventName] == nil then
		_hooks[eventName] = {}
	end

	_hooks[eventName][name] = func
	hook._functionData[func] = {
		name = name,
		eventName = eventName,
	}
	hook.resetCache()
end

function hook.once(eventName, func)
	assert(type(eventName) == "string")
	assert(type(func) == "function")

	if _tempHooks[eventName] == nil then
		_tempHooks[eventName] = {}
	end

	table.insert(_tempHooks[eventName], func)
	hook.enable(eventName)
end

function hook.remove(eventName, name)
	assert(type(eventName) == "string")
	if _hooks[eventName] == nil then
		return
	end

	_hooks[eventName][name] = nil
	hook.resetCache()
end

function hook.run(eventName, ...)
	if _knownEngineEvents[eventName] and not _enabledEngineEvents[eventName] then
		return false
	end

	local hadTemp = false
	local hookInfo = {
		runs = {},
	}
	local hookTotalStart = os.clock()

	if _tempHooks[eventName] ~= nil then
		local tempOverride = false
		for _, tempHook in ipairs(_tempHooks[eventName]) do
			local hookStart = os.clock()
			local res = tempHook(...)
			local funcInfo = hook._functionData[tempHook]

			table.insert(hookInfo.runs, {
				time = os.clock() - hookStart,
				name = funcInfo and funcInfo.name or "unknown",
			})

			if res == hook.override or res == true then
				tempOverride = true
				break
			end
		end
		_tempHooks[eventName] = nil
		if tempOverride then
			return true
		end
		hadTemp = true
	end

	local cache = _cache[eventName]
	if cache ~= nil then
		for _, hookFunc in pairs(cache) do
			local hookStart = os.clock()
			local res = hookFunc(...)
			local funcInfo = hook._functionData[hookFunc]

			table.insert(hookInfo.runs, {
				time = os.clock() - hookStart,
				name = funcInfo and funcInfo.name or "unknown",
			})

			if res == hook.continue then
				return false
			end
			if res == hook.override then
				return true
			end
		end
		hook._lastRunInfo[eventName] = {
			time = os.clock() - hookTotalStart,
			runs = hookInfo.runs,
		}
	elseif hadTemp then
		hook.disable(eventName)
	end

	return false
end

function hook.autoCompletePlugin(beginning, nameSpace)
	beginning = beginning:lower()

	for _, plugin in pairs(hook.plugins) do
		if (not nameSpace or plugin.nameSpace == nameSpace) and plugin.fileName:lower():startsWith(beginning) then
			return plugin.fileName, plugin
		end
	end

	return nil, nil
end

function hook.getPluginByName(name, nameSpace)
	name = name:lower()

	for _, plugin in pairs(hook.plugins) do
		if (not nameSpace or plugin.nameSpace == nameSpace) and plugin.fileName:lower() == name then
			return plugin
		end
	end

	return nil
end

return hook
