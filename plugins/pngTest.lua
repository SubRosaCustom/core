---@type Plugin
local plugin = ...
plugin.name = "PNG Test"
plugin.author = "Sub Rosa Custom"
plugin.description = "Loads the jellybean texture, renders it, and shows detailed runtime state for debugging."

local imagePath = "jellybean"
local overlayX = 24
local overlayY = 24
local textScale = 14
local lineSpacing = 14
local panelWidth = 420
local panelHeight = 250
local retryIntervalTicks = 60
local worldPosition = Vector(2938.2, 25, 1538)
local worldSize = 3.0
local worldRotation = orientations.e

local texture = nil
local lastLoadError = "not attempted"
local loadAttempts = 0
local logicTicks = 0
local lastRetryTick = -1
local lastDrawOk = false
local textureAlignFlags = bit.bor(
	enum.renderer.textureAlign.center_x,
	enum.renderer.textureAlign.center_y
)
local worldTextureFlags = bit.bor(textureAlignFlags, 0x80)

local function stringify(value)
	if value == nil then
		return "nil"
	end
	return tostring(value)
end

local function tryLoadImage()
	loadAttempts = loadAttempts + 1
	lastRetryTick = logicTicks

	local ok, result = pcall(function()
		return Texture.loadFromFile(imagePath)
	end)

	if not ok then
		texture = nil
		lastLoadError = tostring(result)
		return false
	end

	texture = result
	if texture == nil then
		lastLoadError = "Texture.loadFromFile returned nil"
		return false
	end

	lastLoadError = "none"
	return true
end

local function shouldRetryLoad()
	if texture ~= nil then
		return false
	end

	if lastRetryTick < 0 then
		return true
	end

	return (logicTicks - lastRetryTick) >= retryIntervalTicks
end

local function drawLine(text, x, y)
	renderer:drawText(text, x, y, textScale, 1.0, 1.0, 1.0, 1.0, 0x20)
end

plugin:addEnableHandler(function()
	texture = nil
	lastLoadError = "not attempted"
	loadAttempts = 0
	logicTicks = 0
	lastRetryTick = -1
	lastDrawOk = false
	tryLoadImage()
end)

plugin:addHook("Logic", function()
	logicTicks = logicTicks + 1

	if shouldRetryLoad() then
		tryLoadImage()
	end
end)

plugin:addHook("Draw3D", function()
	lastDrawOk = false
	if not (texture and texture.isValid) then
		return
	end

	local pushOk, pushErr = pcall(function()
		renderer:pushWorldTransform(worldPosition, worldRotation)
	end)

	if not pushOk then
		lastLoadError = "pushWorldTransform error: " .. tostring(pushErr)
		return
	end

	local drawOk, drawResult = pcall(function()
		return renderer:drawTexture(
			texture,
			0.0,
			0.0,
			worldSize,
			worldSize,
			1.0,
			1.0,
			1.0,
			1.0,
			worldTextureFlags
		)
	end)

	local popOk, popErr = pcall(function()
		renderer:popWorldTransform()
	end)

	lastDrawOk = drawOk and drawResult == true and popOk

	if not drawOk then
		lastLoadError = "drawTexture error: " .. tostring(drawResult)
	elseif not popOk then
		lastLoadError = "popWorldTransform error: " .. tostring(popErr)
	else
		lastLoadError = "none"
	end
end)

plugin:addHook("DrawUI", function()
	local x = overlayX
	local y = overlayY

	renderer:drawRectangle2D(
		x - 8,
		y - 8,
		panelWidth,
		panelHeight,
		0.0,
		0.0,
		0.0,
		0.55
	)

	drawLine("PNG Test", x, y)
	y = y + lineSpacing
	drawLine("requestedPath: " .. stringify(imagePath), x, y)
	y = y + lineSpacing
	drawLine("logicTicks: " .. stringify(logicTicks), x, y)
	y = y + lineSpacing
	drawLine("loadAttempts: " .. stringify(loadAttempts), x, y)
	y = y + lineSpacing
	drawLine("lastLoadError: " .. stringify(lastLoadError), x, y)
	y = y + lineSpacing
	drawLine("image lua type: " .. type(image), x, y)
	y = y + lineSpacing
	drawLine("image tostring: " .. stringify(image), x, y)
	y = y + lineSpacing
	drawLine("image.class: " .. stringify(image and image.class), x, y)
	y = y + lineSpacing
	drawLine("image.isValid: " .. stringify(image and image.isValid), x, y)
	y = y + lineSpacing
	drawLine("image.atlas: " .. stringify(image and image.atlas), x, y)
	y = y + lineSpacing
	drawLine("image.id: " .. stringify(image and image.id), x, y)
	y = y + lineSpacing
	drawLine("image.width: " .. stringify(image and image.width), x, y)
	y = y + lineSpacing
	drawLine("image.height: " .. stringify(image and image.height), x, y)
	y = y + lineSpacing
	drawLine("image.path: " .. stringify(image and image.path), x, y)
	y = y + lineSpacing

	drawLine("drawTexture ok: " .. stringify(lastDrawOk), x, y)
	y = y + lineSpacing
	drawLine("world pos: (" .. worldPosition.x .. ", " .. worldPosition.y .. ", " .. worldPosition.z .. ")", x, y)
	y = y + lineSpacing
	drawLine("world size: " .. stringify(worldSize), x, y)
	y = y + lineSpacing
	drawLine("world flags: " .. stringify(worldTextureFlags), x, y)
end)
