local color = require("color")

local main_hover_c = color("#00000001")
local header_border = color("#111114")
local header_text = {
	font = "icons",
	size = 40,
	color = color("#cccccc"),
}

local display_list = {
	root = { box = { bg = "#333333" } },

	header = {
		box = {
			bg = color("#1e1d26"),
			border = { center = true, width = 2, color = header_border },
		},
	},
	header_left_b = {
		button = {
			idle = {
				border = { center = true, width = 2, color = header_border },
			},
			hovered = {
				bg = main_hover_c,
			},
		},
		text = header_text,
	},
	header_left_b_icons = {
		text = header_text,
	},
}

return display_list
