---@diagnostic disable: lowercase-global

local json = require("main.json")

local disabled_plugins_file = "disabledPlugins.json"

local function print_scoped(...)
	print("\27[34m[SRCC/Plugins]\27[0m " .. concatVarArgs("\t", ...))
end

local disabled_plugins = {}
local loading_plugin = nil
local server_event_registration_phase = nil
local new_plugin

local function replace_disabled_plugins(next_disabled_plugins)
	for name, _ in pairs(disabled_plugins) do
		disabled_plugins[name] = nil
	end

	for name, _ in pairs(next_disabled_plugins) do
		disabled_plugins[name] = true
	end
end

local function load_disabled_plugins()
	local source = __src_read_file(disabled_plugins_file)
	if not source or source == "" then
		replace_disabled_plugins({})
		return true
	end

	local ok, decoded = pcall(json.decode, source)
	if not ok or type(decoded) ~= "table" then
		print_scoped(string.format("\27[33mFailed to parse %s", disabled_plugins_file))
		return false
	end

	local next_disabled_plugins = {}
	for _, name in ipairs(decoded) do
		if type(name) == "string" and name ~= "" then
			next_disabled_plugins[name] = true
		end
	end

	replace_disabled_plugins(next_disabled_plugins)
	return true
end

load_disabled_plugins()

---@class PluginHookInfo
---@field func function
---@field priority number
---@field name string
---@field order integer

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
---@field private _server_event_handlers table<string, function[]>
---@field private _active_server_event_handlers table<string, function[]>
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

function plugin:enable(should_save)
	if not self.isEnabled then
		if not self:_activate(false) then
			return false
		end

		if should_save then
			disabled_plugins[self.fileName] = nil
		end
	end

	return true
end

function plugin:disable(should_save)
	if self.isEnabled then
		local success = self:_deactivate(false)

		if should_save then
			disabled_plugins[self.fileName] = true
		end

		return success
	end

	return true
end

function plugin:print(...)
	local prefix = "\27[38;5;33m[" .. self.name .. "]\27[0m "
	print(prefix .. concatVarArgs("\t", ...))
end

function plugin:warn(...)
	local prefix = "\27[33m[" .. self.name .. "]\27[0m "
	print(prefix .. concatVarArgs("\t", ...))
end

function plugin:require(module_name)
	if not self.requireCache[module_name] then
		local file_name = self.nameSpace .. "/" .. self.fileName .. "/" .. module_name .. ".lua"
		local loaded_file = assert(loadfile(file_name))
		local previous_loading_plugin = loading_plugin
		local previous_registration_phase = server_event_registration_phase
		loading_plugin = self
		server_event_registration_phase = "entry"
		local results = { pcall(loaded_file, self) }
		loading_plugin = previous_loading_plugin
		server_event_registration_phase = previous_registration_phase

		if not results[1] then
			error(results[2], 0)
		end

		table.remove(results, 1)
		self.requireCache[module_name] = results
	end

	return unpack(self.requireCache[module_name])
end

function plugin:addHook(event_name, func, options)
	if not self.polyHooks[event_name] then
		self.polyHooks[event_name] = {}
	end

	options = options or {}
	table.insert(self.polyHooks[event_name], {
		func = func,
		priority = options.priority or 0,
		name = self.name,
		order = hook._next_order(),
	})
end

function plugin:addEnableHandler(func)
	table.insert(self.polyEnableHandlers, func)
end

function plugin:callEnableHandlers(is_reload)
	for _, func in ipairs(self.polyEnableHandlers) do
		func(is_reload)
	end
	self.onEnable(is_reload)
end

function plugin:addDisableHandler(func)
	table.insert(self.polyDisableHandlers, func)
end

function plugin:callDisableHandlers(is_reload)
	local success = true
	local ok, err = pcall(self.onDisable, is_reload)
	if not ok then
		success = false
		self:warn("Disable handler failed: " .. tostring(err))
	end

	for _, func in ipairs(self.polyDisableHandlers) do
		ok, err = pcall(func, is_reload)
		if not ok then
			success = false
			self:warn("Disable handler failed: " .. tostring(err))
		end
	end

	return success
end

function plugin:setConfig()
	self.config = {}

	for key, value in pairs(self.defaultConfig) do
		self.config[key] = value
	end

	local conf = config[self.nameSpace] and config[self.nameSpace][self.fileName]
	if conf then
		for key, value in pairs(conf) do
			self.config[key] = value
		end
	end
