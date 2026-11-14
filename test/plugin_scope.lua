unpack = unpack or table.unpack
bit32 = bit32 or { bxor = function(a, b) return (a ~ b) & 0xFFFFFFFF end, band = function(a, b) return (a & b) & 0xFFFFFFFF end }
-- Run from core/: lua test/plugin_scope.lua
local native_loadfile = loadfile
local compile = loadstring or load
local files, script_paths, runtime
local evaluated, enabled, disabled, events

function string:startsWith(prefix)
	return self:sub(1, #prefix) == prefix
end

function concatVarArgs(separator, ...)
	local values = { ... }
	for i, value in ipairs(values) do
		values[i] = tostring(value)
	end
	return table.concat(values, separator)
end

local function reset(next_files, next_paths, persistent_mode)
	files = next_files
	script_paths = next_paths
	evaluated, enabled, disabled, events = {}, {}, {}, {}
	config = { plugins = {}, defaultGameMode = "active" }
	-- stands in for the native hook table
	hook = {
		enable = function() return true end,
		disable = function() return true end,
		clear = function() end,
	}
	__src_persistent_mode = persistent_mode or ""
	dofile("main/hook.lua")
	__src_read_file = function(path) return files[path] end
	__src_list_scripts = function() return script_paths end
	loadfile = function(path)
		if not files[path] then
			return nil, "not found"
		end
		return compile(files[path], "@" .. path)
	end
	-- Lifecycle fixtures can observe evaluation separately from activation.
	_G.recordEntry = function(name) evaluated[#evaluated + 1] = name end
	_G.recordEnable = function(name) enabled[#enabled + 1] = name end
	_G.recordDisable = function(name) disabled[#disabled + 1] = name end
	_G.recordEvent = function(name) events[#events + 1] = name end
	runtime = assert(native_loadfile("main/plugins.lua"))()
	-- real init.lua (onServerEvent, dispatch) bound to this runtime; only unrelated libs are stubbed
	package.loaded["main.plugins"] = runtime
	for _, name in ipairs({ "util", "input", "blips", "enum", "dataTyper", "gameUtil", "hook" }) do
		package.loaded["main." .. name] = true
	end
	package.loaded["main.yaml"] = { parse = function() return {} end }
	package.loaded["main.eventCodec"] = nil
	-- init's own loadConfig would fire ConfigLoaded and load plugins before the fixture runs
	local run = hook.run
	hook.run = function() end
	dofile("main/init.lua")
	hook.run = run
	config = { plugins = {}, defaultGameMode = "active" }
	return runtime
end

local function source(name, extra)
	return string.format([[
local plugin = ...
recordEntry(%q)
plugin.onEnable = function() recordEnable(%q) end
plugin.onDisable = function() recordDisable(%q) end
plugin:addHook("Logic", function() recordEvent(%q) end)
onServerEvent("scope." .. %q, function() recordEvent("event:" .. %q) end)
%s
]], name, name, name, name, name, name, extra or "")
end

local function contains(values, value)
	for _, current in ipairs(values) do
		if current == value then return true end
	end
	return false
end

local function assert_list(values, expected, message)
	assert(table.concat(values, ",") == table.concat(expected, ","), message)
end

-- The server-resolved default mode owns the assets in the received snapshot.
reset({
	['modes/selected/init.lua'] = source('selected'),
	['modes/active/init.lua'] = source('wrong-default'),
}, { 'modes/selected/init.lua', 'modes/active/init.lua' }, 'selected').loadPlugins()
assert_list(evaluated, { 'selected' }, 'published mode takes precedence over client default')
assert(hook.persistentMode == 'selected' and hook.plugins['modes:selected'].isEnabled)

-- Discovered owner stems are strict, sorted, and use init.lua deterministically.
local initial_files = {
	["disabledPlugins.json"] = '["disabled"]',
	["plugins/alpha.lua"] = source("alpha"),
	["plugins/zeta.lua"] = source("zeta"),
	["plugins/duplicate.lua"] = source("wrong-duplicate"),
	["plugins/duplicate/init.lua"] = source("duplicate"),
	["plugins/disabled.lua"] = source("disabled"),
	["plugins/bad.name.lua"] = source("invalid"),
	["plugins/helper/lib.lua"] = source("helper"),
	["plugins/../init.lua"] = source("traversal"),
	["modes/active/init.lua"] = source("active"),
	["modes/inactive/init.lua"] = source("inactive"),
}
local paths = {
	"plugins/zeta.lua", "plugins/duplicate/init.lua", "plugins/duplicate.lua",
	"plugins/bad.name.lua", "plugins/disabled.lua", "plugins/alpha.lua",
	"modes/inactive/init.lua", "plugins/helper/lib.lua", "plugins/../init.lua",
	"modes/active/init.lua",
}
reset(initial_files, paths).loadPlugins()
assert_list(evaluated, { "alpha", "duplicate", "zeta", "active" }, "strict sorted lazy discovery")
assert(hook.plugins["plugins:duplicate"].entryPath == "plugins/duplicate/init.lua")
assert(not hook.plugins["plugins:bad.name"] and not hook.plugins["plugins:helper"])
assert(not hook.plugins["plugins:disabled"].isEnabled)
assert(not hook.plugins["modes:inactive"]._is_loaded)
events = {}
local dispatched = __src_dispatch_server_event(require("main.eventCodec").hash_name("scope.alpha"), require("main.eventCodec").encode())
assert(dispatched.status == "processed" and dispatched.handled == 1 and contains(events, "event:alpha"), "plugin-owned handler runs through real dispatch")
local reversed = {}
for i = #paths, 1, -1 do reversed[#reversed + 1] = paths[i] end
reset(initial_files, reversed).loadPlugins()
assert_list(evaluated, { "alpha", "duplicate", "zeta", "active" }, "discovery independent of listing order")

-- A disabled/inactive patch must not evaluate its changed entry, even once.
files["plugins/new.lua"] = source("new")
script_paths[#script_paths + 1] = "plugins/new.lua"
files["plugins/alpha.lua"] = source("new-alpha")
files["modes/inactive/init.lua"] = source("new-inactive")
files["disabledPlugins.json"] = '["disabled","alpha","new"]'
assert(runtime.applyPatch({ "plugins/new.lua", "plugins/alpha.lua", "modes/inactive/init.lua", "disabledPlugins.json" }))
assert(not contains(evaluated, "new") and not contains(evaluated, "new-alpha") and not contains(evaluated, "new-inactive"))
assert(not hook.plugins["plugins:alpha"].isEnabled and not hook.plugins["plugins:new"].isEnabled)
assert(contains(disabled, "alpha"), "existing enabled plugin is disabled before the patch")

-- Enabling a deferred entry loads it once; a changed disabled entry stays fresh.
files["disabledPlugins.json"] = '["disabled"]'
assert(runtime.applyPatch({ "disabledPlugins.json" }))
assert(contains(evaluated, "new-alpha") and contains(evaluated, "new"))
assert(hook.plugins["plugins:alpha"].isEnabled and hook.plugins["plugins:new"].isEnabled)
local count = #evaluated
assert(hook.plugins["plugins:new"]:enable(false))
assert(#evaluated == count, "enabling twice must not re-evaluate")
assert(hook.plugins["modes:inactive"]:enable(false))
assert(contains(evaluated, "new-inactive"), "explicit enable loads an inactive mode lazily")

-- A syntax error during reload must leave no enabled hooks or stale event handlers.
local alpha = hook.plugins["plugins:alpha"]
files["plugins/alpha.lua"] = "not valid lua !!!"
assert(runtime.applyPatch({ "plugins/alpha.lua" }))
assert(not alpha.isEnabled and not alpha._is_loaded)
assert(next(alpha.hooks) == nil and next(alpha.polyHooks) == nil)
assert(next(alpha._server_event_handlers) == nil and next(alpha._active_server_event_handlers) == nil)
events = {}
hook.run("Logic")
assert(not contains(events, "new-alpha"), "failed reload must not retain active hooks")

-- A later fixed entry retries according to the enabled-on-disk scope.
files["plugins/alpha.lua"] = source("recovered-alpha")
assert(runtime.applyPatch({ "plugins/alpha.lua" }))
assert(alpha.isEnabled and contains(evaluated, "recovered-alpha"))
files["plugins/alpha.lua"] = source("broken-alpha", 'error("entry failed")')
assert(runtime.applyPatch({ "plugins/alpha.lua" }))
assert(not alpha.isEnabled and not alpha._is_loaded)
assert(next(alpha.polyHooks) == nil and next(alpha._server_event_handlers) == nil)
assert(contains(disabled, "broken-alpha"), "partly evaluated entries get cleanup")

-- Old direct lifecycle handlers must not survive a new definition.
files["plugins/alpha.lua"] = 'local plugin = ...; recordEntry("minimal-alpha")'
local enable_count = #enabled
assert(runtime.applyPatch({ "plugins/alpha.lua" }))
assert(alpha.isEnabled and #enabled == enable_count)

-- Runtime activation errors also remain disabled, including same-batch list edits.
files["plugins/alpha.lua"] = source("activation-error", 'plugin.onEnable = function() error("activation failed") end')
files["disabledPlugins.json"] = '["disabled","new"]'
local before_failed = #evaluated
assert(runtime.applyPatch({ "disabledPlugins.json", "plugins/alpha.lua" }))
assert(not alpha.isEnabled and #evaluated == before_failed + 1, "failed activation must not be retried within the patch")

-- Invalid disable state must not expand scope or evaluate any newly discovered entry.
files["plugins/blocked.lua"] = source("blocked")
script_paths[#script_paths + 1] = "plugins/blocked.lua"
for _, invalid in ipairs({ '', '{"new":true}', '["../new"]', '[false]', 'not json' }) do
	files["disabledPlugins.json"] = invalid
	assert(not runtime.applyPatch({ "disabledPlugins.json", "plugins/blocked.lua" }))
	assert(not contains(evaluated, "blocked") and not hook.plugins["plugins:new"].isEnabled)
end

-- Decoder null holes cannot hide later disabled names.
files["disabledPlugins.json"] = '[null,"blocked","new","disabled"]'
assert(runtime.applyPatch({ "disabledPlugins.json", "plugins/blocked.lua" }))
assert(not contains(evaluated, "blocked") and not hook.plugins["plugins:blocked"].isEnabled)

-- Removing the selected entry deactivates and removes its plugin object.
files["plugins/zeta.lua"] = nil
for i = #script_paths, 1, -1 do
	if script_paths[i] == "plugins/zeta.lua" then table.remove(script_paths, i) end
end
assert(runtime.applyPatch({ "plugins/zeta.lua" }))
assert(not hook.plugins["plugins:zeta"] and contains(disabled, "zeta"))

-- A malformed first disable list also fails closed until a valid list arrives.
reset({ ["disabledPlugins.json"] = "{}", ["plugins/safe.lua"] = source("safe") }, { "plugins/safe.lua" }).loadPlugins()
assert(#evaluated == 0 and not hook.plugins["plugins:safe"].isEnabled)
files["disabledPlugins.json"] = "[]"
assert(runtime.applyPatch({ "disabledPlugins.json" }))
assert(hook.plugins["plugins:safe"].isEnabled)

-- Pool must rebuild plugin-owned server-event registrations after reload.
local pool_file = assert(io.open("modes/pool/init.lua", "r"))
local pool_source = pool_file:read("*a")
pool_file:close()
reset({ ["modes/pool/init.lua"] = pool_source }, { "modes/pool/init.lua" })
config.defaultGameMode = "pool"
__srccPoolClientRuntime = nil
local noop = function() end
local constants = { defaultConfig = {}, EVENTS = { state = "srcc.pool.state", notice = "srcc.pool.notice" } }
local state = setmetatable({ newContext = function() return {} end }, { __index = function() return noop end })
local module_stub = setmetatable({}, { __index = function() return noop end })
local modules = { constants = constants, state = state, input = module_stub, render = module_stub }
runtime.plugin.require = function(_, name) return modules[name] end
runtime.loadPlugins()
local pool = hook.plugins["modes:pool"]
local event_codec = require("main.eventCodec")
local state_key, notice_key = event_codec.hash_name(constants.EVENTS.state), event_codec.hash_name(constants.EVENTS.notice)
assert(#state_key == 8 and #notice_key == 8)
assert(pool.isEnabled and #pool._server_event_handlers[state_key] == 1 and #pool._server_event_handlers[notice_key] == 1)
assert(runtime.applyPatch({ "modes/pool/init.lua" }))
assert(pool.isEnabled and #pool._server_event_handlers[state_key] == 1 and #pool._server_event_handlers[notice_key] == 1)

-- Hook diagnostics must survive collection for active callbacks without owning old definitions.
reset({ ["modes/active/init.lua"] = source("active") }, { "modes/active/init.lua" }, "active").loadPlugins()
local active_mode = hook.plugins["modes:active"]
local function metadata_count()
	local count = 0
	for _ in pairs(hook._function_data) do
		count = count + 1
	end
	return count
end
collectgarbage("collect")
local initial_metadata_count = metadata_count()
local old_callbacks = setmetatable({ active_mode.polyHooks.Logic[1].func }, { __mode = "v" })
for _ = 1, 1000 do
	assert(active_mode:reload(true))
end
collectgarbage("collect")
assert(old_callbacks[1] == nil, "Hook metadata must release callbacks from old mode definitions")
assert(metadata_count() == initial_metadata_count, "Repeated reloads must not accumulate hook metadata")
local current_callback = active_mode.polyHooks.Logic[1].func
assert(hook._function_data[current_callback].name == "active")
assert(hook._function_data[current_callback].event_name == "Logic")
events = {}
hook.run("Logic")
assert_list(events, { "active" }, "Active callback still runs after collection")
for i = 1, 1000 do
	local captured = { iteration = i, }
	hook.add("Logic", "retention-test", function() return captured.iteration end)
	hook.remove("Logic", "retention-test")
end
collectgarbage("collect")
assert(metadata_count() == initial_metadata_count, "Removed named hooks must release their metadata")

loadfile = native_loadfile
print("scoped plugin lifecycle and hook metadata collection checks passed")
