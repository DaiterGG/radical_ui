local function apply_display(elem)
  love.graphics.print(elem.display_id or "", (elem.align.index or 0) * 80, 0)
end

return apply_display
