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

-- encode a Unicode codepoint as a UTF-8 string (no utf8 lib needed).
-- used for Font Awesome icon glyphs, e.g. utils.utf8_char(0xE052)
function utils.utf8_char(cp)
  cp = tonumber(cp) or 0
  if cp < 0x80 then
    return string.char(cp)
  elseif cp < 0x800 then
    return string.char(0xC0 + math.floor(cp / 0x40), 0x80 + cp % 0x40)
  else
    return string.char(
      0xE0 + math.floor(cp / 0x1000),
      0x80 + math.floor(cp / 0x40) % 0x40,
      0x80 + cp % 0x40
    )
  end
end

function utils.display_init()
  return {
    elements = {},
  }
end

return utils
