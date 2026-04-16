---@type Plugin
local plugin = ...
plugin.name = "Fart Sound Example"
plugin.author = "Sub Rosa Custom"
plugin.description = "Example plugin that loads a fart sound, replays it every 10 seconds, and stops it after 5 seconds."

local sound_path = "fart.wav"
local max_distance = 512.0
local interval_ticks = 600
local stop_after_ticks = 300
local volume = 1.0
local pitch = 1.0

local loaded_sound_id = -1
local active_emitter_id = -1
local next_play_tick = nil
local next_stop_tick = nil

local function format_position(position)
	return string.format("(%.2f, %.2f, %.2f)", position.x, position.y, position.z)
end

local function reset_state()
	loaded_sound_id = -1
	active_emitter_id = -1
	next_play_tick = nil
	next_stop_tick = nil
end

local function get_play_position()
	if client and client.camera and client.camera.pos then
		return client.camera.pos, "camera"
	end

	if client and client.human and client.human.pos then
		return client.human.pos, "human"
	end

	return nil, "none"
end

local function try_load_sound()
	if not sounds then
		plugin:warn("sounds API is unavailable; upgrade client before using this example plugin")
		return false
	end

	local ok, sound_id = pcall(
		sounds.loadSound,
		sounds,
		sound_path,
		max_distance
	)
	if not ok then
		plugin:warn(string.format("failed to load sound '%s': %s", sound_path, tostring(sound_id)))
		return false
	end

	if type(sound_id) ~= "number" or sound_id < 0 then
		plugin:warn(string.format("sound '%s' did not load", sound_path))
		return false
	end

	loaded_sound_id = sound_id
	plugin:print(string.format(
		"loaded fart sound id %d from '%s' (max_distance=%.1f volume=%.2f pitch=%.2f interval_ticks=%d)",
		loaded_sound_id,
		sound_path,
		max_distance,
		volume,
		pitch,
		interval_ticks
	))
	return true
end

local function try_stop_sound(current_tick)
	if active_emitter_id < 0 then
		plugin:warn(string.format("skipping stop at tick %d because no emitter is active", current_tick))
		return
	end

	local ok, stop_err = pcall(
		sounds.stopSound,
		sounds,
		active_emitter_id
	)
	if not ok then
		plugin:warn(string.format("failed to stop fart emitter %d at tick %d: %s", active_emitter_id, current_tick, tostring(stop_err)))
		return
	end

	plugin:print(string.format("stopped fart emitter %d at tick %d", active_emitter_id, current_tick))
	active_emitter_id = -1
	next_stop_tick = nil
end

local function try_play_sound(current_tick)
	if loaded_sound_id < 0 then
		plugin:warn(string.format("skipping play at tick %d because no sound is loaded", current_tick))
		return
	end

	local play_position, position_source = get_play_position()
	if not play_position then
		plugin:warn(string.format("skipping play at tick %d because no camera/human position is available", current_tick))
		return
	end

	plugin:print(string.format(
		"attempting fart sound id %d at tick %d from %s %s",
		loaded_sound_id,
		current_tick,
		position_source,
		format_position(play_position)
	))

	local ok, did_play = pcall(
		sounds.playSound3D,
		sounds,
		loaded_sound_id,
		play_position,
		volume,
		pitch
	)
	if not ok then
		plugin:warn(string.format("failed to play fart sound id %d: %s", loaded_sound_id, tostring(did_play)))
		return
	end

	if type(did_play) == "number" and did_play >= 0 then
		active_emitter_id = did_play
		next_stop_tick = current_tick + stop_after_ticks
		plugin:print(string.format(
			"played fart sound id %d at tick %d with emitter %d; stop scheduled for tick %d",
			loaded_sound_id,
			current_tick,
			active_emitter_id,
			next_stop_tick
		))
	else
		plugin:warn(string.format(
			"playSound3D returned invalid emitter '%s' for sound id %d at tick %d from %s %s",
			tostring(did_play),
			loaded_sound_id,
			current_tick,
			position_source,
			format_position(play_position)
		))
	end
end

plugin:addEnableHandler(function()
	reset_state()
	plugin:print("enable handler fired for fart sound example")
	if try_load_sound() and client and type(client.ticksSinceReset) == "number" then
		try_play_sound(client.ticksSinceReset)
		next_play_tick = client.ticksSinceReset + interval_ticks
		plugin:print(string.format("next fart playback scheduled for tick %d", next_play_tick))
	else
		plugin:warn("sound did not schedule on enable")
	end
end)

plugin:addDisableHandler(function()
	reset_state()
end)

plugin:addHook("Logic", function()
	if not client or type(client.ticksSinceReset) ~= "number" then
		return
	end

	local current_tick = client.ticksSinceReset
	if next_play_tick == nil then
		next_play_tick = current_tick
	end

	if next_stop_tick ~= nil and current_tick >= next_stop_tick then
		try_stop_sound(current_tick)
	end

	if current_tick < next_play_tick then
		return
	end

	try_play_sound(current_tick)
	next_play_tick = current_tick + interval_ticks
end)
