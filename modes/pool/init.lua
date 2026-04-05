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
	active_context = nil,
}
_G.__srccPoolClientRuntime = runtime

local function active_context()
	local activePlugin = runtime.activePlugin
	if not activePlugin or not activePlugin.isEnabled then
		return nil
	end

	return runtime.active_context
end

local function install_handlers()
	if runtime.initialized then
		return
	end

	runtime.initialized = true

	onServerEvent(constants.EVENTS.state, function(snapshotBlob)
		local context = active_context()
		if context then
			state.applySnapshot(context, snapshotBlob)
		end
	end)

	onServerEvent(constants.EVENTS.notice, function(text)
		local context = active_context()
		if context then
			state.applyNotice(context, text)
		end
	end)
end

install_handlers()

plugin:addEnableHandler(function()
	local context = state.newContext()
	runtime.activePlugin = plugin
	runtime.active_context = context

	state.ensureModelsLoaded(context)
	poolInput.bind(context, state)
	state.requestState(context, false)
end)

plugin:addDisableHandler(function()
	poolInput.unbind()

	local context = runtime.active_context
	if context then
		state.restoreCamera(context)
		context.loadedModelIds = {}
	end

	if runtime.activePlugin == plugin then
		runtime.activePlugin = nil
		runtime.active_context = nil
	end
end)

plugin:addHook("Logic", function()
	local context = active_context()
	if not context then
		return
	end

	state.logicTick(context)
end)

plugin:addHook("RenderFrame", function()
	local context = active_context()
	if not context then
		return
	end

	render.updateCamera(context, state)
	render.renderFrame(context, state)
end)

plugin:addHook("PostRenderFrame", function()
	local context = active_context()
	if not context then
		return
	end

	render.drawDebug(context, state)
end)

plugin:addHook("Draw3D", function()
	local context = active_context()
	if not context then
		return
	end

	render.drawDebug(context, state)
end)

plugin:addHook("DrawUI", function()
	local context = active_context()
	if not context then
		return
	end

	render.drawUI(context, state)
end)
