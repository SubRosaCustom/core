local plugin = ...
local constants = plugin:require("constants")

local render = {}

local function drawPanel(x, y, w, h, r, g, b, a)
	renderer:drawRectangle2D(x, y, w, h, r, g, b, a)
end

local function drawLabel(text, x, y, scale, r, g, b, a)
	renderer:drawText(text, x, y, scale, r, g, b, a, 0x20)
end

local function clamp01(value)
	if value <= 0 then
		return 0
	end
	if value >= 1 then
		return 1
	end
	return value
end

local function easeOutCubic(value)
	local t = 1 - clamp01(value)
	return 1 - (t * t * t)
end

local function easeInCubic(value)
	local t = clamp01(value)
	return t * t * t
end

local function lerp(a, b, t)
	return a + ((b - a) * t)
end

local function worldDebugPoint(x, z, y)
	return constants.TABLE_POS + (Vector(x, y or constants.DEBUG_LINE_HEIGHT, z) * constants.TABLE_ROT)
end

local function drawLineStrip(points, r, g, b, a)
	if #points < 2 then
		return
	end

	renderer:resetDebugBatchTransform()
	renderer:setDebugBatchColor(r, g, b, a)
	renderer:beginDebugBatch(2)
	for i = 1, #points - 1 do
		renderer:addDebugBatchVertex(points[i])
		renderer:addDebugBatchVertex(points[i + 1])
	end
	renderer:flushDebugBatch()
end

local function drawCross(x, z, size, y, r, g, b, a)
	drawLineStrip({
		worldDebugPoint(x - size, z, y),
		worldDebugPoint(x + size, z, y),
	}, r, g, b, a)
	drawLineStrip({
		worldDebugPoint(x, z - size, y),
		worldDebugPoint(x, z + size, y),
	}, r, g, b, a)
end

local function drawVerticalMarker(x, z, centerY, size, r, g, b, a)
	drawLineStrip({
		worldDebugPoint(x, z, centerY - size),
		worldDebugPoint(x, z, centerY + size),
	}, r, g, b, a)
end

local function drawCircleXZ(x, y, z, radius, segments, r, g, b, a)
	local points = {}
	for i = 0, segments do
		local angle = (i / segments) * (math.pi * 2)
		points[#points + 1] = worldDebugPoint(
			x + (math.cos(angle) * radius),
			z + (math.sin(angle) * radius),
			y
		)
	end
	drawLineStrip(points, r, g, b, a)
end

local function drawCircleXY(x, y, z, radius, segments, r, g, b, a)
	local points = {}
	for i = 0, segments do
		local angle = (i / segments) * (math.pi * 2)
		points[#points + 1] = worldDebugPoint(
			x + (math.cos(angle) * radius),
			z,
			y + (math.sin(angle) * radius)
		)
	end
	drawLineStrip(points, r, g, b, a)
end

local function drawCircleYZ(x, y, z, radius, segments, r, g, b, a)
	local points = {}
	for i = 0, segments do
		local angle = (i / segments) * (math.pi * 2)
		points[#points + 1] = worldDebugPoint(
			x,
			z + (math.cos(angle) * radius),
			y + (math.sin(angle) * radius)
		)
	end
	drawLineStrip(points, r, g, b, a)
end

local function drawPocketSphere(pocket, r, g, b, a)
	local radius = constants.POCKET_SPHERE_RADIUS
	local segments = 18
	drawCircleXZ(pocket.x, pocket.y, pocket.z, radius, segments, r, g, b, a)
	drawCircleXY(pocket.x, pocket.y, pocket.z, radius, segments, r, g, b, a * 0.9)
	drawCircleYZ(pocket.x, pocket.y, pocket.z, radius, segments, r, g, b, a * 0.9)
	drawCross(pocket.x, pocket.z, 0.08, pocket.y, 1.0, 0.40, 0.40, 0.95)
	drawVerticalMarker(pocket.x, pocket.z, pocket.y, 0.08, 1.0, 0.40, 0.40, 0.95)
end

local function animationProgress(context, animation)
	if not animation then
		return 1
	end

	local span = math.max(1, (animation.endTick or 0) - (animation.startTick or 0))
	return clamp01((context.localTicks - (animation.startTick or 0)) / span)
end

local function renderBallModel(modelId, x, z, y)
	if type(modelId) ~= "number" then
		return
	end

	renderer:renderObject(modelId, constants.localToWorld(x, z, y), constants.TABLE_ROT)
end

