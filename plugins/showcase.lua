---@type Plugin
local plugin = ...
plugin.name = "SRCC Showcase"
plugin.author = "Sub Rosa Custom"
plugin.description = "Demonstrates SRCC hooks, keybinds, blips, UI drawing, and client/server events."

plugin.defaultConfig = {
	toggleOverlayScancode = 63, -- F6
	pingServerScancode = 64, -- F7
	requestStateScancode = 65, -- F8
	overlayX = 150,
	overlayY = 10,
	textScale = 16.0,
}

-- TODO (soon): add binary payload demonstration once SRCC plugins expose
-- a higher-level helper for binary encode/decode on both sides.

local overlay_enabled = true
local overlay_lines = {}
local ticks = 0
local status_color = { 0.3, 1.0, 0.3, 1.0 }

local bind_toggle_overlay = "srcc_showcase_toggle_overlay"
local bind_ping_server = "srcc_showcase_ping_server"
local bind_request_state = "srcc_showcase_request_state"

local function push_line(text)
	table.insert(overlay_lines, 1, tostring(text))
	while #overlay_lines > 10 do
		table.remove(overlay_lines)
	end
end

local function set_status(text, r, g, b, a)
	push_line(text)
	status_color[1] = r or status_color[1]
	status_color[2] = g or status_color[2]
	status_color[3] = b or status_color[3]
	status_color[4] = a or status_color[4]
end

local function emit(name, ...)
	local ok = emitServerEvent(name, ...)
	if ok then
		push_line("emitServerEvent OK: " .. name)
	else
		set_status("emitServerEvent FAILED: " .. name, 1.0, 0.35, 0.35, 1.0)
	end
end

onServerEvent("srcc.showcase.welcome", function(message, server_tick)
	set_status("> WELCOME from server: " .. tostring(message) .. " @" .. tostring(server_tick), 0.2, 0.9, 1.0, 1.0)
end)

onServerEvent("srcc.showcase.pong", function(server_tick, reason)
	set_status("> PONG serverTick=" .. tostring(server_tick) .. " reason=" .. tostring(reason), 0.3, 1.0, 0.3, 1.0)
end)

onServerEvent("srcc.showcase.state", function(server_tick, connected_clients)
	set_status("> STATE tick=" .. tostring(server_tick) .. " connectedClients=" .. tostring(connected_clients), 1.0, 0.85, 0.35, 1.0)
end)

onServerEvent("srcc.showcase.notice", function(text, server_tick)
	set_status("> NOTICE: " .. tostring(text) .. " @" .. tostring(server_tick), 1.0, 1.0, 0.35, 1.0)
end)

plugin:addEnableHandler(function()
	overlay_enabled = true
	overlay_lines = {}
	ticks = 0

	input:bind(bind_toggle_overlay, plugin.config.toggleOverlayScancode, function(_, toggled)
		if toggled then
			overlay_enabled = not overlay_enabled
			push_line("Overlay toggled: " .. tostring(overlay_enabled))
		end
	end, true, 5)

	input:bind(bind_ping_server, plugin.config.pingServerScancode, function(_, toggled)
		if toggled then
			emit("srcc.showcase.ping", "keybind_ping", ticks)
		end
	end, true, 5)

	input:bind(bind_request_state, plugin.config.requestStateScancode, function(_, toggled)
		if toggled then
			emit("srcc.showcase.request_state", ticks)
		end
	end, true, 5)

	blips:add("showcase_origin", {
		worldX = 0, worldZ = 0,
		r = 0.2, g = 0.9, b = 1.0, a = 1.0,
		size = 5, shape = blips.shape.diamond,
		clamp = true,
	})

	blips:add("showcase_arrow", {
		worldX = 50, worldZ = 50,
		r = 1.0, g = 0.35, b = 0.35, a = 1.0,
		size = 4, shape = blips.shape.arrow,
		yaw = math.pi / 4,
		clamp = true,
	})

	blips:add("showcase_square", {
		worldX = -50, worldZ = 30,
		r = 0.3, g = 1.0, b = 0.3, a = 1.0,
		size = 4, shape = blips.shape.square,
	})

	push_line("SRCC Showcase enabled")
	push_line("F6 toggle overlay | F7 ping server | F8 request state")

	emit("srcc.showcase.hello", client and client.serverAddress or "unknown", client and client.serverPort or 0)
end)

plugin:addDisableHandler(function()
	input:removeBind(bind_toggle_overlay)
	input:removeBind(bind_ping_server)
	input:removeBind(bind_request_state)

	blips:remove("showcase_origin")
	blips:remove("showcase_arrow")
	blips:remove("showcase_square")
end)

plugin:addHook("Logic", function()
	ticks = ticks + 1

	local local_human = client.human
	if local_human then
		local base_x = local_human.pos.x
		local base_z = local_human.pos.z

		blips:update("showcase_arrow", {
			worldX = base_x + 40,
			worldZ = base_z + 20,
			yaw = ticks * 0.03,
		})

		blips:update("showcase_square", {
			worldX = base_x - 30,
			worldZ = base_z + 10,
		})
	end
end)

plugin:addHook("DrawUI", function()
	if not overlay_enabled then
		return
	end

	local x = plugin.config.overlayX
	local y = plugin.config.overlayY
	local scale = plugin.config.textScale

	renderer:drawText("SRCC Showcase", x, y, scale, status_color[1], status_color[2], status_color[3], status_color[4], 0x20)
	y = y + plugin.config.textScale

	renderer:drawText(
		"Tick: " .. tostring(ticks) .. "  Server: " .. tostring(client.serverAddress) .. ":" .. tostring(client.serverPort),
		x,
		y,
		scale,
		0.85,
		0.85,
		0.85,
		1.0,
		0x20
	)
	y = y + plugin.config.textScale

	for i = 1, #overlay_lines do
		renderer:drawText(overlay_lines[i], x, y, scale, 1.0, 1.0, 1.0, 1.0, 0x20)
		y = y + plugin.config.textScale
	end
end)
