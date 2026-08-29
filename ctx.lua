local actions = require("actions")
local display_init = require("style_dispaly")

local function ctx_init(game, mount_path)
  return {
    game = game,
    mountPath = mount_path,
    action_pump = actions(),
    ui = {
      need_to_realign = true,
      root_elements = {},
      display = display_init(),
    },
    last_delta = .1,
  }
end

return ctx_init
