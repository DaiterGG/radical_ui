local background = require("background")
local box = require("box")
local button = require("button")
local text = require("text")
local icon = require("icon")
local icons = require("icons")
local align_mod = require("apply_align")
local list_view = require("list_view")
local ui_manager = require("ui_manager")
local ui_element = require("ui_element")
local utils = require("utils")

local Align = align_mod.Align
local Size = align_mod.Size

return function(ctx)
	if not ctx.ui.need_to_realign then
		return
	end
	ctx.ui.need_to_realign = false

	local root = ui_element("root", { box() })
	root.align = Align():absolute({
		pivot = { x = 0, y = 0 },
		parent_pivot = { x = 0, y = 0 },
		size = Size({ per_hor = 100, per_vert = 100 }),
	})

	-- demo song items
	local songs = {
		"Alex Giudici - Reconstructing Science",
		"(execute.) - Ardolf",
		"Kaito - Nightcore Boost",
		"DJ Max - Poker Face",
		"Narupo - Hoshi",
		"Kobaryo - Hirogarissu Sky",
		"Tanchiky - Caramelldansen",
		"Cosmograph - Lullaby of the Void",
		"M-Project - Melt",
		"Kobojack - Kageboushi",
		"Zunko - Spiral",
		"Orangestar - Kagerou Daze",
		"Giga - Gigantic",
		"t+pazolite - Mekakucity Actors",
		"Neru - Mekakushi Dance",
		"Doll - Eureka",
		"HoneyWorks - Yume Utsutsu",
		"Yamajo - Rokudai no Gensou",
		"kemu - Hare Tokidoki Kurenai",
		"DECO*27 - Satsujin Banka",
		"Yorushika - Kizuna no Kiseki",
		"Ado - Usseewa",
		"Kenshi Yonezu - Kick Back",
		"YOASOBI - Idol",
		"LiSA - Gurenge",
	}

	local lv = list_view()

	local item_height = 48
	for _, title in ipairs(songs) do
		local item = ui_element("list_item", {
			button({ child = text(title) }),
		})

    item.align = Align():absolute({
      pivot = { x = 0, y = 0 },
      parent_pivot = { x = 0, y = 0 },
      size = Size({ per_hor = 100, px_vert = item_height }),
    })
		lv:add_child(item)
	end

	local list_elem = ui_element("scrollable_list", { lv })
	list_elem.align = Align():absolute({
		pivot = { x = 0, y = 0 },
		parent_pivot = { x = 0, y = 0 },
		size = Size({ px_hor = 400, px_vert = 500 }),
	})
  root:push_child(list_elem)

  -- utils.print(root)

	ctx.ui.root_elements = { root }

	ui_manager.align(ctx)
end
