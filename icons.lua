-- icon registry: name -> Font Awesome codepoint (U+xxxx)
-- names preserved from figma_export.xml Vector names
local icons = {
	-- header row icons (top-row)
	["back1"] = 0x0023,
	["back2"] = 0x004A,
	["cog1"] = 0x0041,
}

-- encode a Unicode codepoint as a UTF-8 string (no utf8 lib needed).
-- used for Font Awesome icon glyphs, e.g. utils.utf8_char(0xE052)
local function utf8_char(cp)
	cp = tonumber(cp) or 0
	if cp < 0x80 then
		return string.char(cp)
	end
end

-- precompute ready UTF-8 glyph strings (no utf8 lib needed)
local glyphs = {}
for name, cp in pairs(icons) do
	glyphs[name] = string.char(cp)
end

return glyphs
