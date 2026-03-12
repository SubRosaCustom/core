local plugin = ...
local constants = plugin:require("constants")

local state = {}

local function shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

local function createBall(context, id, x, z)
	local group = "solids"
	local modelName = "ball" .. id

	if id == 0 then
		group = "cue"
		modelName = "cueball"
	elseif id == 8 then
		group = "eight"
	elseif id >= 9 then
		group = "stripes"
	end

	local ball = {
		id = id,
		modelName = modelName,
		group = group,
		x = x,
		z = z,
		vx = 0.0,
		vz = 0.0,
		active = true,
	}

	table.insert(context.balls, ball)
	context.ballsById[id] = ball
end

function state.newContext()
	local context = {
		loadedModelIds = {},
		balls = {},
		ballsById = {},
		turnPlayer = 1,
		assignments = { [1] = nil, [2] = nil },
		winner = nil,
		ballInHand = false,
		cueAim = math.pi,
		shotPower = 0.60,
		statusLine = "Press Space to break.",
		shotInProgress = false,
		cueBallPocketedThisShot = false,
		firstHitGroup = nil,
		pocketedThisShot = {},
	}

	state.resetMatch(context)
	return context
end

function state.getCueBall(context)
	return context.ballsById[0]
end

function state.ensureModelsLoaded(context)
	for _, name in ipairs(constants.modelNames) do
		if context.loadedModelIds[name] == nil then
			local modelId = renderer:loadCMO(name)
			if modelId and modelId ~= -1 then
				context.loadedModelIds[name] = modelId
			else
				context.loadedModelIds[name] = false
				plugin:warn("Missing model asset '" .. name .. "'")
			end
		end
	end
end

function state.ballsAreMoving(context)
	local minSpeedSq = constants.STOP_EPSILON * constants.STOP_EPSILON
	for _, ball in ipairs(context.balls) do
		if ball.active then
			local speedSq = (ball.vx * ball.vx) + (ball.vz * ball.vz)
			if speedSq > minSpeedSq then
				return true
			end
		end
	end

	return false
end

function state.countActiveGroup(context, group)
	local count = 0
	for _, ball in ipairs(context.balls) do
		if ball.active and ball.group == group then
			count = count + 1
		end
	end
	return count
end

function state.canPlaceCueBallAt(context, x, z)
	if x < constants.HEAD_STRING_X or x > (constants.TABLE_MAX_X - constants.BALL_RADIUS) then
		return false
	end

	if z < (constants.TABLE_MIN_Z + constants.BALL_RADIUS) or z > (constants.TABLE_MAX_Z - constants.BALL_RADIUS) then
		return false
	end

	for _, ball in ipairs(context.balls) do
		if ball.active and ball.group ~= "cue" then
			local dx = x - ball.x
			local dz = z - ball.z
			if (dx * dx) + (dz * dz) < (constants.BALL_DIAMETER * constants.BALL_DIAMETER) then
				return false
			end
		end
	end

	return true
end

function state.placeCueBallForHand(context)
	local cueBall = state.getCueBall(context)
	if not cueBall then
		return
	end

	cueBall.active = true
	cueBall.vx = 0
	cueBall.vz = 0

	local candidateX = constants.CUE_START_X
	local candidateZ = constants.CUE_START_Z

	if not state.canPlaceCueBallAt(context, candidateX, candidateZ) then
		local found = false
		for z = (constants.TABLE_MIN_Z + constants.BALL_RADIUS), (constants.TABLE_MAX_Z - constants.BALL_RADIUS), 0.08 do
			if state.canPlaceCueBallAt(context, candidateX, z) then
				candidateZ = z
				found = true
				break
			end
		end

		if not found then
			candidateX = constants.HEAD_STRING_X
			candidateZ = constants.CUE_START_Z
		end
	end

	cueBall.x = math.clamp(candidateX, constants.HEAD_STRING_X, constants.TABLE_MAX_X - constants.BALL_RADIUS)
	cueBall.z = math.clamp(candidateZ, constants.TABLE_MIN_Z + constants.BALL_RADIUS, constants.TABLE_MAX_Z - constants.BALL_RADIUS)
end

function state.resetRoundState(context)
	context.shotInProgress = false
	context.cueBallPocketedThisShot = false
	context.firstHitGroup = nil
	context.pocketedThisShot = {}
end

function state.resetMatch(context)
	context.balls = {}
	context.ballsById = {}

	context.turnPlayer = 1
	context.assignments = { [1] = nil, [2] = nil }
	context.winner = nil
	context.ballInHand = false
	context.cueAim = math.pi
	context.shotPower = 0.60
	context.statusLine = "Press Space to break."
	state.resetRoundState(context)

	createBall(context, 0, constants.CUE_START_X, constants.CUE_START_Z)

	local solids = { 1, 2, 3, 4, 5, 6, 7 }
	local stripes = { 9, 10, 11, 12, 13, 14, 15 }
	shuffle(solids)
	shuffle(stripes)

	local layout = {}
	layout[5] = 8
	layout[11] = solids[#solids]
	table.remove(solids, #solids)
	layout[15] = stripes[#stripes]
	table.remove(stripes, #stripes)

	local remaining = {}
	for i = 1, #solids do
		table.insert(remaining, solids[i])
	end
	for i = 1, #stripes do
		table.insert(remaining, stripes[i])
	end
	shuffle(remaining)

	local cursor = 1
	for slot = 1, #constants.rackOffsets do
		if layout[slot] == nil then
			layout[slot] = remaining[cursor]
			cursor = cursor + 1
		end
	end

	for slot = 1, #constants.rackOffsets do
		local id = layout[slot]
		local off = constants.rackOffsets[slot]
		createBall(context, id, off.x, off.z)
	end
end

function state.tryMoveCueBall(context, dx, dz)
	if context.winner or not context.ballInHand or state.ballsAreMoving(context) then
		return
	end

	local cueBall = state.getCueBall(context)
	if not cueBall or not cueBall.active then
		return
	end

	local targetX = math.clamp(cueBall.x + dx, constants.HEAD_STRING_X, constants.TABLE_MAX_X - constants.BALL_RADIUS)
	local targetZ = math.clamp(cueBall.z + dz, constants.TABLE_MIN_Z + constants.BALL_RADIUS, constants.TABLE_MAX_Z - constants.BALL_RADIUS)

	if state.canPlaceCueBallAt(context, targetX, targetZ) then
		cueBall.x = targetX
		cueBall.z = targetZ
	end
end

function state.pocketBall(context, ball)
	ball.active = false
	ball.vx = 0
	ball.vz = 0

	if not context.shotInProgress then
		return
	end

	if ball.group == "cue" then
		context.cueBallPocketedThisShot = true
	else
		table.insert(context.pocketedThisShot, ball)
	end
end

function state.shootCueBall(context)
	if context.winner or state.ballsAreMoving(context) then
		return
	end

	local cueBall = state.getCueBall(context)
	if not cueBall then
		return
	end

	if context.ballInHand and not state.canPlaceCueBallAt(context, cueBall.x, cueBall.z) then
		context.statusLine = "Invalid cue-ball placement."
		return
	end

	local speed = math.max(constants.MIN_SHOT_POWER, context.shotPower) * constants.SHOT_POWER_SCALE
	cueBall.vx = math.cos(context.cueAim) * speed
	cueBall.vz = math.sin(context.cueAim) * speed

	context.shotInProgress = true
	context.cueBallPocketedThisShot = false
	context.firstHitGroup = nil
	context.pocketedThisShot = {}
	context.statusLine = "Player " .. context.turnPlayer .. " shoots."
end

return state
