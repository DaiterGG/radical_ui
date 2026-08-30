local utils = require("utils")

-- icon registry: name -> Font Awesome codepoint (U+xxxx)
-- names preserved from figma_export.xml Vector names
local icons = {
  -- header row icons (top-row)
  ["top-row_1"]   = 0xE001,
  ["top-row_2"]   = 0xE002,
  ["top-row_3"]   = 0xE003,
  ["top-row_4"]   = 0xE004,
  ["top-row_5"]   = 0xE005,

  -- button action icons
  ["refresh-button"] = 0xF021,   -- refresh/cw icon
  ["folder-button"]  = 0xF07C,   -- folder icon
  ["edit-button"]    = 0xF044,   -- edit pencil icon

  -- decorative / shape icons
  ["Vector_5"]       = 0xF0D7,   -- right chevron
  ["Vector_9"]       = 0xF0D7,   -- right chevron
  ["Vector_10"]      = 0xF0D7,   -- right chevron
  ["Vector_11"]      = 0xF0D7,   -- right chevron
  ["Vector_12"]      = 0xF0D7,   -- right chevron

  -- legacy / existing
  dailymotion = 0x52,
}

-- precompute ready UTF-8 glyph strings (no utf8 lib needed)
local glyphs = {}
for name, cp in pairs(icons) do
  glyphs[name] = utils.utf8_char(cp)
end

return glyphs
