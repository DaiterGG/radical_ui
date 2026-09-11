local color = require("color")

local main_hover_c = color("#000000", 10)
local main_text = color("#cccccc")
local main_accent = color("#26FF88")
-- local second_accent = color("#272531")
local main_panel = color("#25232E")
local main_panel_br = color("#292733")
local separator_main = color("#14151A")
local glass_icons = color("#C7C7C7")
local glass_stroke = color("#000000", 46)
local glass_list_element_dark = color("#000000", 5)
local glass_list_element_transparent = color("#000000", 0)
local glass_list_bg = color("#000000", 8)
local glass_scroll_bar = color("#000000", 8)
local glass_buttons_fill = color("#000000", 15)

local separator_header = color("#0E0E12")
local glass_bg_tint = color("#3E3E46", 58)

local display_list = {
	root = { box = { bg = color("#333333") } },

	header = {
		box = {
			bg = color("#1e1d26"),
			border = { center = true, width = 1, color = separator_header },
		},
	},
	header_back_b = {
		button = {
			idle = {
				bg = color("#1e1d26"),
				border = { center = true, width = 1, color = separator_header },
			},
			held = {
				bg = color("#1e1d26"),
				border = { center = true, width = 1, color = separator_header },
			},
			hovered = {
				bg = main_hover_c,
			},
		},
	},
	header_left_b = {
		button = {
			idle = {
				bg = color("#1e1d26"),
				border = { center = true, width = 1, color = separator_header },
			},
			hovered = {
				bg = main_hover_c,
			},
		},
	},
	header_left_b_icons = {
		text = {
			idle = {
				font = "icons",
				size = 30,
				color = main_text,
			},
			held = {
				font = "icons",
				size = 30,
				color = main_accent,
			},
		},
	},
	test_p = {
		button = {
			idle = {
				bg = main_panel_br,
				border = { center = true, width = 1, color = separator_main },
			},
		},
	},
	first_b = {
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
				bg = main_panel,
				border = { center = true, width = 1, color = separator_main },
			},
			pressed = {
				bg = main_panel,
				border = { center = true, width = 1, color = separator_main },
			},
		},
	},
	first_b_text = {
		text = {
			idle = {
				font = "afacad_bold",
				size = 45,
				color = main_text,
			},
			held = {
				font = "afacad_bold",
				size = 45,
				color = main_accent,
			},
		},
	},
	second_b_text = {
		text = {
			idle = {
				font = "afacad_bold",
				size = 60,
				color = main_text,
			},
			held = {
				font = "afacad_bold",
				size = 60,
				color = main_accent,
			},
		},
	},
	second_b = {
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
		button = {
			idle = {
				bg = main_panel,
				border = { width = 1, color = separator_main },
			},
		},
	},
	second_header_b = {
		button = {
			idle = {
				bg = main_panel_br,
				border = { width = 1, color = separator_main },
			},
		},
	},
	w_settings_tab_text_left = {

		text = {
			idle = {
				font = "custom",
				size = 70,
				align_x = "right",
				color = main_text,
			},
			held = {
				font = "custom",
				size = 60,
				align_x = "right",
				color = main_accent,
				line_gap = -500,
			},
		},
	},
	w_settings_tab_text_right = {
		text = {
			font = "custom",
			size = 70,
			color = main_text,
			align_x = "left",
		},
	},
	w_settings_tab_left = {
		button = {
			bg = glass_bg_tint,
			border = { width = 1, color = glass_stroke },
		},
	},
	w_settings_tab_right = {
		button = {
			bg = glass_bg_tint,
			border = { width = 1, color = glass_stroke },
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
		box = {
			bg = glass_bg_tint,
			border = { width = 1, color = glass_stroke },
		},
	},
	w_header_dis = {
		box = {
			bg = glass_bg_tint,
			border = { width = 1, color = glass_stroke },
		},
	},
	w_main = {
		box = {
			bg = main_panel_br,
			border = { width = 1, color = separator_main },
		},
	},
	w_footer = {
		box = {
			bg = glass_bg_tint,
			border = { width = 1, color = glass_stroke },
		},
	},

	third_header_b = {
		button = {
			idle = {
				-- bg = main_panel_br,
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
	main_list = { spring_list = {} },

	main_list_button = {
		button = {
			bg = glass_bg_tint,
			border = { center = true, radius = 999, width = 1, color = glass_stroke },
		},
	},
	main_list_title = {
		text = {
			font = "afacad_bold",
			size = 30,
			align_x = "center",
			align_y = "center",
			color = main_text,
			downscale = 0.5,
		},
	},
	main_list_author = {
		text = {
			font = "afacad_medium",
			size = 18,
			align_x = "center",
			align_y = "center",
			color = main_text,
			downscale = 0.5,
		},
	},

	right_footer_text = {
		text = {
			idle = {
				font = "afacad_bold",
				size = 25,
				color = main_text,
				line_gap = -5,
			},
			held = {
				font = "afacad_bold",
				size = 25,
				line_gap = -5,
				color = main_accent,
			},
		},
	},
	right_header_icon = {
		text = {
			idle = {
				font = "icons",
				size = 40,
				color = main_text,
			},
			held = {
				font = "icons",
				size = 40,
				color = main_accent,
			},
		},
	},

	up_panel = {
		box = {
			bg = glass_bg_tint,
			border = { center = true, width = 1, color = glass_stroke },
		},
	},
	middle_panel = {
		box = {
			bg = glass_bg_tint,
			border = { center = true, width = 1, color = glass_stroke },
		},
	},
	down_panel = {
		box = {
			bg = glass_bg_tint,
			border = { center = true, width = 1, color = glass_stroke },
		},
	},
	down_list = {
		list_view = {
			bg = glass_list_bg,
			scroll_speed = 0.4,
			scroll_bar = {
				width = 16,
				padding = 8,
			},
		},
	},
	down_list_item_dark = {
		box = {
			bg = glass_list_element_dark,
		},
		text = {
			font = "afacad_medium",
			size = 28,
			align_x = "left",
			align_y = "center",
			color = main_text,
		},
	},
	down_list_item_transparent = {
		box = {
			bg = glass_list_element_transparent,
		},
		text = {
			font = "afacad_medium",
			size = 28,
			align_x = "left",
			align_y = "center",
			color = main_text,
		},
	},
	down_list_scrollbar = {
		box = {
			bg = glass_scroll_bar,
		},
	},
}

return display_list
