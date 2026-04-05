local plugin = ...
local constants = plugin:require("constants")
local codec = plugin:require("codec")

local state = {}

local function ballModelNameForId(ballId)
	if ballId == 0 then
		return "cueball"
	end

	if type(ballId) == "number" and ballId > 0 then
		return "ball" .. tostring(ballId)
	end

	return nil
end

function state.newContext()
	return {
		loadedModelIds = {},
		ballAnimations = {},
		snapshot = nil,
		noticeLine = "Waiting for pool server state...",
		lastSnapshotTick = -1,
		localTicks = 0,
		cameraCaptured = false,
		cameraPos = nil,
		cameraRot = nil,
		cameraFov = nil,
		cameraMode = constants.CAMERA_MODE_ORDER[1],
		hudMode = constants.HUD_MODE_ORDER[1],
	}
end

local function getBallIndex(snapshot)
	local indexed = {}
	local balls = snapshot and snapshot.balls
	if type(balls) ~= "table" then
		return indexed
	end

	for i = 1, #balls do
		local ball = balls[i]
		if type(ball) == "table" and type(ball.id) == "number" then
			indexed[ball.id] = ball
		end
	end

	return indexed
end

local function nearestPocket(x, z)
	local nearest = nil
	local nearestDistSq = math.huge

	for i = 1, #constants.pocketCenters do
		local pocket = constants.pocketCenters[i]
		local dx = x - pocket.x
		local dz = z - pocket.z
		local distSq = (dx * dx) + (dz * dz)
		if distSq < nearestDistSq then
			nearest = pocket
			nearestDistSq = distSq
		end
	end

	return nearest
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

local function emit(name, ...)
	local ok = emitServerEvent(name, ...)
	if not ok then
		plugin:warn("Failed to emit pool event '" .. tostring(name) .. "'")
	end
	return ok
end

function state.requestState(context, forceSeatClaim)
	return emit(constants.EVENTS.requestState, context.localTicks, forceSeatClaim == true)
end

function state.sendCommand(context, action, ...)
	return emit(constants.EVENTS.command, action, context.localTicks, ...)
end

function state.applySnapshot(context, data)
	if type(data) == "string" then
		local decoded, decodeErr = codec.decodeSnapshot(data)
		if not decoded then
			plugin:warn("Failed to decode pool snapshot: " .. tostring(decodeErr))
			return
		end
		data = decoded
	elseif type(data) ~= "table" then
		return
	end

	constants.applyServerConstants(data.sharedConstants)

	local previousSnapshot = context.snapshot
	if type(previousSnapshot) == "table" and type(data.balls) == "table" then
		local previousBalls = getBallIndex(previousSnapshot)
		local nextBalls = getBallIndex(data)

		for i = 1, #data.balls do
			local ball = data.balls[i]
			local previous = previousBalls[ball.id]
			if ball.active and (not previous or previous.active ~= true) then
				context.ballAnimations[ball.id] = {
					kind = "spawn",
					startTick = context.localTicks,
					endTick = context.localTicks + constants.BALL_PLACE_ANIM_TICKS,
					x = ball.x,
					z = ball.z,
					modelName = ball.modelName or ballModelNameForId(ball.id),
				}
			end
		end

		for id, previous in pairs(previousBalls) do
			local nextBall = nextBalls[id]
			if previous.active and (not nextBall or nextBall.active ~= true) then
				local pocket = nearestPocket(previous.x, previous.z)
				context.ballAnimations[id] = {
					kind = "despawn",
					startTick = context.localTicks,
					endTick = context.localTicks + constants.BALL_SINK_ANIM_TICKS,
					x = previous.x,
					z = previous.z,
					targetX = pocket and pocket.x or previous.x,
					targetZ = pocket and pocket.z or previous.z,
					modelName = previous.modelName or ballModelNameForId(previous.id),
				}
			elseif nextBall and nextBall.active then
				local animation = context.ballAnimations[id]
				if animation and animation.kind == "despawn" then
					context.ballAnimations[id] = nil
				end
			end
		end
	else
		context.ballAnimations = {}
	end

	if type(data.balls) == "table" then
		for i = 1, #data.balls do
			local ball = data.balls[i]
			if type(ball) == "table" and ball.modelName == nil then
				ball.modelName = ballModelNameForId(ball.id)
			end
		end
	end

	context.snapshot = data
	context.lastSnapshotTick = context.localTicks

	if type(data.noticeLine) == "string" and data.noticeLine ~= "" then
		context.noticeLine = data.noticeLine
	elseif type(data.statusLine) == "string" and data.statusLine ~= "" then
		context.noticeLine = data.statusLine
	else
		context.noticeLine = "Connected to pool server."
	end
