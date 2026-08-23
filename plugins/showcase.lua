---@type Plugin
local plugin = ...
plugin.name = "SRC Capability Gallery"
plugin.author = "Sub Rosa Custom"
plugin.description = "A compact live gallery for SRC rendering, particles, blips, input, and client/server events."

plugin.defaultConfig = {
	toggleOverlayScancode = 63, -- F6
	pingServerScancode = 64, -- F7
	requestStateScancode = 65, -- F8
	particle_burst_scancode = 66, -- F9
	overlayX = 24,
	overlayY = 40,
}

local PANEL_WIDTH = 364
local PANEL_HEIGHT = 214
local TITLE_SIZE = 20.0
local TEXT_SIZE = 13.0
local PARTICLE_TYPE_PUFF = 2
local LOG_LIMIT = 4
local SERVER_TIMEOUT_TICKS = 600

local overlay_enabled = true
local overlay_lines = {}
local ticks = 0
local server_state = "waiting"
local last_round_trip = "not measured"
local last_server_response_tick = nil
local burst_emitter = nil

local bind_toggle_overlay = "src_gallery_toggle_overlay"
local bind_ping_server = "src_gallery_ping_server"
local bind_request_state = "src_gallery_request_state"
local bind_particle_burst = "src_gallery_particle_burst"

local function push_line(text)
	table.insert(overlay_lines, 1, tostring(text))
	while #overlay_lines > LOG_LIMIT do
		table.remove(overlay_lines)
	end
end

local function emit(name, ...)
	local ok = emitServerEvent(name, ...)
	if not ok then
		server_state = "event failed"
		push_line(string.format("Event failed: %s", name))
	end
	return ok
end

local function local_position()
	if client and client.human and client.human.pos then
		return client.human.pos
	end
	if client and client.camera and client.camera.pos then
		return client.camera.pos
	end
	return nil
end

local function configure_particles()
	if not particle or not particle.new then
		return
	end

	local ok, emitter = pcall(function()
		local configured_emitter = particle.new("src_gallery_pulse")
		configured_emitter.type = PARTICLE_TYPE_PUFF
		configured_emitter.lifeTime = 1.2
		configured_emitter.startSize = 0.18
		configured_emitter.gravity = -0.003
		configured_emitter.damping = 0.98
		configured_emitter.maxParticles = 96
		return configured_emitter
	end)
	if not ok or not emitter then
		push_line("Particle API unavailable")
		return
	end

	burst_emitter = emitter
end

local function emit_particle_burst()
	local position = local_position()
	if not burst_emitter or not position then
		push_line("Particle burst unavailable")
		return
	end

	local origin = position + Vector(0.0, 1.0, 0.0)
	local emitted = 0
	for i = 1, 12 do
		local angle = (i / 12) * math.pi * 2
		local velocity = Vector(math.cos(angle) * 0.025, 0.035, math.sin(angle) * 0.025)
		local ok, count = pcall(burst_emitter.emit, burst_emitter, origin, velocity, 1)
		if ok then
			emitted = emitted + (count or 0)
		end
	end

	push_line(string.format("Particle pulse: %d emitted", emitted))
end

local function draw_text(text, x, y, size, r, g, b, a)
	renderer:drawText(text, x, y, size, r, g, b, a, 0x20)
end

local function draw_status_row(label, value, x, y, active)
	local color_r = active and 0.25 or 0.55
	local color_g = active and 0.95 or 0.58
	local color_b = active and 0.72 or 0.65
	renderer:drawRectangle2D(x, y + 3, 5, 5, color_r, color_g, color_b, 1.0)
	draw_text(label, x + 12, y, TEXT_SIZE, 0.70, 0.74, 0.80, 1.0)
	draw_text(value, x + 122, y, TEXT_SIZE, 0.94, 0.96, 1.0, 1.0)
end

local function draw_gallery()
	if not overlay_enabled then
		return
	end

	local x = plugin.config.overlayX
	local y = plugin.config.overlayY
	local pulse = 0.55 + (math.sin(ticks * 0.06) * 0.15)
	local connected = server_state == "connected"

	renderer:drawRectangle2D(x, y, PANEL_WIDTH, PANEL_HEIGHT, 0.025, 0.035, 0.055, 0.94)
	renderer:drawRectangle2D(x, y, 4, PANEL_HEIGHT, 0.20, 0.85, pulse, 1.0)
	renderer:drawRectangle2D(x + 16, y + 43, PANEL_WIDTH - 32, 1, 0.18, 0.23, 0.31, 0.9)

	draw_text("SRC CAPABILITY GALLERY", x + 18, y + 11, TITLE_SIZE, 0.82, 0.96, 1.0, 1.0)
	draw_text("live client runtime", x + 18, y + 29, 11.0, 0.40, 0.70, 0.78, 1.0)

	draw_status_row("SERVER LINK", server_state, x + 18, y + 57, connected)
	draw_status_row(
		"ROUND TRIP",
		last_round_trip,
		x + 18,
		y + 78,
		last_round_trip ~= "not measured"
	)
	draw_status_row(
		"WORLD FX",
		burst_emitter and "ready" or "unavailable",
		x + 18,
		y + 99,
		burst_emitter ~= nil
	)
	draw_status_row("MINIMAP", "3 markers", x + 18, y + 120, true)

	draw_text("F6 PANEL   F7 PING   F8 STATE   F9 PULSE", x + 18, y + 148, 12.0, 0.96, 0.78, 0.30, 1.0)
	renderer:drawRectangle2D(x + 16, y + 170, PANEL_WIDTH - 32, 1, 0.18, 0.23, 0.31, 0.9)

	for i = 1, #overlay_lines do
		draw_text(overlay_lines[i], x + 18, y + 175 + ((i - 1) * 12), 10.0, 0.66, 0.71, 0.78, 1.0)
	end
