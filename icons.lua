-- icon registry: name -> Font Awesome codepoint (U+xxxx)
-- names preserved from figma_export.xml Vector names
local icons = {
	-- header row icons (top-row)
	["back1"] = 0x0023,
	["back2"] = 0x004A,
	["cog1"] = 0x0041,
	["brush1"] = 0x0067,
	["online1"] = 0x0061,
	["online2"] = 0x0058,
}

-- precompute ready UTF-8 glyph strings (no utf8 lib needed)
local glyphs = {}
for name, cp in pairs(icons) do
	glyphs[name] = string.char(cp)
end

return glyphs
