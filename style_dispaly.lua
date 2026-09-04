local color = require("color")

local main_hover_c = color("#000000", 1)
local main_text = color("#cccccc")
local main_panel = color("#25232E")
local main_panel_br = color("#292733")
local separator_main = color("#14151A")
local glass_icons = color("#C7C7C7")

local separator_header = color("#0E0E12")
local glass_bg_tint = color("#3E3E46", 58)
local header_text = {
	font = "icons",
	size = 40,
	color = main_text,
}

local display_list = {
	root = { box = { bg = color("#333333") } },

	header = {
		box = {
			bg = color("#1e1d26"),
			border = { center = true, width = 2, color = header_border },
		},
	},
	header_left_b = {
		button = {
			idle = {
				border = { center = true, width = 2, color = separator_header },
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
	first_b = {
		polyline = {
			{ 0, 0 },
			{ x_px = 220, y_px = 0 },
			{ x_px = 220, y_pc = 45 },
			{ x_px = 270, y_pc = 80 },
			{ x_px = 270, y_pc = 100 },
			{ x_px = 0, y_pc = 100 },
			{ 0, 0 },
		},
		button = {
			idle = {
				bg = main_panel_br,
				border = { center = true, width = 2, color = separator_main },
			},
		},
	},
	first_b_text = {
		text = {
			font = "afacad",
			size = 80,
			color = main_text,
		},
	},
	second_b_text = {
		text = {
			font = "afacad",
			size = 100,
			color = main_text,
		},
	},
	second_b = {
		button = {
			idle = {
				bg = main_panel,
				border = { center = true, width = 2, color = separator_main },
			},
		},
	},
	third_b = {
		button = {
			idle = {
				bg = main_panel_br,
				border = {
					left = { center = true, width = 2, color = separator_main },
					up = { center = false, width = 2, color = separator_main },
					down = { center = false, width = 2, color = separator_main },
					right = { center = true, width = 2, color = separator_main },
				},
			},
		},
	},
	up_panel = {
		-- polyline = {
		-- 	{ 0, 0 },
		-- 	{ 750, 0 },
		-- 	{ 750, 300 },
		-- 	{ 720, 330 },
		-- 	{ 0, 330 },
		-- },
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
