unpack = unpack or table.unpack
bit32 = bit32 or { bxor = function(a, b) return (a ~ b) & 0xFFFFFFFF end, band = function(a, b) return (a & b) & 0xFFFFFFFF end }
-- Run from core/: lua test/dispatch_cache.lua
function string:startsWith(prefix)
	return self:sub(1, #prefix) == prefix
end

package.loaded["main.util"] = true
package.loaded["main.input"] = true
package.loaded["main.blips"] = true
package.loaded["main.enum"] = true
package.loaded["main.dataTyper"] = true
package.loaded["main.gameUtil"] = true
package.loaded["main.yaml"] = { parse = function() return {} end, }
package.loaded["main.plugins"] = {
	_get_server_event_registration = function() return nil, nil end,
}
__src_read_file = function() return nil end
__src_emit_server_event = function() end
__src_persistent_mode = ""
-- stands in for the native hook table
hook = {
	enable = function() return true end,
	disable = function() return true end,
	clear = function() end,
}
dofile("main/hook.lua")
require("main.init")

local function check(cond, msg)
	if not cond then error(msg, 2) end
end

local codec = require("main.eventCodec")
local function dispatch(name, ...)
	return __src_dispatch_server_event(codec.hash_name(name), codec.encode(...))
end

-- global handlers receive the decoded arguments
local got
onServerEvent("ping", function(a, b) got = a .. b end)
local r = dispatch("ping", "x", "y")
check(r.status == "processed" and r.handled == 1 and got == "xy", "global handler")
local seen
onServerEvent("holes", function(...) seen = { n = select("#", ...), ... } end)
dispatch("holes", "x", nil, 3)
check(seen.n == 3 and seen[1] == "x" and seen[2] == nil and seen[3] == 3, "nil holes survive dispatch")
r = __src_dispatch_server_event(codec.hash_name("ping"), "not a blob")
check(r.status == "decode_error", "malformed argument blob reported")

-- erroring handler is reported, others still run
onServerEvent("ping", function() error("boom") end)
r = dispatch("ping", "x", "y")
check(r.status == "handler_error" and r.errors == 1 and r.handled == 1, "error reporting")

-- plugin handlers: enable/disable invalidates via hook.resetCache
local plug = { isEnabled = false, hooks = {}, polyHooks = {},
	_server_event_handlers = {}, _active_server_event_handlers = {}, }
local plug_calls = 0
plug._server_event_handlers[codec.hash_name("pong")] = { function() plug_calls = plug_calls + 1 end, }
hook.plugins.p = plug
r = dispatch("pong", "x")
check(r.status == "no_handler", "disabled plugin has no handler")
plug.isEnabled = true
hook.resetCache()
r = dispatch("pong", "x")
check(r.status == "processed" and plug_calls == 1, "enabled plugin handler runs")
plug.isEnabled = false
hook.resetCache()
r = dispatch("pong", "x")
check(r.status == "no_handler", "disabled again")

-- hook.run dispatch semantics unchanged
local order = {}
hook.add("T", "a", function() order[#order + 1] = "a" end)
hook.once("T", function() order[#order + 1] = "once" end)
hook.run("T")
hook.run("T")
check(table.concat(order, ",") == "once,a,a", "once/add order: " .. table.concat(order, ","))
hook.add("O", "x", function() return hook.override end)
check(hook.run("O") == true, "override returns true")
hook.add("C", "x", function() return hook.continue end)
check(hook.run("C") == false, "continue returns false")

print("dispatch_cache: ok")
