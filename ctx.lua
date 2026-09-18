local actions = require("actions")
local unils = require("utils")
local style = require("style_dispaly")
local input_state = require("input_state")
local keybinding = require("keybinding")
local fonts = require("fonts")
local class = require("class")
local animation_registry = require("animation_registry")
local widget_registry = require("widget_registry")
local beatmaps = require("beatmaps")
local cursor = require("cursor")
local GameplayAPI = require("game_api.Gameplay")
local GameAPI = require("game_api")
local settings = require("settings")

local ctx = class()

-- on game start
function ctx:new(game, mount_path)
	self.game = game
	self.mountPath = mount_path
	self.beatmaps = beatmaps(game)
	self.gameplay_api = GameplayAPI(game)
	self.game_api = GameAPI(game)
	self.action_queue = actions()
	self.event_queue = {}
	self.theme = style.theme()
	self.display_list = style.display_data(self.theme)
	self.input_state = input_state()
	self.keybindings = keybinding()
	self.fonts = fonts.load(love.graphics.getFont(), mount_path)
	self.anim_reg = animation_registry.new()
	self.widget_reg = widget_registry.new()
	self.settings = settings()
end

function ctx:on_load()
	self.cursor = cursor(self.fonts)
	local w, h = love.graphics.getDimensions()
	local res = { w = w, h = h }
	self.settings = self.settings:on_load()
	local ui_scale = self.settings.ui_settings.custom_scale * h / 1080
	self.state = {
		scene = "select",
		root_elements = {},
		need_to_rebuild = true,
		need_to_realign = true,
		active_window = "Settings",
		-- active_window = nil,
		res = res,
		settings_tab = "Menu",
		keybind_capture = nil,
		dif_selected = 1,
		last_delta = 0.1,
		ui_scale = ui_scale,
		background_canvas = nil,
		cursor_hidden = false,
	}
end

function ctx:update(dt)
	local w, h = love.graphics.getDimensions()
	local res = { w = w, h = h }
	local ui_scale = self.settings.ui_settings.custom_scale * h / 1080
	if w ~= self.state.res.w or h ~= self.state.res.h then
		print("new res:", res.w, res.h)
		print("ratio:", w / h)
		self.state.need_to_rebuild = true
		self.state.need_to_realign = true
	end

	self.state.last_delta = dt
	self.state.res = res
	self.state.ui_scale = ui_scale
end

return ctx
