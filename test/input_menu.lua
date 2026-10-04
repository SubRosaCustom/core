-- Run from core/: lua test/input_menu.lua
KEY_UP, KEY_DOWN, KEY_PRESSED = 0, 1, 2
client = { player = {}, isTabMenu = 1 }
local input = dofile("main/input.lua")
local normal, toggles = {}, {}
input:bind("normal",77,function(_,state) normal[#normal+1]=state end,false,5)
input:bind("toggle",78,function(_,value) toggles[#toggles+1]=value end,true,5)
input._dispatch(77,KEY_PRESSED)
input._dispatch(77,KEY_DOWN)
input._dispatch(77,KEY_UP)
assert(#normal==3 and normal[1]==input.state.begin and normal[2]==input.state.current and normal[3]==input.state.ended,
 "ordinary binds receive all edges while Tab menu is open")
input._dispatch(78,KEY_PRESSED);input._dispatch(78,KEY_UP)
assert(toggles[1]==true and toggles[2]==false,"toggle bind edges preserved")
input:removeBind("normal");input._dispatch(77,KEY_PRESSED)
assert(#normal==3,"removed bind stays removed")
print("ordinary Tab-menu input dispatch checks passed")
