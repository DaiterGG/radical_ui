-- ui_element(display_key, widgets)
-- display_key: string key from ctx.display_list
-- widgets: list of independent widget modules (box/button/slider)
local ui_element = {}

-- methods below take the element explicitly as `this`, so they work both
-- module-style (ui_element:draw(elem, ctx)) and instance-style
-- (elem:draw(ctx)) once attached in :new.

function ui_element:push_child(this, child)
  this.children[#this.children + 1] = child
end

-- draw one widget: if its display data is a state map (has an `idle` table)
-- iterate the element's active states, otherwise pass the plain data through.
local function draw_widget(w, this, ctx, data, entry)
  if not w.draw then return end
  if not (data and type(data.idle) == "table") then
    w:draw(this, ctx, data, entry)
    return
  end
  for state, active in pairs(this.states) do
    local state_data = active and data[state]
    if state_data then
      w:draw(this, ctx, state_data, entry)
    end
  end
end

-- draw this element's widgets (children are drawn by ui_manager recursion)
function ui_element:draw(this, ctx)
  local entry = ctx.display_list and ctx.display_list[this.display_key]
  for _, w in ipairs(this.widget) do
    draw_widget(w, this, ctx, entry and entry[w.type], entry)
  end
end

-- pointer pass: handle display states and return whether this element was
-- hit. recursion into children is done by the manager (mirrors quick-board's
-- UIElement::pointer_collision_rec).
function ui_element:pointer_collision(this, ctx, parent_hit)
  -- hit = parent was hit and pointer is within this element's rect
  local rect = this.rect
  local hit = parent_hit and rect ~= nil
      and ctx.input_state.pos.x >= rect.x and ctx.input_state.pos.x < rect.x + rect.w
      and ctx.input_state.pos.y >= rect.y and ctx.input_state.pos.y < rect.y + rect.h

  -- update display states (idle stays active as the base)
  this.states.hovered = hit
  this.states.pressed = hit and ctx.input_state.left == "pressed"
  this.states.held = hit and ctx.input_state.left == "held"
  this.states.released = hit and ctx.input_state.left == "released"

  -- widget-specific logic (widgets take (ctx, hit))
  for _, w in ipairs(this.widget) do
    if w.pointer_collision then
      w:pointer_collision(ctx, hit)
    end
  end

  return hit
end

-- factory: returns a plain element table with ui_element methods attached
function ui_element:new(display_key, widgets)
  local elem = {
    display_key = display_key,
    widget = widgets or {},
    align = nil,
    children = {},
    rect = nil,
    states = {
      idle = true,
      hovered = false,
      pressed = false,
      held = false,
      released = false,
    },
  }
  return elem
end

return ui_element
