local plugin = ...
local constants = plugin:require("constants")

local state = {}

local function push_log(context, text)
	context.log_lines[#context.log_lines + 1] = tostring(text)
	while #context.log_lines > 3 do
		table.remove(context.log_lines, 1)
	end
end

local function current_page(context)
	return constants.pages[constants.wrap_index(context.page_index, #constants.pages)]
end

local function clone_vector(value)
	return value and value.clone and value:clone() or nil
end

local function lerp_number(a, b, t)
	return a + ((b - a) * t)
end

local function lerp_vector(a, b, t)
	return Vector(
		lerp_number(a.x, b.x, t),
		lerp_number(a.y, b.y, t),
		lerp_number(a.z, b.z, t)
	)
end

local function smoothstep(t)
	local clamped = math.max(0.0, math.min(1.0, t))
	return clamped * clamped * (3.0 - (2.0 * clamped))
end

local function current_time_seconds()
	return os.clock()
end

local function has_local_human()
	return client and client.human and client.human.pos ~= nil
end

local function capture_camera(context)
	if context.camera_captured or not client or not client.camera then
		return
	end

	context.camera_captured = true
	context.camera_pos = clone_vector(client.camera.pos)
	context.camera_rot = client.camera.rot and client.camera.rot:clone() or nil
	context.camera_fov = client.camera.fov
end

local function restore_camera(context)
	if not context.camera_captured or not client or not client.camera then
		return
	end

	if context.camera_pos then
		client.camera.pos:set(context.camera_pos)
	end
	if context.camera_rot then
		client.camera.rot:set(context.camera_rot)
	end
	if context.camera_fov then
		client.camera.fov = context.camera_fov
	end

	context.camera_captured = false
	context.camera_pos = nil
	context.camera_rot = nil
	context.camera_fov = nil
end

local function capture_hud_state(context)
	if context.hud_state or not client or not client.hud then
		return
	end

	local hud = client.hud
	context.hud_state = {
		inventory_panel = hud.inventory.panel.enabled,
		inventory_equipment_panel = hud.inventory.equipmentPanel.enabled,
		inventory_direction_widget = hud.inventory.directionWidget.enabled,
		minimap = hud.minimap.enabled,
		crosshair = hud.crosshair.enabled,
		stamina_bar = hud.staminaBar.enabled,
		move_mode_text = hud.moveModeText.enabled,
		chat_mode_text = hud.chatModeText.enabled,
		progress_bar = hud.progressBar.enabled,
		phone_prompts = hud.phonePrompts.enabled,
		midget_widget = hud.midgetWidget.enabled,
		message_ring = hud.messageRing.enabled,
		press_tab_hint = hud.pressTabHint.enabled,
		money_text = hud.moneyText.enabled,
		team_money_text = hud.teamMoneyText.enabled,
		round_start_text = hud.roundStartText.enabled,
		round_result_text = hud.roundResultText.enabled,
		role_reveal_text = hud.roleRevealText.enabled,
		savior_text = hud.saviorText.enabled,
		chat_feed = hud.chatFeed.enabled,
		map_toggle_hint = hud.mapToggleHint.enabled,
	}
end

local function set_hud_hidden(context, hidden)
	if not client or not client.hud then
		return
	end

	local hud = client.hud
	if hidden then
		hud.inventory.panel.enabled = false
		hud.inventory.equipmentPanel.enabled = false
		hud.inventory.directionWidget.enabled = false
		hud.minimap.enabled = false
		hud.crosshair.enabled = false
		hud.staminaBar.enabled = false
		hud.moveModeText.enabled = false
		hud.chatModeText.enabled = false
		hud.progressBar.enabled = false
		hud.phonePrompts.enabled = false
		hud.midgetWidget.enabled = false
		hud.messageRing.enabled = false
		hud.pressTabHint.enabled = false
		hud.moneyText.enabled = false
		hud.teamMoneyText.enabled = false
		hud.roundStartText.enabled = false
		hud.roundResultText.enabled = false
		hud.roleRevealText.enabled = false
		hud.saviorText.enabled = false
		hud.chatFeed.enabled = false
		hud.mapToggleHint.enabled = false
		return
	end

	if not context.hud_state then
		return
	end

	hud.inventory.panel.enabled = context.hud_state.inventory_panel
	hud.inventory.equipmentPanel.enabled = context.hud_state.inventory_equipment_panel
	hud.inventory.directionWidget.enabled = context.hud_state.inventory_direction_widget
	hud.minimap.enabled = context.hud_state.minimap
	hud.crosshair.enabled = context.hud_state.crosshair
	hud.staminaBar.enabled = context.hud_state.stamina_bar
	hud.moveModeText.enabled = context.hud_state.move_mode_text
	hud.chatModeText.enabled = context.hud_state.chat_mode_text
	hud.progressBar.enabled = context.hud_state.progress_bar
	hud.phonePrompts.enabled = context.hud_state.phone_prompts
	hud.midgetWidget.enabled = context.hud_state.midget_widget
	hud.messageRing.enabled = context.hud_state.message_ring
	hud.pressTabHint.enabled = context.hud_state.press_tab_hint
	hud.moneyText.enabled = context.hud_state.money_text
	hud.teamMoneyText.enabled = context.hud_state.team_money_text
	hud.roundStartText.enabled = context.hud_state.round_start_text
	hud.roundResultText.enabled = context.hud_state.round_result_text
	hud.roleRevealText.enabled = context.hud_state.role_reveal_text
	hud.saviorText.enabled = context.hud_state.savior_text
	hud.chatFeed.enabled = context.hud_state.chat_feed
	hud.mapToggleHint.enabled = context.hud_state.map_toggle_hint
end

local function set_cutscene_pose(context, shot, position_t)
	context.cutscene.current_pos = lerp_vector(shot.from_pos, shot.to_pos, position_t)
	context.cutscene.current_target = lerp_vector(shot.from_target, shot.to_target, position_t)
	context.cutscene.subtitle = shot.text
end

local function finish_cutscene(context)
	context.cutscene.phase = "finished"
	context.cutscene.overlay_alpha = 0.0
	context.cutscene.current_pos = nil
	context.cutscene.current_target = nil
	context.cutscene.subtitle = ""
	restore_camera(context)
	set_hud_hidden(context, false)
	push_log(context, "intro cutscene finished")
end

local function update_cutscene(context)
	if context.cutscene.phase == "awaiting_spawn" then
		capture_hud_state(context)
		set_hud_hidden(context, true)
		context.cutscene.overlay_alpha = 1.0
		context.cutscene.subtitle = ""
		if has_local_human() then
			capture_camera(context)
			context.cutscene.phase = "playing"
			context.cutscene.start_time = current_time_seconds()
			set_cutscene_pose(context, constants.cutscene_shots[1], 0.0)
			push_log(context, "intro cutscene started")
		end
		return
	end

	if context.cutscene.phase ~= "playing" then
		return
	end

	set_hud_hidden(context, true)

	local elapsed = current_time_seconds() - context.cutscene.start_time
	context.cutscene.overlay_alpha = 1.0 - math.min(1.0, elapsed / constants.cutscene_fade_seconds)

	local timeline_cursor = 0
	for i = 1, #constants.cutscene_shots do
		local shot = constants.cutscene_shots[i]
		local move_end = timeline_cursor + shot.move_seconds
		local hold_end = move_end + shot.hold_seconds

		if elapsed < move_end then
			local shot_elapsed = elapsed - timeline_cursor
			local progress = smoothstep(shot_elapsed / shot.move_seconds)
			set_cutscene_pose(context, shot, progress)
			return
		end

		if elapsed < hold_end then
			set_cutscene_pose(context, shot, 1.0)
			return
		end

		timeline_cursor = hold_end
	end

	finish_cutscene(context)
end

local function emit(event_name, ...)
	local ok = emitServerEvent(event_name, ...)
	if not ok then
		plugin:warn(string.format("failed to emit src_test_mode event '%s'", tostring(event_name)))
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
	return "src_test_mode_station_" .. station.id
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
		page_index = 1,
		selected_item_index = 1,
		manual_status = manual_status,
		ui_enabled = true,
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
		camera_captured = false,
		camera_pos = nil,
		camera_rot = nil,
		camera_fov = nil,
		hud_state = nil,
		cutscene = {
			phase = "awaiting_spawn",
			start_time = nil,
			overlay_alpha = 1.0,
			current_pos = nil,
			current_target = nil,
			subtitle = "",
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

	update_cutscene(context)
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
	if state.is_cutscene_active(context) then
		return
	end

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
		context.page_index = 1
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

function state.current_page(context)
	return current_page(context)
end

function state.page_delta(context, delta)
	if state.is_cutscene_active(context) then
		return
	end

	context.page_index = constants.wrap_index(context.page_index + delta, #constants.pages)
end

function state.select_delta(context, delta)
	if state.is_cutscene_active(context) then
		return
	end

	if current_page(context).id ~= "checklist" then
		return
	end

	context.selected_item_index = constants.wrap_index(
		context.selected_item_index + delta,
		#constants.checklist
	)
end

function state.toggle_ui(context)
	if state.is_cutscene_active(context) then
		return
	end

	context.ui_enabled = not context.ui_enabled
	push_log(context, context.ui_enabled and "ui shown" or "ui hidden")
end

function state.mark_selected(context, status)
	if state.is_cutscene_active(context) then
		return
	end

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
	if item_id == "non_active_modes_still_sync" then
		return string.format("%d other-mode scripts reported", context.server.non_active_mode_script_count)
	end

	if item_id == "ui_texture_visible" then
		if context.ui_texture and context.ui_texture ~= false then
			if context.focused_station_id == "ui_texture" and context.frame_metrics.ui_texture_drawn then
				return "Preview is visible"
			end
			return "Focus station 01 to preview it"
		end
		return "Texture failed to load"
	end

	if item_id == "world_texture_visible" then
		return context.frame_metrics.world_texture_drawn and "World quad drew this frame" or "World quad has not drawn yet"
	end

	if item_id == "rotating_texture_spinning" then
		return context.frame_metrics.rotating_texture_drawn
			and string.format("Spinning at %.2f rad", context.rotation_angle)
			or "Rotating quad has not drawn yet"
	end

	if item_id == "sound_plays" then
		if context.sound_state == "playing" then
			return string.format("Sound is playing on emitter %s", tostring(context.sound_emitter_id))
		end
		if context.sound_state == "ended" then
			return "Playback reached the end"
		end
		return "Press E at station 04 to start it"
	end

	if item_id == "sound_stops_or_replays" then
		return string.format("State: %s", context.sound_state)
	end

	if item_id == "sound_progress_moves" then
		return string.format("Progress: %d%%", math.floor(context.sound_progress * 100.0))
	end

	if item_id == "model_visible" then
		return type(context.model_id) == "number" and context.model_id >= 0
			and string.format("Model loaded as id %d", context.model_id)
			or "Model failed to load"
	end

	if item_id == "debug_boxes_visible" then
		return context.frame_metrics.debug_drawn and "Debug lines and box drew" or "Debug draw has not happened yet"
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

function state.is_cutscene_active(context)
	return context.cutscene and context.cutscene.phase ~= "finished"
end

function state.cutscene_overlay_alpha(context)
	if not state.is_cutscene_active(context) then
		return 0.0
	end

	return context.cutscene.overlay_alpha or 0.0
end

function state.cutscene_subtitle(context)
	if not state.is_cutscene_active(context) then
		return ""
	end

	return context.cutscene.subtitle or ""
end

function state.apply_cutscene_camera(context)
	if not state.is_cutscene_active(context) or context.cutscene.phase ~= "playing" then
		return false
	end

	if not client or not client.camera or not context.cutscene.current_pos or not context.cutscene.current_target then
		return false
	end

	client.camera.pos:set(context.cutscene.current_pos)
	client.camera.rot:set(getRotMatrixLookingAt(context.cutscene.current_pos, context.cutscene.current_target))
	return true
end

function state.focus_prompt(context)
	if context.focused_station_id == "sound" then
		if context.sound_state == "playing" then
			return "E stops the sound  |  Left/Right switches pages  |  U hides UI"
		end
		return "E plays the sound  |  Left/Right switches pages  |  U hides UI"
	end

	if context.focused_station_id == "sync" then
		return "E refreshes sync data  |  Left/Right switches pages  |  U hides UI"
	end

	if context.focused_station_id then
		return "E jumps to this checklist row  |  Left/Right switches pages  |  U hides UI"
	end

	return "Walk into a station  |  Left/Right switches pages  |  U hides UI"
end

function state.diagnostics_lines(context)
	local lines = {}
	local client_mode = hook and hook.persistentMode or ""
	local station = nil
	if context.focused_station_id then
		station = constants.find_station(context.focused_station_id)
	end

	local sync_line = "Waiting for the server diagnostics reply"
	if context.server_state_received and context.last_server_state_tick >= 0 then
		local age = context.local_ticks - context.last_server_state_tick
		if age <= 60 then
			sync_line = string.format("Server diagnostics are fresh (%d ticks ago)", age)
		else
			sync_line = string.format("Last server diagnostics reply was %d ticks ago", age)
		end
	end

	lines[#lines + 1] = string.format(
		"Client mode loaded: %s",
		client_mode ~= "" and client_mode or "none"
	)
	lines[#lines + 1] = string.format(
		"Server persistent mode: %s",
		context.server.persistent_mode ~= "" and context.server.persistent_mode or "none"
	)
	lines[#lines + 1] = sync_line
	lines[#lines + 1] = string.format(
		"Server sync generation: %d at tick %d",
		context.server.sync_generation,
		context.server.server_tick
	)
	lines[#lines + 1] = string.format(
		"Payload size: %d scripts and %d assets",
		context.server.script_count,
		context.server.asset_count
	)
	lines[#lines + 1] = string.format(
		"Mode breakdown: %d active-mode scripts, %d other-mode scripts",
		context.server.mode_script_count,
		context.server.non_active_mode_script_count
	)
	lines[#lines + 1] = string.format("Connected SRC clients: %d", context.server.client_count)
	lines[#lines + 1] = string.format(
		"Loaded server level: %s",
		context.server.loaded_level ~= "" and context.server.loaded_level or "unknown"
	)
	lines[#lines + 1] = string.format(
		"Current station: %s",
		station and station.label or "none"
	)

	return lines
end

function state.shutdown(context)
	stop_sound(context)
	restore_camera(context)
	set_hud_hidden(context, false)
end

return state
