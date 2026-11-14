-- Run from core/: lua test/blips.lua
local blips = dofile("main/blips.lua")

blips:add("a", { worldX = 1, worldZ = 2, shape = "circle" })
local blip = blips:get("a")
assert(blip.worldX == 1 and blip.shape == "circle" and blip.size == 1.5 and blip.clamp == false, "defaults are filled in")
assert(not pcall(blips.add, blips, "a", { worldX = 0, worldZ = 0 }), "duplicate name rejected")
assert(not pcall(blips.add, blips, "b", { worldX = 0 }), "missing coordinate rejected")
assert(not pcall(blips.add, blips, "b", { worldX = 0, worldZ = 0, shape = "hexagon" }), "unknown shape rejected")
assert(not pcall(blips.add, blips, "b", { worldX = 0, worldZ = 0, bogus = 1 }), "unknown option rejected")
assert(not pcall(blips.add, blips, "b", { worldX = 0, worldZ = 0, size = "big" }), "wrong option type rejected")
assert(blips:get("b") == nil, "rejected blips are not stored")
blips:update("a", { worldX = 9 })
assert(blips:get("a").worldX == 9 and blips:get("a").worldZ == 2, "update merges fields")
assert(not pcall(blips.update, blips, "missing", { worldX = 1 }), "updating an unknown blip fails")
blips:remove("a")
assert(blips:get("a") == nil)

print("blip validation checks passed")
