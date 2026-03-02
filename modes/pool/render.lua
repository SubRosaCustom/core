local plugin = ...
local constants = plugin:require("constants")

local render = {}

function render.renderFrame(context, state)
	state.ensureModelsLoaded(context)

	local tableModel = context.loadedModelIds.table
	if type(tableModel) == "number" then
		renderer.renderCMO(tableModel, constants.TABLE_POS, constants.TABLE_ROT)
	end

	for _, ball in ipairs(context.balls) do
		if ball.active then
			local modelId = context.loadedModelIds[ball.modelName]
			if type(modelId) == "number" then
				renderer.renderCMO(modelId, constants.localToWorld(ball.x, ball.z), constants.TABLE_ROT)
			end
		end
	end

	if context.winner == nil and not state.ballsAreMoving(context) then
		local cueModelId = context.loadedModelIds.cue
		local cueBall = state.getCueBall(context)
		if type(cueModelId) == "number" and cueBall and cueBall.active then
			local dirX = math.cos(context.cueAim)
			local dirZ = math.sin(context.cueAim)
			local cueDistance = 0.78 + ((1.0 - context.shotPower) * 0.25)
			local cueX = cueBall.x - (dirX * cueDistance)
			local cueZ = cueBall.z - (dirZ * cueDistance)
			local cueRot = yawToRotMatrix(context.cueAim + (math.pi * 0.5))
			renderer.renderCMO(cueModelId, constants.localToWorld(cueX, cueZ), cueRot)
		end
	end
end

function render.drawUI(context)
	local x = plugin.config.overlayX
	local y = plugin.config.overlayY
	local scale = plugin.config.textScale

	local heading = "Pool 8-Ball"
	local turnText = context.winner and ("Winner: Player " .. context.winner) or ("Turn: Player " .. context.turnPlayer)
	local assignText = "P1: " .. constants.formatGroup(context.assignments[1]) .. "  P2: " .. constants.formatGroup(context.assignments[2])
	local aimDeg = (math.deg(context.cueAim) % 360 + 360) % 360
	local shotText = string.format("Aim %.1f  Power %.0f%%", aimDeg, context.shotPower * 100)
	local handText = context.ballInHand and "Ball in hand: use WASD to place cue ball." or " "
	local controlsText = "Arrows aim/power | Space shoot | R rerack"

	renderer.drawText(heading, x, y, scale, 0.90, 0.95, 1.00, 1.00, 0x20)
	y = y + scale
	renderer.drawText(turnText, x, y, scale, 1.00, 1.00, 1.00, 1.00, 0x20)
	y = y + scale
	renderer.drawText(assignText, x, y, scale, 0.95, 0.95, 0.95, 1.00, 0x20)
	y = y + scale
	renderer.drawText(shotText, x, y, scale, 0.95, 0.95, 0.95, 1.00, 0x20)
	y = y + scale
	renderer.drawText(context.statusLine, x, y, scale, 1.00, 0.85, 0.35, 1.00, 0x20)
	y = y + scale
	renderer.drawText(handText, x, y, scale, 0.75, 1.00, 0.75, 1.00, 0x20)
	y = y + scale
	renderer.drawText(controlsText, x, y, scale, 0.80, 0.80, 0.80, 1.00, 0x20)
end

return render
