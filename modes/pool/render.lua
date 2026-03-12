local plugin = ...
local constants = plugin:require("constants")

local render = {}

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

function render.drawUI(context, state)
	local x = plugin.config.overlayX
	local y = plugin.config.overlayY
	local scale = plugin.config.textScale

	local snapshot = context.snapshot
	local heading = "Pool 8-Ball"
	local turnText = "Turn: -"
	local assignText = "P1: -  P2: -"
	local shotText = "Aim -  Power -"
	local statusText = context.noticeLine
	local handText = " "
	local seatText = "Seat: Spectator"
	local scoreText = "Score: P1 0 - 0 P2"
	local phaseText = "Phase: Waiting"
	local controlsText = "J join | L leave | Enter ready | Arrows aim/power | Space shoot | R rerack | WASD move cue ball"

	if type(snapshot) == "table" then
		if snapshot.winner then
			turnText = "Winner: Player " .. tostring(snapshot.winner)
		else
			turnText = "Turn: Player " .. tostring(snapshot.turnPlayer or "?")
		end

		assignText = "P1: "
			.. constants.formatGroup(snapshot.assignments and snapshot.assignments[1] or nil)
			.. "  P2: "
			.. constants.formatGroup(snapshot.assignments and snapshot.assignments[2] or nil)

		local cueAim = tonumber(snapshot.cueAim) or 0
		local shotPower = tonumber(snapshot.shotPower) or 0
		local aimDeg = (math.deg(cueAim) % 360 + 360) % 360
		shotText = string.format("Aim %.1f  Power %.0f%%", aimDeg, shotPower * 100)
		statusText = tostring(snapshot.statusLine or context.noticeLine)
		handText = snapshot.ballInHand and "Ball in hand: use WASD to place cue ball." or " "

		local localSeat = state.getLocalSeat(context)
		if localSeat then
			seatText = "Seat: Player "
				.. tostring(localSeat)
				.. " ("
				.. state.getSeatDisplay(snapshot, localSeat)
				.. ")"
		else
			seatText = "Seat: Spectator"
		end

		local seatOne = state.getSeatInfo(context, 1)
		local seatTwo = state.getSeatInfo(context, 2)
		local scoreOne = seatOne and tonumber(seatOne.wins) or 0
		local scoreTwo = seatTwo and tonumber(seatTwo.wins) or 0
		scoreText = string.format("Score: P1 %d - %d P2", scoreOne or 0, scoreTwo or 0)

		local function readyText(info)
			if not info then
				return "-"
			end
			return info.ready and "Ready" or "Not Ready"
		end

		phaseText = "Phase: "
			.. tostring(snapshot.phase or "waiting")
			.. " | P1 "
			.. readyText(seatOne)
			.. " | P2 "
			.. readyText(seatTwo)
	end

	renderer:drawText(heading, x, y, scale, 0.90, 0.95, 1.00, 1.00, 0x20)
	y = y + scale
	renderer:drawText(turnText, x, y, scale, 1.00, 1.00, 1.00, 1.00, 0x20)
	y = y + scale
	renderer:drawText(assignText, x, y, scale, 0.95, 0.95, 0.95, 1.00, 0x20)
	y = y + scale
	renderer:drawText(seatText, x, y, scale, 0.75, 0.95, 1.00, 1.00, 0x20)
	y = y + scale
	renderer:drawText(scoreText, x, y, scale, 0.90, 0.90, 0.70, 1.00, 0x20)
	y = y + scale
	renderer:drawText(phaseText, x, y, scale, 0.75, 0.95, 0.75, 1.00, 0x20)
	y = y + scale
	renderer:drawText(shotText, x, y, scale, 0.95, 0.95, 0.95, 1.00, 0x20)
	y = y + scale
	renderer:drawText(statusText, x, y, scale, 1.00, 0.85, 0.35, 1.00, 0x20)
	y = y + scale
	renderer:drawText(handText, x, y, scale, 0.75, 1.00, 0.75, 1.00, 0x20)
	y = y + scale
	renderer:drawText(controlsText, x, y, scale, 0.80, 0.80, 0.80, 1.00, 0x20)
end

return render
