local class = require("class")

local ctx_init = require("ctx")
local actions = require("actions_poll")
local view = require("view.view")
local ui_manager = require("ui_manager")
local event_handler = require("event_handler")
local keybind_load = require("keybind_load")

local UserInterface = class()

function UserInterface:new(game, mount_path)
	self.ctx = ctx_init(game, mount_path)
end

function UserInterface:load()
	-- apply default keybindings (runs once by the host after the UI is created)
	keybind_load(self.ctx)
end

function UserInterface:unload()
	self.ctx = nil
end

function UserInterface:receive(event)
	if event.name == "framestarted" or event.name == "update" then
		return
	end
	event_handler.receive(self.ctx, event)
end

function UserInterface:update(dt)
	self.ctx:update(dt)

	-- 1) feed this frame's queued events into input_state (pos/buttons/modifiers/delta/scroll)
	event_handler.process(self.ctx)

	actions(self.ctx)
	ui_manager.pointer_collision(self.ctx)
	view(self.ctx)
	ui_manager.align(self.ctx)

	-- 2) reset stored per-frame deltas and drive the button state machines
	self.ctx.input_state:reset()
end

function UserInterface:draw()
	ui_manager.draw(self.ctx)
end

return UserInterface
