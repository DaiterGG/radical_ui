local class = require("class")

local utils = require("utils")
local ctx = require("ctx")
local actions = require("actions_poll")
local load_keybindings = require("keybind_load")
local view = require("view.view")
local ui_manager = require("ui_manager")
local event_handler = require("event_handler")
local profiler = require("profiler")

local UserInterface = class()

function UserInterface:new(game, mount_path)
	print("new")
	self.ctx = ctx(game, mount_path)
	local font = love.graphics.getFont()
	love.graphics.setFont(font)
end

function UserInterface:load()
	print("load")
	love.keyboard.setKeyRepeat(true)

	self.ctx:on_load()
	load_keybindings(self.ctx)
	self.ctx.anim_reg:update("test_animation", "in", true)
	self.ctx.beatmaps:play_preview()
	self:activate_cursor()

	-- view(self.ctx)
	-- ui_manager.align(self.ctx)
end

function UserInterface:unload()
	self.ctx.beatmaps:unload()
	love.mouse.setVisible(true)
	love.mouse.setCursor()
end

function UserInterface:activate_cursor()
	if not self.ctx.state.cursor_hidden then
		love.mouse.setVisible(true)
	end
	self.ctx.cursor:set_state(self.ctx.cursor.state)
end

function UserInterface:receive(event)
	if self.ctx.state.scene == "gameplay" and self.ctx.gameplay_api.loaded then
		self.ctx.gameplay_api:receive(event)
	end

	if event.name == "framestarted" or event.name == "update" then
		return
	end
	event_handler.receive(self.ctx, event)
end

function UserInterface:update(dt)
	profiler.start()
	self.ctx:update(dt)
	self:activate_cursor()
	profiler.checkpoint("update", "after ctx_update")

	if self.ctx.state.scene == "gameplay" then
		self.ctx.gameplay_api:update(dt)
	else
		self.ctx.beatmaps:update(dt)
	end
	profiler.checkpoint("update", "after beatmaps_update")
	-- 1) feed this frame's queued events into input_state (pos/buttons/modifiers/delta/scroll)
	event_handler.process(self.ctx)
	profiler.checkpoint("update", "after event_handler")

	ui_manager.pointer_collision(self.ctx)
	profiler.checkpoint("update", "after pointer_collision")
	actions(self.ctx)
	profiler.checkpoint("update", "after actions")

	view(self.ctx)
	profiler.checkpoint("update", "after view")
	ui_manager.align(self.ctx)
	profiler.checkpoint("update", "after align")

	-- 2) reset stored per-frame deltas and drive the button state machines
	self.ctx.input_state:reset()
	profiler.checkpoint("update", "after input reset")
	profiler.finish(1, {
		-- "update" ,
		-- "main_view",
		-- "actions",
	})
end

function UserInterface:draw()
	ui_manager.draw(self.ctx)
end

return UserInterface
