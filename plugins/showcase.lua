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

local overlayEnabled = true
local overlayLines = {}
local ticks = 0
local statusColor = { 0.3, 1.0, 0.3, 1.0 }

local bindToggleOverlay = "srcc_showcase_toggle_overlay"
local bindPingServer = "srcc_showcase_ping_server"
local bindRequestState = "srcc_showcase_request_state"

local function pushLine(text)
	table.insert(overlayLines, 1, tostring(text))
	while #overlayLines > 10 do
		table.remove(overlayLines)
	end
end

local function setStatus(text, r, g, b, a)
	pushLine(text)
	statusColor[1] = r or statusColor[1]
	statusColor[2] = g or statusColor[2]
	statusColor[3] = b or statusColor[3]
	statusColor[4] = a or statusColor[4]
end

local function emit(name, ...)
	local ok = emitServerEvent(name, ...)
	if ok then
		pushLine("emitServerEvent OK: " .. name)
	else
		setStatus("emitServerEvent FAILED: " .. name, 1.0, 0.35, 0.35, 1.0)
	end
end

onServerEvent("srcc.showcase.welcome", function(message, serverTick)
	setStatus("> WELCOME from server: " .. tostring(message) .. " @" .. tostring(serverTick), 0.2, 0.9, 1.0, 1.0)
end)

onServerEvent("srcc.showcase.pong", function(serverTick, reason)
	setStatus("> PONG serverTick=" .. tostring(serverTick) .. " reason=" .. tostring(reason), 0.3, 1.0, 0.3, 1.0)
end)

onServerEvent("srcc.showcase.state", function(serverTick, connectedClients)
	setStatus("> STATE tick=" .. tostring(serverTick) .. " connectedClients=" .. tostring(connectedClients), 1.0, 0.85, 0.35, 1.0)
end)

onServerEvent("srcc.showcase.notice", function(text, serverTick)
	setStatus("> NOTICE: " .. tostring(text) .. " @" .. tostring(serverTick), 1.0, 1.0, 0.35, 1.0)
end)

plugin:addEnableHandler(function()
	overlayEnabled = true
	overlayLines = {}
	ticks = 0

	input:bind(bindToggleOverlay, plugin.config.toggleOverlayScancode, function(_, toggled)
		if toggled then
			overlayEnabled = not overlayEnabled
			pushLine("Overlay toggled: " .. tostring(overlayEnabled))
		end
	end, true, 5)

	input:bind(bindPingServer, plugin.config.pingServerScancode, function(_, toggled)
		if toggled then
			emit("srcc.showcase.ping", "keybind_ping", ticks)
		end
	end, true, 5)

	input:bind(bindRequestState, plugin.config.requestStateScancode, function(_, toggled)
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

	pushLine("SRCC Showcase enabled")
	pushLine("F6 toggle overlay | F7 ping server | F8 request state")

	emit("srcc.showcase.hello", client and client.serverAddress or "unknown", client and client.serverPort or 0)
end)

plugin:addDisableHandler(function()
	input:removeBind(bindToggleOverlay)
	input:removeBind(bindPingServer)
	input:removeBind(bindRequestState)

	blips:remove("showcase_origin")
	blips:remove("showcase_arrow")
	blips:remove("showcase_square")
end)

plugin:addHook("Logic", function()
	ticks = ticks + 1

	local localHuman = client.human
	if localHuman then
		local baseX = localHuman.pos.x
		local baseZ = localHuman.pos.z

		blips:update("showcase_arrow", {
			worldX = baseX + 40,
			worldZ = baseZ + 20,
			yaw = ticks * 0.03,
		})

		blips:update("showcase_square", {
			worldX = baseX - 30,
			worldZ = baseZ + 10,
		})
	end
end)

plugin:addHook("DrawUI", function()
	if not overlayEnabled then
		return
	end

	local x = plugin.config.overlayX
	local y = plugin.config.overlayY
	local scale = plugin.config.textScale

	renderer:drawText("SRCC Showcase", x, y, scale, statusColor[1], statusColor[2], statusColor[3], statusColor[4], 0x20)
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

	for i = 1, #overlayLines do
		renderer:drawText(overlayLines[i], x, y, scale, 1.0, 1.0, 1.0, 1.0, 0x20)
		y = y + plugin.config.textScale
	end
end)
