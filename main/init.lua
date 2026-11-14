-- Version: 1.0.0
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
local hash_by_name = {}
local hash_by_name_count = 0
local MAX_MEMOIZED_NAMES = 1024
local handler_cache = {}
local handler_cache_count = 0
local handler_cache_generation = -1
local MAX_CACHED_HASHES = 256

-- memo resets at a cap, names aren't trusted to stay few
local function hash_name(name)
	local hash = hash_by_name[name]
	if hash == nil then
		hash = event_codec.hash_name(name)
		if hash_by_name_count >= MAX_MEMOIZED_NAMES then
			hash_by_name = {}
			hash_by_name_count = 0
		end
		hash_by_name[name] = hash
		hash_by_name_count = hash_by_name_count + 1
	end
	return hash
end

local function invalidate_handler_cache()
	handler_cache = {}
	handler_cache_count = 0
end

function onServerEvent(name, fn)
	assert(type(name) == "string" and name ~= "", "onServerEvent(name, fn): name must be non-empty string")
	assert(type(fn) == "function", "onServerEvent(name, fn): fn must be function")

	local hash = hash_name(name)
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
	invalidate_handler_cache()
end

local function emit_server_event(emit, name, ...)
	assert(type(name) == "string" and name ~= "", "emitServerEvent(name, ...): name must be non-empty string")
	local hash = hash_name(name)
	local existing_name = server_event_names_by_hash[hash]
	if existing_name and existing_name ~= name then
		error(string.format("emitServerEvent hash collision: '%s' conflicts with '%s'", name, existing_name))
	end
	server_event_names_by_hash[hash] = name

	local args_bytes, encode_error = event_codec.encode(...)
	assert(args_bytes ~= nil, "emitServerEvent(name, ...): " .. tostring(encode_error))

	return emit(name, hash, args_bytes)
end

function emitServerEvent(name, ...)
	return emit_server_event(__src_emit_server_event, name, ...)
end
function emitServerEventLatest(name, ...)
	return emit_server_event(__src_emit_server_event_latest, name, ...)
end

local function collect_server_event_handlers(hash)
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

	return handlers
end

-- plugin changes end in hook.resetCache, which bumps the generation; onServerEvent invalidates directly
function __src_dispatch_server_event(hash, args_bytes)
	if handler_cache_generation ~= hook._generation then
		invalidate_handler_cache()
		handler_cache_generation = hook._generation
	end

	local handlers = handler_cache[hash]
	if handlers == nil then
		handlers = collect_server_event_handlers(hash)
		if handler_cache_count >= MAX_CACHED_HASHES then
			invalidate_handler_cache()
		end
		handler_cache[hash] = handlers
		handler_cache_count = handler_cache_count + 1
	end

	if #handlers == 0 then
		return {
			status = "no_handler",
			handled = 0,
			errors = 0,
			error = "no handlers registered",
		}
	end

	local args = event_codec.decode_args(args_bytes)
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
		-- decode_args caps args at 255, within unpack's limit
		local ok, err = pcall(fn, unpack(args, 1, args.n))
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
