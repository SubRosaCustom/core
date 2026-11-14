-- Run from core/: lua test/input_binds.lua
KEY_UP, KEY_DOWN, KEY_PRESSED = 0, 1, 2
client = { player = {} }
local input = dofile("main/input.lua")

local normal, toggles = {}, {}
input:bind("normal", 77, function(_, state) normal[#normal + 1] = state end, false, 5)
input:bind("toggle", 78, function(_, value) toggles[#toggles + 1] = value end, true, 5)
input._dispatch(77, KEY_PRESSED)
input._dispatch(77, KEY_DOWN)
input._dispatch(77, KEY_UP)
assert(#normal == 3 and normal[1] == input.state.begin and normal[2] == input.state.current and normal[3] == input.state.ended,
	"ordinary binds receive begin, current and ended")
input._dispatch(78, KEY_PRESSED); input._dispatch(78, KEY_UP)
assert(toggles[1] == true and toggles[2] == false, "toggle bind receives press and release")
input._dispatch(77, KEY_PRESSED)
assert(#toggles == 2, "toggle binds ignore other keys")
input:removeBind("normal"); input._dispatch(77, KEY_PRESSED)
assert(#normal == 4, "removed bind stays removed")

-- lower priority runs first; equal priority keeps registration order
local order = {}
local function recorder(name) return function() order[#order + 1] = name end end
input:bind("late", 90, recorder("late"), false, 50)
input:bind("first_a", 90, recorder("first_a"), false, 1)
input:bind("first_b", 90, recorder("first_b"), false, 1)
input:bind("default", 90, recorder("default"), false)
input._dispatch(90, KEY_PRESSED)
assert(table.concat(order, ",") == "first_a,first_b,late,default", table.concat(order, ","))
assert(not pcall(input.bind, input, "late", 91, function() end), "duplicate bind names are rejected")

print("input bind dispatch and priority checks passed")
