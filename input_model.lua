local class = require("class")

local function format_input_mode(mode)
	return mode
		:gsub("key", "K")
		:gsub("scratch", "S")
		:gsub("pedal", "P")
end

local function get_input_mode_parts(mode)
	local parts = {}
	for count, input_type in mode:gmatch("([0-9]+)([a-z]+)") do
		parts[#parts + 1] = {
			count = tonumber(count),
			input_type = input_type,
		}
	end
	return parts
end

local function get_input_window(position, count)
	local first = math.max(1, position - 3)
	local last = math.min(count, first + 6)
	first = math.max(1, last - 6)
	return first, last
end

local function get_input_key_name(input_type, index)
	return input_type .. index
end

local function find_input_key(keys, index, special)
	for _, input_key in ipairs(keys) do
		if input_key.index == index and input_key.special == special then
			return input_key
		end
	end
	return nil
end

---@class ui.InputModel
---@operator call: ui.InputModel
local input_model = class()

input_model.all_standard = {
	"1key",
	"2key",
	"3key",
	"4key",
	"5key",
	"6key",
	"7key",
	"7key1scratch",
	"8key",
	"9key",
	"10key",
	"11key",
	"10key2scratch",
	"12key",
	"14key",
	"14key2scratch",
	"16key",
	"18key",
}
---@param game sphere.GameController
function input_model:new(game)
	assert(game, "input_model requires a game")
	assert(game.inputModel, "game.inputModel is required")
	self.game = game
	self.model = game.inputModel
	self.input_pos = 9
end

---@return string
function input_model:getCurrentInputMode()
	local select_controller = self.game.selectController
	assert(select_controller, "game.selectController is required")
	assert(select_controller.state, "game.selectController.state is required")
	assert(select_controller.state.inputMode, "game.selectController.state.inputMode is required")
	return tostring(select_controller.state.inputMode)
end

---@return string
function input_model:getInputMode()
	return self:getCurrentInputMode()
end

---@param mode string
---@return string[]
function input_model:getInputs(mode)
	assert(type(mode) == "string", "input mode must be a string")
	return self.model:getInputs(mode)
end

---@param mode string
---@return integer
function input_model:getBindsCount(mode)
	assert(type(mode) == "string", "input mode must be a string")
	return self.model:getBindsCount(mode)
end

---@param mode string
---@param virtual_key string
---@param row integer
---@return string?
function input_model:getKey(mode, virtual_key, row)
	assert(type(mode) == "string", "input mode must be a string")
	assert(type(virtual_key) == "string", "virtual key must be a string")
	assert(type(row) == "number", "binding row must be numeric")
	return self.model:getKey(mode, virtual_key, row)
end

---@param mode string
---@param virtual_key string
---@param row integer
---@param device string?
---@param id any?
---@param key string?
function input_model:setKey(mode, virtual_key, row, device, id, key)
	assert(type(mode) == "string", "input mode must be a string")
	assert(type(virtual_key) == "string", "virtual key must be a string")
	assert(type(row) == "number", "binding row must be numeric")
	if device ~= nil then
		assert(type(device) == "string", "input device must be a string")
	end
	if key ~= nil then
		assert(type(key) == "string", "input key must be a string")
	end
	return self.model:setKey(mode, virtual_key, row, device, id, key)
end

---@param virtual_key string
---@param row integer
---@return string?
function input_model:getCurrentKey(virtual_key, row)
	return self:getKey(self:getCurrentInputMode(), virtual_key, row)
end

---@param virtual_key string
---@param row integer
---@return string?
function input_model:getKeybind(virtual_key, row)
	return self:getCurrentKey(virtual_key, row)
end

---@param virtual_key string
---@param row integer
---@param device string?
---@param id any?
---@param key string?
function input_model:setCurrentKey(virtual_key, row, device, id, key)
	return self:setKey(self:getCurrentInputMode(), virtual_key, row, device, id, key)
end

---@param virtual_key string
---@param row integer
---@param device string?
---@param id any?
---@param key string?
function input_model:setKeybind(virtual_key, row, device, id, key)
	return self:setCurrentKey(virtual_key, row, device, id, key)
end

---@return {mode: string, display: string, keys: {index: integer, game_index: integer, special: boolean, key: string, keybind: string?}[]}[]
function input_model:getInputRows()
	local modes = self.all_standard
	local first, last = get_input_window(self.input_pos, #modes)
	local rows = {}

	for mode_index = first, last do
		local mode = modes[mode_index]
		local row = {
			mode = mode,
			display = format_input_mode(mode),
			keys = {},
		}
		local type_indexes = {
			key = 0,
			scratch = 0,
			pedal = 0,
		}
		local game_indexes = {}
		local parts = get_input_mode_parts(mode)

		local game_index = 0
		for _, part in ipairs(parts) do
			for _ = 1, part.count do
				type_indexes[part.input_type] = type_indexes[part.input_type] + 1
				game_index = game_index + 1
				local virtual_key = get_input_key_name(part.input_type, type_indexes[part.input_type])
				game_indexes[virtual_key] = game_index
			end
		end

		type_indexes = {
			key = 0,
			scratch = 0,
			pedal = 0,
		}
		for _, input_type in ipairs({ "scratch", "pedal", "key" }) do
			for _, part in ipairs(parts) do
				if part.input_type == input_type then
					for _ = 1, part.count do
						type_indexes[input_type] = type_indexes[input_type] + 1
						local index = type_indexes[input_type]
						local virtual_key = get_input_key_name(input_type, index)
						local keybind = self:getKey(mode, virtual_key, 1)
						row.keys[#row.keys + 1] = {
							index = index,
							game_index = game_indexes[virtual_key],
							special = input_type ~= "key",
							key = virtual_key,
							keybind = keybind,
						}
					end
				end
			end
		end

		rows[#rows + 1] = row
	end

	return rows
end

---@param row {mode: string, display: string, keys: table[]}
---@param index integer
---@param special boolean
---@param bind_row integer
---@param device string?
---@param id any?
---@param key string?
function input_model:setInputKey(row, index, special, bind_row, device, id, key)
	assert(type(row) == "table", "input row must be a table")
	assert(type(row.mode) == "string", "input row mode must be a string")
	assert(type(index) == "number", "input key index must be numeric")
	assert(type(special) == "boolean", "input key special flag must be boolean")
	assert(type(bind_row) == "number", "binding row must be numeric")
	assert(type(row.keys) == "table", "input row keys must be a table")
	local input_key = find_input_key(row.keys, index, special)
	assert(input_key, "input key index is out of range")
	assert(type(input_key.key) == "string", "input key must be a string")
	return self:setKey(row.mode, input_key.key, bind_row, device, id, key)
end

return input_model
