---@type Plugin
local plugin = ...
plugin.name = "Pool"
plugin.author = "Sub Rosa Custom"
plugin.description = "Networked 8-ball pool client for the authoritative server pool mode."

local constants = plugin:require("constants")
local state = plugin:require("state")
local poolInput = plugin:require("input")
local render = plugin:require("render")

plugin.defaultConfig = constants.defaultConfig

local runtime = _G.__srccPoolClientRuntime or {
	initialized = false,
	activePlugin = nil,
	activeContext = nil,
}
_G.__srccPoolClientRuntime = runtime

local function activeContext()
	local activePlugin = runtime.activePlugin
	if not activePlugin or not activePlugin.isEnabled then
		return nil
	end

	return runtime.activeContext
end

local function installHandlers()
	if runtime.initialized then
		return
	end

	runtime.initialized = true

	onServerEvent(constants.EVENTS.state, function(data)
		local context = activeContext()
		if context then
			state.applySnapshot(context, data)
		end
	end)

	onServerEvent(constants.EVENTS.notice, function(data)
		local context = activeContext()
		if context then
			state.applyNotice(context, data)
		end
	end)
end

installHandlers()

plugin:addEnableHandler(function()
	local context = state.newContext()
	runtime.activePlugin = plugin
	runtime.activeContext = context

	state.ensureModelsLoaded(context)
	poolInput.bind(context, state)
	state.requestState(context, false)
end)

plugin:addDisableHandler(function()
	poolInput.unbind()

	local context = runtime.activeContext
	if context then
		state.restoreCamera(context)
		context.loadedModelIds = {}
	end

	if runtime.activePlugin == plugin then
		runtime.activePlugin = nil
		runtime.activeContext = nil
	end
end)

plugin:addHook("Logic", function()
	local context = activeContext()
	if not context then
		return
	end

	state.logicTick(context)
end)

plugin:addHook("RenderFrame", function()
	local context = activeContext()
	if not context then
		return
	end

	render.updateCamera(context, state)
	render.renderFrame(context, state)
end)

plugin:addHook("Draw3D", function()
	local context = activeContext()
	if not context then
		return
	end

	render.draw3D(context, state)
end)

plugin:addHook("DrawUI", function()
	local context = activeContext()
	if not context then
		return
	end

	render.drawUI(context, state)
end)