local function drawArrow(x, z, dirX, dirZ, length, headSize, y, r, g, b, a)
	local endX = x + (dirX * length)
	local endZ = z + (dirZ * length)
	drawLineStrip({
		worldDebugPoint(x, z, y),
		worldDebugPoint(endX, endZ, y),
	}, r, g, b, a)

	local leftX = endX - (dirX * headSize) + (dirZ * headSize * 0.65)
	local leftZ = endZ - (dirZ * headSize) - (dirX * headSize * 0.65)
	local rightX = endX - (dirX * headSize) - (dirZ * headSize * 0.65)
	local rightZ = endZ - (dirZ * headSize) + (dirX * headSize * 0.65)
	drawLineStrip({
		worldDebugPoint(leftX, leftZ, y),
		worldDebugPoint(endX, endZ, y),
		worldDebugPoint(rightX, rightZ, y),
	}, r, g, b, a)
end

local function drawTableDebug(context, state)
	local snapshot = state.getRenderSnapshot(context)
	if type(snapshot) ~= "table" then
		return
	end

	local minX = constants.TABLE_MIN_X
	local maxX = constants.TABLE_MAX_X
	local minZ = constants.TABLE_MIN_Z
	local maxZ = constants.TABLE_MAX_Z
	local centerX = (minX + maxX) * 0.5
	local centerZ = (minZ + maxZ) * 0.5
	local safeMinX = minX + constants.BALL_RADIUS
	local safeMaxX = maxX - constants.BALL_RADIUS
	local safeMinZ = minZ + constants.BALL_RADIUS
	local safeMaxZ = maxZ - constants.BALL_RADIUS
	local axisOriginX = minX - 0.22

	drawArrow(axisOriginX, centerZ, 1.0, 0.0, 0.65, 0.12, constants.DEBUG_LINE_HEIGHT + 0.05, 1.0, 0.18, 0.18, 0.95)
	drawArrow(axisOriginX, centerZ, 0.0, 1.0, 0.65, 0.12, constants.DEBUG_LINE_HEIGHT + 0.05, 0.18, 0.55, 1.0, 0.95)
	drawLineStrip({
		worldDebugPoint(axisOriginX, centerZ, constants.DEBUG_LINE_HEIGHT - 0.12),
		worldDebugPoint(axisOriginX, centerZ, constants.DEBUG_LINE_HEIGHT + 0.55),
	}, 0.32, 1.0, 0.32, 0.95)

	renderer:drawDebugWireBox3D(
		worldDebugPoint(centerX, centerZ, constants.DEBUG_LINE_HEIGHT),
		constants.TABLE_ROT,
		(maxX - minX) * 0.5,
		constants.DEBUG_ZONE_THICKNESS,
		(maxZ - minZ) * 0.5,
		0.16,
		1.0,
		0.72,
		1.0
	)

	drawLineStrip({
		worldDebugPoint(minX, minZ),
		worldDebugPoint(maxX, minZ),
		worldDebugPoint(maxX, maxZ),
		worldDebugPoint(minX, maxZ),
		worldDebugPoint(minX, minZ),
	}, 0.26, 1.0, 0.78, 0.96)

	drawLineStrip({
		worldDebugPoint(safeMinX, safeMinZ, constants.DEBUG_LINE_HEIGHT + 0.04),
		worldDebugPoint(safeMaxX, safeMinZ, constants.DEBUG_LINE_HEIGHT + 0.04),
		worldDebugPoint(safeMaxX, safeMaxZ, constants.DEBUG_LINE_HEIGHT + 0.04),
		worldDebugPoint(safeMinX, safeMaxZ, constants.DEBUG_LINE_HEIGHT + 0.04),
		worldDebugPoint(safeMinX, safeMinZ, constants.DEBUG_LINE_HEIGHT + 0.04),
	}, 0.52, 0.76, 1.0, 0.82)

	drawLineStrip({
		worldDebugPoint(centerX, minZ),
		worldDebugPoint(centerX, maxZ),
	}, 0.34, 0.90, 1.0, 0.72)

	drawLineStrip({
		worldDebugPoint(constants.HEAD_STRING_X, minZ),
		worldDebugPoint(constants.HEAD_STRING_X, maxZ),
	}, 1.0, 0.88, 0.32, 0.88)

	for i = 1, #constants.pocketCenters do
		local pocket = constants.pocketCenters[i]
		drawPocketSphere(pocket, 0.98, 0.26, 0.26, 0.72)
	end

	local balls = snapshot.balls
	if type(balls) == "table" then
		for i = 1, #balls do
			local ball = balls[i]
			if ball and ball.active then
				local collisionY = constants.BALL_HEIGHT + 0.01
				local colorR = 0.92
				local colorG = 0.92
				local colorB = 0.92
				if ball.id == 0 then
					colorR = 1.0
					colorG = 1.0
					colorB = 1.0
				elseif ball.id == 8 then
					colorR = 0.18
					colorG = 0.18
					colorB = 0.18
				else
					colorR = 1.0
					colorG = 0.76
					colorB = 0.22
				end

				-- Ball collision shape lives on the ball plane; table/aim debug stays higher.
				drawCircleXZ(ball.x, collisionY, ball.z, constants.BALL_RADIUS, 18, colorR, colorG, colorB, 0.90)
				drawCircleXY(ball.x, collisionY, ball.z, constants.BALL_RADIUS, 14, colorR, colorG, colorB, 0.68)
				drawCircleYZ(ball.x, collisionY, ball.z, constants.BALL_RADIUS, 14, colorR, colorG, colorB, 0.68)
				drawCross(ball.x, ball.z, ball.id == 0 and 0.06 or 0.05, collisionY + 0.015, colorR, colorG, colorB, 0.92)
			end
		end
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
			0.18
		)
		renderer:drawDebugWireBox3D(
			worldDebugPoint(zoneCenterX, 0.0, constants.DEBUG_ZONE_HEIGHT),
			constants.TABLE_ROT,
			math.max(zoneHalfX, 0.02),
			constants.DEBUG_ZONE_THICKNESS,
			math.max(zoneHalfZ, 0.02),
			0.42,
			0.74,
			1.0,
			0.95
		)
	end

	local cueBall = state.getCueBall(context, snapshot)
	if not cueBall or not cueBall.active or snapshot.moving == true or snapshot.winner ~= nil then
		if cueBall and cueBall.active then
			drawCross(cueBall.x, cueBall.z, 0.10, constants.DEBUG_LINE_HEIGHT + 0.02, 1.0, 1.0, 1.0, 0.90)
		end
		return
	end

	local aim = tonumber(snapshot.cueAim) or 0.0
	local power = tonumber(snapshot.shotPower) or constants.MIN_SHOT_POWER
	local dirX = math.cos(aim)
	local dirZ = math.sin(aim)
	local posX = cueBall.x
	local posZ = cueBall.z
	local remaining = (math.max(constants.MIN_SHOT_POWER, power) * constants.SHOT_POWER_SCALE) * 26.0

	local predictionPoints = {
		worldDebugPoint(posX, posZ),
	}
	local bouncePoints = {}

	drawArrow(posX, posZ, dirX, dirZ, 0.95, 0.14, constants.DEBUG_LINE_HEIGHT + 0.07, 1.0, 0.92, 0.30, 0.95)

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
		table.insert(predictionPoints, worldDebugPoint(nextX, nextZ))

		local hitX = math.abs(hitDistance - tx) < 0.001
		local hitZ = math.abs(hitDistance - tz) < 0.001
		posX = math.clamp(nextX, minX, maxX)
		posZ = math.clamp(nextZ, minZ, maxZ)
		remaining = remaining - hitDistance
		if hitX or hitZ then
			table.insert(bouncePoints, { x = posX, z = posZ })
		end

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

	drawLineStrip(predictionPoints, 1.0, 0.92, 0.34, 0.95)
	drawCross(cueBall.x, cueBall.z, 0.10, constants.DEBUG_LINE_HEIGHT + 0.02, 1.0, 1.0, 1.0, 0.90)
	drawCross(posX, posZ, 0.08, constants.DEBUG_LINE_HEIGHT + 0.02, 1.0, 0.92, 0.34, 0.95)
	for i = 1, #bouncePoints do
		local bounce = bouncePoints[i]
		drawCross(bounce.x, bounce.z, 0.07, constants.DEBUG_LINE_HEIGHT + 0.04, 1.0, 0.46, 0.18, 0.95)
	end
