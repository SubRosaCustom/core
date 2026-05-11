local plugin = ...
local constants = plugin:require("constants")
local state = plugin:require("state")

local render = {}
local WORLD_TEXT_FLAGS = 0x80 + 0x20 + 0x1
local STATION_LABEL_SCALE = 0.22

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

local function draw_cutscene_overlay(context)
	local overlay_alpha = state.cutscene_overlay_alpha(context)
	local subtitle = state.cutscene_subtitle(context)

	if overlay_alpha > 0.0 then
		draw_panel(0, 0, constants.overlay_width, constants.overlay_height, 0.0, 0.0, 0.0, overlay_alpha)
	end

	if subtitle ~= "" then
		renderer:drawText(
			subtitle,
			constants.screen_width * 0.5,
			constants.cutscene_subtitle_y,
			18,
			1.0,
			1.0,
			1.0,
			1.0,
			0x1 + 0x20
		)
	end
end

local function draw_tab(context, page, page_index, x, y, width)
	local active = context.page_index == page_index
	draw_panel(
		x,
		y,
		width,
		20,
		active and 0.18 or 0.08,
		active and 0.24 or 0.11,
		active and 0.29 or 0.14,
		0.90
	)
	draw_label(
		page.label,
		x + 10,
		y + 4,
		12,
		active and 1.0 or 0.78,
		active and 0.92 or 0.83,
		active and 0.46 or 0.90,
		1.0
	)
end

local function draw_checklist_page(context, x, y, width)
	local list_y = y
	local note_x = x + 238

	for i = 1, #constants.checklist do
		local item = constants.checklist[i]
		local selected = i == context.selected_item_index
		local status = state.manual_status_for_item(context, item.id)
		local status_r, status_g, status_b, status_a = state.status_color(status)
		local prefix = status == constants.status_pass and "[PASS]"
			or status == constants.status_fail and "[FAIL]"
			or "[TODO]"
		local row_y = list_y + ((i - 1) * 18)

		if selected then
			draw_panel(x - 4, row_y - 2, width + 8, 16, 0.16, 0.20, 0.24, 0.85)
		end

		draw_label(
			string.format("%s %s", prefix, item.label),
			x + 2,
			row_y,
			12,
			status_r,
			status_g,
			status_b,
			status_a
		)
		draw_label(
			state.item_note(context, item.id),
			note_x,
			row_y,
			10,
			0.76,
			0.86,
			0.95,
			1.0
		)
	end
end

local function draw_diagnostics_page(context, x, y)
	local lines = state.diagnostics_lines(context)
	for i = 1, #lines do
		draw_label(lines[i], x, y + ((i - 1) * 16), 12, 0.92, 0.96, 1.0, 1.0)
	end

	local log_y = y + (#lines * 16) + 8
	draw_label("Recent log", x, log_y, 13, 0.96, 0.92, 0.70, 1.0)
	for i = 1, #context.log_lines do
		draw_label(
			context.log_lines[i],
			x,
			log_y + 16 + ((i - 1) * 14),
			11,
			0.82,
			0.88,
			0.94,
			1.0
		)
	end
end

local function draw_ui_texture_widget(context, x, y, width, height)
	draw_panel(x, y, width, height, 0.05, 0.08, 0.11, 0.86)
	draw_label("01 UI Texture", x + 10, y + 8, 13, 0.92, 0.98, 1.0, 1.0)

	if context.ui_texture and context.ui_texture ~= false then
		if renderer:drawTexture(context.ui_texture, x + 14, y + 24, 92, 92) then
			context.frame_metrics.ui_texture_drawn = true
		end
		draw_label(
			"Preview only shows while you are standing in station 01.",
			x + 118,
			y + 34,
			11,
			0.96,
			0.92,
			0.70,
			1.0
		)
		draw_label(
			"Use O or K after you confirm the texture looks correct.",
			x + 118,
			y + 52,
			11,
			0.78,
			0.90,
			1.0,
			1.0
		)
	else
		draw_label("Texture failed to load.", x + 14, y + 44, 12, 1.0, 0.40, 0.40, 1.0)
	end
end

local function draw_sound_widget(context, x, y, width, height)
	draw_panel(x, y, width, height, 0.05, 0.08, 0.11, 0.86)
	draw_label("04 Sound Station", x + 10, y + 8, 13, 0.92, 0.98, 1.0, 1.0)
	draw_label(
		string.format("Sound: %s", context.sound_state),
		x + 12,
		y + 30,
		12,
		1.0,
		1.0,
		1.0,
		1.0
	)
	draw_label(
		string.format("Progress: %d%%", math.floor(context.sound_progress * 100.0)),
		x + 12,
		y + 46,
		12,
		0.90,
		0.96,
		1.0,
		1.0
	)
	draw_progress_bar(x + 12, y + 66, width - 24, 16, context.sound_progress, 1.0, 0.55, 0.18)
	draw_label(
		"Press E here to play or stop the sound, then mark the checklist with O or K.",
		x + 12,
		y + 90,
		11,
		0.96,
		0.92,
		0.70,
		1.0
	)
end

local function draw_station_label(station, position)
	if not client or not client.camera or not client.camera.rot then
		return
	end

	local label_position = position + Vector(0.0, constants.station_label_height, 0.0)
	renderer:pushWorldTransform(label_position, client.camera.rot)
	renderer:drawText(station.label, 0.0, 0.0, STATION_LABEL_SCALE, 1.0, 1.0, 1.0, 1.0, WORLD_TEXT_FLAGS)
	renderer:popWorldTransform()
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
	if state.is_cutscene_active(context) then
		draw_cutscene_overlay(context)
		return
	end

	local margin = 10
	local panel_x = margin
	local panel_y = margin + 24
	local panel_w = 432
	local panel_h = 304
	local tab_y = panel_y + 64
	local content_x = panel_x + 14
	local content_y = panel_y + 92
	local widget_x = panel_x
	local widget_y = panel_y + panel_h + 10
	local widget_w = panel_w
	local widget_h = 120
	local active_page = state.current_page(context)

	if not context.ui_enabled then
		draw_label("SRC TEST MODE UI HIDDEN  |  PRESS U TO SHOW", panel_x + 12, panel_y, 12, 0.92, 0.98, 1.0, 0.95)
		return
	end

	draw_panel(panel_x, panel_y, panel_w, panel_h, 0.04, 0.06, 0.08, 0.86)
	draw_label("SRC TEST MODE", panel_x + 12, panel_y + 10, 20, 0.92, 0.98, 1.0, 1.0)
	draw_label(
		"Up/Down moves checklist  |  Left/Right switches pages",
		panel_x + 12,
		panel_y + 32,
		12,
		0.75,
		0.85,
		0.94,
		1.0
	)
	draw_label(
		state.focus_prompt(context),
		panel_x + 12,
		panel_y + 48,
		12,
		1.0,
		0.88,
		0.35,
		1.0
	)

	draw_tab(context, constants.pages[1], 1, panel_x + 12, tab_y, 106)
	draw_tab(context, constants.pages[2], 2, panel_x + 124, tab_y, 118)

	if active_page.id == "diagnostics" then
		draw_diagnostics_page(context, content_x, content_y)
	else
		draw_checklist_page(context, content_x, content_y, panel_w - 28)
	end

	if context.focused_station_id == "ui_texture" then
		draw_ui_texture_widget(context, widget_x, widget_y, widget_w, widget_h)
	elseif context.focused_station_id == "sound" then
		draw_sound_widget(context, widget_x, widget_y, widget_w, widget_h)
	end
end

return render
