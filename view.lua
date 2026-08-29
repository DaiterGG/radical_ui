local ui_element = require("ui_element")

return function(ctx)
  if ctx.ui.need_to_realign then
    ctx.ui.need_to_realign = false
    ctx.ui.root_elements = { ui_element("test") }
  end
end
