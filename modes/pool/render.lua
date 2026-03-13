local plugin = ...
local constants = plugin:require("constants")

local render = {}

local function drawPanel(x, y, w, h, r, g, b, a)
	renderer:drawRectangle2D(x, y, w, h, r, g, b, a)
end

local function drawLabel(text, x, y, scale, r, g, b, a)
	renderer:drawText(text, x, y, scale, r, g, b, a, 0x20)
end

local function worldDebugPoint(x, z, y)
	return constants.TABLE_POS + (Vector(x, y or constants.DEBUG_LINE_HEIGHT, z) * constants.TABLE_ROT)
end

local function drawTableDebug(context, state)
	local snapshot = context.snapshot
	if type(snapshot) ~= "table" then
		return
	end

	local minX = constants.TABLE_MIN_X
	local maxX = constants.TABLE_MAX_X
	local minZ = constants.TABLE_MIN_Z
	local maxZ = constants.TABLE_MAX_Z
	local centerX = (minX + maxX) * 0.5
	local centerZ = (minZ + maxZ) * 0.5

	renderer:drawDebugWireBox3D(
		worldDebugPoint(centerX, centerZ, constants.DEBUG_LINE_HEIGHT),
		constants.TABLE_ROT,
		(maxX - minX) * 0.5,
		constants.DEBUG_ZONE_THICKNESS,
		(maxZ - minZ) * 0.5,
		0.20,
		1.0,
		0.68,
		1.0
	)

	renderer:resetDebugBatchTransform()
	renderer:setDebugBatchColor(0.25, 1.0, 0.72, 0.95)
	renderer:beginDebugBatch(2)
	renderer:addDebugBatchVertex(worldDebugPoint(minX, minZ))
	renderer:addDebugBatchVertex(worldDebugPoint(maxX, minZ))
	renderer:addDebugBatchVertex(worldDebugPoint(maxX, minZ))
	renderer:addDebugBatchVertex(worldDebugPoint(maxX, maxZ))
	renderer:addDebugBatchVertex(worldDebugPoint(maxX, maxZ))
	renderer:addDebugBatchVertex(worldDebugPoint(minX, maxZ))
	renderer:addDebugBatchVertex(worldDebugPoint(minX, maxZ))
	renderer:addDebugBatchVertex(worldDebugPoint(minX, minZ))
	renderer:flushDebugBatch()

	renderer:resetDebugBatchTransform()
	renderer:setDebugBatchColor(0.86, 0.84, 0.34, 0.80)
	renderer:beginDebugBatch(2)
	renderer:addDebugBatchVertex(worldDebugPoint(constants.HEAD_STRING_X, minZ))
	renderer:addDebugBatchVertex(worldDebugPoint(constants.HEAD_STRING_X, maxZ))
	renderer:flushDebugBatch()

	for i = 1, #constants.pocketCenters do
		local pocket = constants.pocketCenters[i]
		renderer:drawDebugSolidBox3D(
			constants.localToWorld(pocket.x, pocket.z),
			constants.TABLE_ROT,
			constants.POCKET_RADIUS,
			constants.DEBUG_ZONE_THICKNESS,
			constants.POCKET_RADIUS,
			0.98,
			0.26,
			0.26,
			0.35
		)
	end

	if snapshot.ballInHand then
		local zoneCenterX = (constants.HEAD_STRING_X + constants.TABLE_MAX_X - constants.BALL_RADIUS) * 0.5
		local zoneHalfX = (constants.TABLE_MAX_X - constants.BALL_RADIUS - constants.HEAD_STRING_X) * 0.5
		local zoneHalfZ = (constants.TABLE_MAX_Z - constants.TABLE_MIN_Z - constants.BALL_RADIUS * 2.0) * 0.5
		renderer:drawDebugSolidBox3D(
			worldDebugPoint(zoneCenterX, 0.0, constants.DEBUG_ZONE_HEIGHT),
			constants.TABLE_ROT,
			math.max(zoneHalfX, 0.02),
			constants.DEBUG_ZONE_THICKNESS,
			math.max(zoneHalfZ, 0.02),
			0.30,
			0.62,
			1.0,
			0.14
		)
	end

	local cueBall = state.getCueBall(context)
	if not cueBall or not cueBall.active or snapshot.moving == true or snapshot.winner ~= nil then
		return
	end

	local aim = tonumber(snapshot.cueAim) or 0.0
	local power = tonumber(snapshot.shotPower) or constants.MIN_SHOT_POWER
	local dirX = math.cos(aim)
	local dirZ = math.sin(aim)
	local posX = cueBall.x
	local posZ = cueBall.z
	local remaining = (math.max(constants.MIN_SHOT_POWER, power) * constants.SHOT_POWER_SCALE) * 26.0

	renderer:setDebugBatchColor(1.0, 0.92, 0.34, 0.95)
	renderer:beginDebugBatch(2)

	for _ = 1, constants.DEBUG_PREDICTION_STEPS do
		if remaining <= 0.01 then
			break
		end

		local tx = math.huge
		local tz = math.huge

		if dirX > 0.0001 then
			tx = (maxX - posX) / dirX
		elseif dirX < -0.0001 then
			tx = (minX - posX) / dirX
		end

		if dirZ > 0.0001 then
			tz = (maxZ - posZ) / dirZ
		elseif dirZ < -0.0001 then
			tz = (minZ - posZ) / dirZ
		end

		local hitDistance = math.min(tx, tz, remaining)
		if hitDistance == math.huge or hitDistance <= 0 then
			break
		end

		local nextX = posX + (dirX * hitDistance)
		local nextZ = posZ + (dirZ * hitDistance)
		renderer:addDebugBatchVertex(worldDebugPoint(posX, posZ))
		renderer:addDebugBatchVertex(worldDebugPoint(nextX, nextZ))

		local hitX = math.abs(hitDistance - tx) < 0.001
		local hitZ = math.abs(hitDistance - tz) < 0.001
		posX = math.clamp(nextX, minX, maxX)
		posZ = math.clamp(nextZ, minZ, maxZ)
		remaining = remaining - hitDistance

		if hitX then
			dirX = -dirX
		end
		if hitZ then
			dirZ = -dirZ
		end

		if not hitX and not hitZ then
			break
		end
	end

	renderer:flushDebugBatch()
