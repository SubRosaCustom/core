---@diagnostic disable: lowercase-global
---@class main.DataTyper
data = {}

-- Formatted with class, type as strings
local data_format = "_typed_%s_%s"

---@generic T
---@param object Player|Human|Item|Vehicle|RigidBody|Account Object to access data from.
---@param dataType `T` Type of data to access in object.
---@return T data Returned data.
function data.get(object, data_type)
	local index = string.format(data_format, object.class, data_type)
	if not object.data[index] then
		object.data[index] = {}
	end

	return object.data[index]
end

---@generic T
---@param object Player|Human|Item|Vehicle|RigidBody|Account Object to set data for.
---@param dataType `T` Type of data to access in object.
---@param toSet table Data to set in object.
function data.set(object, data_type, to_set)
	local index = string.format(data_format, object.class, data_type)
	object.data[index] = to_set
end

---@generic T
---@param object Player|Human|Item|Vehicle|RigidBody|Account
---@param dataType `T` Type of data to access in object.
---@param key any Key to set in object data.
---@param value any Value to set in object data.
function data.setValue(object, data_type, key, value)
	local index = string.format(data_format, object.class, data_type)
	if not object.data[index] then
		object.data[index] = {}
	end

	object.data[index][key] = value
end
