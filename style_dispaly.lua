local div = require("div")
local color = require("color")

local function display_init()
  return {
    button_left = div.display("button_left")
      .color(color(225, 225, 225, 255))
      .border(1, 10, color(200, 200, 200, 255)),
  }
end

return display_init