end

function render.updateCamera(context, state)
	if not state.shouldUseTableCamera(context) or not client or not client.camera then
		state.restoreCamera(context)
		return
	end

	state.captureCamera(context)
	local seat = state.getLocalSeat(context)
	local cameraPos = constants.tableCameraPosition(seat)
	local cameraTarget = constants.tableCameraTarget(seat)
	client.camera.pos:set(cameraPos)
	client.camera.rot:set(getRotMatrixLookingAt(cameraPos, cameraTarget))
	client.camera.fov = constants.CAMERA_FOV
end

function render.renderFrame(context, state)
	state.ensureModelsLoaded(context)

	local snapshot = context.snapshot
	if type(snapshot) ~= "table" then
		return
	end

	local tableModel = context.loadedModelIds.table
	if type(tableModel) == "number" then
		renderer:renderObject(tableModel, constants.TABLE_POS, constants.TABLE_ROT)
	end

	local balls = snapshot.balls
	if type(balls) == "table" then
		for i = 1, #balls do
			local ball = balls[i]
			if ball and ball.active then
				local modelId = context.loadedModelIds[ball.modelName]
				if type(modelId) == "number" then
					renderer:renderObject(modelId, constants.localToWorld(ball.x, ball.z), constants.TABLE_ROT)
				end
			end
		end
	end

	if snapshot.winner == nil and snapshot.moving ~= true then
		local cueModelId = context.loadedModelIds.cue
		local cueBall = state.getCueBall(context)
		if type(cueModelId) == "number" and cueBall and cueBall.active then
			local cueAim = tonumber(snapshot.cueAim) or math.pi
			local shotPower = tonumber(snapshot.shotPower) or constants.MIN_SHOT_POWER
			local dirX = math.cos(cueAim)
			local dirZ = math.sin(cueAim)
			local cueDistance = 0.78 + ((1.0 - shotPower) * 0.25)
			local cueX = cueBall.x - (dirX * cueDistance)
			local cueZ = cueBall.z - (dirZ * cueDistance)
			local cueRot = yawToRotMatrix(cueAim + (math.pi * 0.5))
			renderer:renderObject(cueModelId, constants.localToWorld(cueX, cueZ), cueRot)
		end
	end
