-- icon registry: name -> Font Awesome codepoint (U+xxxx)
-- names preserved from figma_export.xml Vector names
local icons = {
	-- header row icons (top-row)
	["back1"] = 0x0023,
	["back2"] = 0x004A,
	["input1"] = 0x0052,
	["input2"] = 0x0036,
	["cog1"] = 0x0041,
	["brush1"] = 0x0071,
	["online1"] = 0x0051,
	["online2"] = 0x0061,

	["collections1"] = 0x0043,
	["sort1"] = 0x004E,
	["filter1"] = 0x0032,
	["filter2"] = 0x006F,
}

-- precompute ready UTF-8 glyph strings (no utf8 lib needed)
local glyphs = {}
for name, cp in pairs(icons) do
	glyphs[name] = string.char(cp)
end

return glyphs