end

function plugin:_activate(is_reload)
	self._active_server_event_handlers = {}
	local previous_loading_plugin = loading_plugin
	local previous_registration_phase = server_event_registration_phase
	loading_plugin = self
	server_event_registration_phase = "activation"
	local success, err = pcall(self.callEnableHandlers, self, is_reload)
	loading_plugin = previous_loading_plugin
	server_event_registration_phase = previous_registration_phase
	if not success then
		self:warn("Enable handler failed: " .. tostring(err))
		self:callDisableHandlers(is_reload)
		self._active_server_event_handlers = {}
		self.isEnabled = false
		hook.resetCache()
		return false
	end

	self.isEnabled = true
	hook.resetCache()
	return true
end

function plugin:_deactivate(is_reload)
	self.isEnabled = false
	hook.resetCache()
	local success = self:callDisableHandlers(is_reload)
	self._active_server_event_handlers = {}
	return success
end

function plugin:load(is_enabled, is_reload)
	local loaded_file, load_error = loadfile(self.entryPath)
	if not loaded_file then
		print_scoped(string.format("\27[38;5;196mFailed to load plugin '%s': %s", self.entryPath, load_error))
		return false
	end

	local previous_loading_plugin = loading_plugin
	local previous_registration_phase = server_event_registration_phase
	loading_plugin = self
	server_event_registration_phase = "entry"
	local success, err = pcall(loaded_file, self)
	loading_plugin = previous_loading_plugin
	server_event_registration_phase = previous_registration_phase
	if not success then
		print_scoped(string.format("\27[38;5;196mFailed to load plugin '%s': %s", self.entryPath, err or "unknown"))
		return false
	end

	self:setConfig()
	self.isEnabled = false
	if is_enabled then
		return self:_activate(is_reload)
	end

	return true
end

function plugin:reload()
	local key = self.nameSpace .. ":" .. self.fileName
	local replacement = new_plugin(self.nameSpace, self.fileName)
	local was_enabled = self.isEnabled

	replacement.entryPath = self.entryPath
	replacement.fullFileName = self.fullFileName
	if not replacement:load(false, true) then
		return false
	end

	if was_enabled then
		if not self:_deactivate(true) then
			return false
		end
		if not replacement:_activate(true) then
			self:_activate(true)
			return false
		end
	end

	hook.plugins[key] = replacement
	hook.resetCache()
	return true
end

function plugin.onEnable(_) end
function plugin.onDisable(_) end

new_plugin = function(name_space, stem)
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
		isEnabled = false,
		requireCache = {},
		nameSpace = name_space,
		fileName = stem,
		doAutoReload = false,
		_server_event_handlers = {},
		_active_server_event_handlers = {},
	}, plugin)
end

