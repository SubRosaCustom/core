local plugin = ...
local constants = plugin:require("constants")

local state = {}

local function push_log(context, text)
	context.log_lines[#context.log_lines + 1] = tostring(text)
	while #context.log_lines > 7 do
		table.remove(context.log_lines, 1)
	end
end

local function emit(event_name, ...)
	local ok = emitServerEvent(event_name, ...)
	if not ok then
		plugin:warn(string.format("failed to emit showcase event '%s'", tostring(event_name)))
	end
	return ok
end

local function sound_station_position()
	local station = constants.find_station("sound")
	if not station then
		return constants.origin
	end
	return constants.station_world_position(station)
end

local function set_server_state(
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
	context.server.server_tick = tonumber(server_tick) or 0
	context.server.persistent_mode = tostring(persistent_mode or "")
	context.server.sync_generation = tonumber(sync_generation) or 0
	context.server.script_count = tonumber(script_count) or 0
	context.server.asset_count = tonumber(asset_count) or 0
	context.server.client_count = tonumber(client_count) or 0
	context.server.mode_script_count = tonumber(mode_script_count) or 0
	context.server.non_active_mode_script_count = tonumber(non_active_mode_script_count) or 0
	context.server.loaded_level = tostring(loaded_level or "")
	context.last_server_state_tick = context.local_ticks
	context.server_state_received = true
end

local function request_state(context, reason)
	context.last_state_request_tick = context.local_ticks
	return emit(constants.events.request_state, context.local_ticks, tostring(reason or "manual"))
end

local function station_blip_name(station)
	return "showcase_station_" .. station.id
end

local function update_blips(context)
	for i = 1, #constants.stations do
		local station = constants.stations[i]
		local ground_position = constants.station_ground_position(station)
		local color_r = 0.30
		local color_g = 0.85
		local color_b = 1.00
		local shape = blips.shape.square

		if station.id == context.focused_station_id then
			color_r = 1.00
			color_g = 0.85
			color_b = 0.25
			shape = blips.shape.diamond
		end

		blips:update(station_blip_name(station), {
			worldX = ground_position.x,
			worldZ = ground_position.z,
			r = color_r,
			g = color_g,
			b = color_b,
			shape = shape,
		})
	end
end

local function ensure_texture_loaded(context)
	if context.ui_texture ~= nil then
		return
	end

	local ok, result = pcall(Texture.loadFromFile, "jellybean")
	if not ok then
		push_log(context, "texture load failed: " .. tostring(result))
		context.ui_texture = false
		return
	end

	if result and result.isValid then
		context.ui_texture = result
		push_log(context, "loaded jellybean texture")
	else
		context.ui_texture = false
		push_log(context, "texture load returned invalid handle")
	end
end

local function ensure_model_loaded(context)
	if context.model_id ~= nil then
		return
	end

	local ok, result = pcall(renderer.loadCMO, renderer, "custom_ball")
	if not ok then
		push_log(context, "model load failed: " .. tostring(result))
		context.model_id = false
		return
	end

	if type(result) == "number" and result >= 0 then
		context.model_id = result
		push_log(context, string.format("loaded custom_ball model id %d", result))
	else
		context.model_id = false
		push_log(context, "model load returned invalid id")
	end
end

local function ensure_sound_loaded(context)
	if context.sound_id ~= nil then
		return
	end

	local ok, result = pcall(sounds.loadSound, sounds, "fart.wav", 256.0)
	if not ok then
		push_log(context, "sound load failed: " .. tostring(result))
		context.sound_id = false
		return
	end

	if type(result) == "number" and result >= 0 then
		context.sound_id = result
		push_log(context, string.format("loaded fart.wav sound id %d", result))
	else
		context.sound_id = false
		push_log(context, "sound load returned invalid id")
	end
end

local function ensure_assets_loaded(context)
	ensure_texture_loaded(context)
	ensure_model_loaded(context)
	ensure_sound_loaded(context)
end

local function current_human_position()
	if client and client.human and client.human.pos then
		return client.human.pos
	end

	if client and client.camera and client.camera.pos then
		return client.camera.pos
	end

	return nil
end

local function update_focus_station(context)
	local human_position = current_human_position()
	local previous_station_id = context.focused_station_id
	local best_station_id = nil
	local best_distance_sq = math.huge

	if human_position then
		for i = 1, #constants.stations do
			local station = constants.stations[i]
			local station_position = constants.station_ground_position(station)
			local dx = human_position.x - station_position.x
			local dz = human_position.z - station_position.z
			local distance_sq = (dx * dx) + (dz * dz)
			if distance_sq <= (constants.station_focus_radius * constants.station_focus_radius)
				and distance_sq < best_distance_sq then
				best_distance_sq = distance_sq
				best_station_id = station.id
			end
		end
	end

	context.focused_station_id = best_station_id

	if previous_station_id ~= context.focused_station_id then
		if context.focused_station_id then
			local station = constants.find_station(context.focused_station_id)
			if station then
				push_log(context, string.format("entered %s", station.label))
			end
		end
		update_blips(context)
	end
end

local function stop_sound(context, reason)
	if type(context.sound_emitter_id) == "number" and context.sound_emitter_id >= 0 then
		pcall(sounds.stopSound, sounds, context.sound_emitter_id)
	end

	context.sound_emitter_id = -1
	context.sound_state = "stopped"
	context.sound_started_tick = nil
	context.sound_progress = 0.0
	if reason then
		push_log(context, reason)
	end
end

local function play_sound(context)
	if type(context.sound_id) ~= "number" or context.sound_id < 0 then
		push_log(context, "sound station unavailable: sound not loaded")
		return
	end

	local emitter_position = sound_station_position()
	local ok, emitter_id = pcall(
		sounds.playSound3D,
		sounds,
		context.sound_id,
		emitter_position,
		1.0,
		1.0
	)
	if not ok then
		push_log(context, "sound play failed: " .. tostring(emitter_id))
		return
	end

	if type(emitter_id) == "number" and emitter_id >= 0 then
		context.sound_emitter_id = emitter_id
		context.sound_state = "playing"
		context.sound_started_tick = context.local_ticks
		context.sound_progress = 0.0
		push_log(context, string.format("sound playing on emitter %d", emitter_id))
	else
		context.sound_emitter_id = -1
		context.sound_state = "ended"
		context.sound_started_tick = nil
		push_log(context, "sound play returned invalid emitter")
	end
end

function state.new_context()
	local manual_status = {}
	for i = 1, #constants.checklist do
		manual_status[constants.checklist[i].id] = constants.status_unknown
	end

	return {
		local_ticks = 0,
		selected_item_index = 1,
		manual_status = manual_status,
		focused_station_id = nil,
		last_state_request_tick = -1,
		last_server_state_tick = -1,
		server_state_received = false,
		server = {
			server_tick = 0,
			persistent_mode = "",
			sync_generation = 0,
			script_count = 0,
			asset_count = 0,
			client_count = 0,
			mode_script_count = 0,
			non_active_mode_script_count = 0,
			loaded_level = "",
		},
		ui_texture = nil,
		model_id = nil,
		sound_id = nil,
		sound_emitter_id = -1,
		sound_state = "stopped",
		sound_started_tick = nil,
		sound_progress = 0.0,
		rotation_angle = 0.0,
		rotation_moved = false,
		frame_metrics = {
			ui_texture_drawn = false,
			world_texture_drawn = false,
			rotating_texture_drawn = false,
			model_drawn = false,
			debug_drawn = false,
		},
		log_lines = {},
	}
end

function state.install_blips(context)
	for i = 1, #constants.stations do
		local station = constants.stations[i]
		local ground_position = constants.station_ground_position(station)
		blips:add(station_blip_name(station), {
			worldX = ground_position.x,
			worldZ = ground_position.z,
			r = 0.30,
			g = 0.85,
			b = 1.00,
			a = 1.00,
			size = 3.8,
			shape = blips.shape.square,
			clamp = false,
		})
	end

	update_blips(context)
end

function state.remove_blips()
	for i = 1, #constants.stations do
		blips:remove(station_blip_name(constants.stations[i]))
	end
end

function state.request_state(context, reason)
	return request_state(context, reason)
end

function state.apply_server_state(
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
	set_server_state(
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
end

function state.logic_tick(context)
	context.local_ticks = context.local_ticks + 1
	context.rotation_angle = context.rotation_angle + 0.03
	if context.rotation_angle > (math.pi * 2.0) then
		context.rotation_angle = context.rotation_angle - (math.pi * 2.0)
	end
	context.rotation_moved = true

	context.frame_metrics.ui_texture_drawn = false
	context.frame_metrics.world_texture_drawn = false
	context.frame_metrics.rotating_texture_drawn = false
	context.frame_metrics.model_drawn = false
	context.frame_metrics.debug_drawn = false

	ensure_assets_loaded(context)
	update_focus_station(context)

	if context.local_ticks == 1 or context.local_ticks % constants.state_request_interval == 0 then
		request_state(context, "logic")
	end

	if context.server_state_received and context.last_server_state_tick >= 0 then
		if (context.local_ticks - context.last_server_state_tick) > constants.state_timeout_ticks then
			context.server_state_received = false
			push_log(context, "server state timed out; requesting refresh")
			request_state(context, "timeout")
		end
	end

	if context.sound_state == "playing" and context.sound_started_tick ~= nil then
		local elapsed = context.local_ticks - context.sound_started_tick
		local progress = elapsed / constants.sound_duration_ticks
		if progress >= 1.0 then
			context.sound_progress = 1.0
			context.sound_state = "ended"
			context.sound_emitter_id = -1
			context.sound_started_tick = nil
			push_log(context, "sound playback window ended")
		else
			context.sound_progress = progress
		end
	elseif context.sound_state ~= "playing" then
		if context.sound_state == "ended" then
			context.sound_progress = 1.0
		else
			context.sound_progress = 0.0
		end
	end
end

function state.interact(context)
	local station = nil
	if context.focused_station_id then
		station = constants.find_station(context.focused_station_id)
	end

	if not station then
		push_log(context, "no station focused")
		return
	end

	local checklist_index = constants.find_checklist_index(station.primary_item_id)
	if checklist_index then
		context.selected_item_index = checklist_index
	end

	if station.id == "sound" then
		if context.sound_state == "playing" then
			stop_sound(context, "sound stopped by E")
		else
			play_sound(context)
		end
	elseif station.id == "sync" then
		request_state(context, "interact")
		push_log(context, "requested fresh sync diagnostics")
	else
		push_log(context, string.format("inspecting %s", station.label))
	end
end

function state.select_delta(context, delta)
	context.selected_item_index = constants.wrap_index(
		context.selected_item_index + delta,
		#constants.checklist
	)
end

function state.mark_selected(context, status)
	local item = constants.checklist[context.selected_item_index]
	if not item then
		return
	end

	context.manual_status[item.id] = status
	local verb = status == constants.status_pass and "PASS" or "FAIL"
	push_log(context, string.format("%s -> %s", item.label, verb))
end

function state.manual_status_for_item(context, item_id)
	return context.manual_status[item_id] or constants.status_unknown
end

function state.item_note(context, item_id)
	if item_id == "active_mode_showcase" then
		return string.format(
			"mode=%s level=%s",
			context.server.persistent_mode ~= "" and context.server.persistent_mode or "<none>",
			context.server.loaded_level ~= "" and context.server.loaded_level or "<none>"
		)
	end

	if item_id == "non_active_modes_still_sync" then
		return string.format(
			"mode_scripts=%d non_active=%d",
			context.server.mode_script_count,
			context.server.non_active_mode_script_count
		)
	end

	if item_id == "ui_texture_visible" then
		return string.format("texture_loaded=%s", tostring(context.ui_texture and context.ui_texture ~= false))
	end

	if item_id == "world_texture_visible" then
		return string.format("drawn=%s", tostring(context.frame_metrics.world_texture_drawn))
	end

	if item_id == "rotating_texture_spinning" then
		return string.format(
			"drawn=%s angle=%.2f",
			tostring(context.frame_metrics.rotating_texture_drawn),
			context.rotation_angle
		)
	end

	if item_id == "sound_plays" then
		return string.format("state=%s emitter=%s", context.sound_state, tostring(context.sound_emitter_id))
	end

	if item_id == "sound_stops_or_replays" then
		return string.format("state=%s progress=%d%%", context.sound_state, math.floor(context.sound_progress * 100.0))
	end

	if item_id == "sound_progress_moves" then
		return string.format("%d%%", math.floor(context.sound_progress * 100.0))
	end

	if item_id == "model_visible" then
		return string.format("model_id=%s", tostring(context.model_id))
	end

	if item_id == "debug_boxes_visible" then
		return string.format("drawn=%s", tostring(context.frame_metrics.debug_drawn))
	end

	return ""
end

function state.status_color(status)
	if status == constants.status_pass then
		return 0.35, 0.95, 0.35, 1.0
	end

	if status == constants.status_fail then
		return 1.0, 0.35, 0.35, 1.0
	end

	return 0.85, 0.85, 0.85, 1.0
end

function state.focus_prompt(context)
	if context.focused_station_id == "sound" then
		if context.sound_state == "playing" then
			return "Press E to stop sound"
		end
		return "Press E to play sound"
	end

	if context.focused_station_id == "sync" then
		return "Press E to refresh sync diagnostics"
	end

	if context.focused_station_id then
		return "Press E to jump to this checklist item"
	end

	return "Walk into a debug box and use O/K to mark the checklist"
end

function state.shutdown(context)
	stop_sound(context)
end

return state