end

function state.applyNotice(context, data)
	if type(data) == "string" and data ~= "" then
		context.noticeLine = data
	elseif type(data) == "table" and type(data.text) == "string" and data.text ~= "" then
		context.noticeLine = data.text
	end
end

function state.logicTick(context)
	context.localTicks = context.localTicks + 1

	for id, animation in pairs(context.ballAnimations) do
		if context.localTicks >= (animation.endTick or 0) then
			context.ballAnimations[id] = nil
		end
	end

	if context.snapshot == nil then
		if context.localTicks == 1 or context.localTicks % constants.RESUBSCRIBE_TICKS == 0 then
			state.requestState(context, false)
		end
		return
	end

	if context.lastSnapshotTick >= 0 and (context.localTicks - context.lastSnapshotTick) > constants.STATE_TIMEOUT_TICKS then
		context.snapshot = nil
		context.noticeLine = "Pool server state timed out. Re-requesting."
		state.requestState(context, false)
	elseif context.localTicks % constants.RESUBSCRIBE_TICKS == 0 then
		state.requestState(context, false)
	end
end

function state.getRenderSnapshot(context)
	local snapshot = context.snapshot
	if type(snapshot) ~= "table" then
		return nil
	end

	return snapshot
end

function state.getBallAnimation(context, ballId)
	if type(ballId) ~= "number" then
		return nil
	end

	return context.ballAnimations[ballId]
end

function state.getBallAnimations(context)
	return context.ballAnimations
end

function state.getCueBall(context, snapshot)
	snapshot = snapshot or context.snapshot
	local balls = snapshot and snapshot.balls
	if type(balls) ~= "table" then
		return nil
	end

	for i = 1, #balls do
		local ball = balls[i]
		if ball and ball.id == 0 then
			return ball
		end
	end

	return nil
end

function state.getLocalSeat(context, snapshot)
	snapshot = snapshot or context.snapshot
	if type(snapshot) ~= "table" then
		return nil
	end

	local seat = tonumber(snapshot.localSeat)
	if seat == 1 or seat == 2 then
		return seat
	end

	return nil
end

local function canControlCue(context, snapshot)
	snapshot = snapshot or context.snapshot
	if type(snapshot) ~= "table" then
		return false
	end

	local localSeat = state.getLocalSeat(context, snapshot)
	if not localSeat then
		return false
	end

	if snapshot.phase ~= "playing" or snapshot.winner ~= nil or snapshot.moving == true then
		return false
	end

	return tonumber(snapshot.turnPlayer) == localSeat
end

function state.moveCueByCamera(context, forwardSign, rightSign)
	local snapshot = context.snapshot
	if not canControlCue(context, snapshot) or not snapshot.ballInHand then
		return false
	end

	local cueAim = tonumber(snapshot.cueAim) or 0.0
	local forwardX = math.cos(cueAim)
	local forwardZ = math.sin(cueAim)
	local rightX = forwardZ
	local rightZ = -forwardX

	local f = tonumber(forwardSign) or 0.0
	local r = tonumber(rightSign) or 0.0
	if f == 0.0 and r == 0.0 then
		return false
	end

	local moveStep = constants.CUE_MOVE_STEP
	local dx = ((forwardX * f) + (rightX * r)) * moveStep
	local dz = ((forwardZ * f) + (rightZ * r)) * moveStep
	state.sendCommand(context, "move_cue", dx, dz)
	return true