local function collect_entries(name_space)
	local entries = {}
	for _, path in ipairs(__src_list_scripts()) do
		if path:startsWith(name_space .. "/") then
			local relative = path:sub(#name_space + 2)

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

local function plugin_key(name_space, stem)
	return name_space .. ":" .. stem
end

local function should_start_plugin_enabled(plug)
	return not disabled_plugins[plug.fileName]
end

local function should_start_mode_enabled(plug)
	return plug.fileName == hook.persistentMode
end

local function reconcile_disabled_plugins()
	for _, plug in pairs(hook.plugins) do
		if plug.nameSpace == "plugins" then
			local should_enable = should_start_plugin_enabled(plug)
			if should_enable and not plug.isEnabled then
				if plug:enable(false) then
					print_scoped("Enabled plugin " .. plug.fileName)
				else
					print_scoped("Failed to enable plugin " .. plug.fileName)
				end
			elseif (not should_enable) and plug.isEnabled then
				plug:disable(false)
				print_scoped("Disabled plugin " .. plug.fileName)
			end
		end
	end
end

local function discover_in_namespace(name_space, is_enabled_func)
	local loaded_count = 0
	local error_count = 0

	local entries = collect_entries(name_space)
	for stem, entry in pairs(entries) do
		local key = plugin_key(name_space, stem)
		if not hook.plugins[key] then
			local plug = new_plugin(name_space, stem)
			plug.entryPath = entry.path
			plug.fullFileName = entry.fullFileName

			hook.plugins[key] = plug
			local is_enabled = is_enabled_func(plug)

			print_scoped(string.format("Loading \27[30;1m%s.\27[0m%s", name_space, stem))
			local success = plug:load(is_enabled, false)
			if success then
				loaded_count = loaded_count + 1
			else
				hook.plugins[key] = nil
				error_count = error_count + 1
			end
		end
	end

	return loaded_count, error_count
end

local function load_plugin_namespace(name_space, is_enabled_func)
	print_scoped("Loading " .. name_space .. "...")

	local loaded_count, error_count = discover_in_namespace(name_space, is_enabled_func)
	print_scoped("Loaded " .. loaded_count .. " " .. name_space)
	if error_count > 0 then
		print_scoped(string.format("\27[38;5;196mFailed to load %d %s", error_count, name_space))
	end
end

local function load_plugins()
	if hook.persistentMode == "" and type(config.defaultGameMode) == "string" then
		hook.persistentMode = config.defaultGameMode
	end

	load_plugin_namespace("plugins", should_start_plugin_enabled)
	load_plugin_namespace("modes", should_start_mode_enabled)
	hook.resetCache()
end

function discoverNewPlugins()
	local loaded_count = 0
	local plugin_count = discover_in_namespace("plugins", should_start_plugin_enabled)
	local mode_count = discover_in_namespace("modes", should_start_mode_enabled)
	loaded_count = plugin_count + mode_count
	hook.resetCache()
	return loaded_count
end

local function reload_plugin_configs()
	for _, plug in pairs(hook.plugins) do
		plug:setConfig()
	end
end

hook.add("ConfigLoaded", "main.plugins", function(is_reload)
	if not is_reload then
		load_plugins()
	else
		reload_plugin_configs()
	end
end)

local function plugin_from_path(path)
	for _, name_space in ipairs({ "plugins", "modes" }) do
		if path:startsWith(name_space .. "/") then
			local relative = path:sub(#name_space + 2)
			local single = relative:match("^([^/]+)%.lua$")
			if single then
				return name_space, single
			end

			local folder = relative:match("^([^/]+)/")
			if folder then
				return name_space, folder
			end
		end
	end

	return nil, nil
end

local function entry_still_exists(entry_path)
	return __src_read_file(entry_path) ~= nil
end

local function apply_patch(changed_paths)
	local touched = {}
	local disabled_plugins_changed = false
	for _, path in ipairs(changed_paths) do
		if path == disabled_plugins_file then
			disabled_plugins_changed = true
		end

		local name_space, name = plugin_from_path(path)
		if name_space and name then
			touched[name_space] = touched[name_space] or {}
			touched[name_space][name] = true
		end
	end

	local entries_by_namespace = {
		plugins = collect_entries("plugins"),
		modes = collect_entries("modes"),
	}

	local function should_start_enabled(name_space, plug)
		if name_space == "modes" then
			return should_start_mode_enabled(plug)
		end

		return should_start_plugin_enabled(plug)
	end

	for name_space, touched_names in pairs(touched) do
		for name, _ in pairs(touched_names) do
			local key = plugin_key(name_space, name)
			local plug = hook.plugins[key]
			local entry = entries_by_namespace[name_space] and entries_by_namespace[name_space][name] or nil

			if not entry then
				if plug then
					plug:disable(false)
					hook.plugins[key] = nil
					print_scoped("Removed " .. name_space .. " " .. name)
				end
			elseif plug then
				plug.entryPath = entry.path
				plug.fullFileName = entry.fullFileName

				if entry_still_exists(plug.entryPath) then
					if plug:reload() then
						print_scoped("Reloaded " .. name_space .. " " .. name)
					end
				else
					plug:disable(false)
					hook.plugins[key] = nil
					print_scoped("Removed " .. name_space .. " " .. name)
				end
			else
				local new_plug = new_plugin(name_space, name)
				new_plug.entryPath = entry.path
				new_plug.fullFileName = entry.fullFileName
				hook.plugins[key] = new_plug

				local ok = new_plug:load(should_start_enabled(name_space, new_plug), false)
				if ok then
					print_scoped("Loaded new " .. name_space .. " " .. name)
				else
					hook.plugins[key] = nil
				end
			end
		end
	end

	if disabled_plugins_changed and load_disabled_plugins() then
		reconcile_disabled_plugins()
	end

	discoverNewPlugins()
	hook.resetCache()
	return true
end

return {
	applyPatch = apply_patch,
	loadPlugins = load_plugins,
	discoverNewPlugins = discoverNewPlugins,
	plugin = plugin,
	_get_server_event_registration = function()
		return loading_plugin, server_event_registration_phase
	end,
}
