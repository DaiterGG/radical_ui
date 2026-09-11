-- icon registry: name -> Font Awesome codepoint (U+xxxx)
-- names preserved from figma_export.xml Vector names
local icons = {
	-- header row icons (top-row)
	["gameplay1"] = 0x0001,
	["gameplay2"] = 0x0002,
	["select1"] = 0x0003,
	["select2"] = 0x0004,
	["graphics1"] = 0x0005,
	["graphics2"] = 0x0006,
	["audio1"] = 0x0007,
	["audio2"] = 0x0008,
	["offsets1"] = 0x0009,
	["offsets2"] = 0x000B,
	["other2"] = 0x000C,
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

	["idle"] = 0x000C,
	["hover"] = 0x000B,
	["scroll"] = 0x000B,
	["press"] = 0x000B,
}

-- precompute ready UTF-8 glyph strings (no utf8 lib needed)
local glyphs = {}
for name, cp in pairs(icons) do
	glyphs[name] = string.char(cp)
end

return glyphs
