local class = require("class")

local ctx_init = require("ctx")
local actions = require("actions_poll")
local view = require("view")
local ui_manager = require("ui_manager")

local UserInterface = class()

function UserInterface:new(game, mount_path)
  self.ctx = ctx_init(game, mount_path)
end

function UserInterface:load()
end

function UserInterface:unload()
  self.ctx = nil
end

function UserInterface:receive(event)
  if event.name == "framestarted" or event.name == "focus" then
    return
  end
  --TODO: handle keboards events with a event_handler; elseif event.name == "mousemoved" then

  -- self.ctx.action_queue:register(event.name)
end

function UserInterface:update(dt)
  self.ctx.last_delta = dt
  view(self.ctx)
  ui_manager.align(self.ctx)
  ui_manager.pointer_collision(self.ctx)
  actions(self.ctx)
end

function UserInterface:draw()
  ui_manager.draw(self.ctx)
end

return UserInterface
