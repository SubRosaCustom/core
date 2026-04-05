local plugin = ...
local constants = plugin:require("constants")

local poolInput = {}

local function on_continuous_input(keyState)
	return keyState == input.state.begin or keyState == input.state.current
end

local function send_step_command(context, state, action, ...)
	if not context.snapshot then
		state.requestState(context, false)
		return
	end

	state.sendCommand(context, action, ...)
end

local function ensure_snapshot(context, state)
	if context.snapshot then
		return true
	end

	state.requestState(context, false)
	return false
end

function poolInput.bind(context, state)
	local binds = constants.BINDS

	input:bind(binds.aimLeft, plugin.config.aimLeftScancode, function(_, keyState)
		if on_continuous_input(keyState) and ensure_snapshot(context, state) then
			send_step_command(context, state, "adjust_aim", -constants.AIM_STEP)
		end
	end, false, 5)

	input:bind(binds.aimRight, plugin.config.aimRightScancode, function(_, keyState)
		if on_continuous_input(keyState) and ensure_snapshot(context, state) then
			send_step_command(context, state, "adjust_aim", constants.AIM_STEP)
		end
	end, false, 5)

	input:bind(binds.powerUp, plugin.config.powerUpScancode, function(_, keyState)
		if on_continuous_input(keyState) and ensure_snapshot(context, state) then
			send_step_command(context, state, "adjust_power", constants.POWER_STEP)
		end
	end, false, 5)

	input:bind(binds.powerDown, plugin.config.powerDownScancode, function(_, keyState)
		if on_continuous_input(keyState) and ensure_snapshot(context, state) then
			send_step_command(context, state, "adjust_power", -constants.POWER_STEP)
		end
	end, false, 5)

	input:bind(binds.moveCueLeft, plugin.config.moveCueLeftScancode, function(_, keyState)
		if on_continuous_input(keyState) and ensure_snapshot(context, state) then
			state.moveCueByCamera(context, 0, -1)
		end
	end, false, 5)

	input:bind(binds.moveCueRight, plugin.config.moveCueRightScancode, function(_, keyState)
		if on_continuous_input(keyState) and ensure_snapshot(context, state) then
			state.moveCueByCamera(context, 0, 1)
		end
	end, false, 5)

	input:bind(binds.moveCueUp, plugin.config.moveCueUpScancode, function(_, keyState)
		if on_continuous_input(keyState) and ensure_snapshot(context, state) then
			state.moveCueByCamera(context, 1, 0)
		end
	end, false, 5)

	input:bind(binds.moveCueDown, plugin.config.moveCueDownScancode, function(_, keyState)
		if on_continuous_input(keyState) and ensure_snapshot(context, state) then
			state.moveCueByCamera(context, -1, 0)
		end
	end, false, 5)

	input:bind(binds.shoot, plugin.config.shootScancode, function(_, toggled)
		if toggled and ensure_snapshot(context, state) then
			state.shoot(context)
		end
	end, true, 5)

	input:bind(binds.rerack, plugin.config.rerackScancode, function(_, toggled)
		if toggled then
			send_step_command(context, state, "rerack")
		end
	end, true, 5)

	input:bind(binds.join, plugin.config.joinScancode, function(_, toggled)
		if toggled then
			send_step_command(context, state, "join")
		end
	end, true, 5)

	input:bind(binds.leave, plugin.config.leaveScancode, function(_, toggled)
		if toggled then
			send_step_command(context, state, "leave")
		end
	end, true, 5)

	input:bind(binds.ready, plugin.config.readyScancode, function(_, toggled)
		if toggled then
			send_step_command(context, state, "ready")
		end
	end, true, 5)

	input:bind(binds.hudMode, plugin.config.hudModeScancode, function(_, toggled)
		if toggled then
			state.cycleHudMode(context)
		end
	end, true, 5)

	input:bind(binds.debugRender, plugin.config.debugRenderScancode, function(_, toggled)
		if toggled then
			state.toggleDebugRender(context)
		end
	end, true, 5)
end

function poolInput.unbind()
	for _, bindName in pairs(constants.BINDS) do
		input:removeBind(bindName)
	end
end

return poolInput