end

function state.shoot(context)
	local snapshot = context.snapshot
	if not canControlCue(context, snapshot) then
		return false
	end

	local cueBall = state.getCueBall(context, snapshot)
	if not cueBall or not cueBall.active then
		return false
	end

	local cueAim = tonumber(snapshot.cueAim) or 0.0
	local shotPower = tonumber(snapshot.shotPower) or constants.MIN_SHOT_POWER
	if snapshot.ballInHand then
		state.sendCommand(context, "shoot", cueAim, shotPower, tonumber(cueBall.x), tonumber(cueBall.z))
	else
		state.sendCommand(context, "shoot", cueAim, shotPower)
	end
	return true
end

function state.getSeatDisplay(snapshot, seat)
	local seats = snapshot and snapshot.seats
	if type(seats) ~= "table" then
		return "-"
	end

	local info = seats[seat]
	if type(info) ~= "table" then
		return "-"
	end

	if type(info.playerName) == "string" and info.playerName ~= "" then
		return info.playerName
	end

	return "-"
end

function state.getSeatInfo(context, seat, snapshot)
	snapshot = snapshot or context.snapshot
	local seats = snapshot and snapshot.seats
	if type(seats) ~= "table" then
		return nil
	end

	local info = seats[seat]
	if type(info) ~= "table" then
		return nil
	end

	return info
end

function state.getPhase(context)
	local snapshot = context.snapshot
	if type(snapshot) ~= "table" or type(snapshot.phase) ~= "string" then
		return "waiting"
	end

	return snapshot.phase
end

function state.getCameraMode(context)
	return context.cameraMode or constants.CAMERA_MODE_ORDER[1]
end

function state.getHudMode(context)
	return context.hudMode or constants.HUD_MODE_ORDER[1]
end

function state.cycleCameraMode(context)
	context.cameraMode = constants.nextMode(constants.CAMERA_MODE_ORDER, state.getCameraMode(context))
	context.noticeLine = constants.CAMERA_MODE_LABELS[context.cameraMode] or "Camera updated."
end

function state.cycleHudMode(context)
	context.hudMode = constants.nextMode(constants.HUD_MODE_ORDER, state.getHudMode(context))
	context.noticeLine = constants.HUD_MODE_LABELS[context.hudMode] or "HUD updated."
end

function state.isChatOpen()
	local localPlayer = client and client.player or nil
	return localPlayer ~= nil and tonumber(localPlayer.menuTab) == 2
end

function state.isInputBlocked()
	return (client and tonumber(client.isPauseMenu) or 0) ~= 0
		or (client and tonumber(client.menuState) or 0) ~= 0
		or state.isChatOpen()
end

function state.shouldUseTableCamera(context)
	return not state.isInputBlocked()
		and state.getCameraMode(context) ~= "off"
		and state.getLocalSeat(context) ~= nil
		and context.snapshot ~= nil
end

function state.captureCamera(context)
	if context.cameraCaptured or not client or not client.camera then
		return
	end

	context.cameraCaptured = true
	context.cameraPos = client.camera.pos and client.camera.pos:clone() or nil
	context.cameraRot = client.camera.rot and client.camera.rot:clone() or nil
	context.cameraFov = client.camera.fov
end

function state.restoreCamera(context)
	if not context.cameraCaptured or not client or not client.camera then
		return
	end

	if context.cameraPos then
		client.camera.pos:set(context.cameraPos)
	end
	if context.cameraRot then
		client.camera.rot:set(context.cameraRot)
	end
	if context.cameraFov then
		client.camera.fov = context.cameraFov
	end

	context.cameraCaptured = false
	context.cameraPos = nil
	context.cameraRot = nil
	context.cameraFov = nil
end

return state
