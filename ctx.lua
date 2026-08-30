local actions = require("actions")
local display_list = require("style_dispaly")
local input_state = require("input_state")
local fonts = require("fonts")

local function ctx_init(game, mount_path)
  local w, h = love.graphics.getDimensions()
  local res = { w = w, h = h }
  local ui_scale = h / 1080

  return {
    game = game,
    mountPath = mount_path,
    action_queue = actions(),
    res = res,
    ui_scale = ui_scale,
    display_list = display_list,
    input_state = input_state:new(),
    fonts = fonts.load(mount_path),
    ui = {
      need_to_realign = true,
      root_elements = {},
    },
    last_delta = .1,
  }
end

return ctx_init
