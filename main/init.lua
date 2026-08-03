---@diagnostic disable: lowercase-global

require("main.util")
require("main.hook")
local plugins_runtime = require("main.plugins")
require("main.input")
require("main.blips")
require("main.enum")
require("main.dataTyper")
require("main.gameUtil")
local event_codec = require("main.eventCodec")

local yaml = require("main.yaml")
local unpack_fn = table.unpack or unpack

local has_config_loaded_once = false

config = {
	plugins = {},
}

function loadConfig(file_name)
	local path = file_name or "config.yml"
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

	hook.run("ConfigLoaded", has_config_loaded_once)
	has_config_loaded_once = true
end

local server_event_handlers = {}
local server_event_names_by_hash = {}

function onServerEvent(name, fn)
	assert(type(name) == "string" and name ~= "", "onServerEvent(name, fn): name must be non-empty string")
	assert(type(fn) == "function", "onServerEvent(name, fn): fn must be function")

	local hash = event_codec.hashName(name)
	local existing_name = server_event_names_by_hash[hash]
	if existing_name and existing_name ~= name then
		error(string.format("onServerEvent hash collision: '%s' conflicts with '%s'", name, existing_name))
	end
	server_event_names_by_hash[hash] = name

	local owner, registration_phase = plugins_runtime._get_server_event_registration()
	local handlers = server_event_handlers
	if owner then
		if registration_phase == "activation" then
			handlers = owner._active_server_event_handlers
		else
			handlers = owner._server_event_handlers
		end
	end
	if not handlers[hash] then
		handlers[hash] = {}
	end

	table.insert(handlers[hash], fn)
end

function emitServerEvent(name, ...)
	assert(type(name) == "string" and name ~= "", "emitServerEvent(name, ...): name must be non-empty string")
	local hash = event_codec.hashName(name)
	local existing_name = server_event_names_by_hash[hash]
	if existing_name and existing_name ~= name then
		error(string.format("emitServerEvent hash collision: '%s' conflicts with '%s'", name, existing_name))
	end
	server_event_names_by_hash[hash] = name

	local args_bytes, encode_error = event_codec.encodeArgs(...)
	assert(args_bytes ~= nil, "emitServerEvent(name, ...): " .. tostring(encode_error))

	return __src_emit_server_event(name, hash, args_bytes)
end

function __src_dispatch_server_event(hash, args_bytes)
	local handlers = {}
	for _, fn in ipairs(server_event_handlers[hash] or {}) do
		table.insert(handlers, fn)
	end

	for _, plug in pairs(hook.plugins) do
		if plug.isEnabled then
			for _, fn in ipairs(plug._server_event_handlers[hash] or {}) do
				table.insert(handlers, fn)
			end
			for _, fn in ipairs(plug._active_server_event_handlers[hash] or {}) do
				table.insert(handlers, fn)
			end
		end
	end

	if #handlers == 0 then
		return {
			status = "no_handler",
			handled = 0,
			errors = 0,
			error = "no handlers registered",
		}
	end

	local args = event_codec.decodeArgs(args_bytes)
	if not args then
		return {
			status = "decode_error",
			handled = 0,
			errors = 1,
			error = "invalid event arg blob",
		}
	end

	local handled = 0
	local errors = 0
	local first_error = nil

	for _, fn in ipairs(handlers) do
		local ok, err = pcall(fn, unpack_fn(args, 1, args.n))
		if not ok then
			errors = errors + 1
			if not first_error then
				first_error = tostring(err)
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
			error = first_error or "handler error",
		}
	end

	return {
		status = "processed",
		handled = handled,
		errors = 0,
	}
end

blob = event_codec.blob

function __src_dispatch_hook(event_name, ...)
	return hook.run(event_name, ...)
end

function __src_dispatch_keybind(scancode, state)
	if input and input._dispatch then
		input._dispatch(scancode, state)
	end
end

function __src_apply_plugin_patch(changed_paths)
	return plugins_runtime.applyPatch(changed_paths)
end

loadConfig()
