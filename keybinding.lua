local class = require("class")

-- keybinding: simple key-combo -> action map.
--   kb.keys["ctrl+p"] = "open_settings"    -- direct binding
--   kb:rebind("open_settings", 1, "p")     -- change key #1 of an action
--   local action = kb:trigger("p", mods)   -- resolve a key press (mods optional)
--   kb:list()                              -- buffered { {action=.., keys={..}}, .. }
-- trigger flow (event -> keybinding):
--   modifiers on  -> try "mods+key" combo, and if that isn't bound fall back
--                    to the bare key
--   modifiers off -> just the bare key
local keybinding = class()

function keybinding:new()
	self._keys = {} -- [key_comb] = action
	self._actions = {} -- [action] = { count = n, [1..n] = key_comb }
	self._list = nil -- buffered list() output; rebuilt on any change

	-- assignable API: kb.keys[key_comb] = action (nil unbinds)
	self.keys = setmetatable({}, {
		__index = function(_, comb)
			return self._keys[comb]
		end,
		__newindex = function(_, comb, action)
			self:set(comb, action)
		end,
	})
end

-- bind/unbind a key combo directly (used by keys[...] assignment)
function keybinding:set(comb, action)
	local old = self._keys[comb]
	if old == action then
		return
	end
	if old then
		self:_remove_key(old, comb)
	end
	if action then
		self._keys[comb] = action
		self:_add_key(action, comb)
	else
		self._keys[comb] = nil
	end
	self:_invalidate()
end

-- replace the key at `pos` of an action's bindings (or append if the slot is
-- new). a key combo can only belong to one action.
function keybinding:rebind(action, pos, new_key)
	pos = pos or 1
	local a = self._actions[action]
	local old = a and a[pos] or nil

	if old == new_key then
		return
	end

	-- free new_key from whichever action currently owns it
	local prev_action = self._keys[new_key]
	if prev_action and prev_action ~= action then
		self:_remove_key(prev_action, new_key)
	end

	if old then
		self._keys[old] = nil
	end

	self._keys[new_key] = action

	if not a then
		a = { count = 0 }
		self._actions[action] = a
	end

	if old then
		a[pos] = new_key
	else
		a.count = a.count + 1
		a[a.count] = new_key
	end

	self:_invalidate()
end

-- resolve a key press to an action (see header for the modifier flow)
function keybinding:trigger(key, modifiers)
	if modifiers and (modifiers.shift or modifiers.ctrl or modifiers.alt or modifiers.super) then
		local action = self._keys[self:comb(modifiers, key)]
		if action then
			return action
		end
	end
	return self._keys[key]
end

-- resolve a non-repeating key press and enqueue its action
function keybinding:trigger_key(ctx, key, is_repeat)
	if is_repeat then
		return nil
	end
	local action = self:trigger(key, ctx.input_state.modifiers)
	if action then
		ctx.action_queue:register({
			action = action,
			key = key,
			modifiers = {
				shift = ctx.input_state.modifiers.shift,
				ctrl = ctx.input_state.modifiers.ctrl,
				alt = ctx.input_state.modifiers.alt,
				super = ctx.input_state.modifiers.super,
			},
		})
	end
	return action
end

-- canonical combo string, e.g. "ctrl+shift+p"
function keybinding:comb(modifiers, key)
	local parts = {}
	if modifiers.ctrl then
		parts[#parts + 1] = "ctrl"
	end
	if modifiers.shift then
		parts[#parts + 1] = "shift"
	end
	if modifiers.alt then
		parts[#parts + 1] = "alt"
	end
	if modifiers.super then
		parts[#parts + 1] = "super"
	end
	parts[#parts + 1] = key
	return table.concat(parts, "+")
end

-- buffered: recomputed only after a bind/rebind
function keybinding:list()
	if self._list then
		return self._list
	end
	local out = {}
	for action, a in pairs(self._actions) do
		local entry = { action = action, keys = {} }
		for i = 1, a.count do
			entry.keys[i] = a[i]
		end
		out[#out + 1] = entry
	end
	table.sort(out, function(x, y)
		return x.action < y.action
	end)
	self._list = out
	return out
end

-- internals ---------------------------------------------------------------

function keybinding:_add_key(action, comb)
	local a = self._actions[action]
	if not a then
		a = { count = 0 }
		self._actions[action] = a
	end
	for i = 1, a.count do
		if a[i] == comb then
			return
		end
	end
	a.count = a.count + 1
	a[a.count] = comb
end

function keybinding:_remove_key(action, comb)
	local a = self._actions[action]
	if not a then
		return
	end
	for i = 1, a.count do
		if a[i] == comb then
			for j = i, a.count - 1 do
				a[j] = a[j + 1]
			end
			a[a.count] = nil
			a.count = a.count - 1
			return
		end
	end
end

function keybinding:_invalidate()
	self._list = nil
end

return keybinding
