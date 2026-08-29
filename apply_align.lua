local function apply_align(elem)
  local x = (elem.align.index or 0) * 80
  elem.rect = { x = x, y = 0, w = 80, h = 20 }
end

return apply_align