end

onServerEvent("srcc.showcase.welcome", function(message, server_tick)
	server_state = "connected"
	last_server_response_tick = ticks
	push_line(string.format("Welcome: %s @%s", tostring(message), tostring(server_tick)))
end)

onServerEvent("srcc.showcase.pong", function(server_tick, reason, local_tick)
	server_state = "connected"
	last_round_trip = string.format("%d ticks", math.max(0, ticks - (tonumber(local_tick) or ticks)))
	last_server_response_tick = ticks
	push_line(string.format("Pong: %s @%s", tostring(reason), tostring(server_tick)))
end)

onServerEvent("srcc.showcase.state", function(server_tick, connected_clients)
	server_state = "connected"
	last_server_response_tick = ticks
	push_line(string.format("State: %s clients @%s", tostring(connected_clients), tostring(server_tick)))
end)

onServerEvent("srcc.showcase.notice", function(text, server_tick)
	server_state = "connected"
	last_server_response_tick = ticks
	push_line(string.format("Notice: %s @%s", tostring(text), tostring(server_tick)))
end)

plugin:addEnableHandler(function()
	overlay_enabled = true
	overlay_lines = {}
	ticks = 0
	server_state = "waiting"
	last_round_trip = "not measured"
	last_server_response_tick = nil
	configure_particles()

	input:bind(bind_toggle_overlay, plugin.config.toggleOverlayScancode, function(_, toggled)
		if toggled then
			overlay_enabled = not overlay_enabled
		end
	end, true, 5)

	input:bind(bind_ping_server, plugin.config.pingServerScancode, function(_, toggled)
		if toggled and emit("srcc.showcase.ping", "gallery", ticks) then
			push_line("Ping sent")
		end
	end, true, 5)

	input:bind(bind_request_state, plugin.config.requestStateScancode, function(_, toggled)
		if toggled then
			emit("srcc.showcase.request_state", ticks)
		end
	end, true, 5)

	input:bind(bind_particle_burst, plugin.config.particle_burst_scancode, function(_, toggled)
		if toggled then
			emit_particle_burst()
		end
	end, true, 5)

	blips:add("showcase_origin", {
		worldX = 0,
		worldZ = 0,
		r = 0.2,
		g = 0.9,
		b = 1.0,
		a = 1.0,
		size = 5,
		shape = blips.shape.diamond,
		clamp = true,
	})
	blips:add("showcase_arrow", {
		worldX = 50,
		worldZ = 50,
		r = 1.0,
		g = 0.55,
		b = 0.2,
		a = 1.0,
		size = 4,
		shape = blips.shape.arrow,
		clamp = true,
	})
	blips:add("showcase_orbit", {
		worldX = -50,
		worldZ = 30,
		r = 0.25,
		g = 1.0,
		b = 0.65,
		a = 1.0,
		size = 3,
		shape = blips.shape.circle,
	})

	push_line("Gallery ready")
	emit(
		"srcc.showcase.hello",
		client and client.serverAddress or "unknown",
		client and client.serverPort or 0
	)
end)

plugin:addDisableHandler(function()
	input:removeBind(bind_toggle_overlay)
	input:removeBind(bind_ping_server)
	input:removeBind(bind_request_state)
	input:removeBind(bind_particle_burst)
	blips:remove("showcase_origin")
	blips:remove("showcase_arrow")
	blips:remove("showcase_orbit")
	burst_emitter = nil
end)

plugin:addHook("Logic", function()
	ticks = ticks + 1
	if last_server_response_tick and ticks - last_server_response_tick > SERVER_TIMEOUT_TICKS then
		server_state = "timed out"
		last_round_trip = "stale"
		last_server_response_tick = nil
	end

	local position = local_position()
	if not position then
		return
	end

	local angle = ticks * 0.018
	blips:update("showcase_arrow", {
		worldX = position.x + (math.cos(angle) * 38),
		worldZ = position.z + (math.sin(angle) * 38),
		yaw = angle + (math.pi * 0.5),
	})
	blips:update("showcase_orbit", {
		worldX = position.x + (math.cos(-angle * 1.4) * 22),
		worldZ = position.z + (math.sin(-angle * 1.4) * 22),
	})
end)

plugin:addHook("Draw3D", function()
	if not overlay_enabled then
		return
	end

	local position = local_position()
	if not position then
		return
	end

	local base = position + Vector(0.0, 0.05, 0.0)
	local top = base + Vector(0.0, 2.5 + (math.sin(ticks * 0.05) * 0.25), 0.0)
	renderer:drawDebugLine3D(base, top, 0.20, 0.90, 1.0, 0.75)
	renderer:drawDebugLine3D(
		top + Vector(-0.35, 0.0, 0.0),
		top + Vector(0.35, 0.0, 0.0),
		1.0,
		0.72,
		0.2,
		0.9
	)
	renderer:drawDebugLine3D(
		top + Vector(0.0, 0.0, -0.35),
		top + Vector(0.0, 0.0, 0.35),
		1.0,
		0.72,
		0.2,
		0.9
	)
end)

plugin:addHook("DrawUI", draw_gallery)
