---@diagnostic disable: lowercase-global

---@alias main.input.BindToggleCallback fun(player: Player|nil, toggle: boolean)
---@alias main.input.BindCallback fun(player: Player|nil, state: main.input.State)

---@class main.input.KeyBind
---@field name string
---@field callback main.input.BindCallback|main.input.BindToggleCallback
---@field toggle boolean
---@field priority integer
---@field key integer
---@field order integer

---@class main.input.InputLib
---@field private _key_binds { [string]: main.input.KeyBind }
---@field private _sorted_binds { [integer]: string[] }
input = {
	_key_binds = {},
	_sorted_binds = {},
	_next_order = 0,
}

---@enum main.input.State
input.state = {
	begin = 0,
	ended = 1,
	current = 2,
}

function input:_sort_binds_for_key(key)
	table.sort(self._sorted_binds[key], function(a, b)
		local bind = input._key_binds[a]
		local other = input._key_binds[b]
		assert(bind and other, "keybind sorter missing bind")
		if bind.priority == other.priority then
			return bind.order < other.order
		end
		return bind.priority < other.priority
	end)
end

function input:_sort_new_bind(name)
	local bind_data = self._key_binds[name]
	assert(bind_data, "new keybind missing")

	if not self._sorted_binds[bind_data.key] then
		self._sorted_binds[bind_data.key] = {}
	end

	table.insert(self._sorted_binds[bind_data.key], name)
	self:_sort_binds_for_key(bind_data.key)
end

function input:_sort_remove_bind(name)
	local bind_data = self._key_binds[name]
	if not bind_data then
		return
	end

	for index, bind_name in ipairs(self._sorted_binds[bind_data.key] or {}) do
		if bind_name == name then
			table.remove(self._sorted_binds[bind_data.key], index)
			break
		end
	end
end

function input:bind(name, key, callback, toggle, priority)
	assert(type(name) == "string" and name ~= "", "bind name must be non-empty string")
	assert(type(key) == "number", "bind key must be number")
	assert(type(callback) == "function", "bind callback must be function")
	assert(not self._key_binds[name], "bind with the same name already exists: " .. name)

	if toggle == nil then
		toggle = true
	end

	---@type main.input.KeyBind
	self._next_order = self._next_order + 1
	local new_bind = {
		name = name,
		callback = callback,
		toggle = toggle,
		priority = priority or 100,
		key = key,
		order = self._next_order,
	}
	self._key_binds[name] = new_bind
	self:_sort_new_bind(name)
end

function input:removeBind(name)
	if not self._key_binds[name] then
		return
	end

	self:_sort_remove_bind(name)
	self._key_binds[name] = nil
end

local function trigger_toggle_binds_for_key(key, toggle, player)
	for _, bind in ipairs(input._sorted_binds[key] or {}) do
		local bind_data = input._key_binds[bind]
		if bind_data and bind_data.toggle then
			bind_data.callback(player, toggle)
		end
	end
end

local function trigger_binds_for_key(key, state, player)
	for _, bind in ipairs(input._sorted_binds[key] or {}) do
		local bind_data = input._key_binds[bind]
		if bind_data and not bind_data.toggle then
			bind_data.callback(player, state)
		end
	end
end

local function dispatch_key(scancode, key_state)
	local binds = input._sorted_binds[scancode]
	if not binds or #binds == 0 then
		return
	end

	local player = client and client.player or nil

	if key_state == KEY_PRESSED then
		trigger_toggle_binds_for_key(scancode, true, player)
		trigger_binds_for_key(scancode, input.state.begin, player)
	elseif key_state == KEY_DOWN then
		trigger_binds_for_key(scancode, input.state.current, player)
	elseif key_state == KEY_UP then
		trigger_toggle_binds_for_key(scancode, false, player)
		trigger_binds_for_key(scancode, input.state.ended, player)
	end
end

function input._dispatch(scancode, key_state)
	dispatch_key(scancode, key_state)
end

return input
