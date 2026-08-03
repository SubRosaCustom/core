---@type Plugin
local plugin = ...
plugin.name = "PNG Test"
plugin.author = "Sub Rosa Custom"
plugin.description = "Loads the jellybean texture, renders it, and shows detailed runtime state for debugging."

local image_path = "jellybean"
local overlay_x = 24
local overlay_y = 24
local text_scale = 14
local line_spacing = 14
local panel_width = 420
local panel_height = 250
local retry_interval_ticks = 60
local world_position = Vector(2938.2, 25, 1538)
local world_size = 3.0
local world_rotation = orientations.e

local texture = nil
local last_load_error = "not attempted"
local load_attempts = 0
local logic_ticks = 0
local last_retry_tick = -1
local last_draw_ok = false
local texture_align_flags = bit.bor(
	enum.renderer.textureAlign.center_x,
	enum.renderer.textureAlign.center_y
)
local world_texture_flags = bit.bor(texture_align_flags, 0x80)

local function stringify(value)
	if value == nil then
		return "nil"
	end
	return tostring(value)
end

local function try_load_image()
	load_attempts = load_attempts + 1
	last_retry_tick = logic_ticks

	local ok, result = pcall(function()
		return Texture.loadFromFile(image_path)
	end)

	if not ok then
		texture = nil
		last_load_error = tostring(result)
		return false
	end

	texture = result
	if texture == nil then
		last_load_error = "Texture.loadFromFile returned nil"
		return false
	end

	last_load_error = "none"
	return true
end

local function should_retry_load()
	if texture ~= nil then
		return false
	end

	if last_retry_tick < 0 then
		return true
	end

	return (logic_ticks - last_retry_tick) >= retry_interval_ticks
end

local function draw_line(text, x, y)
	renderer:drawText(text, x, y, text_scale, 1.0, 1.0, 1.0, 1.0, 0x20)
end

plugin:addEnableHandler(function()
	texture = nil
	last_load_error = "not attempted"
	load_attempts = 0
	logic_ticks = 0
	last_retry_tick = -1
	last_draw_ok = false
	try_load_image()
end)

plugin:addHook("Logic", function()
	logic_ticks = logic_ticks + 1

	if should_retry_load() then
		try_load_image()
	end
end)

plugin:addHook("Draw3D", function()
	last_draw_ok = false
	if not (texture and texture.isValid) then
		return
	end

	local push_ok, push_error = pcall(function()
		renderer:pushWorldTransform(world_position, world_rotation)
	end)

	if not push_ok then
		last_load_error = "pushWorldTransform error: " .. tostring(push_error)
		return
	end

	local draw_ok, draw_result = pcall(function()
		return renderer:drawTexture(
			texture,
			0.0,
			0.0,
			world_size,
			world_size,
			1.0,
			1.0,
			1.0,
			1.0,
			world_texture_flags
		)
	end)

	local pop_ok, pop_error = pcall(function()
		renderer:popWorldTransform()
	end)

	last_draw_ok = draw_ok and draw_result == true and pop_ok

	if not draw_ok then
		last_load_error = "drawTexture error: " .. tostring(draw_result)
	elseif not pop_ok then
		last_load_error = "popWorldTransform error: " .. tostring(pop_error)
	else
		last_load_error = "none"
	end
end)

plugin:addHook("DrawUI", function()
	local x = overlay_x
	local y = overlay_y

	renderer:drawRectangle2D(
		x - 8,
		y - 8,
		panel_width,
		panel_height,
		0.0,
		0.0,
		0.0,
		0.55
	)

	draw_line("PNG Test", x, y)
	y = y + line_spacing
	draw_line("requestedPath: " .. stringify(image_path), x, y)
	y = y + line_spacing
	draw_line("logicTicks: " .. stringify(logic_ticks), x, y)
	y = y + line_spacing
	draw_line("loadAttempts: " .. stringify(load_attempts), x, y)
	y = y + line_spacing
	draw_line("lastLoadError: " .. stringify(last_load_error), x, y)
	y = y + line_spacing
	draw_line("texture lua type: " .. type(texture), x, y)
	y = y + line_spacing
	draw_line("texture tostring: " .. stringify(texture), x, y)
	y = y + line_spacing
	draw_line("texture.class: " .. stringify(texture and texture.class), x, y)
	y = y + line_spacing
	draw_line("texture.index: " .. stringify(texture and texture.index), x, y)
	y = y + line_spacing
	draw_line("texture.isValid: " .. stringify(texture and texture.isValid), x, y)
	y = y + line_spacing
	draw_line("texture.width: " .. stringify(texture and texture.width), x, y)
	y = y + line_spacing
	draw_line("texture.height: " .. stringify(texture and texture.height), x, y)
	y = y + line_spacing
	draw_line("texture.glTextureID: " .. stringify(texture and texture.glTextureID), x, y)
	y = y + line_spacing
	draw_line("texture.minFilter: " .. stringify(texture and texture.minFilter), x, y)
	y = y + line_spacing
	draw_line("texture.magFilter: " .. stringify(texture and texture.magFilter), x, y)
	y = y + line_spacing

	draw_line("drawTexture ok: " .. stringify(last_draw_ok), x, y)
	y = y + line_spacing
	draw_line("world pos: (" .. world_position.x .. ", " .. world_position.y .. ", " .. world_position.z .. ")", x, y)
	y = y + line_spacing
	draw_line("world size: " .. stringify(world_size), x, y)
	y = y + line_spacing
	draw_line("world flags: " .. stringify(world_texture_flags), x, y)
end)
