---@diagnostic disable: lowercase-global

local json = require("main.json")

local disabled_plugins_file = "disabledPlugins.json"

local function printScoped(...)
	print("\27[34m[SRCC/Plugins]\27[0m " .. concatVarArgs("\t", ...))
end

local disabledPluginsMap = {}

local function replaceDisabledPlugins(nextDisabledPluginsMap)
	for name, _ in pairs(disabledPluginsMap) do
		disabledPluginsMap[name] = nil
	end

	for name, _ in pairs(nextDisabledPluginsMap) do
		disabledPluginsMap[name] = true
	end
end

local function loadDisabledPlugins()
	local source = __src_read_file(disabled_plugins_file)
	if not source or source == "" then
		replaceDisabledPlugins({})
		return true
	end

	local ok, decoded = pcall(json.decode, source)
	if not ok or type(decoded) ~= "table" then
		printScoped(string.format("\27[33mFailed to parse %s", disabled_plugins_file))
		return false
	end

	local nextDisabledPluginsMap = {}
	for _, name in ipairs(decoded) do
		if type(name) == "string" and name ~= "" then
			nextDisabledPluginsMap[name] = true
		end
	end

	replaceDisabledPlugins(nextDisabledPluginsMap)
	return true
end

loadDisabledPlugins()

---@class PluginHookInfo
---@field func function
---@field priority number
---@field name string

---@class PluginHookOptions
---@field priority number?

---@class Plugin
---@field name string
---@field author string
---@field description string
---@field hooks table<string, function>
---@field polyHooks table<string, PluginHookInfo[]>
---@field defaultConfig table
---@field config table
---@field isEnabled boolean
---@field fileName string
---@field fullFileName string?
---@field doAutoReload boolean
---@field nameSpace string
---@field entryPath string
---@field addHook fun(self: Plugin, eventName: "ConfigLoaded", func: hooks.ConfigLoaded, options?: PluginHookOptions)
---@field addHook fun(self: Plugin, eventName: "Logic", func: hooks.Logic, options?: PluginHookOptions)
---@field addHook fun(self: Plugin, eventName: "DrawUI", func: hooks.DrawUI, options?: PluginHookOptions)
---@field addHook fun(self: Plugin, eventName: "RenderFrame", func: hooks.RenderFrame, options?: PluginHookOptions)
---@field addHook fun(self: Plugin, eventName: "PostRenderFrame", func: function, options?: PluginHookOptions)
---@field addHook fun(self: Plugin, eventName: "DrawHuman", func: hooks.DrawHuman, options?: PluginHookOptions)
---@field addHook fun(self: Plugin, eventName: "DrawHumanLabels", func: hooks.DrawHumanLabels, options?: PluginHookOptions)
---@field addHook fun(self: Plugin, eventName: "DrawMapMenu", func: hooks.DrawMapMenu, options?: PluginHookOptions)
---@field addHook fun(self: Plugin, eventName: "DrawMenuItems", func: hooks.DrawMenuItems, options?: PluginHookOptions)
---@field addHook fun(self: Plugin, eventName: "Draw3D", func: hooks.Draw3D, options?: PluginHookOptions)
---@field addHook fun(self: Plugin, eventName: "DrawModels", func: hooks.DrawModels, options?: PluginHookOptions)
---@field addHook fun(self: Plugin, eventName: "WriteClientData", func: hooks.WriteClientData, options?: PluginHookOptions)
---@field addHook fun(self: Plugin, eventName: "ExitGameCall", func: hooks.ExitGameCall, options?: PluginHookOptions)
---@field addHook fun(self: Plugin, eventName: "PlayerControlHandler", func: hooks.PlayerControlHandler, options?: PluginHookOptions)
---@field addHook fun(self: Plugin, eventName: "PostPlayerControlHandler", func: hooks.PostPlayerControlHandler, options?: PluginHookOptions)
---@field addHook fun(self: Plugin, eventName: "DrawMapMarkers", func: hooks.DrawMapMarkers, options?: PluginHookOptions)
---@field addHook fun(self: Plugin, eventName: string, func: function, options?: PluginHookOptions)

---@type Plugin
local plugin = {}
plugin.__index = plugin

function plugin:enable(shouldSave)
	if not self.isEnabled then
		self.isEnabled = true
		hook.resetCache()
		self:callEnableHandlers(false)

		if shouldSave then
			disabledPluginsMap[self.fileName] = nil
		end
	end
end

function plugin:disable(shouldSave)
	if self.isEnabled then
		self.isEnabled = false
		self:callDisableHandlers(false)
		hook.resetCache()

		if shouldSave then
			disabledPluginsMap[self.fileName] = true
		end
	end
end

function plugin:print(...)
	local prefix = "\27[38;5;33m[" .. self.name .. "]\27[0m "
	print(prefix .. concatVarArgs("\t", ...))
end

