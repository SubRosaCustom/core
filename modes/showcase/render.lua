local plugin = ...
local constants = plugin:require("constants")
local state = plugin:require("state")

local render = {}

local function draw_panel(x, y, width, height, r, g, b, a)
	renderer:drawRectangle2D(x, y, width, height, r, g, b, a)
end

local function draw_label(text, x, y, scale, r, g, b, a)
	renderer:drawText(text, x, y, scale, r, g, b, a, 0x20)
end

local function draw_progress_bar(x, y, width, height, progress, r, g, b)
	local clamped = math.max(0.0, math.min(1.0, progress))
	draw_panel(x, y, width, height, 0.08, 0.08, 0.08, 0.85)
	draw_panel(x + 2, y + 2, (width - 4) * clamped, height - 4, r, g, b, 0.95)
end

local function draw_station_label(station, position)
	local label_position = renderer:worldToScreenPosition(
		position + Vector(0.0, constants.station_label_height, 0.0),
		false
	)
	if not label_position then
		return
	end

	draw_label(station.label, label_position.x - 40, label_position.y, 14, 1.0, 1.0, 1.0, 1.0)
end

local function draw_station_box(context, station)
	local position = constants.station_world_position(station)
	local wire_r = station.id == context.focused_station_id and 1.00 or 0.25
	local wire_g = station.id == context.focused_station_id and 0.85 or 0.70
	local wire_b = station.id == context.focused_station_id and 0.20 or 1.00

	renderer:drawDebugWireBox3D(
		position,
		orientations.n,
		constants.station_width,
		constants.station_height,
		constants.station_depth,
		wire_r,
		wire_g,
		wire_b,
		0.95
	)
	draw_station_label(station, position)
end

local function draw_world_texture(context, station, rotation)
	if not context.ui_texture or context.ui_texture == false then
		return
	end

	local position = constants.station_world_position(station) + Vector(0.0, 0.15, 0.0)
	renderer:pushWorldTransform(position, rotation)
	local ok = renderer:drawTexture(
		context.ui_texture,
		0.0,
		0.0,
		2.0,
		2.0,
		1.0,
		1.0,
		1.0,
		1.0,
		constants.texture_flags
	)
	renderer:popWorldTransform()
	return ok == true
end

function render.draw_world(context)
	for i = 1, #constants.stations do
		draw_station_box(context, constants.stations[i])
	end

	local world_station = constants.find_station("world_texture")
	if world_station and draw_world_texture(context, world_station, orientations.n) then
		context.frame_metrics.world_texture_drawn = true
	end

	local rotating_station = constants.find_station("rotating_texture")
	if rotating_station and draw_world_texture(
		context,
		rotating_station,
		yawToRotMatrix(context.rotation_angle)
	) then
		context.frame_metrics.rotating_texture_drawn = true
	end

	local model_station = constants.find_station("model")
	if model_station and type(context.model_id) == "number" and context.model_id >= 0 then
		renderer:renderObject(
			context.model_id,
			constants.station_world_position(model_station) + Vector(0.0, -0.85, 0.0),
			yawToRotMatrix(context.rotation_angle * 0.8)
		)
		context.frame_metrics.model_drawn = true
	end

	local debug_station = constants.find_station("debug")
	if debug_station then
		local debug_position = constants.station_world_position(debug_station)
		local line_size = 1.35
		renderer:drawDebugLine3D(
			debug_position + Vector(-line_size, 0.0, 0.0),
			debug_position + Vector(line_size, 0.0, 0.0),
			1.0,
			0.22,
			0.22,
			1.0
		)
		renderer:drawDebugLine3D(
			debug_position + Vector(0.0, 0.0, -line_size),
			debug_position + Vector(0.0, 0.0, line_size),
			0.22,
			0.70,
			1.0,
			1.0
		)
		renderer:drawDebugWireBox3D(
			debug_position + Vector(1.0, -0.55, 0.0),
			yawToRotMatrix(context.rotation_angle * 0.5),
			0.70,
			0.70,
			0.70,
			1.0,
			0.55,
			0.22,
			1.0
		)
		context.frame_metrics.debug_drawn = true
	end
end

