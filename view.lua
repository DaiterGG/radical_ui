local ui_element = require("ui_element")
local background = require("background")
local box = require("box")
local button = require("button")
local text = require("text")
local icon = require("icon")
local icons = require("icons")
local align_mod = require("apply_align")

local Align = align_mod.Align
local Size = align_mod.Size

return function(ctx)
  if not ctx.ui.need_to_realign then return end
  ctx.ui.need_to_realign = false

  local root = ui_element:new("root", { background() })
  root.align = Align():absolute({
    pivot = { x = 0, y = 0 },
    parent_pivot = { x = 0, y = 0 },
    size = Size({ percentOfHor = 100, percentOfVert = 100 }),
  })

  -- header bar
  local header = ui_element:new("header", { box() })
  header.align = Align():absolute({
    pivot = { x = 0, y = 0 },
    parent_pivot = { x = 0, y = 0 },
    size = Size({ percentOfHor = 100, vertPixels = 44 }),
  })

  -- -- top-row icons as children of header
  -- for i, icon_key in ipairs({ "top-row_1", "top-row_2", "top-row_3", "top-row_4", "top-row_5" }) do
  --   local el = ui_element:new("top-row-icon", { icon(icons[icon_key]) })
  --   local px_x = 84 + (i - 1) * 117
  --   el.align = Align():absolute({
  --     pivot = { x = 0, y = 0 },
  --     parent_pivot = { x = px_x, y = 16 },
  --     size = Size({ horPixels = 18, vertPixels = 12 }),
  --   })
  --   ui_element:push_child(header, el)
  -- end

  ui_element:push_child(root, header)

  -- -- scores-list panel
  -- local scores_list = ui_element:new("scores-list", { box() })
  -- scores_list.align = Align():absolute({
  --   pivot = { x = 0, y = 0 },
  --   parent_pivot = { x = 2, y = 46 },
  --   size = Size({ horPixels = 552, vertPixels = 354 }),
  -- })

  -- -- header text inside scores-list
  -- local scores_header_text = ui_element:new("scores-list-header", { text("№     Player             Time         rating    rate   mode   accuracy   score     misses    difficulty") })
  -- scores_header_text.align = Align():absolute({
  --   pivot = { x = 0, y = 0 },
  --   parent_pivot = { x = 12, y = 0 },
  --   size = Size({ horPixels = 551, vertPixels = 37 }),
  -- })
  -- ui_element:push_child(scores_list, scores_header_text)

  -- -- sample score row inside scores-list
  -- local score_row_text = ui_element:new("scores-list-row", { text("1.      Daiter         1 day ago    10.2     1.00      8K       83.24%     8488       32            3.34") })
  -- score_row_text.align = Align():absolute({
  --   pivot = { x = 0, y = 0 },
  --   parent_pivot = { x = 12, y = 37 },
  --   size = Size({ horPixels = 551, vertPixels = 33 }),
  -- })
  -- ui_element:push_child(scores_list, score_row_text)

  -- -- refresh buttons inside scores-list (right side)
  -- for i, y_pos in ipairs({ 58, 119, 181 }) do
  --   local rel_y = y_pos - 46  -- relative to scores_list top
  --   local refresh_btn = ui_element:new("scores-list-refresh-btn", { button({ action = "refresh_scores" }) })
  --   refresh_btn.align = Align():absolute({
  --     pivot = { x = 0, y = 0 },
  --     parent_pivot = { x = 569 - 552, y = rel_y },
  --     size = Size({ horPixels = 48, vertPixels = 48 }),
  --   })
  --   local refresh_icon = ui_element:new("refresh-button-icon", { icon(icons["refresh-button"]) })
  --   refresh_icon.align = Align():absolute({
  --     pivot = { x = 50, y = 50 },
  --     parent_pivot = { x = 50, y = 50 },
  --     size = Size({ horPixels = 28, vertPixels = 28 }),
  --   })
  --   ui_element:push_child(refresh_btn, refresh_icon)
  --   ui_element:push_child(scores_list, refresh_btn)
  -- end

  -- ui_element:push_child(root, scores_list)

  -- -- chart_info text
  -- local chart_info_text = ui_element:new("chart_info", { text("chart info") })
  -- chart_info_text.align = Align():absolute({
  --   pivot = { x = 0, y = 0 },
  --   parent_pivot = { x = 13, y = 419 },
  --   size = Size({ horPixels = 299, vertPixels = 238 }),
  -- })
  -- ui_element:push_child(root, chart_info_text)

  -- -- dif-select panel
  -- local dif_select = ui_element:new("dif-select", { box() })
  -- dif_select.align = Align():absolute({
  --   pivot = { x = 0, y = 0 },
  --   parent_pivot = { x = -1, y = 669 },
  --   size = Size({ horPixels = 557, vertPixels = 282 }),
  -- })

  -- -- difficulty rows inside dif-select
  -- local dif_entries = {
  --   { name = "CS' Normal", rating = "2.9", time = "7K", author = "   by Aksha-   ", y = 681 },
  --   { name = "CS' Normal", rating = "4.5", time = "7K", author = "   by Aksha-   ", y = 731 },
  --   { name = "CS' Normal", rating = "5.1", time = "7K", author = "   by Aksha-   ", y = 780 },
  -- }

  -- for _, entry in ipairs(dif_entries) do
  --   local rel_y = entry.y - 669

  --   local name_text = ui_element:new("dif-select-name", { text(entry.name) })
  --   name_text.align = Align():absolute({
  --     pivot = { x = 0, y = 0 },
  --     parent_pivot = { x = 40, y = rel_y },
  --     size = Size({ horPixels = 397, vertPixels = 27 }),
  --   })
  --   ui_element:push_child(dif_select, name_text)

  --   local rating_text = ui_element:new("dif-select-rating", { text(entry.rating) })
  --   rating_text.align = Align():absolute({
  --     pivot = { x = 0, y = 0 },
  --     parent_pivot = { x = 439, y = rel_y },
  --     size = Size({ horPixels = 57, vertPixels = 18 }),
  --   })
  --   ui_element:push_child(dif_select, rating_text)

  --   local time_text = ui_element:new("dif-select-time", { text(entry.time) })
  --   time_text.align = Align():absolute({
  --     pivot = { x = 0, y = 0 },
  --     parent_pivot = { x = 439, y = rel_y },
  --     size = Size({ horPixels = 57, vertPixels = 18 }),
  --   })
  --   ui_element:push_child(dif_select, time_text)

  --   local author_text = ui_element:new("dif-select-author", { text(entry.author) })
  --   author_text.align = Align():absolute({
  --     pivot = { x = 0, y = 0 },
  --     parent_pivot = { x = 32, y = rel_y + 25 },
  --     size = Size({ horPixels = 60, vertPixels = 16 }),
  --   })
  --   ui_element:push_child(dif_select, author_text)
  -- end

  -- -- folder-button inside dif-select
  -- local folder_btn = ui_element:new("folder-button-bg", { button({ action = "open_folder" }) })
  -- folder_btn.align = Align():absolute({
  --   pivot = { x = 0, y = 0 },
  --   parent_pivot = { x = 508, y = 889 - 669 },
  --   size = Size({ horPixels = 48, vertPixels = 48 }),
  -- })
  -- local folder_icon = ui_element:new("folder-button-icon", { icon(icons["folder-button"]) })
  -- folder_icon.align = Align():absolute({
  --   pivot = { x = 50, y = 50 },
  --   parent_pivot = { x = 50, y = 50 },
  --   size = Size({ horPixels = 32, vertPixels = 26 }),
  -- })
  -- ui_element:push_child(folder_btn, folder_icon)
  -- ui_element:push_child(dif_select, folder_btn)

  -- -- refresh-button inside dif-select
  -- local dif_refresh_btn = ui_element:new("dif-refresh-button-bg", { button({ action = "refresh_difficulties" }) })
  -- dif_refresh_btn.align = Align():absolute({
  --   pivot = { x = 0, y = 0 },
  --   parent_pivot = { x = 508, y = 829 - 669 },
  --   size = Size({ horPixels = 48, vertPixels = 48 }),
  -- })
  -- local dif_refresh_icon = ui_element:new("refresh-button-icon", { icon(icons["refresh-button"]) })
  -- dif_refresh_icon.align = Align():absolute({
  --   pivot = { x = 50, y = 50 },
  --   parent_pivot = { x = 50, y = 50 },
  --   size = Size({ horPixels = 28, vertPixels = 29 }),
  -- })
  -- ui_element:push_child(dif_refresh_btn, dif_refresh_icon)
  -- ui_element:push_child(dif_select, dif_refresh_btn)

  -- ui_element:push_child(root, dif_select)

  -- -- select-top panel (top-right)
  -- local select_top = ui_element:new("select-top", { box() })
  -- select_top.align = Align():absolute({
  --   pivot = { x = 0, y = 0 },
  --   parent_pivot = { x = 1275, y = 43 },
  --   size = Size({ horPixels = 645, vertPixels = 83 }),
  -- })

  -- -- select-top-center as child of select-top
  -- local select_top_center = ui_element:new("select-top-center", { box() })
  -- select_top_center.align = Align():absolute({
  --   pivot = { x = 0, y = 0 },
  --   parent_pivot = { x = 1432 - 1275, y = 45 - 43 },
  --   size = Size({ horPixels = 331, vertPixels = 79 }),
  -- })
  -- ui_element:push_child(select_top, select_top_center)

  -- ui_element:push_child(root, select_top)

  -- -- play-center polygon button
  -- local play_center_btn = ui_element:new("play-center", { button({ action = "play_game" }) })
  -- play_center_btn.align = Align():absolute({
  --   pivot = { x = 0, y = 0 },
  --   parent_pivot = { x = 240, y = 952 },
  --   size = Size({ horPixels = 291, vertPixels = 128 }),
  -- })

  -- -- play text inside play-center button
  -- local play_btn_text = ui_element:new("text-play-large", { text("Play") })
  -- play_btn_text.align = Align():absolute({
  --   pivot = { x = 50, y = 50 },
  --   parent_pivot = { x = 50, y = 50 },
  --   size = Size({ horPixels = 231, vertPixels = 129 }),
  -- })
  -- ui_element:push_child(play_center_btn, play_btn_text)

  -- ui_element:push_child(root, play_center_btn)

  -- -- input and mods text labels at bottom
  -- local input_btn_text = ui_element:new("text-large", { text("Input") })
  -- input_btn_text.align = Align():absolute({
  --   pivot = { x = 0, y = 0 },
  --   parent_pivot = { x = 0, y = 952 },
  --   size = Size({ horPixels = 240, vertPixels = 129 }),
  -- })
  -- ui_element:push_child(root, input_btn_text)

  -- local mods_btn_text = ui_element:new("text-large", { text("Mods") })
  -- mods_btn_text.align = Align():absolute({
  --   pivot = { x = 0, y = 0 },
  --   parent_pivot = { x = 502, y = 954 },
  --   size = Size({ horPixels = 252, vertPixels = 129 }),
  -- })
  -- ui_element:push_child(root, mods_btn_text)

  -- -- play-row separators
  -- local separator_left = ui_element:new("play-row-separator", { box() })
  -- separator_left.align = Align():absolute({
  --   pivot = { x = 0, y = 0 },
  --   parent_pivot = { x = 240, y = 951 },
  --   size = Size({ horPixels = 40, vertPixels = 129 }),
  -- })
  -- ui_element:push_child(root, separator_left)

  -- local separator_right = ui_element:new("play-row-separator", { box() })
  -- separator_right.align = Align():absolute({
  --   pivot = { x = 0, y = 0 },
  --   parent_pivot = { x = 507, y = 952 },
  --   size = Size({ horPixels = 24, vertPixels = 129 }),
  -- })
  -- ui_element:push_child(root, separator_right)

  -- -- Notes frame
  -- local notes_bg = ui_element:new("Notes", { box() })
  -- notes_bg.align = Align():absolute({
  --   pivot = { x = 0, y = 0 },
  --   parent_pivot = { x = 681, y = 71 },
  --   size = Size({ horPixels = 524, vertPixels = 974 }),
  -- })

  -- -- floating note rectangles as children of Notes
  -- local note_rects = {
  --   { x = 0, y = 171 }, { x = 262, y = 171 }, { x = 131, y = 0 },
  --   { x = 131, y = 486 }, { x = 393, y = 342 }, { x = 0, y = 630 },
  --   { x = 393, y = 630 }, { x = 131, y = 774 }, { x = 393, y = 922 },
  -- }
  -- for _, r in ipairs(note_rects) do
  --   local rect = ui_element:new("note-rectangle", { box() })
  --   rect.align = Align():absolute({
  --     pivot = { x = 0, y = 0 },
  --     parent_pivot = { x = r.x, y = r.y },
  --     size = Size({ horPixels = 131, vertPixels = 52 }),
  --   })
  --   ui_element:push_child(notes_bg, rect)
  -- end

  -- ui_element:push_child(root, notes_bg)

  ctx.ui.root_elements = { root }
end
