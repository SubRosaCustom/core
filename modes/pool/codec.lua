local eventCodec = require("main.eventCodec")

local codec = {}

local SNAPSHOT_VERSION = 1
local unpackFn = table.unpack or unpack

local function push(parts, ...)
	for i = 1, select("#", ...) do
		parts.n = (parts.n or 0) + 1
		parts[parts.n] = select(i, ...)
	end
end

local function ball_model_name_for_id(ballId)
	if ballId == 0 then
		return "cueball"
	end

	if type(ballId) == "number" and ballId > 0 then
		return "ball" .. tostring(ballId)
	end

	return nil
end

function codec.encodeSnapshot(snapshot)
	if type(snapshot) ~= "table" then
		return nil, "snapshot must be table"
	end

	local shared = snapshot.sharedConstants or {}
	local seats = snapshot.seats or {}
	local balls = snapshot.balls or {}
	local assignments = snapshot.assignments or {}
	local parts = { n = 0 }

	push(
		parts,
		SNAPSHOT_VERSION,
		tonumber(snapshot.version) or 0,
		tonumber(snapshot.serverTick) or 0,
		snapshot.phase,
		tonumber(snapshot.matchNumber) or 0,
		tonumber(snapshot.turnPlayer),
		tonumber(snapshot.winner),
		tonumber(snapshot.lastWinnerSeat),
		snapshot.ballInHand == true,
		tonumber(snapshot.cueAim) or 0,
		tonumber(snapshot.shotPower) or 0,
		snapshot.statusLine,
		snapshot.noticeLine,
		snapshot.moving == true,
		tonumber(snapshot.localSeat),
		snapshot.practiceMode == true,
		assignments[1],
		assignments[2]
	)

	local seat1 = seats[1] or {}
	local seat2 = seats[2] or {}
	push(
		parts,
		tonumber(seat1.playerIndex),
		seat1.playerName,
		seat1.ready == true,
		tonumber(seat1.wins) or 0,
		tonumber(seat2.playerIndex),
		seat2.playerName,
		seat2.ready == true,
		tonumber(seat2.wins) or 0
	)

	push(
		parts,
		tonumber(shared.tableMinX) or 0,
		tonumber(shared.tableMaxX) or 0,
		tonumber(shared.tableMinZ) or 0,
		tonumber(shared.tableMaxZ) or 0,
		tonumber(shared.headStringX) or 0,
		tonumber(shared.cueStartX) or 0,
		tonumber(shared.cueStartZ) or 0,
		tonumber(shared.ballRadius) or 0,
		tonumber(shared.pocketRadius) or 0,
		tonumber(shared.tableFriction) or 0,
		tonumber(shared.railBounce) or 0,
		tonumber(shared.collisionDamping) or 0,
		tonumber(shared.stopEpsilon) or 0,
		tonumber(shared.physicsSubsteps) or 0,
		tonumber(shared.aimStep) or 0,
		tonumber(shared.powerStep) or 0,
		tonumber(shared.minShotPower) or 0,
		tonumber(shared.maxShotPower) or 0,
		tonumber(shared.shotPowerScale) or 0,
		tonumber(shared.cueMoveStep) or 0
	)

	local pocketCenters = shared.pocketCenters or {}
	push(parts, #pocketCenters)
	for i = 1, #pocketCenters do
		local pocket = pocketCenters[i] or {}
		push(parts, tonumber(pocket.x) or 0, tonumber(pocket.z) or 0)
	end

	push(parts, #balls)
	for i = 1, #balls do
		local ball = balls[i] or {}
		push(
			parts,
			tonumber(ball.id) or 0,
			tonumber(ball.x) or 0,
			tonumber(ball.z) or 0,
			ball.active == true
		)
	end

	return eventCodec.encode(unpackFn(parts, 1, parts.n))
end

function codec.decodeSnapshot(blob)
	local values, countOrErr = eventCodec.decode(blob)
	if not values then
		return nil, countOrErr
	end

	local index = 1
	local function next_value()
		if index > countOrErr then
			return nil
		end
		local value = values[index]
		index = index + 1
		return value
	end

	local snapshot = {
		snapshotVersion = next_value(),
		version = next_value(),
		serverTick = next_value(),
		phase = next_value(),
		matchNumber = next_value(),
		turnPlayer = next_value(),
		winner = next_value(),
		lastWinnerSeat = next_value(),
		ballInHand = next_value() == true,
		cueAim = next_value(),
		shotPower = next_value(),
		statusLine = next_value(),
		noticeLine = next_value(),
		moving = next_value() == true,
		localSeat = next_value(),
		practiceMode = next_value() == true,
		assignments = {
			[1] = next_value(),
			[2] = next_value(),
		},
		seats = {},
		sharedConstants = {},
		balls = {},
	}

	for seatIndex = 1, 2 do
		local playerIndex = next_value()
		local playerName = next_value()
		local ready = next_value() == true
		local wins = next_value()
		if playerIndex ~= nil or playerName ~= nil or ready or (tonumber(wins) or 0) ~= 0 then
			snapshot.seats[seatIndex] = {
				playerIndex = playerIndex,
				playerName = playerName,
				ready = ready,
				wins = tonumber(wins) or 0,
			}
		end
	end

	local shared = snapshot.sharedConstants
	shared.tableMinX = next_value()
	shared.tableMaxX = next_value()
	shared.tableMinZ = next_value()
	shared.tableMaxZ = next_value()
	shared.headStringX = next_value()
	shared.cueStartX = next_value()
	shared.cueStartZ = next_value()
	shared.ballRadius = next_value()
	shared.pocketRadius = next_value()
	shared.tableFriction = next_value()
	shared.railBounce = next_value()
	shared.collisionDamping = next_value()
	shared.stopEpsilon = next_value()
	shared.physicsSubsteps = next_value()
	shared.aimStep = next_value()
	shared.powerStep = next_value()
	shared.minShotPower = next_value()
	shared.maxShotPower = next_value()
	shared.shotPowerScale = next_value()
	shared.cueMoveStep = next_value()

	local pocketCount = tonumber(next_value()) or 0
	shared.pocketCenters = {}
	for i = 1, pocketCount do
		shared.pocketCenters[i] = {
			x = next_value(),
			z = next_value(),
		}
	end

	local ballCount = tonumber(next_value()) or 0
	for i = 1, ballCount do
		local ballId = next_value()
		local ball = {
			id = ballId,
			x = next_value(),
			z = next_value(),
			active = next_value() == true,
		}
		ball.modelName = ball_model_name_for_id(ball.id)
		snapshot.balls[i] = ball
	end

	if index <= countOrErr then
		return nil, "trailing snapshot bytes"
	end

	return snapshot
end

return codec
