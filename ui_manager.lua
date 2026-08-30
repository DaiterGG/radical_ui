local apply_align   = require("apply_align")
local apply_display = require("apply_display")
local ui_element    = require("ui_element")
local input_state   = require("input_state")

local function align_rec(elem, window, ctx)
  local rect = elem.align:apply(window, ctx.ui_scale)
  elem.rect = rect

  -- clone into available_window: children block aligns mutate their window,
  -- so they get a copy while elem.rect stays intact
  local available_window = { x = rect.x, y = rect.y, w = rect.w, h = rect.h }

  for i, child in ipairs(elem.children) do
    align_rec(child, available_window, ctx)
  end
end

local function display_rec(elem, ctx)
  ui_element:draw(elem, ctx)
  for i, child in ipairs(elem.children) do
    display_rec(child, ctx)
  end
end

local function align(ctx)
  local w, h = ctx.res.w or 800, ctx.res.h or 600
  local screen_window = { x = 0, y = 0, w = w, h = h }

  for i, root in ipairs(ctx.ui.root_elements) do
    root.align.index = i
    align_rec(root, screen_window, ctx)
  end
end

-- recursion is in the manager: each element handles its own state and
-- returns its hit, which is passed down to children as parent_hit
local function pointer_collision_rec(elem, ctx, parent_hit)
  local hit = ui_element:pointer_collision(elem, ctx, parent_hit)
  for _, child in ipairs(elem.children) do
    pointer_collision_rec(child, ctx, hit)
  end
  return hit
end

local function draw(ctx)
  for _, root in ipairs(ctx.ui.root_elements) do
    display_rec(root, ctx)
  end
end

local function pointer_collision(ctx)
  input_state:poll(ctx.input_state)

  local hit = false
  for _, root in ipairs(ctx.ui.root_elements) do
    hit = pointer_collision_rec(root, ctx, true) or hit
  end
  ctx.ui.pointer = hit
end

return { align = align, draw = draw, pointer_collision = pointer_collision }
