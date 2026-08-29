local apply_align = require("apply_align")
local apply_display = require("apply_display")
local apply_collision = require("apply_collision")

local function align_rec(elem)
  apply_align(elem)
  for i, child in ipairs(elem.children) do
    child.align.index = i
    align_rec(child)
  end
end

local function display_rec(elem)
  apply_display(elem)
  for i, child in ipairs(elem.children) do
    child.align.index = i
    display_rec(child)
  end
end

local function align(ctx)
  for i, root in ipairs(ctx.ui.root_elements) do
    root.align.index = i
    align_rec(root)
  end
end

local function collision_rec(elem)
  if apply_collision(elem) then
    return true
  end
  for i, child in ipairs(elem.children) do
    child.align.index = i
    if collision_rec(child) then
      return true
    end
  end
  return false
end

local function draw(ctx)
  for _, root in ipairs(ctx.ui.root_elements) do
    display_rec(root)
  end
end

local function pointer_collision(ctx)
  local hit = false
  for i, root in ipairs(ctx.ui.root_elements) do
    root.align.index = i
    if collision_rec(root) then
      hit = true
      break
    end
  end
  ctx.ui.pointer = hit
end

return { align = align, draw = draw, pointer_collision = pointer_collision }