end

function render.updateCamera(context, state)
	if not state.shouldUseTableCamera(context) or not client or not client.camera then
		state.restoreCamera(context)
		return
	end

	state.captureCamera(context)
	local snapshot = state.getRenderSnapshot(context) or context.snapshot or {}
	local cueBall = state.getCueBall(context, snapshot)
	local focusX = constants.TABLE_CENTER_X
	local focusZ = 0.0

	if cueBall and cueBall.active then
		focusX = cueBall.x
		focusZ = cueBall.z
	end

	local cueAim = tonumber(snapshot.cueAim) or 0.0
	local followDistance = 1.55
	local localPos = Vector(
		focusX - (math.cos(cueAim) * followDistance),
		1.95,
		focusZ - (math.sin(cueAim) * followDistance)
	)
	local cameraPos = constants.TABLE_POS + (localPos * constants.TABLE_ROT)
	local cameraTarget = constants.localToWorld(focusX, focusZ)

	client.camera.pos:set(cameraPos)
	client.camera.rot:set(getRotMatrixLookingAt(cameraPos, cameraTarget))
	client.camera.fov = constants.CAMERA_FOV
end

function render.renderFrame(context, state)
	state.ensureModelsLoaded(context)

	local snapshot = state.getRenderSnapshot(context)
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
				local animation = state.getBallAnimation(context, ball.id)
				local y = constants.BALL_HEIGHT
				if animation and animation.kind == "spawn" then
					local progress = animationProgress(context, animation)
					y = y + ((1 - easeOutCubic(progress)) * constants.BALL_PLACE_HEIGHT)
				end

				renderBallModel(context.loadedModelIds[ball.modelName], ball.x, ball.z, y)
			end
		end
	end

	local animations = state.getBallAnimations(context)
	for _, animation in pairs(animations) do
		if animation.kind == "despawn" then
			local progress = animationProgress(context, animation)
			local eased = easeInCubic(progress)
			local x = lerp(animation.x, animation.targetX or animation.x, eased)
			local z = lerp(animation.z, animation.targetZ or animation.z, eased)
			local y = constants.BALL_HEIGHT - (eased * constants.BALL_SINK_DEPTH)
			renderBallModel(context.loadedModelIds[animation.modelName], x, z, y)
		end
	end

	if snapshot.winner == nil and snapshot.moving ~= true then
		local cueModelId = context.loadedModelIds.cue
		local cueBall = state.getCueBall(context, snapshot)
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

