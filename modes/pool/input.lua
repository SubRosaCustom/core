local plugin = ...
local constants = plugin:require("constants")

local poolInput = {}

local function onContinuousInput(keyState)
	return keyState == input.state.begin or keyState == input.state.current
end

function poolInput.bind(context, state)
	local binds = constants.BINDS

	input:bind(binds.aimLeft, plugin.config.aimLeftScancode, function(_, keyState)
		if onContinuousInput(keyState) and not context.winner and not state.ballsAreMoving(context) then
			context.cueAim = constants.wrapAngle(context.cueAim - constants.AIM_STEP)
		end
	end, false, 5)

	input:bind(binds.aimRight, plugin.config.aimRightScancode, function(_, keyState)
		if onContinuousInput(keyState) and not context.winner and not state.ballsAreMoving(context) then
			context.cueAim = constants.wrapAngle(context.cueAim + constants.AIM_STEP)
		end
	end, false, 5)

	input:bind(binds.powerUp, plugin.config.powerUpScancode, function(_, keyState)
		if onContinuousInput(keyState) and not context.winner and not state.ballsAreMoving(context) then
			context.shotPower = math.clamp(context.shotPower + constants.POWER_STEP, constants.MIN_SHOT_POWER, constants.MAX_SHOT_POWER)
		end
	end, false, 5)

	input:bind(binds.powerDown, plugin.config.powerDownScancode, function(_, keyState)
		if onContinuousInput(keyState) and not context.winner and not state.ballsAreMoving(context) then
			context.shotPower = math.clamp(context.shotPower - constants.POWER_STEP, constants.MIN_SHOT_POWER, constants.MAX_SHOT_POWER)
		end
	end, false, 5)

	input:bind(binds.moveCueLeft, plugin.config.moveCueLeftScancode, function(_, keyState)
		if onContinuousInput(keyState) then
			state.tryMoveCueBall(context, -constants.CUE_MOVE_STEP, 0)
		end
	end, false, 5)

	input:bind(binds.moveCueRight, plugin.config.moveCueRightScancode, function(_, keyState)
		if onContinuousInput(keyState) then
			state.tryMoveCueBall(context, constants.CUE_MOVE_STEP, 0)
		end
	end, false, 5)

	input:bind(binds.moveCueUp, plugin.config.moveCueUpScancode, function(_, keyState)
		if onContinuousInput(keyState) then
			state.tryMoveCueBall(context, 0, -constants.CUE_MOVE_STEP)
		end
	end, false, 5)

	input:bind(binds.moveCueDown, plugin.config.moveCueDownScancode, function(_, keyState)
		if onContinuousInput(keyState) then
			state.tryMoveCueBall(context, 0, constants.CUE_MOVE_STEP)
		end
	end, false, 5)

	input:bind(binds.shoot, plugin.config.shootScancode, function(_, toggled)
		if toggled then
			state.shootCueBall(context)
		end
	end, true, 5)

	input:bind(binds.rerack, plugin.config.rerackScancode, function(_, toggled)
		if toggled then
			state.resetMatch(context)
		end
	end, true, 5)
end

function poolInput.unbind()
	for _, bindName in pairs(constants.BINDS) do
		input:removeBind(bindName)
	end
end

return poolInput
