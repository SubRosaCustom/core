local plugin = ...

local constants = {}
local bit_lib = bit32 or bit

constants.default_config = {
	select_prev_scancode = 80, -- Left Arrow
	select_next_scancode = 79, -- Right Arrow
	select_up_scancode = 82, -- Up Arrow
	select_down_scancode = 81, -- Down Arrow
	interact_scancode = 8, -- E
	confirm_scancode = 18, -- O
	reject_scancode = 14, -- K
	request_state_scancode = 20, -- Q
	text_scale = 15.0,
}

constants.binds = {
	select_prev = "showcase_select_prev",
	select_next = "showcase_select_next",
	select_up = "showcase_select_up",
	select_down = "showcase_select_down",
	interact = "showcase_interact",
	confirm = "showcase_confirm",
	reject = "showcase_reject",
	request_state = "showcase_request_state",
}

constants.events = {
	request_state = "srcc.showcase.request_state",
	state = "srcc.showcase.state",
}

constants.status_unknown = 0
constants.status_pass = 1
constants.status_fail = 2

constants.screen_width = 1024
constants.screen_height = 576

constants.origin = Vector(1610.0, 23.95, 1192.0)
constants.overview_spawn = Vector(1610.0, 24.20, 1182.0)
constants.overview_rotation = orientations.n

constants.station_width = 3.30
constants.station_height = 2.70
constants.station_depth = 3.30
constants.station_focus_radius = 2.60
constants.station_label_height = 2.40
constants.station_content_height = 1.10
constants.station_row_z = 0.0

constants.sound_duration_ticks = 220
constants.state_request_interval = 180
constants.state_timeout_ticks = 420

constants.texture_flags = bit_lib.bor(
	enum.renderer.textureAlign.center_x,
	enum.renderer.textureAlign.center_y,
	0x80
)

constants.stations = {
	{
		id = "ui_texture",
		label = "01 UI Texture",
		offset_x = -24.0,
		offset_z = constants.station_row_z,
		primary_item_id = "ui_texture_visible",
	},
	{
		id = "world_texture",
		label = "02 World Texture",
		offset_x = -16.0,
		offset_z = constants.station_row_z,
		primary_item_id = "world_texture_visible",
	},
	{
		id = "rotating_texture",
		label = "03 Rotating Texture",
		offset_x = -8.0,
		offset_z = constants.station_row_z,
		primary_item_id = "rotating_texture_spinning",
	},
	{
		id = "sound",
		label = "04 Sound Station",
		offset_x = 0.0,
		offset_z = constants.station_row_z,
		primary_item_id = "sound_plays",
	},
	{
		id = "model",
		label = "05 Model",
		offset_x = 8.0,
		offset_z = constants.station_row_z,
		primary_item_id = "model_visible",
	},
	{
		id = "debug",
		label = "06 Debug Boxes",
		offset_x = 16.0,
		offset_z = constants.station_row_z,
		primary_item_id = "debug_boxes_visible",
	},
	{
		id = "sync",
		label = "07 Mode + Sync",
		offset_x = 24.0,
		offset_z = constants.station_row_z,
		primary_item_id = "active_mode_showcase",
	},
}

constants.checklist = {
	{
		id = "active_mode_showcase",
		label = "Active mode is showcase",
	},
	{
		id = "non_active_modes_still_sync",
		label = "Non-active mode files are still in sync payload",
	},
	{
		id = "ui_texture_visible",
		label = "Number 1 UI texture is visible",
	},
	{
		id = "world_texture_visible",
		label = "Number 2 world texture is visible",
	},
	{
		id = "rotating_texture_spinning",
		label = "Number 3 world texture is spinning",
	},
	{
		id = "sound_plays",
		label = "Number 4 sound plays on E",
	},
	{
		id = "sound_stops_or_replays",
		label = "Number 4 sound stops or replays on E",
	},
	{
		id = "sound_progress_moves",
		label = "Number 4 progress bar moves",
	},
	{
		id = "model_visible",
		label = "Number 5 model is visible",
	},
	{
		id = "debug_boxes_visible",
		label = "Number 6 debug boxes are visible",
	},
}

function constants.station_world_position(station)
	return constants.origin + Vector(station.offset_x, constants.station_content_height, station.offset_z)
end

function constants.station_ground_position(station)
	return constants.origin + Vector(station.offset_x, 0.0, station.offset_z)
end

function constants.find_station(station_id)
	for i = 1, #constants.stations do
		local station = constants.stations[i]
		if station.id == station_id then
			return station, i
		end
	end

	return nil, nil
end

function constants.find_checklist_index(item_id)
	for i = 1, #constants.checklist do
		if constants.checklist[i].id == item_id then
			return i
		end
	end

	return nil
end

function constants.wrap_index(index, count)
	if count <= 0 then
		return 1
	end

	if index < 1 then
		return count
	end

	if index > count then
		return 1
	end

	return index
end

return constants
