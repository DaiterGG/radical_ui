local color = require("color")

local function theme()
	return {
		main_hover_c = color("#000000", 10),
		main_text = color("#cccccc"),
		glass_text = color("#FFFFFF"),
		main_font = "afacad_medium",
		international_font = "afacad_medium",
		main_accent = color("#26FF88"),
		main_panel = color("#25232E"),
		main_panel_br = color("#292733"),
		separator_main = color("#14151A"),
		glass_icons = color("#C7C7C7"),
		glass_stroke = color("#000000", 46),
		glass_list_element_dark = color("#000000", 5),
		glass_list_element_transparent = color("#000000", 0),
		glass_list_bg = color("#000000", 8),
		glass_scroll_bar = color("#000000", 8),
		glass_buttons_fill = color("#000000", 15),
		glass_table_header_fill = color("#000000", 15),
		separator_header = color("#0E0E12"),
		glass_bg_tint = color("#3E3E46", 58),
		glass_blur = { percent = 1, blurSize = 4 },
		glass_list_blur = { percent = 0.2, blurSize = 2, opacity = 0.35 },
		root_bg = color("#333333"),
		header_bg = color("#1e1d26"),
	}
end

local function display_data(theme)
	return {
		root = { box = { bg = theme.root_bg } },

		header = {
			box = {
				bg = theme.header_bg,
				border = { center = true, width = 1, color = theme.separator_header },
			},
		},
		header_back_b = {
			button = {
				idle = {
					bg = theme.header_bg,
					border = { center = true, width = 1, color = theme.separator_header },
				},
				held = {
					bg = theme.header_bg,
					border = { center = true, width = 1, color = theme.separator_header },
				},
				hovered = {
					bg = theme.main_hover_c,
				},
			},
		},
		header_left_b = {
			button = {
				idle = {
					bg = theme.header_bg,
					border = { center = true, width = 1, color = theme.separator_header },
				},
				hovered = {
					bg = theme.main_hover_c,
				},
			},
		},
		header_left_b_icons = {
			text = {
				idle = {
					font = "icons",
					size = 30,
					color = theme.main_text,
				},
				held = {
					font = "icons",
					size = 30,
					color = theme.main_accent,
				},
			},
		},
		header_input = {
			text_input = {
				bg = theme.header_bg,
				selected_bg = theme.header_bg,
				border = { center = true, width = 1, color = theme.separator_header, radius = 4 },
				bg_focused = theme.header_bg,
				border_focused = { center = true, width = 1, color = theme.separator_header, radius = 4 },
				font = theme.main_font,
				size = 18,
				text_color = theme.main_text,
				placeholder_color = theme.glass_icons,
				align_x = "center",
			},
		},
		test_p = {
			button = {
				idle = {
					bg = theme.main_panel_br,
					border = { center = true, width = 1, color = theme.separator_main },
				},
			},
		},
		first_b = {
			button = {
				idle = {
					bg = theme.main_panel_br,
					border = { center = true, width = 1, color = theme.separator_main },
				},
				hovered = {
					bg = theme.main_hover_c,
					border = { center = true, width = 1, color = theme.separator_main },
				},
				held = {
					bg = theme.main_panel,
					border = { center = true, width = 1, color = theme.separator_main },
				},
				pressed = {
					bg = theme.main_panel,
					border = { center = true, width = 1, color = theme.separator_main },
				},
			},
		},
		first_b_text = {
			text = {
				idle = {
					font = theme.main_font,
					size = 45,
					color = theme.main_text,
				},
				held = {
					font = theme.main_font,
					size = 45,
					color = theme.main_accent,
				},
			},
		},
		second_b_text = {
			text = {
				idle = {
					font = theme.main_font,
					size = 60,
					color = theme.main_text,
				},
				held = {
					font = theme.main_font,
					size = 60,
					color = theme.main_accent,
				},
			},
		},
		second_b = {
			button = {
				idle = {
					bg = theme.main_panel,
					border = { center = true, width = 1, color = theme.separator_main },
				},
				hovered = {
					bg = theme.main_hover_c,
					border = { center = true, width = 1, color = theme.separator_main },
				},
				held = {
					bg = theme.main_panel,
					border = { center = true, width = 1, color = theme.separator_main },
				},
				pressed = {
					bg = theme.main_panel,
					border = { center = true, width = 1, color = theme.separator_main },
				},
			},
		},
		third_b = {
			button = {
				idle = {
					bg = theme.main_panel_br,
					border = { center = true, width = 1, color = theme.separator_main },
				},
				hovered = {
					bg = theme.main_hover_c,
					border = { center = true, width = 1, color = theme.separator_main },
				},
				held = {
					bg = theme.main_panel_br,
					border = { center = true, width = 1, color = theme.separator_main },
				},
				pressed = {
					bg = theme.main_panel_br,
					border = { center = true, width = 1, color = theme.separator_main },
				},
			},
		},

		first_header_b = {
			button = {
				idle = {
					bg = theme.main_panel,
					border = { width = 1, color = theme.separator_main },
				},
			},
		},
		second_header_b = {
			button = {
				idle = {
					bg = theme.main_panel_br,
					border = { width = 1, color = theme.separator_main },
				},
			},
		},
		w_settings_tab_text_left = {

			text = {
				idle = {
					font = "custom",
					size = 70,
					align_x = "right",
					color = theme.main_text,
				},
				held = {
					font = "custom",
					size = 60,
					align_x = "right",
					color = theme.main_accent,
					line_gap = -500,
				},
			},
		},
		w_settings_tab_text_right = {
			text = {
				font = "custom",
				size = 70,
				color = theme.main_text,
				align_x = "left",
			},
		},
		w_settings_tab_left = {
			button = {
				bg = theme.glass_bg_tint,
				border = { width = 1, color = theme.glass_stroke },
			},
		},
		w_settings_tab_right = {
			button = {
				bg = theme.glass_bg_tint,
				border = { width = 1, color = theme.glass_stroke },
			},
		},
		w_settings_active_tab_text = {
			text = {
				font = theme.main_font,
				size = 50,
				color = theme.main_text,
			},
		},
		w_settings_active_tab = {
			box = {
				bg = theme.glass_bg_tint,
				blur = theme.glass_blur,
				border = { width = 1, color = theme.glass_stroke },
			},
		},
		w_header_dis = {
			box = {
				bg = theme.glass_bg_tint,
				blur = theme.glass_blur,
				border = { width = 1, color = theme.glass_stroke },
			},
		},
		w_main = {
			box = {
				bg = theme.main_panel_br,
				border = { width = 1, color = theme.separator_main },
			},
		},
		w_footer = {
			box = {
				bg = theme.glass_bg_tint,
				blur = theme.glass_blur,
				border = { width = 1, color = theme.glass_stroke },
			},
		},

		third_header_b = {
			button = {
				idle = {
					-- bg = theme.main_panel_br,
					border = { width = 1, color = theme.separator_main },
				},
				-- hovered = {
				-- 	bg = theme.main_hover_c,
				-- 	border = { center = true, width = 1, color = theme.separator_main },
				-- },
				-- held = {
				-- 	bg = theme.main_panel_br,
				-- 	border = { center = true, width = 1, color = theme.separator_main },
				-- },
				-- pressed = {
				-- 	bg = theme.main_panel_br,
				-- 	border = { center = true, width = 1, color = theme.separator_main },
				-- },
			},
		},
		main_list = {
			spring_list = {
			},
		},

		main_list_button = {
			button = {
        blur = theme.glass_blur,
				bg = theme.glass_bg_tint,
				border = { center = true, radius = 999, width = 1, color = theme.glass_stroke },
			},
		},
		main_list_selected = {
			box = {
				bg = theme.main_accent,
				border = { center = true, radius = 999, width = 1, color = theme.main_accent },
			},
		},
		main_list_title = {
			text = {
				font = theme.main_font,
				size = 30,
				align_x = "center",
				align_y = "center",
				color = theme.glass_text,
				downscale = 0.5,
			},
		},
		main_list_author = {
			text = {
				font = theme.international_font,
				size = 18,
				align_x = "center",
				align_y = "center",
				color = theme.glass_text,
				downscale = 0.5,
			},
		},

		right_footer_text = {
			text = {
				idle = {
					font = theme.main_font,
					size = 25,
					color = theme.main_text,
					line_gap = -5,
				},
				held = {
					font = theme.main_font,
					size = 25,
					line_gap = -5,
					color = theme.main_accent,
				},
			},
		},
		right_header_icon = {
			text = {
				idle = {
					font = "icons",
					size = 40,
					color = theme.main_text,
				},
				held = {
					font = "icons",
					size = 40,
					color = theme.main_accent,
				},
			},
		},

		up_panel = {
			box = {
				bg = theme.glass_bg_tint,
				blur = theme.glass_blur,
				border = { center = true, width = 1, color = theme.glass_stroke },
			},
		},
		top_list = {
			list_view = {
				bg = theme.glass_list_bg,
				blur = theme.glass_list_blur,
				scroll_speed = 0.4,
			},
		},
		top_table_header = {
			box = {
				bg = theme.glass_table_header_fill,
			},
		},
		top_table_row_dark = {
			box = {
				bg = theme.glass_list_element_dark,
			},
		},
		top_table_row_transparent = {
			box = {
				bg = theme.glass_list_element_transparent,
			},
		},
		top_table_header_text = {
			text = {
				font = theme.international_font,
				size = 18,
				align_x = "center",
				align_y = "center",
				color = theme.glass_text,
				-- downscale = 0.5,
			},
		},
		top_table_cell_text = {
			text = {
				font = theme.international_font,
				size = 18,
				align_x = "center",
				align_y = "center",
				color = theme.glass_text,
				-- downscale = 0.5,
			},
		},
		middle_panel = {
			box = {
				bg = theme.glass_bg_tint,
				blur = theme.glass_blur,
				border = { center = true, width = 1, color = theme.glass_stroke },
			},
		},
		down_panel = {
			box = {
				bg = theme.glass_bg_tint,
				blur = theme.glass_blur,
				border = { center = true, width = 1, color = theme.glass_stroke },
			},
		},
		down_list = {
			list_view = {
				bg = theme.glass_list_bg,
				blur = theme.glass_list_blur,
				scroll_speed = 0.4,
				scroll_bar = {
					width = 16,
					padding = 8,
				},
			},
		},
		down_list_item_dark = {
			box = {
				bg = theme.glass_list_element_dark,
			},
			text = {
				font = theme.international_font,
				size = 28,
				align_x = "left",
				align_y = "center",
				color = theme.glass_text,
			},
		},
		down_list_item_transparent = {
			box = {
				bg = theme.glass_list_element_transparent,
			},
			text = {
				font = theme.international_font,
				size = 28,
				align_x = "left",
				align_y = "center",
				color = theme.glass_text,
			},
		},
		down_list_item_name = {
			text = {
				font = theme.international_font,
				size = 28,
				align_x = "left",
				align_y = "center",
				color = theme.glass_text,
				downscale = 0.5,
			},
		},
		down_list_item_author = {
			text = {
				font = theme.international_font,
				size = 18,
				align_x = "left",
				align_y = "bottom",
				color = theme.glass_text,
				downscale = 0.5,
			},
		},
		down_list_item_keymod = {
			text = {
				font = theme.international_font,
				size = 22,
				align_x = "center",
				align_y = "top",
				color = theme.glass_text,
			},
		},
		down_list_item_dif = {
			text = {
				font = theme.main_font,
				size = 22,
				align_x = "center",
				align_y = "bottom",
				color = theme.glass_text,
			},
		},
		down_list_item_selected = {
			box = {
				bg = theme.main_accent,
				border = { center = true, radius = 999, width = 1, color = theme.main_accent },
			},
		},
		down_list_scrollbar = {
			box = {
				bg = theme.glass_scroll_bar,
			},
		},
	}
end

return {
	theme = theme,
	display_data = display_data,
}
