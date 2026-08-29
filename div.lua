local div = {}

-- generates a display data table with chainable style setters
function div.display(id)
  local elem = {
    display_id = id or "",
    style = {},
  }

  function elem.color(c)
    elem.style.color = c
    return elem
  end

  function elem.border(width, radius, c)
    elem.style.border = { width = width, radius = radius, color = c }
    return elem
  end

  return elem
end

return div
