local class = require("class")

local utils = require("utils")
local ctx_init = require("ctx")
local actions = require("actions_poll")
local view = require("view.view")
local ui_manager = require("ui_manager")
local event_handler = require("event_handler")
local keybind_load = require("keybind_load")

local UserInterface = class()

function UserInterface:new(game, mount_path)
	self.ctx = ctx_init(game, mount_path)
	local font = love.graphics.getFont()
	love.graphics.setFont(font)
end

function UserInterface:load()
	love.keyboard.setKeyRepeat(true)

	-- apply default keybindings (runs once by the host after the UI is created)
	keybind_load(self.ctx)
	self.ctx.anim_reg:update("test_animation", "in", true)
	self.ctx.beatmaps:play_preview()

	-- view(self.ctx)
	-- ui_manager.align(self.ctx)
end

function UserInterface:unload()
	love.mouse.setVisible(true)
	love.mouse.setCursor()
	self.ctx = nil
end

function UserInterface:receive(event)
	if self.ctx.ui.scene == "gameplay" and self.ctx.gameplay_api.loaded then
		self.ctx.gameplay_api:receive(event)
	end

	if event.name == "framestarted" or event.name == "update" then
		return
	end
	event_handler.receive(self.ctx, event)
end

function UserInterface:update(dt)
	self.ctx:update(dt)

	if self.ctx.ui.scene == "gameplay" then
		self.ctx.gameplay_api:update(dt)
	else
		self.ctx.beatmaps:update()
	end

	-- 1) feed this frame's queued events into input_state (pos/buttons/modifiers/delta/scroll)
	event_handler.process(self.ctx)

	ui_manager.pointer_collision(self.ctx)
	actions(self.ctx)
	view(self.ctx)
	ui_manager.align(self.ctx)

	-- 2) reset stored per-frame deltas and drive the button state machines
	self.ctx.input_state:reset()
end

function UserInterface:draw()
	ui_manager.draw(self.ctx)
end

return UserInterface
