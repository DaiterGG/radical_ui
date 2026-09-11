local actions = require("actions")
local unils = require("utils")
local display_list = require("style_dispaly")
local input_state = require("input_state")
local keybinding = require("keybinding")
local fonts = require("fonts")
local class = require("class")
local animation_registry = require("animation_registry")
local widget_registry = require("widget_registry")
local beatmaps = require("beatmaps")
local cursor = require("cursor")

local ctx = class()

function ctx:new(game, mount_path)
	local w, h = love.graphics.getDimensions()
	local res = { w = w, h = h }
	self.game = game
	self.mountPath = mount_path
	self.beatmaps = beatmaps(game)
	self.action_queue = actions()
	self.event_queue = {} -- game events queued by receive(), drained each update
	self.res = res

	self.display_list = display_list
	self.input_state = input_state()
	self.keybindings = keybinding()
	self.fonts = fonts.load(love.graphics.getFont(), mount_path)
	self.cursor = cursor(self.fonts)
	self.ui = {
		custom_scale = 1,
		need_to_rebuild = true,
		need_to_realign = true,
		root_elements = {},
	}
	self.anim_reg = animation_registry.new()
	self.widget_reg = widget_registry.new()
	self.state = {
		-- active_window = "Settings",
		settings_tab = "Gameplay",
	}
	self.last_delta = 0.1

	local ui_scale = self.ui.custom_scale * h / 1080
	self.ui_scale = ui_scale
end

function ctx:update(dt)
	local w, h = love.graphics.getDimensions()
	local res = { w = w, h = h }
	local ui_scale = self.ui.custom_scale * h / 1080
	if w ~= self.res.w or h ~= self.res.h then
		print("new res:", res.w, res.h)
		print("ratio:", w / h)
		self.ui.need_to_rebuild = true
	end

	self.dt = dt
	self.res = res
	self.ui_scale = ui_scale
end

return ctx
