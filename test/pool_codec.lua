-- Run from core/: lua test/pool_codec.lua
unpack = unpack or table.unpack
bit32 = bit32 or { bxor = function(a, b) return (a ~ b) & 0xFFFFFFFF end, band = function(a, b) return (a & b) & 0xFFFFFFFF end }
local eventCodec = require("main.eventCodec")
local codec = dofile("modes/pool/codec.lua")

local function pack(values) return assert(eventCodec.encode(unpack(values, 1, values.n))) end

local values = { n = 0 }
local function put(...)
	for i = 1, select("#", ...) do
		values.n = values.n + 1
		values[values.n] = (select(i, ...))
	end
end
put(3, 4, 120, "playing", 2, 1, 0, 2, true, 0.5, 0.75, "status", "notice", true, 1, false) -- header
put(1, 2) -- assignments
put(5, "ann", true, 3) -- seat 1
put(nil, nil, false, 0) -- seat 2 (empty)
for i = 1, 20 do put(i) end -- shared constants
put(2, 10, 11, 12, 13) -- pockets
put(2, 0, 1.5, 2.5, true, 7, 3.5, 4.5, false) -- balls

local snapshot = assert(codec.decodeSnapshot(pack(values)))
assert(snapshot.snapshotVersion == 3 and snapshot.serverTick == 120 and snapshot.phase == "playing")
assert(snapshot.ballInHand == true and snapshot.cueAim == 0.5 and snapshot.statusLine == "status" and snapshot.moving == true)
assert(snapshot.assignments[1] == 1 and snapshot.assignments[2] == 2)
assert(snapshot.seats[1].playerName == "ann" and snapshot.seats[1].ready == true and snapshot.seats[1].wins == 3)
assert(snapshot.seats[2] == nil, "empty seat is omitted")
assert(snapshot.sharedConstants.tableMinX == 1 and snapshot.sharedConstants.cueMoveStep == 20)
assert(#snapshot.sharedConstants.pocketCenters == 2 and snapshot.sharedConstants.pocketCenters[2].z == 13)
assert(#snapshot.balls == 2 and snapshot.balls[1].modelName == "cueball" and snapshot.balls[1].active == true)
assert(snapshot.balls[2].modelName == "ball7" and snapshot.balls[2].z == 4.5 and snapshot.balls[2].active == false)

put("junk")
local trailing, reason = codec.decodeSnapshot(pack(values))
assert(trailing == nil and reason == "trailing snapshot bytes")
local bad, bad_reason = codec.decodeSnapshot("garbage")
assert(bad == nil and type(bad_reason) == "string")
local short = codec.decodeSnapshot(pack({ n = 3, 1, 2, 3 }))
assert(short == nil, "a truncated snapshot is rejected")

print("pool snapshot codec checks passed")
