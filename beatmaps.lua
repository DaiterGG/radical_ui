local class = require("class")
local profiler = require("profiler")

local PREVIEW_DELAY = 0.1

local beatmaps = class()

function beatmaps:new(game)
	assert(game, "beatmaps.init requires a game")

	self.game = game
	self.select_model = assert(game.selectModel, "game.selectModel is required")
	self.select_controller = assert(game.selectController, "game.selectController is required")
	self.controller_loaded = false
	self.selected_index = nil
	self.spring_list_data = nil
	self.cache = {}
	self.preview_timer = nil
end

function beatmaps:ensure_loaded()
	if self.controller_loaded then
		return
	end

	self.select_controller:load()
	self.controller_loaded = true
end

function beatmaps:unload()
	if not self.controller_loaded then
		return
	end

	self.select_controller:beginUnload()
	self.select_controller:unload()
	self.controller_loaded = false
end

function beatmaps:update(dt)
	self:ensure_loaded()
	if self.selected_index == nil then
		self.selected_index = self.select_model.chartview_set_index or 1
		self.spring_list_data = { scroll_to = self.selected_index }
	end
	self.select_controller:update()

	if self.preview_timer ~= nil then
		self.preview_timer = self.preview_timer - dt
		if self.preview_timer <= 0 then
			self.preview_timer = nil
			self.game.previewModel:loadPreview()
		end
	end
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

	for ind = first, last do
		if self.cache[ind] == nil then
			self.cache[ind] = items[ind] --library has native caching but it's broken or I don't understand it
		end
	end

	return self.cache
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

---@param index integer
function beatmaps:select(index)
	assert(type(index) == "number" and index % 1 == 0, "index must be an integer")
	assert(index >= 1, "index must be greater than or equal to 1")

	self:ensure_loaded()
	self.select_model:scrollNoteChartSet(nil, index)
	self.select_model:scrollNoteChart(nil, 1)
	self.selected_index = index
end

---@return integer?
function beatmaps:select_middle_difficulty()
	local difficulties = self:get_difficulties()
	local count = #difficulties
	if count == 0 then
		return nil
	end

	local index = math.floor((count + 1) / 2)
	self:select_difficulty(index)
	return index
end

---@return table?
function beatmaps:get_selected()
	self:ensure_loaded()

	local library = assert(self.select_model.noteChartSetLibrary, "noteChartSetLibrary is required")
	return (library.items or {})[self.selected_index]
end

---@return love.Image[]
function beatmaps:get_background_images()
	self:ensure_loaded()

	local background_model = self.game.backgroundModel
	return background_model and background_model.images or {}
end

---@return boolean
function beatmaps:has_background()
	local images = self:get_background_images()
	for index = 1, 2 do
		local image = images[index]
		if image then
			local width, height = image:getDimensions()
			if width > 1 and height > 1 then
				return true
			end
		end
	end
	return false
end

---@return string?
function beatmaps:get_background_image_path()
	self:ensure_loaded()

	local background_model = self.game.backgroundModel
	return background_model and background_model.path or nil
end

---@return number
function beatmaps:get_background_alpha()
	self:ensure_loaded()

	local background_model = self.game.backgroundModel
	return background_model and background_model.alpha or 1
end

---@return table[]
function beatmaps:get_difficulties()
	self:ensure_loaded()

	local library = assert(self.select_model.noteChartLibrary, "noteChartLibrary is required")
	return library.items or {}
end

---@return integer
function beatmaps:get_selected_difficulty()
	self:ensure_loaded()
	return self.select_model.chartview_index or 1
end

---@param index integer
function beatmaps:select_difficulty(index)
	assert(type(index) == "number" and index % 1 == 0, "index must be an integer")
	assert(index >= 1, "index must be greater than or equal to 1")

	self:ensure_loaded()
	self.select_model:scrollNoteChart(nil, index)
end

---@param beatmap_index integer
---@param difficulty_index integer
function beatmaps:reselect(beatmap_index, difficulty_index)
	assert(type(beatmap_index) == "number" and beatmap_index % 1 == 0, "beatmap_index must be an integer")
	assert(type(difficulty_index) == "number" and difficulty_index % 1 == 0, "difficulty_index must be an integer")
	assert(beatmap_index >= 1, "beatmap_index must be greater than or equal to 1")
	assert(difficulty_index >= 1, "difficulty_index must be greater than or equal to 1")

	self:ensure_loaded()
	self.select_model:scrollNoteChartSet(nil, beatmap_index)
	self.select_model:scrollNoteChart(nil, difficulty_index)
	self.select_model:noDebouncePullNoteChartSet()
	self.selected_index = beatmap_index
end

function beatmaps:play_preview()
	self.preview_timer = PREVIEW_DELAY
end

function beatmaps:stop_preview()
	self.preview_timer = nil
	self.game.previewModel:stop()
end

---@return table[]
function beatmaps:get_scores()
	self:ensure_loaded()

	local library = assert(self.select_model.scoreLibrary, "scoreLibrary is required")
	return library.items or {}
end

---@param index integer
function beatmaps:set_selected(index)
	assert(type(index) == "number" and index % 1 == 0, "index must be an integer")
	assert(index >= 1, "index must be greater than or equal to 1")

	self:select(index)
end

---@param index integer
---@return boolean
function beatmaps:is_selected(index)
	return self.selected_index == index
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

return beatmaps
