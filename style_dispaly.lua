local color = require("color")

local main_hover_c = color("#000000", 1)
local main_text = color("#cccccc")
local main_panel = color("#25232E")
local main_panel_br = color("#292733")
local separator_main = color("#14151A")
local glass_icons = color("#C7C7C7")
local stroke_glass = color("#000000", 46)
local glass_buttons_fill = color("#000000", 15)

local separator_header = color("#0E0E12")
local glass_bg_tint = color("#3E3E46", 58)
local header_text = {
	font = "icons",
	size = 35,
	color = main_text,
}

local display_list = {
	root = { box = { bg = color("#333333") } },

	header = {
		box = {
			bg = color("#1e1d26"),
			border = { center = true, width = 1, color = separator_header },
		},
	},
	header_back_b = {
		polyline = {
			{ x_px = 3, y_px = 1 },
			{ x_px = 120, y_px = 1 },
			{ x_px = 120, y_px = 30 },
			{ x_px = 140, y_px = 49 },
			{ x_px = 1, y_px = 49 },
			{ x_px = 1, y_px = 0 },
		},
		button = {
			idle = {
				border = { center = true, width = 1, color = separator_header },
			},
			hovered = {
				bg = main_hover_c,
			},
		},
		text = header_text,
	},
	header_left_b = {
		polyline = {
			{ x_px = -10, y_px = 1 },
			{ x_px = 120, y_px = 1 },
			{ x_px = 120, y_px = 30 },
			{ x_px = 140, y_px = 49 },
			{ x_px = 10, y_px = 49 },
			{ x_px = -10, y_px = 30 },
			{ x_px = -10, y_px = 0 },
		},
		button = {
			idle = {
				border = { center = true, width = 1, color = separator_header },
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
	test_p = {
		polyline = {
			{ x_px = 0, y_pc = 0 },
			{ x_px = 220, y_pc = 0 },
			{ x_px = 220, y_pc = 45 },
			-- { x_px = 270, y_pc = 100 },
			{ x_px = 320, y_pc = 100 },
			{ x_pc = 0, y_pc = 100, center = false },
			{ x_px = 0, y_px = 0, center = false },
		},
		button = {
			idle = {
				bg = main_panel_br,
				border = { center = true, width = 1, color = separator_main },
			},
		},
	},
	first_b = {
		polyline = {
			{ x_px = 1, y_px = 1 },
			{ x_px = 228, y_px = 1 },
			{ x_px = 228, y_px = 45 },
			{ x_px = 261, y_px = 80 },
			{ x_px = 261, y_px = 102 },
			{ x_px = 1, y_px = 102 },
			{ x_px = 1, y_px = 0 },
		},
		button = {
			idle = {
				bg = main_panel_br,
				border = { center = true, width = 1, color = separator_main },
			},
		},
	},
	first_b_text = {
		text = {
			font = "afacad_medium",
			size = 40,
			color = main_text,
		},
	},
	second_b_text = {
		text = {
			font = "afacad_medium",
			size = 55,
			color = main_text,
		},
	},
	second_b = {
		polyline = {
			{ x_px = -20, y_px = 1 },
			{ x_px = 285, y_px = 1 },
			{ x_px = 285, y_px = 25 },
			{ x_px = 265, y_px = 45 },
			{ x_px = 265, y_px = 102 },
			{ x_px = 15, y_px = 102 },
			{ x_px = 15, y_px = 80 },
			{ x_px = -20, y_px = 45 },
			{ x_px = -20, y_px = 0 },
		},
		button = {
			idle = {
				bg = main_panel,
				border = { center = true, width = 1, color = separator_main },
			},
		},
	},
	third_b = {

		polyline = {
			{ x_px = 15, y_px = 1 },
			{ x_px = 270, y_px = 1 },
			{ x_px = 270, y_px = 102 },
			{ x_px = -5, y_px = 102 },
			{ x_px = -5, y_px = 45 },
			{ x_px = 15, y_px = 25 },
			{ x_px = 15, y_px = 1 },
		},
		button = {
			idle = {
				bg = main_panel_br,
				border = { center = true, width = 1, color = separator_main },
			},
		},
	},
	up_panel = {
		polyline = {
			{ 0, 0 },
			{ 750, 0 },
			{ 750, 300 },
			{ 720, 330 },
			{ 0, 330 },
		},
		box = {
			bg = glass_bg_tint,
			border = { center = true, width = 1, color = separator_main }, -- TODO:
		},
	},
	middle_panel = {
		box = {
			bg = glass_bg_tint,
			border = { center = true, width = 1, color = separator_main }, -- TODO:
		},
	},
	down_panel = {
		box = {
			bg = glass_bg_tint,
			border = { center = true, width = 1, color = separator_main }, -- TODO:
		},
	},
}

return display_list