function plugin:warn(...)
	local prefix = "\27[33m[" .. self.name .. "]\27[0m "
	print(prefix .. concatVarArgs("\t", ...))
end

function plugin:require(modName)
	if not self.requireCache[modName] then
		local fileName = self.nameSpace .. "/" .. self.fileName .. "/" .. modName .. ".lua"
		local loadedFile = assert(loadfile(fileName))
		self.requireCache[modName] = { loadedFile(self) }
	end

	return unpack(self.requireCache[modName])
end

function plugin:addHook(eventName, func, options)
	if not self.polyHooks[eventName] then
		self.polyHooks[eventName] = {}
	end

	options = options or {}
	table.insert(self.polyHooks[eventName], {
		func = func,
		priority = options.priority or 0,
		name = self.name,
	})
end

function plugin:addEnableHandler(func)
	table.insert(self.polyEnableHandlers, func)
end

function plugin:callEnableHandlers(isReload)
	for _, func in ipairs(self.polyEnableHandlers) do
		func(isReload)
	end
	self.onEnable(isReload)
end

function plugin:addDisableHandler(func)
	table.insert(self.polyDisableHandlers, func)
end

function plugin:callDisableHandlers(isReload)
	self.onDisable(isReload)
	for _, func in ipairs(self.polyDisableHandlers) do
		func(isReload)
	end
end

function plugin:setConfig()
	self.config = {}

	for k, v in pairs(self.defaultConfig) do
		self.config[k] = v
	end

	local conf = config[self.nameSpace] and config[self.nameSpace][self.fileName]
	if conf then
		for k, v in pairs(conf) do
			self.config[k] = v
		end
	end
end

function plugin:load(isEnabled, isReload)
	local loadedFile = assert(loadfile(self.entryPath))

	local success, err = pcall(function()
		loadedFile(self)
	end)
	if not success then
		printScoped(string.format("\27[38;5;196mFailed to load plugin '%s': %s", self.entryPath, err or "unknown"))
		self:disable(false)
		return false
	end

	self:setConfig()
	self.isEnabled = isEnabled
	if self.isEnabled then
		hook.resetCache()
		self:callEnableHandlers(isReload)
	end

	return true
end

function plugin:reload()
	local isEnabled = self.isEnabled

	if isEnabled then
		self:callDisableHandlers(true)
	end

	self.hooks = {}
	self.polyHooks = {}
	self.polyEnableHandlers = {}
	self.polyDisableHandlers = {}
	self.defaultConfig = {}
	self.requireCache = {}

	hook.resetCache()
	self:load(isEnabled, true)
	hook.resetCache()
end

function plugin.onEnable(_) end
function plugin.onDisable(_) end

local function newPlugin(nameSpace, stem)
	return setmetatable({
		name = "Unknown",
		author = "Unknown",
		description = "n/a",
		hooks = {},
		polyHooks = {},
		polyEnableHandlers = {},
		polyDisableHandlers = {},
		defaultConfig = {},
		config = {},
		isEnabled = true,
		requireCache = {},
		nameSpace = nameSpace,
		fileName = stem,
		doAutoReload = false,
	}, plugin)
end

