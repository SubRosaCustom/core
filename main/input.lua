---@diagnostic disable: lowercase-global

---@alias main.input.BindToggleCallback fun(player: Player|nil, toggle: boolean)
---@alias main.input.BindCallback fun(player: Player|nil, state: main.input.State)

---@class main.input.KeyBind
---@field name string
---@field callback main.input.BindCallback|main.input.BindToggleCallback
---@field toggle boolean
---@field priority integer
---@field key integer

---@class main.input.InputLib
---@field private _keyBinds { [string]: main.input.KeyBind }
---@field private _sortedBinds { [integer]: string[] }
input = {
	_keyBinds = {},
	_sortedBinds = {},
}

---@enum main.input.State
input.state = {
	begin = 0,
	ended = 1,
	current = 2,
}

function input:_sortBindsForKey(key)
	table.sort(self._sortedBinds[key], function(a, b)
		local bind = input._keyBinds[a]
		local other = input._keyBinds[b]
		assert(bind and other, "keybind sorter missing bind")
		return bind.priority < other.priority
	end)
end

function input:_sortNewBind(name)
	local bindData = self._keyBinds[name]
	assert(bindData, "new keybind missing")

	if not self._sortedBinds[bindData.key] then
		self._sortedBinds[bindData.key] = {}
	end

	table.insert(self._sortedBinds[bindData.key], name)
	self:_sortBindsForKey(bindData.key)
end

function input:_sortRemoveBind(name)
	local bindData = self._keyBinds[name]
	if not bindData then
		return
	end

	for idx, bindName in pairs(self._sortedBinds[bindData.key] or {}) do
		if bindName == name then
			table.remove(self._sortedBinds[bindData.key], idx)
			break
		end
	end
end

function input:bind(name, key, callback, toggle, priority)
	assert(type(name) == "string" and name ~= "", "bind name must be non-empty string")
	assert(type(key) == "number", "bind key must be number")
	assert(type(callback) == "function", "bind callback must be function")
	assert(not self._keyBinds[name], "bind with the same name already exists: " .. name)

	if toggle == nil then
		toggle = true
	end

	---@type main.input.KeyBind
	local newBind = {
		name = name,
		callback = callback,
		toggle = toggle,
		priority = priority or 100,
		key = key,
	}
	self._keyBinds[name] = newBind
	self:_sortNewBind(name)
end

function input:removeBind(name)
	if not self._keyBinds[name] then
		return
	end

	self:_sortRemoveBind(name)
	self._keyBinds[name] = nil
end

local function triggerToggleBindsForKey(key, toggle, player)
	for _, bind in pairs(input._sortedBinds[key] or {}) do
		local bindData = input._keyBinds[bind]
		if bindData and bindData.toggle then
			bindData.callback(player, toggle)
		end
	end
end

local function triggerBindsForKey(key, state, player)
	for _, bind in pairs(input._sortedBinds[key] or {}) do
		local bindData = input._keyBinds[bind]
		if bindData and not bindData.toggle then
			bindData.callback(player, state)
		end
	end
end

local function dispatchKey(scancode, keyState)
	local binds = input._sortedBinds[scancode]
	if not binds or #binds == 0 then
		return
	end

	local player = client and client.player or nil

	if keyState == KEY_PRESSED then
		triggerToggleBindsForKey(scancode, true, player)
		triggerBindsForKey(scancode, input.state.begin, player)
	elseif keyState == KEY_DOWN then
		triggerBindsForKey(scancode, input.state.current, player)
	elseif keyState == KEY_UP then
		triggerToggleBindsForKey(scancode, false, player)
		triggerBindsForKey(scancode, input.state.ended, player)
	end
end

function input._dispatch(scancode, keyState)
	dispatchKey(scancode, keyState)
end

return input
