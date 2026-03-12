local plugin = ...
local constants = plugin:require("constants")

local state = {}

function state.newContext()
	return {
		loadedModelIds = {},
		snapshot = nil,
		noticeLine = "Waiting for pool server state...",
		lastSnapshotTick = -1,
		localTicks = 0,
	}
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

local function emit(name, payload)
	local ok = emitServerEvent(name, payload)
	if not ok then
		plugin:warn("Failed to emit pool event '" .. tostring(name) .. "'")
	end
	return ok
end

function state.requestState(context, forceSeatClaim)
	local payload = {
		localTick = context.localTicks,
	}
	if forceSeatClaim then
		payload.claimSeat = true
	end

	return emit(constants.EVENTS.requestState, payload)
end

function state.sendCommand(context, action, payload)
	payload = payload or {}
	payload.action = action
	payload.localTick = context.localTicks
	return emit(constants.EVENTS.command, payload)
end

function state.applySnapshot(context, data)
	if type(data) ~= "table" then
		return
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
	if type(data) == "table" and type(data.text) == "string" and data.text ~= "" then
		context.noticeLine = data.text
	end
end

function state.logicTick(context)
	context.localTicks = context.localTicks + 1

	if context.snapshot == nil then
		if context.localTicks == 1 or context.localTicks % constants.RESUBSCRIBE_TICKS == 0 then
			state.requestState(context, true)
		end
		return
	end

	if context.lastSnapshotTick >= 0 and (context.localTicks - context.lastSnapshotTick) > constants.STATE_TIMEOUT_TICKS then
		context.snapshot = nil
		context.noticeLine = "Pool server state timed out. Re-requesting."
		state.requestState(context, true)
	elseif context.localTicks % constants.RESUBSCRIBE_TICKS == 0 then
		state.requestState(context, false)
	end
end

function state.getCueBall(context)
	local snapshot = context.snapshot
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

function state.getLocalSeat(context)
	local snapshot = context.snapshot
	if type(snapshot) ~= "table" then
		return nil
	end

	local seat = tonumber(snapshot.localSeat)
	if seat == 1 or seat == 2 then
		return seat
	end

	return nil
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

return state