function render.drawDebug(context, state)
	drawTableDebug(context, state)
end

function render.drawUI(context, state)
	local hudMode = state.getHudMode(context)
	if hudMode == "hidden" then
		return
	end

	local snapshot = state.getRenderSnapshot(context) or context.snapshot
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
	local controlsText = "J Join  L Leave  P Ready  Arrows Aim/Power  Space Shoot  R Rerack  WASD Cue"
	local practiceText = " "
	local seatOneName = "Open"
	local seatTwoName = "Open"
	local seatOneReady = "Idle"
	local seatTwoReady = "Idle"
	local cameraText = constants.CAMERA_MODE_LABELS[state.getCameraMode(context)] or "Camera"
	local hudText = constants.HUD_MODE_LABELS[hudMode] or "HUD"
	local staleText = " "

	if type(snapshot) == "table" then
		local seatOne = state.getSeatInfo(context, 1, snapshot)
		local seatTwo = state.getSeatInfo(context, 2, snapshot)
		local localSeat = state.getLocalSeat(context, snapshot)
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
		if context.lastSnapshotTick >= 0 then
			local age = context.localTicks - context.lastSnapshotTick
			if age > math.floor(constants.RESUBSCRIBE_TICKS * 0.5) then
				staleText = "State stale: waiting for fresh server snapshot."
			end
		end
	end

	if hudMode == "compact" then
		local compactWidth = width - (margin * 2)
		local compactHeight = 78
		local compactY = height - margin - compactHeight
		drawPanel(margin, compactY, compactWidth, compactHeight, 0.05, 0.10, 0.10, 0.76)
		drawLabel("POOL 8-BALL (BETA)", margin + 16, compactY + 12, 24, 0.88, 0.98, 0.94, 1.0)
		drawLabel(phaseText .. "  |  " .. turnText, margin + 16, compactY + 40, 16, 0.95, 0.95, 0.95, 1.0)
		drawLabel(seatText .. "  |  " .. cameraText .. "  |  " .. hudText, margin + 330, compactY + 12, 16, 0.72, 0.89, 1.0, 1.0)
		drawLabel(statusText, margin + 330, compactY + 40, 16, 0.80, 0.92, 0.84, 1.0)
		return
	end

	drawPanel(contentLeft, contentTop, leftWidth, topHeight, 0.05, 0.12, 0.11, 0.78)
	drawPanel(contentLeft, contentTop + topHeight + margin, leftWidth, contentBottom - contentTop - topHeight - bottomHeight - margin * 2, 0.04, 0.08, 0.08, 0.44)
	drawPanel(contentLeft, contentBottom - bottomHeight, leftWidth, bottomHeight, 0.08, 0.12, 0.10, 0.78)
	drawPanel(contentLeft + leftWidth + margin, contentTop, rightWidth, contentBottom - contentTop, 0.06, 0.07, 0.10, 0.82)

	drawLabel("POOL 8-BALL (BETA)", contentLeft + 18, contentTop + 18, 30, 0.88, 0.98, 0.94, 1.0)
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
	drawLabel(hudText, contentLeft + 238, contentBottom - bottomHeight + 18, 18, 0.74, 0.89, 1.0, 1.0)
	drawLabel("J Join  L Leave  P Ready  Arrows Aim/Power  Space Shoot  R Rerack  WASD Cue  N HUD",
		contentLeft + 18,
		contentBottom - bottomHeight + 44,
		15,
		0.82,
		0.84,
		0.87,
		1.0)
end

return render
