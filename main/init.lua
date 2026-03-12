---@diagnostic disable: lowercase-global

require("main.util")
require("main.hook")
local pluginsRuntime = require("main.plugins")
require("main.input")
require("main.blips")
require("main.enum")
require("main.dataTyper")
require("main.gameUtil")

local json = require("main.json")
local yaml = require("main.yaml")

local hasConfigLoadedOnce = false

config = {
	plugins = {},
}

function loadConfig(fileName)
	local path = fileName or "config.yml"
	local source = __src_read_file(path)

	if source and source ~= "" then
		local ok, parsed = pcall(yaml.parse, source)
		if ok and type(parsed) == "table" then
			config = parsed
		else
			print("[SRCC] Failed to parse config file: " .. path)
			config = { plugins = {} }
		end
	else
		config = { plugins = {} }
	end

	if type(config.plugins) ~= "table" then
		config.plugins = {}
	end

	if hook and (hook.persistentMode == nil or hook.persistentMode == "") then
		if type(config.defaultGameMode) == "string" and config.defaultGameMode ~= "" then
			hook.persistentMode = config.defaultGameMode
		end
	end

	hook.run("ConfigLoaded", hasConfigLoadedOnce)
	hasConfigLoadedOnce = true
end

local serverEventHandlers = {}

function onServerEvent(name, fn)
	assert(type(name) == "string" and name ~= "", "onServerEvent(name, fn): name must be non-empty string")
	assert(type(fn) == "function", "onServerEvent(name, fn): fn must be function")

	if not serverEventHandlers[name] then
		serverEventHandlers[name] = {}
	end

	table.insert(serverEventHandlers[name], fn)
end

function emitServerEvent(name, data, bin)
	assert(type(name) == "string" and name ~= "", "emitServerEvent(name, data, bin): name must be non-empty string")
	if bin ~= nil then
		assert(type(bin) == "string", "emitServerEvent(name, data, bin): bin must be string or nil")
	end

	local dataJson = "null"
	if data ~= nil then
		local ok, encoded = pcall(json.encode, data)
		if ok then
			dataJson = encoded
		else
			dataJson = json.encode(tostring(data))
		end
	end

	return __src_emit_server_event(name, dataJson, bin)
end

function __src_dispatch_server_event(name, dataJson, bin)
	local handlers = serverEventHandlers[name]
	if not handlers or #handlers == 0 then
		return {
			status = "no_handler",
			handled = 0,
			errors = 0,
			error = "no handlers registered",
		}
	end

	local payload = nil
	if type(dataJson) == "string" and dataJson ~= "" and dataJson ~= "null" then
		local ok, decoded = pcall(json.decode, dataJson)
		if ok then
			payload = decoded
		else
			payload = dataJson
		end
	end

	local handled = 0
	local errors = 0
	local firstError = nil

	for _, fn in ipairs(handlers) do
		local ok, err = pcall(fn, payload, bin)
		if not ok then
			errors = errors + 1
			if not firstError then
				firstError = tostring(err)
			end
			print("[SRCC/Event] " .. tostring(err))
		else
			handled = handled + 1
		end
	end

	if errors > 0 then
		return {
			status = "handler_error",
			handled = handled,
			errors = errors,
			error = firstError or "handler error",
		}
	end

	return {
		status = "processed",
		handled = handled,
		errors = 0,
	}
end

function __src_dispatch_hook(eventName, ...)
	return hook.run(eventName, ...)
end

function __src_dispatch_keybind(scancode, state)
	if input and input._dispatch then
		input._dispatch(scancode, state)
	end
end

function __src_apply_plugin_patch(changedPaths)
	return pluginsRuntime.applyPatch(changedPaths)
end

loadConfig()
