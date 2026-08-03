---@diagnostic disable: lowercase-global

---@alias main.blips.ShapeName "square"|"rectangle"|"diamond"|"circle"|"arrow"

---@class main.blips.BlipOptions
---@field worldX number World X coordinate
---@field worldZ number World Z coordinate
---@field r? number Red color component (0-1, default 1)
---@field g? number Green color component (0-1, default 1)
---@field b? number Blue color component (0-1, default 1)
---@field a? number Alpha component (0-1, default 1)
---@field size? number Blip size in map-space units (default 1.5)
---@field shape? main.blips.ShapeName Shape to render (default "square")
---@field yaw? number Rotation angle in radians (used by arrow/rectangle shapes)
---@field clamp? boolean Whether to clamp blip to minimap boundary (default false)
---@field icon? userdata PNG texture loaded with Texture.loadFromFile

---@class main.blips.Blip
---@field name string
---@field worldX number
---@field worldZ number
---@field r number
---@field g number
---@field b number
---@field a number
---@field size number
---@field shape main.blips.ShapeName
---@field yaw number
---@field clamp boolean
---@field icon? userdata

---@class main.blips.BlipsLib
---@field private _blips { [string]: main.blips.Blip }
blips = {
	_blips = {},
}

---@enum main.blips.Shape
blips.shape = {
	square = "square",
	rectangle = "rectangle",
	diamond = "diamond",
	circle = "circle",
	arrow = "arrow",
}

local default_blip_values = {
	r = 1,
	g = 1,
	b = 1,
	a = 1,
	size = 1.5,
	shape = "square",
	yaw = 0,
	clamp = false,
}

local blip_option_types = {
	worldX = "number",
	worldZ = "number",
	r = "number",
	g = "number",
	b = "number",
	a = "number",
	size = "number",
	shape = "string",
	yaw = "number",
	clamp = "boolean",
	icon = "userdata",
}

local function validate_options(options)
	for key, value in pairs(options) do
		local expected_type = blip_option_types[key]
		assert(expected_type, "invalid blip option: " .. tostring(key))
		assert(type(value) == expected_type, "blip " .. key .. " must be a " .. expected_type)
	end

	if options.shape ~= nil then
		assert(blips.shape[options.shape], "invalid blip shape: " .. tostring(options.shape))
	end
end

---Add a new blip to the minimap.
---@param name string Unique blip identifier
---@param options main.blips.BlipOptions Blip configuration
function blips:add(name, options)
	assert(type(name) == "string" and name ~= "", "blip name must be non-empty string")
	assert(type(options) == "table", "blip options must be a table")
	assert(type(options.worldX) == "number", "blip worldX must be a number")
	assert(type(options.worldZ) == "number", "blip worldZ must be a number")
	assert(not self._blips[name], "blip with the same name already exists: " .. name)
	validate_options(options)

	---@type main.blips.Blip
	local new_blip = {
		name = name,
		worldX = options.worldX,
		worldZ = options.worldZ,
		r = options.r or default_blip_values.r,
		g = options.g or default_blip_values.g,
		b = options.b or default_blip_values.b,
		a = options.a or default_blip_values.a,
		size = options.size or default_blip_values.size,
		shape = options.shape or default_blip_values.shape,
		yaw = options.yaw or default_blip_values.yaw,
		clamp = options.clamp ~= nil and options.clamp or default_blip_values.clamp,
		icon = options.icon,
	}

	self._blips[name] = new_blip
end

---Remove a blip from the minimap.
---@param name string Blip identifier to remove
function blips:remove(name)
	self._blips[name] = nil
end

---Update properties of an existing blip.
---@param name string Blip identifier to update
---@param options table Partial blip options to merge
function blips:update(name, options)
	local blip = self._blips[name]
	assert(blip, "blip not found: " .. tostring(name))
	assert(type(options) == "table", "blip options must be a table")

	validate_options(options)

	for key, value in pairs(options) do
		blip[key] = value
	end
end

---Get blip data by name.
---@param name string Blip identifier
---@return main.blips.Blip|nil blip The blip data, or nil if not found
function blips:get(name)
	return self._blips[name]
end

return blips
