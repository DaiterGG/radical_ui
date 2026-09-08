local color = require("color")

local main_hover_c = color("#000000", 10)
local main_text = color("#cccccc")
local main_accent = color("#2b2936")
local second_accent = color("#272531")
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
	size = 30,
	color = main_text,
}

local w_header_active_w = 300
local w_header_tab_active_w = 400
local w_header_tab_w = 120
local w_header_tab_h = 60
local w_header_dis_w = 600
local w_footer_h = 90
local w_footer_w = 500
local w_footer_small_h = 40
local w_footer_small_w = 80
local w_hor = 1200
local w_up_chamf = 50
local w_down_chamf = 130
local w_vert = 900 - w_footer_h - w_footer_h

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
			{ 3, 1 },
			{ 120, 1 },
			{ 120, 27 },
			{ 137, 44 },
			{ 1, 44 },
			{ 1, 0 },
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
			{ -10, 1 },
			{ 120, 1 },
			{ 120, 27 },
			{ 137, 44 },
			{ 7, 44 },
			{ -10, 27 },
			{ -10, 0 },
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
			{ 1, 1 },
			{ 228, 1 },
			{ 228, 54 },
			{ 270, 96 },
			{ 270, 122 },
			{ 1, 122 },
			{ 1, 0 },
		},
		button = {
			idle = {
				bg = main_panel_br,
				border = { center = true, width = 1, color = separator_main },
			},
			hovered = {
				bg = main_hover_c,
				border = { center = true, width = 1, color = separator_main },
			},
			held = {
				bg = main_accent,
				border = { center = true, width = 1, color = separator_main },
			},
			pressed = {
				bg = main_accent,
				border = { center = true, width = 1, color = separator_main },
			},
		},
	},
	first_b_text = {
		text = {
			font = "afacad_bold",
			size = 45,
			color = main_text,
		},
	},
	second_b_text = {
		text = {
			idle = {
				font = "afacad_bold",
				size = 60,
				color = main_text,
			},
		},
	},
	second_b = {
		polyline = {
			{ -20, 1 },
			{ 285, 1 },
			{ 285, 30 },
			{ 270, 54 },
			{ 270, 122 },
			{ 22, 122 },
			{ 22, 96 },
			{ -20, 54 },
			{ -20, 0 },
		},
		button = {
			idle = {
				bg = main_panel,
				border = { center = true, width = 1, color = separator_main },
			},
			hovered = {
				bg = main_hover_c,
				border = { center = true, width = 1, color = separator_main },
			},
			held = {
				bg = main_panel,
				border = { center = true, width = 1, color = separator_main },
			},
			pressed = {
				bg = main_panel,
				border = { center = true, width = 1, color = separator_main },
			},
		},
	},
	third_b = {
		polyline = {
			{ 9, 1 },
			{ 200, 1 },
			{ 300, 122 },
			{ -18, 122 },
			{ -18, 54 },
			{ 9, 30 },
			{ 9, 1 },
		},
		button = {
			idle = {
				bg = main_panel_br,
				border = { center = true, width = 1, color = separator_main },
			},
			hovered = {
				bg = main_hover_c,
				border = { center = true, width = 1, color = separator_main },
			},
			held = {
				bg = main_panel_br,
				border = { center = true, width = 1, color = separator_main },
			},
			pressed = {
				bg = main_panel_br,
				border = { center = true, width = 1, color = separator_main },
			},
		},
	},

	first_header_b = {
		polyline = {
			{ 0, 0 },
			{ 200 + 71, 0 },
			{ 200 - 34 + 71, 34 },
			{ 200 - 34 - 25 + 71, 34 },
			{ 200 - 88 - 25 + 71, 88 },
			{ 44, 88 },
			{ 0, 44 },
			{ 0, 0 },
		},
		button = {
			idle = {
				bg = main_panel_br,
				border = { width = 1, color = separator_main },
			},
		},
	},
	second_header_b = {
		polyline = {
			{ 71, 0 }, --start point
			{ 71, 2 }, --start point
			{ 71, 3 }, --start point
		},
		button = {
			idle = {
				bg = main_panel_br,
				border = { width = 1, color = separator_main },
			},
		},
	},
	w_settings_tab_text = {
		text = {
			font = "icons",
			size = 30,
			color = main_text,
		},
	},
	w_settings_tab_left = {
		polyline = {
			{ 0, w_header_tab_h },
			{ w_header_tab_h, 0 },
			{ w_header_tab_w + w_header_tab_h, 0 },
			{ w_header_tab_w, w_header_tab_h },
			{ 0, w_header_tab_h },
		},
		button = {
			bg = glass_bg_tint,
			border = { width = 1, color = stroke_glass },
		},
	},
	w_settings_tab_right = {
		polyline = {
			{ -w_header_tab_h, 0 },
			{ -w_header_tab_h + w_header_tab_w, 0 },
			{ w_header_tab_w, w_header_tab_h },
			{ 0, w_header_tab_h },
			{ -w_header_tab_h, 0 },
		},
		button = {
			bg = glass_bg_tint,
			border = { width = 1, color = stroke_glass },
		},
	},
	w_settings_active_tab_text = {
		text = {
			font = "afacad_medium",
			size = 50,
			color = main_text,
		},
	},
	w_settings_active_tab = {
		polyline = {
			{ 0, w_footer_h },
			{ w_footer_h, 0 },
			{ w_header_tab_active_w - w_footer_h, 0 },
			{ w_header_tab_active_w, w_footer_h },
			{ 0, w_footer_h },
		},
		box = {
			bg = glass_bg_tint,
			border = { width = 1, color = stroke_glass },
		},
	},
	w_header_dis = {
		polyline = {
			{ 0, w_footer_h },
			{ w_footer_h, 0 },
			{ w_footer_h + w_header_active_w, 0 },
			{ w_footer_h + w_header_active_w + (w_footer_h - w_footer_small_h), (w_footer_h - w_footer_small_h) },
			{
				w_footer_h + w_header_active_w + (w_footer_h - w_footer_small_h) + w_header_dis_w,
				(w_footer_h - w_footer_small_h),
			},
			{ w_footer_h + w_header_active_w + w_footer_h + w_header_dis_w, w_footer_h },
			{ 0, w_footer_h },
		},
		box = {
			bg = glass_bg_tint,
			border = { width = 1, color = stroke_glass },
		},
	},
	w_main = {

		polyline = {
			{ 0, 0 },
			{ w_hor - w_up_chamf, 0 },
			{ w_hor, w_up_chamf },
			{ w_hor, w_vert },
			{ w_down_chamf, w_vert },
			{ 0, w_vert - w_down_chamf },
			{ 0, 0 },
		},
		box = {
			bg = main_panel_br,
			border = { width = 1, color = separator_main },
		},
	},
	w_footer = {
		polyline = {
			{ w_hor, 0 },
			{ w_hor - w_footer_h, w_footer_h },
			{ w_hor - w_footer_h - w_footer_w, w_footer_h },
			{ w_hor - w_footer_h - w_footer_w - (w_footer_h - w_footer_small_h), w_footer_small_h },
			{ w_hor - w_footer_h - w_footer_w - (w_footer_h - w_footer_small_h) - w_footer_small_w, w_footer_small_h },
			{ w_hor - w_footer_h - w_footer_w - (w_footer_h - w_footer_small_h) - w_footer_small_w, w_footer_small_h },
			{ w_hor - w_footer_h - w_footer_w - w_footer_h - w_footer_small_w, 0 },
			{ w_hor, 0 },
		},
		box = {
			bg = glass_bg_tint,
			border = { width = 1, color = stroke_glass },
		},
	},

	third_header_b = {
		polyline = {
			{ -71, 0 },
			{ 200, 0 },
			{ 200, 44 },
			{ 156, 88 },
			{ 44, 88 },
			{ -12, 34 },
			{ -37, 34 },
			{ -71, 0 },
		},
		button = {
			idle = {
				bg = main_panel_br,
				border = { width = 1, color = separator_main },
			},
			-- hovered = {
			-- 	bg = main_hover_c,
			-- 	border = { center = true, width = 1, color = separator_main },
			-- },
			-- held = {
			-- 	bg = main_panel_br,
			-- 	border = { center = true, width = 1, color = separator_main },
			-- },
			-- pressed = {
			-- 	bg = main_panel_br,
			-- 	border = { center = true, width = 1, color = separator_main },
			-- },
		},
	},

	right_header_icon = {
		text = {
			idle = {
				font = "icons",
				size = 40,
				color = main_text,
			},
		},
	},

	main_list = {
		main_list = {},
	},

	up_panel = {
		polyline = {
			{ 0, 0 },
			{ 700, 0 },
			{ 700, 264 },
			{ 600, 362 },
			{ 0, 362 },
			{ 0, 0 },
		},
		box = {
			bg = glass_bg_tint,
			border = { center = true, width = 1, color = separator_main }, -- TODO:
		},
	},
	middle_panel = {
		polyline = {
			{ 0, 0 },
			{ 580, 0 },
			{ 580, 130 },
			{ 540, 170 },
			{ 540, 272 },
			{ 0, 272 },
			{ 0, 0 },
		},
		box = {
			bg = glass_bg_tint,
			border = { center = true, width = 1, color = separator_main }, -- TODO:
		},
	},
	down_panel = {

		polyline = {
			{ 0, 0 },
			{ 540, 0 },
			{ 580, 40 },
			{ 580, 100 },
			{ 620, 140 },
			{ 620, 273 },
			{ 0, 273 },
			{ 0, 0 },
		},
		box = {
			bg = glass_bg_tint,
			border = { center = true, width = 1, color = separator_main }, -- TODO:
		},
	},
}

return display_list