end

function render.draw3D(context, state)
	drawTableDebug(context, state)
end

function render.drawUI(context, state)
	local snapshot = context.snapshot
	local scale = plugin.config.textScale
	local margin = constants.HUD_MARGIN
	local width = constants.SCREEN_WIDTH
	local height = constants.SCREEN_HEIGHT
	local rightWidth = constants.HUD_RIGHT_WIDTH
	local topHeight = constants.HUD_TOP_HEIGHT
	local bottomHeight = constants.HUD_BOTTOM_HEIGHT
	local contentLeft = margin
	local contentTop = margin
	local contentRight = width - margin
	local contentBottom = height - margin
	local leftWidth = width - (margin * 3) - rightWidth

	local phaseText = "WAITING"
	local turnText = "Player -"
	local seatText = "Spectator"
	local statusText = context.noticeLine
	local scoreText = "0  -  0"
	local groupsText = "Open Table"
	local shotText = "Aim --  Power --"
	local handText = " "
	local controlsText = "J Join  L Leave  Enter Ready  Arrows Aim/Power  Space Shoot  R Rerack  WASD Cue"
	local practiceText = " "
	local seatOneName = "Open"
	local seatTwoName = "Open"
	local seatOneReady = "Idle"
	local seatTwoReady = "Idle"
	local cameraText = "Spectator Camera"
	local staleText = " "

	if type(snapshot) == "table" then
		local seatOne = state.getSeatInfo(context, 1)
		local seatTwo = state.getSeatInfo(context, 2)
		local localSeat = state.getLocalSeat(context)
		local cueAim = tonumber(snapshot.cueAim) or 0
		local shotPower = tonumber(snapshot.shotPower) or 0
		local aimDeg = (math.deg(cueAim) % 360 + 360) % 360
		local scoreOne = seatOne and tonumber(seatOne.wins) or 0
		local scoreTwo = seatTwo and tonumber(seatTwo.wins) or 0

		phaseText = string.upper(tostring(snapshot.phase or "waiting"))
		turnText = snapshot.winner and ("Winner: Player " .. tostring(snapshot.winner))
			or ("Turn: Player " .. tostring(snapshot.turnPlayer or "?"))
		seatText = localSeat and ("Seat: Player " .. tostring(localSeat)) or "Seat: Spectator"
		statusText = tostring(snapshot.statusLine or context.noticeLine)
		scoreText = string.format("%d  -  %d", scoreOne or 0, scoreTwo or 0)
		groupsText = string.format(
			"P1 %s  |  P2 %s",
			constants.formatGroup(snapshot.assignments and snapshot.assignments[1] or nil),
			constants.formatGroup(snapshot.assignments and snapshot.assignments[2] or nil)
		)
		shotText = string.format("Aim %03.0f  |  Power %02.0f%%", aimDeg, shotPower * 100)
		handText = snapshot.ballInHand and "Ball in hand: use WASD to move the cue ball." or " "
		practiceText = snapshot.practiceMode and "Practice Mode Active" or " "
		seatOneName = seatOne and seatOne.playerName or "Open"
		seatTwoName = seatTwo and seatTwo.playerName or "Open"
		seatOneReady = seatOne and (seatOne.ready and "Ready" or "Idle") or "Open"
		seatTwoReady = seatTwo and (seatTwo.ready and "Ready" or "Idle") or "Open"
		cameraText = localSeat and ("Player " .. tostring(localSeat) .. " Camera") or "Spectator Camera"
		if context.lastSnapshotTick >= 0 then
			local age = context.localTicks - context.lastSnapshotTick
			if age > math.floor(constants.RESUBSCRIBE_TICKS * 0.5) then
				staleText = "State stale: waiting for fresh server snapshot."
			end
		end
	end

	drawPanel(contentLeft, contentTop, leftWidth, topHeight, 0.05, 0.12, 0.11, 0.78)
	drawPanel(contentLeft, contentTop + topHeight + margin, leftWidth, contentBottom - contentTop - topHeight - bottomHeight - margin * 2, 0.04, 0.08, 0.08, 0.44)
	drawPanel(contentLeft, contentBottom - bottomHeight, leftWidth, bottomHeight, 0.08, 0.12, 0.10, 0.78)
	drawPanel(contentLeft + leftWidth + margin, contentTop, rightWidth, contentBottom - contentTop, 0.06, 0.07, 0.10, 0.82)

	drawLabel("POOL", contentLeft + 18, contentTop + 18, 30, 0.88, 0.98, 0.94, 1.0)
	drawLabel(phaseText, contentLeft + 18, contentTop + 48, 18, 0.66, 0.90, 0.77, 1.0)
	drawLabel(turnText, contentLeft + 180, contentTop + 22, 18, 0.97, 0.97, 0.97, 1.0)
	drawLabel(seatText, contentLeft + 180, contentTop + 48, 18, 0.78, 0.90, 1.0, 1.0)

	local rightX = contentLeft + leftWidth + margin + 18
	local y = contentTop + 18
	drawLabel("Match", rightX, y, 22, 0.91, 0.95, 1.0, 1.0)
	y = y + 34
	drawLabel("Score", rightX, y, 16, 0.65, 0.78, 0.90, 1.0)
	y = y + 22
	drawLabel(scoreText, rightX, y, 28, 1.0, 0.95, 0.72, 1.0)
	y = y + 44
	drawLabel("Groups", rightX, y, 16, 0.65, 0.78, 0.90, 1.0)
	y = y + 22
	drawLabel(groupsText, rightX, y, 16, 0.94, 0.96, 0.98, 1.0)
	y = y + 40
	drawLabel("Seats", rightX, y, 16, 0.65, 0.78, 0.90, 1.0)
	y = y + 24
	drawLabel("P1  " .. seatOneName, rightX, y, 18, 0.97, 0.97, 0.97, 1.0)
	drawLabel(seatOneReady, rightX + 210, y, 16, 0.66, 0.90, 0.77, 1.0)
	y = y + 24
	drawLabel("P2  " .. seatTwoName, rightX, y, 18, 0.97, 0.97, 0.97, 1.0)
	drawLabel(seatTwoReady, rightX + 210, y, 16, 0.66, 0.90, 0.77, 1.0)
	y = y + 42
	drawLabel("Shot", rightX, y, 16, 0.65, 0.78, 0.90, 1.0)
	y = y + 22
	drawLabel(shotText, rightX, y, 17, 0.95, 0.95, 0.95, 1.0)
	y = y + 30
	drawLabel(statusText, rightX, y, 17, 1.0, 0.84, 0.38, 1.0)
	y = y + 30
	drawLabel(handText, rightX, y, 16, 0.74, 1.0, 0.79, 1.0)
	y = y + 26
	drawLabel(practiceText, rightX, y, 16, 0.76, 0.88, 1.0, 1.0)
	y = y + 24
	drawLabel(staleText, rightX, y, 15, 1.0, 0.70, 0.45, 1.0)

	drawLabel(cameraText, contentLeft + 18, contentBottom - bottomHeight + 18, 18, 0.74, 0.89, 1.0, 1.0)
	drawLabel(controlsText, contentLeft + 18, contentBottom - bottomHeight + 44, 15, 0.82, 0.84, 0.87, 1.0)
end

return render