function render.draw_ui(context)
	local margin = 14
	local checklist_x = margin
	local checklist_y = margin
	local checklist_w = 430
	local checklist_h = 328
	local diagnostics_x = constants.screen_width - 330
	local diagnostics_y = margin
	local diagnostics_w = 316
	local diagnostics_h = 244
	local texture_x = diagnostics_x
	local texture_y = diagnostics_y + diagnostics_h + 12
	local texture_w = 316
	local texture_h = 160
	local text_scale = plugin.config.text_scale

	draw_panel(checklist_x, checklist_y, checklist_w, checklist_h, 0.04, 0.06, 0.08, 0.86)
	draw_panel(diagnostics_x, diagnostics_y, diagnostics_w, diagnostics_h, 0.05, 0.08, 0.11, 0.86)
	draw_panel(texture_x, texture_y, texture_w, texture_h, 0.05, 0.08, 0.11, 0.86)

	draw_label("SRC SHOWCASE", checklist_x + 14, checklist_y + 12, 24, 0.92, 0.98, 1.0, 1.0)
	draw_label(
		"Arrows move  |  E interact  |  O pass  |  K fail  |  Q refresh state",
		checklist_x + 14,
		checklist_y + 38,
		14,
		0.75,
		0.85,
		0.94,
		1.0
	)
	draw_label(
		state.focus_prompt(context),
		checklist_x + 14,
		checklist_y + 58,
		14,
		1.0,
		0.88,
		0.35,
		1.0
	)

	local list_y = checklist_y + 86
	for i = 1, #constants.checklist do
		local item = constants.checklist[i]
		local selected = i == context.selected_item_index
		local status = state.manual_status_for_item(context, item.id)
		local status_r, status_g, status_b, status_a = state.status_color(status)
		local prefix = status == constants.status_pass and "[PASS]"
			or status == constants.status_fail and "[FAIL]"
			or "[TODO]"
		local row_y = list_y + ((i - 1) * 22)

		if selected then
			draw_panel(checklist_x + 8, row_y - 2, checklist_w - 16, 20, 0.16, 0.20, 0.24, 0.85)
		end

		draw_label(
			string.format("%s %s", prefix, item.label),
			checklist_x + 16,
			row_y,
			14,
			status_r,
			status_g,
			status_b,
			status_a
		)
		draw_label(
			state.item_note(context, item.id),
			checklist_x + 258,
			row_y,
			13,
			0.76,
			0.86,
			0.95,
			1.0
		)
	end

	draw_label("Diagnostics", diagnostics_x + 14, diagnostics_y + 12, 22, 0.92, 0.98, 1.0, 1.0)
	draw_label(
		string.format(
			"local_mode=%s  server_mode=%s",
			hook.persistentMode ~= "" and hook.persistentMode or "<none>",
			context.server.persistent_mode ~= "" and context.server.persistent_mode or "<none>"
		),
		diagnostics_x + 14,
		diagnostics_y + 42,
		14,
		1.0,
		1.0,
		1.0,
		1.0
	)
	draw_label(
		string.format(
			"sync_gen=%d  server_tick=%d",
			context.server.sync_generation,
			context.server.server_tick
		),
		diagnostics_x + 14,
		diagnostics_y + 62,
		14,
		1.0,
		1.0,
		1.0,
		1.0
	)
	draw_label(
		string.format(
			"scripts=%d  assets=%d  clients=%d",
			context.server.script_count,
			context.server.asset_count,
			context.server.client_count
		),
		diagnostics_x + 14,
		diagnostics_y + 82,
		14,
		1.0,
		1.0,
		1.0,
		1.0
	)
	draw_label(
		string.format(
			"mode_scripts=%d  non_active=%d",
			context.server.mode_script_count,
			context.server.non_active_mode_script_count
		),
		diagnostics_x + 14,
		diagnostics_y + 102,
		14,
		1.0,
		1.0,
		1.0,
		1.0
	)
	draw_label(
		string.format(
			"server_level=%s  state_ok=%s",
			context.server.loaded_level ~= "" and context.server.loaded_level or "<none>",
			tostring(context.server_state_received)
		),
		diagnostics_x + 14,
		diagnostics_y + 122,
		14,
		1.0,
		1.0,
		1.0,
		1.0
	)
	draw_label(
		string.format(
			"focused_station=%s",
			context.focused_station_id or "<none>"
		),
		diagnostics_x + 14,
		diagnostics_y + 142,
		14,
		1.0,
		1.0,
		1.0,
		1.0
	)
	draw_label(
		string.format(
			"sound=%s progress=%d%%",
			context.sound_state,
			math.floor(context.sound_progress * 100.0)
		),
		diagnostics_x + 14,
		diagnostics_y + 162,
		14,
		1.0,
		1.0,
		1.0,
		1.0
	)
	draw_progress_bar(diagnostics_x + 14, diagnostics_y + 186, diagnostics_w - 28, 18, context.sound_progress, 1.0, 0.55, 0.18)

	draw_label("Recent log", diagnostics_x + 14, diagnostics_y + 214, 16, 0.92, 0.98, 1.0, 1.0)
	local first_log_index = math.max(1, #context.log_lines - 2)
	for i = first_log_index, #context.log_lines do
		draw_label(
			context.log_lines[i],
			diagnostics_x + 14,
			diagnostics_y + 214 + ((i - first_log_index + 1) * 16),
			12,
			0.82,
			0.88,
			0.94,
			1.0
		)
	end

	draw_label("Number 1: UI texture", texture_x + 12, texture_y + 10, 16, 0.92, 0.98, 1.0, 1.0)
	if context.ui_texture and context.ui_texture ~= false then
		if renderer:drawTexture(context.ui_texture, texture_x + 18, texture_y + 30, 126, 126) then
			context.frame_metrics.ui_texture_drawn = true
		end
	else
		draw_label("texture unavailable", texture_x + 18, texture_y + 48, 15, 1.0, 0.40, 0.40, 1.0)
	end

	draw_label(
		"Number 4: use E in the sound box, then mark with O/K.",
		texture_x + 156,
		texture_y + 44,
		14,
		0.96,
		0.92,
		0.70,
		1.0
	)
	draw_label(
		"Mode test: active mode should be showcase.",
		texture_x + 156,
		texture_y + 68,
		14,
		0.78,
		0.90,
		1.0,
		1.0
	)
	draw_label(
		"Sync test: non-active mode files should still count above.",
		texture_x + 156,
		texture_y + 92,
		14,
		0.78,
		0.90,
		1.0,
		1.0
	)
end

return render
