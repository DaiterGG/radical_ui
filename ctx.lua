local actions = require("actions")
local display_list = require("style_dispaly")
local input_state = require("input_state")
local keybinding = require("keybinding")
local fonts = require("fonts")
local class = require("class")

local ctx = class()

function ctx:new(game, mount_path)
	local w, h = love.graphics.getDimensions()
	local res = { w = w, h = h }
	local ui_scale = h / 1080

	self.game = game
	self.mountPath = mount_path
	self.action_queue = actions()
	self.event_queue = {} -- game events queued by receive(), drained each update
	self.res = res
	self.ui_scale = ui_scale
	self.display_list = display_list
	self.input_state = input_state()
	self.keybindings = keybinding()
	self.fonts = fonts.load(mount_path)
	self.ui = {
		need_to_realign = true,
		root_elements = {},
	}
	self.last_delta = 0.1
end

function ctx:update(dt)
	local w, h = love.graphics.getDimensions()
	local res = { w = w, h = h }
	local ui_scale = h / 1080

	self.dt = dt
	self.res = res
	self.ui_scale = ui_scale
end

return ctx
