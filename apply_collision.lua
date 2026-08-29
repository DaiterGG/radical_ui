local function apply_collision(elem)
  local mx, my = love.mouse.getPosition()
  local r = elem.rect
  elem.pointer = r ~= nil and mx >= r.x and mx < r.x + r.w and my >= r.y and my < r.y + r.h
  return elem.pointer
end

return apply_collision
