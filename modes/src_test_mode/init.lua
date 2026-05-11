---@type Plugin
local mode = ...
mode.name = "SRC Test Mode"
mode.author = "Sub Rosa Custom"
mode.description = "Side-by-side SRC test lane for mode, sync, rendering, sound, and checklist validation."

local constants = mode:require("constants")
local state = mode:require("state")
local input_mode = mode:require("input")
local render = mode:require("render")

mode.defaultConfig = constants.default_config

local runtime = _G.__srcc_src_test_mode_client_runtime or {
	context = nil,
}
_G.__srcc_src_test_mode_client_runtime = runtime

local function active_context()
	if not mode.isEnabled then
		return nil
	end

	return runtime.context
end

onServerEvent(constants.events.state, function(
	server_tick,
	persistent_mode,
	sync_generation,
	script_count,
	asset_count,
	client_count,
	mode_script_count,
	non_active_mode_script_count,
	loaded_level
)
	local context = active_context()
	if not context then
		return
	end

	state.apply_server_state(
		context,
		server_tick,
		persistent_mode,
		sync_generation,
		script_count,
		asset_count,
		client_count,
		mode_script_count,
		non_active_mode_script_count,
		loaded_level
	)
end)

mode:addEnableHandler(function()
	local context = state.new_context()
	runtime.context = context
	input_mode.bind(context, state)
	state.install_blips(context)
	state.request_state(context, "enable")
end)

mode:addDisableHandler(function()
	local context = runtime.context
	if context then
		state.shutdown(context)
	end

	input_mode.unbind()
	state.remove_blips()
	runtime.context = nil
end)

mode:addHook("Logic", function()
	local context = active_context()
	if not context then
		return
	end

	state.logic_tick(context)
end)

mode:addHook("RenderFrame", function()
	local context = active_context()
	if not context then
		return
	end

	state.apply_cutscene_camera(context)
end)

mode:addHook("Draw3D", function()
	local context = active_context()
	if not context then
		return
	end

	render.draw_world(context)
end)

mode:addHook("DrawUI", function()
	local context = active_context()
	if not context then
		return
	end

	render.draw_ui(context)
end)
