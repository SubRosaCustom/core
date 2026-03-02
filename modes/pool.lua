---@type Plugin
local plugin = ...
plugin.name = "Pool"
plugin.author = "Sub Rosa Custom"
plugin.description = "Playable 8-ball pool mode."
local constants = plugin:require("constants")
local state = plugin:require("state")
local physics = plugin:require("physics")
local poolInput = plugin:require("input")
local render = plugin:require("render")

plugin.defaultConfig = constants.defaultConfig

local context = state.newContext()

plugin:addEnableHandler(function()
	context = state.newContext()
	state.ensureModelsLoaded(context)
	poolInput.bind(context, state)
end)

plugin:addDisableHandler(function()
	poolInput.unbind()
	context.loadedModelIds = {}
end)

plugin:addHook("Logic", function()
	physics.logicTick(context, state)
end)

plugin:addHook("RenderFrame", function()
	render.renderFrame(context, state)
end)

plugin:addHook("DrawUI", function()
	render.drawUI(context)
end)
