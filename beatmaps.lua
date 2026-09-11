local class = require("class")

local beatmaps = class()

function beatmaps:new(game)
	assert(game, "beatmaps.init requires a game")

	self.game = game
	self.select_model = assert(game.selectModel, "game.selectModel is required")
	self.select_controller = assert(game.selectController, "game.selectController is required")
	self.controller_loaded = false
end

function beatmaps:ensure_loaded()
	if self.controller_loaded then
		return
	end

	self.select_controller:load()
	self.controller_loaded = true
end

---@param first integer
---@param last integer
---@return table[]
function beatmaps:request_range(first, last)
	assert(type(first) == "number" and first % 1 == 0, "first must be an integer")
	assert(type(last) == "number" and last % 1 == 0, "last must be an integer")
	assert(first >= 1, "first must be greater than or equal to 1")
	assert(last >= first, "last must be greater than or equal to first")

	self:ensure_loaded()

	local library = assert(self.select_model.noteChartSetLibrary, "noteChartSetLibrary is required")
	local items = library.items or {}
	local result = {}
	local end_index = math.min(last, #items)

	for index = first, end_index do
		result[#result + 1] = items[index]
	end

	return result
end

---@return integer
function beatmaps:len()
	self:ensure_loaded()

	local library = assert(self.select_model.noteChartSetLibrary, "noteChartSetLibrary is required")
	return #(library.items or {})
end

---@param index integer
function beatmaps:set_collection(index)
	assert(type(index) == "number" and index % 1 == 0, "index must be an integer")
	assert(index >= 1, "index must be greater than or equal to 1")

	self:ensure_loaded()
	self.select_model:scrollCollection(nil, index)
	self.select_model:noDebouncePullNoteChartSet()
end

---@param text string
function beatmaps:set_search(text)
	assert(type(text) == "string", "text must be a string")

	self:ensure_loaded()
	self.game.configModel.configs.select.filterString = text
	self.select_model:debouncePullNoteChartSet()
end

---@param sort_function string
function beatmaps:set_sort(sort_function)
	assert(type(sort_function) == "string", "sort_function must be a string")

	self:ensure_loaded()
	self.select_model:setSortFunction(sort_function)
end

---@param group string
---@param filter string
---@param enabled boolean
function beatmaps:set_filter(group, filter, enabled)
	assert(type(group) == "string", "group must be a string")
	assert(type(filter) == "string", "filter must be a string")
	assert(type(enabled) == "boolean", "enabled must be a boolean")

	self:ensure_loaded()
	self.select_model.filterModel:setFilter(group, filter, enabled)
end

function beatmaps:apply_filters()
	self:ensure_loaded()
	self.select_model.filterModel:apply()
	self.select_model:noDebouncePullNoteChartSet()
end

---@param enabled boolean
function beatmaps:set_grouping(enabled)
	assert(type(enabled) == "boolean", "enabled must be a boolean")

	self:ensure_loaded()
	self.game.configModel.configs.osu_ui.songSelect.groupCharts = enabled
	self.select_model:noDebouncePullNoteChartSet()
end

function beatmaps.init(game)
	return beatmaps(game)
end

return beatmaps
