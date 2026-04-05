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

local function ballModelNameForId(ballId)
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
	local function nextValue()
		if index > countOrErr then
			return nil
		end
		local value = values[index]
		index = index + 1
		return value
	end

	local snapshot = {
		snapshotVersion = nextValue(),
		version = nextValue(),
		serverTick = nextValue(),
		phase = nextValue(),
		matchNumber = nextValue(),
		turnPlayer = nextValue(),
		winner = nextValue(),
		lastWinnerSeat = nextValue(),
		ballInHand = nextValue() == true,
		cueAim = nextValue(),
		shotPower = nextValue(),
		statusLine = nextValue(),
		noticeLine = nextValue(),
		moving = nextValue() == true,
		localSeat = nextValue(),
		practiceMode = nextValue() == true,
		assignments = {
			[1] = nextValue(),
			[2] = nextValue(),
		},
		seats = {},
		sharedConstants = {},
		balls = {},
	}

	for seatIndex = 1, 2 do
		local playerIndex = nextValue()
		local playerName = nextValue()
		local ready = nextValue() == true
		local wins = nextValue()
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
	shared.tableMinX = nextValue()
	shared.tableMaxX = nextValue()
	shared.tableMinZ = nextValue()
	shared.tableMaxZ = nextValue()
	shared.headStringX = nextValue()
	shared.cueStartX = nextValue()
	shared.cueStartZ = nextValue()
	shared.ballRadius = nextValue()
	shared.pocketRadius = nextValue()
	shared.tableFriction = nextValue()
	shared.railBounce = nextValue()
	shared.collisionDamping = nextValue()
	shared.stopEpsilon = nextValue()
	shared.physicsSubsteps = nextValue()
	shared.aimStep = nextValue()
	shared.powerStep = nextValue()
	shared.minShotPower = nextValue()
	shared.maxShotPower = nextValue()
	shared.shotPowerScale = nextValue()
	shared.cueMoveStep = nextValue()

	local pocketCount = tonumber(nextValue()) or 0
	shared.pocketCenters = {}
	for i = 1, pocketCount do
		shared.pocketCenters[i] = {
			x = nextValue(),
			z = nextValue(),
		}
	end

	local ballCount = tonumber(nextValue()) or 0
	for i = 1, ballCount do
		local ballId = nextValue()
		local ball = {
			id = ballId,
			x = nextValue(),
			z = nextValue(),
			active = nextValue() == true,
		}
		ball.modelName = ballModelNameForId(ball.id)
		snapshot.balls[i] = ball
	end

	if index <= countOrErr then
		return nil, "trailing snapshot bytes"
	end

	return snapshot
end

return codec
