local utils = {}

-- prints a value recursively; `seen` tracks visited tables to break loops
local function print_rec(value, indent, seen)
  local prefix = string.rep("  ", indent)
  if type(value) ~= "table" then
    print(prefix .. tostring(value))
    return
  end
  if seen[value] then
    print(prefix .. "<circular>")
    return
  end
  seen[value] = true

  print(prefix .. "{")
  for k, v in pairs(value) do
    if type(v) == "table" then
      print(prefix .. "  [" .. tostring(k) .. "] =")
      print_rec(v, indent + 1, seen)
    else
      print(prefix .. "  [" .. tostring(k) .. "] = " .. tostring(v))
    end
  end
  print(prefix .. "}")

  seen[value] = nil
end

function utils.print(value)
  print_rec(value, 0, {})
end

function utils.display_init()
  return {
    elements = {},
  }
end

return utils
