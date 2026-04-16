local plugin = ...
local constants = plugin:require("constants")

local input_mode = {}

local function bind_toggle(name, scancode, callback)
	input:bind(name, scancode, function(_, toggled)
		if toggled then
			callback()
		end
	end, true, 5)
end

function input_mode.bind(context, state)
	bind_toggle(constants.binds.select_prev, plugin.config.select_prev_scancode, function()
		state.select_delta(context, -1)
	end)

	bind_toggle(constants.binds.select_next, plugin.config.select_next_scancode, function()
		state.select_delta(context, 1)
	end)

	bind_toggle(constants.binds.select_up, plugin.config.select_up_scancode, function()
		state.select_delta(context, -1)
	end)

	bind_toggle(constants.binds.select_down, plugin.config.select_down_scancode, function()
		state.select_delta(context, 1)
	end)

	bind_toggle(constants.binds.interact, plugin.config.interact_scancode, function()
		state.interact(context)
	end)

	bind_toggle(constants.binds.confirm, plugin.config.confirm_scancode, function()
		state.mark_selected(context, constants.status_pass)
	end)

	bind_toggle(constants.binds.reject, plugin.config.reject_scancode, function()
		state.mark_selected(context, constants.status_fail)
	end)

	bind_toggle(constants.binds.request_state, plugin.config.request_state_scancode, function()
		state.request_state(context, "keybind")
	end)
end

function input_mode.unbind()
	for _, bind_name in pairs(constants.binds) do
		input:removeBind(bind_name)
	end
end

return input_mode