local function collectEntries(nameSpace)
	local entries = {}
	for _, path in ipairs(__src_list_scripts()) do
		if path:startsWith(nameSpace .. "/") then
			local relative = path:sub(#nameSpace + 2)

			local single = relative:match("^([^/]+)%.lua$")
			if single then
				entries[single] = {
					stem = single,
					path = path,
					fullFileName = relative,
				}
			end

			local folder = relative:match("^([^/]+)/init%.lua$")
			if folder then
				entries[folder] = {
					stem = folder,
					path = path,
					fullFileName = nil,
				}
			end
		end
	end
	return entries
end

local function plugin_key(nameSpace, stem)
	return nameSpace .. ":" .. stem
end

local function shouldStartPluginEnabled(plug)
	return not disabledPluginsMap[plug.fileName]
end

local function shouldStartModeEnabled(plug)
	return plug.fileName == hook.persistentMode
end

local function reconcileDisabledPlugins()
	for _, plug in pairs(hook.plugins) do
		if plug.nameSpace == "plugins" then
			local should_enable = shouldStartPluginEnabled(plug)
			if should_enable and not plug.isEnabled then
				plug:enable(false)
				printScoped("Enabled plugin " .. plug.fileName)
			elseif (not should_enable) and plug.isEnabled then
				plug:disable(false)
				printScoped("Disabled plugin " .. plug.fileName)
			end
		end
	end
end

local function discoverInNameSpace(nameSpace, isEnabledFunc)
	local numLoaded = 0
	local numErrored = 0

	local entries = collectEntries(nameSpace)
	for stem, entry in pairs(entries) do
		local key = plugin_key(nameSpace, stem)
		if not hook.plugins[key] then
			local plug = newPlugin(nameSpace, stem)
			plug.entryPath = entry.path
			plug.fullFileName = entry.fullFileName

			hook.plugins[key] = plug
			local isEnabled = isEnabledFunc(plug)

			printScoped(string.format("Loading \27[30;1m%s.\27[0m%s", nameSpace, stem))
			local success = plug:load(isEnabled, false)
			if success then
				numLoaded = numLoaded + 1
			else
				numErrored = numErrored + 1
			end
		end
	end

	return numLoaded, numErrored
end

local function loadPluginNameSpace(nameSpace, isEnabledFunc)
	printScoped("Loading " .. nameSpace .. "...")

	local numLoaded, numErrored = discoverInNameSpace(nameSpace, isEnabledFunc)
	printScoped("Loaded " .. numLoaded .. " " .. nameSpace)
	if numErrored > 0 then
		printScoped(string.format("\27[38;5;196mFailed to load %d %s", numErrored, nameSpace))
	end
end

local function loadPlugins()
	if hook.persistentMode == "" and type(config.defaultGameMode) == "string" then
		hook.persistentMode = config.defaultGameMode
	end

	loadPluginNameSpace("plugins", shouldStartPluginEnabled)
	loadPluginNameSpace("modes", shouldStartModeEnabled)
	hook.resetCache()
end

function discoverNewPlugins()
	local numLoaded = 0
	local a, b = discoverInNameSpace("plugins", shouldStartPluginEnabled)
	numLoaded = numLoaded + a + b
	local c, d = discoverInNameSpace("modes", shouldStartModeEnabled)
	numLoaded = numLoaded + c + d
	hook.resetCache()
	return numLoaded
end

local function reloadConfigOfPlugins()
	for _, plug in pairs(hook.plugins) do
		plug:setConfig()
	end
end

hook.add("ConfigLoaded", "main.plugins", function(isReload)
	if not isReload then
		loadPlugins()
	else
		reloadConfigOfPlugins()
	end
end)

local function pluginInfoFromPath(path)
	for _, nameSpace in ipairs({ "plugins", "modes" }) do
		if path:startsWith(nameSpace .. "/") then
			local relative = path:sub(#nameSpace + 2)
			local single = relative:match("^([^/]+)%.lua$")
			if single then
				return nameSpace, single
			end

			local folder = relative:match("^([^/]+)/")
			if folder then
				return nameSpace, folder
			end
		end
	end

	return nil, nil
end

local function entryStillExists(entryPath)
	return __src_read_file(entryPath) ~= nil
end

local function applyPatch(changedPaths)
	local touched = {}
	local disabled_plugins_changed = false
	for _, path in ipairs(changedPaths) do
		if path == disabled_plugins_file then
			disabled_plugins_changed = true
		end

		local nameSpace, name = pluginInfoFromPath(path)
		if nameSpace and name then
			touched[nameSpace] = touched[nameSpace] or {}
			touched[nameSpace][name] = true
		end
	end

	local entriesByNameSpace = {
		plugins = collectEntries("plugins"),
		modes = collectEntries("modes"),
	}

	local function shouldStartEnabled(nameSpace, plug)
		if nameSpace == "modes" then
			return shouldStartModeEnabled(plug)
		end

		return shouldStartPluginEnabled(plug)
	end

	for nameSpace, touchedNames in pairs(touched) do
		for name, _ in pairs(touchedNames) do
			local key = plugin_key(nameSpace, name)
			local plug = hook.plugins[key]
			local entry = entriesByNameSpace[nameSpace] and entriesByNameSpace[nameSpace][name] or nil

			if not entry then
				if plug then
					plug:disable(false)
					hook.plugins[key] = nil
					printScoped("Removed " .. nameSpace .. " " .. name)
				end
			elseif plug then
				plug.entryPath = entry.path
				plug.fullFileName = entry.fullFileName

				if entryStillExists(plug.entryPath) then
					plug:reload()
					printScoped("Reloaded " .. nameSpace .. " " .. name)
				else
					plug:disable(false)
					hook.plugins[key] = nil
					printScoped("Removed " .. nameSpace .. " " .. name)
				end
			else
				local newPlug = newPlugin(nameSpace, name)
				newPlug.entryPath = entry.path
				newPlug.fullFileName = entry.fullFileName
				hook.plugins[key] = newPlug

				local ok = newPlug:load(shouldStartEnabled(nameSpace, newPlug), false)
				if ok then
					printScoped("Loaded new " .. nameSpace .. " " .. name)
				end
			end
		end
	end

	if disabled_plugins_changed and loadDisabledPlugins() then
		reconcileDisabledPlugins()
	end

	discoverNewPlugins()
	hook.resetCache()
	return true
end

return {
	applyPatch = applyPatch,
	loadPlugins = loadPlugins,
	discoverNewPlugins = discoverNewPlugins,
	plugin = plugin,
}
