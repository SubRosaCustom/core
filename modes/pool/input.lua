local plugin = ...
local constants = plugin:require("constants")

local poolInput = {}

local function onContinuousInput(keyState)
	return keyState == input.state.begin or keyState == input.state.current
end

local function sendStepCommand(context, state, action, payload)
	if not context.snapshot then
		state.requestState(context, false)
		return
	end

	state.sendCommand(context, action, payload)
end

function poolInput.bind(context, state)
	local binds = constants.BINDS

	input:bind(binds.aimLeft, plugin.config.aimLeftScancode, function(_, keyState)
		if onContinuousInput(keyState) then
			sendStepCommand(context, state, "adjust_aim", {
				delta = -constants.AIM_STEP,
			})
		end
	end, false, 5)

	input:bind(binds.aimRight, plugin.config.aimRightScancode, function(_, keyState)
		if onContinuousInput(keyState) then
			sendStepCommand(context, state, "adjust_aim", {
				delta = constants.AIM_STEP,
			})
		end
	end, false, 5)

	input:bind(binds.powerUp, plugin.config.powerUpScancode, function(_, keyState)
		if onContinuousInput(keyState) then
			sendStepCommand(context, state, "adjust_power", {
				delta = constants.POWER_STEP,
			})
		end
	end, false, 5)

	input:bind(binds.powerDown, plugin.config.powerDownScancode, function(_, keyState)
		if onContinuousInput(keyState) then
			sendStepCommand(context, state, "adjust_power", {
				delta = -constants.POWER_STEP,
			})
		end
	end, false, 5)

	input:bind(binds.moveCueLeft, plugin.config.moveCueLeftScancode, function(_, keyState)
		if onContinuousInput(keyState) then
			sendStepCommand(context, state, "move_cue", {
				dx = -constants.CUE_MOVE_STEP,
				dz = 0,
			})
		end
	end, false, 5)

	input:bind(binds.moveCueRight, plugin.config.moveCueRightScancode, function(_, keyState)
		if onContinuousInput(keyState) then
			sendStepCommand(context, state, "move_cue", {
				dx = constants.CUE_MOVE_STEP,
				dz = 0,
			})
		end
	end, false, 5)

	input:bind(binds.moveCueUp, plugin.config.moveCueUpScancode, function(_, keyState)
		if onContinuousInput(keyState) then
			sendStepCommand(context, state, "move_cue", {
				dx = 0,
				dz = -constants.CUE_MOVE_STEP,
			})
		end
	end, false, 5)

	input:bind(binds.moveCueDown, plugin.config.moveCueDownScancode, function(_, keyState)
		if onContinuousInput(keyState) then
			sendStepCommand(context, state, "move_cue", {
				dx = 0,
				dz = constants.CUE_MOVE_STEP,
			})
		end
	end, false, 5)

	input:bind(binds.shoot, plugin.config.shootScancode, function(_, toggled)
		if toggled then
			sendStepCommand(context, state, "shoot")
		end
	end, true, 5)

	input:bind(binds.rerack, plugin.config.rerackScancode, function(_, toggled)
		if toggled then
			sendStepCommand(context, state, "rerack")
		end
	end, true, 5)

	input:bind(binds.join, plugin.config.joinScancode, function(_, toggled)
		if toggled then
			sendStepCommand(context, state, "join")
		end
	end, true, 5)

	input:bind(binds.leave, plugin.config.leaveScancode, function(_, toggled)
		if toggled then
			sendStepCommand(context, state, "leave")
		end
	end, true, 5)

	input:bind(binds.ready, plugin.config.readyScancode, function(_, toggled)
		if toggled then
			sendStepCommand(context, state, "ready")
		end
	end, true, 5)
end

function poolInput.unbind()
	for _, bindName in pairs(constants.BINDS) do
		input:removeBind(bindName)
	end
end

return poolInput
