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
				border = { center = true, width = 1, color = separator_header },
			},
			hovered = {
				bg = main_hover_c,
			},
		},
		text = header_text,
	},
	header_left_b = {
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
				bg = main_panel_br,
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
	w_settings_tab_text = {
		text = {
			font = "icons",
			size = 30,
			color = main_text,
		},
	},
	w_settings_tab_left = {
		button = {
			bg = glass_bg_tint,
			border = { width = 1, color = stroke_glass },
		},
	},
	w_settings_tab_right = {
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
		box = {
			bg = glass_bg_tint,
			border = { width = 1, color = stroke_glass },
		},
	},
	w_header_dis = {
		box = {
			bg = glass_bg_tint,
			border = { width = 1, color = stroke_glass },
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
			border = { width = 1, color = stroke_glass },
		},
	},

	third_header_b = {
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
