local color = require("color")

-- display_list: display_key -> per-widget-type style data.
-- Ported from figma_export.xml (Page_4)
local display_list = {
  -- root takes the background widget
  root = {
    box = {
      bg = color(20, 20, 30, 255),
    },
  },

  -- header bar at top with blur
  header = {
    box = {
      bg = color(37, 35, 46, 255),
      border = { width = 1, color = color(14, 14, 18, 255) },
    },
  },

  -- header row icons (5 small icon glyphs)
  ["top-row-icon"] = {
    icon = {
      font = "glyphter1_20",
      size = 12,
      color = color(233, 233, 233, 255),
    },
  },

  -- scores-list panel background
  ["scores-list"] = {
    box = {
      bg = color(20, 20, 30, 20),
    },
  },

  -- scores-list header row (dark bg)
  ["scores-list-header-row"] = {
    box = {
      bg = color(0, 0, 0, 38),
    },
  },

  -- alternating row backgrounds
  ["scores-list-row-bg-odd"] = {
    box = {
      bg = color(0, 0, 0, 13),
    },
  },
  ["scores-list-row-bg-even"] = {
    box = {
      bg = color(0, 0, 0, 0),
    },
  },

  -- scores-list text
  ["scores-list-header"] = {
    text = {
      font = "afacad_bold",
      size = 15,
      color = color(233, 233, 233, 255),
    },
  },
  ["scores-list-row"] = {
    text = {
      font = "afacad_bold",
      size = 15,
      color = color(233, 233, 233, 255),
    },
  },

  -- refresh button on scores-list
  ["scores-list-refresh-btn"] = {
    button = {
      idle    = { bg = color(0, 0, 0, 38), border = { width = 1, radius = 5, color = color(0, 0, 0, 0) } },
      hovered = { bg = color(0, 0, 0, 50), border = { width = 1, radius = 5, color = color(0, 0, 0, 0) } },
      pressed = { bg = color(0, 0, 0, 25), border = { width = 1, radius = 5, color = color(0, 0, 0, 0) } },
    },
  },

  -- dif-select panel background (difficulty selection)
  ["dif-select"] = {
    box = {
      bg = color(0, 0, 0, 20),
      blur = { percent = 0.5, blurSize = 30 },
    },
  },

  -- dif-select text labels
  ["dif-select-name"] = {
    text = {
      font = "afacad_bold",
      size = 20,
      color = color(233, 233, 233, 255),
    },
  },
  ["dif-select-rating"] = {
    text = {
      font = "afacad_bold",
      size = 15,
      color = color(233, 233, 233, 255),
    },
  },
  ["dif-select-time"] = {
    text = {
      font = "afacad_bold",
      size = 15,
      color = color(233, 233, 233, 255),
    },
  },
  ["dif-select-author"] = {
    text = {
      font = "afacad_bold",
      size = 12,
      color = color(233, 233, 233, 255),
    },
  },

  -- folder-button on dif-select
  ["folder-button-bg"] = {
    button = {
      idle    = { bg = color(0, 0, 0, 38), border = { width = 1, radius = 5, color = color(0, 0, 0, 0) } },
      hovered = { bg = color(0, 0, 0, 50), border = { width = 1, radius = 5, color = color(0, 0, 0, 0) } },
      pressed = { bg = color(0, 0, 0, 25), border = { width = 1, radius = 5, color = color(0, 0, 0, 0) } },
    },
  },
  ["folder-button-icon"] = {
    icon = {
      font = "glyphter1_20",
      size = 26,
      color = color(199, 199, 199, 255),
    },
  },

  -- refresh-button on dif-select
  ["dif-refresh-button-bg"] = {
    button = {
      idle    = { bg = color(0, 0, 0, 38), border = { width = 1, radius = 5, color = color(0, 0, 0, 0) } },
      hovered = { bg = color(0, 0, 0, 50), border = { width = 1, radius = 5, color = color(0, 0, 0, 0) } },
      pressed = { bg = color(0, 0, 0, 25), border = { width = 1, radius = 5, color = color(0, 0, 0, 0) } },
    },
  },

  -- refresh icon (reused)
  ["refresh-button-icon"] = {
    icon = {
      font = "glyphter1_20",
      size = 28,
      color = color(199, 199, 199, 255),
    },
  },

  -- select-top panel (top-right with blur)
  ["select-top"] = {
    polyline = {
      { 0, 0 }, { 645, 0 }, { 645, 42 }, { 608, 84 }, { 41, 84 }, { 0, 41 },
    },
    box = {
      bg = color(41, 39, 51, 255),
      border = { width = 1, color = color(20, 21, 26, 255) },
      blur = { percent = 0.5, blurSize = 30 },
    },
  },

  -- select-top-center inset panel
  ["select-top-center"] = {
    polyline = {
      { 102, 0 }, { 228, 0 }, { 259, 31 }, { 284, 31 }, { 331, 79 }, { 0, 79 }, { 46, 30 }, { 71, 30 },
    },
    box = {
      bg = color(37, 35, 46, 255),
      blur = { percent = 0.5, blurSize = 30 },
    },
  },

  -- play row buttons background
  ["play-row"] = {
    box = {
      bg = color(41, 39, 51, 255),
      border = { width = 1, color = color(20, 21, 26, 255) },
      blur = { percent = 0.5, blurSize = 30 },
    },
  },

  -- play-center polygon button
  ["play-center"] = {
    polyline = {
      { 0, 0 }, { 291, 0 }, { 291, 36 }, { 267, 61 }, { 267, 128 }, { 40, 128 }, { 40, 100 }, { 0, 60 },
    },
    button = {
      idle    = { bg = color(37, 35, 46, 255), border = { width = 1, color = color(20, 21, 26, 255) } },
      hovered = { bg = color(45, 42, 56, 255), border = { width = 1, color = color(20, 21, 26, 255) } },
      pressed = { bg = color(30, 28, 40, 255), border = { width = 1, color = color(20, 21, 26, 255) } },
    },
  },

  -- play-row decorative separator lines
  ["play-row-separator"] = {
    box = {
      bg = color(0, 0, 0, 0),
      border = { width = 1, color = color(20, 21, 26, 255) },
    },
  },

  -- large text for bottom buttons
  ["text-large"] = {
    text = {
      font = "afacad_bold",
      size = 40,
      color = color(233, 233, 233, 255),
    },
  },
  ["text-play-large"] = {
    text = {
      font = "afacad_bold",
      size = 64,
      color = color(233, 233, 233, 255),
    },
  },

  -- chart_info text
  ["chart_info"] = {
    text = {
      font = "afacad_bold",
      size = 24,
      color = color(255, 255, 255, 255),
    },
  },

  -- Notes decoration frame
  ["Notes"] = {
    box = {
      bg = color(20, 20, 30, 0),
    },
  },

  -- floating note rectangles
  ["note-rectangle"] = {
    box = {
      bg = color(255, 255, 255, 255),
      border = { width = 1, radius = 2, color = color(0, 0, 0, 255) },
    },
  },

  -- main-middle/main-top polygon backgrounds (layered decor)
  ["main-top"] = {
    polyline = {
      { 0, 0 }, { 631, 0 }, { 631, 282 }, { 553, 356 }, { 0, 356 },
    },
    box = {
      bg = color(62, 62, 70, 148),
      border = { width = 1, color = color(0, 0, 0, 117) },
      blur = { percent = 0.5, blurSize = 30 },
    },
  },
  ["main-middle"] = {
    polyline = {
      { 0, 0 }, { 533, 0 }, { 533, 154 }, { 494, 196 }, { 494, 276 }, { 0, 276 },
    },
    box = {
      bg = color(62, 62, 70, 148),
      border = { width = 1, color = color(0, 0, 0, 117) },
      blur = { percent = 0.5, blurSize = 30 },
    },
  },
  ["main-bottom"] = {
    polyline = {
      { 0, 0 }, { 496, 0 }, { 535, 37 }, { 535, 101 }, { 572, 139 }, { 572, 276 }, { 0, 276 },
    },
    box = {
      bg = color(62, 62, 70, 148),
      border = { width = 1, color = color(0, 0, 0, 117) },
      blur = { percent = 0.5, blurSize = 30 },
    },
  },

  -- generic button template with icon
  icon = {
    icon = {
      font = "glyphter1_20",
      size = 20,
      color = color(233, 233, 233, 255),
    },
  },
  text = {
    text = {
      font = "glyphter1_20",
      size = 20,
      color = color(255, 255, 255, 255),
    },
  },

  -- old test entries (keep for now)
  poly = {
    polyline = { { 0, 0 }, { 300, 0 }, { 150, 150 }, { 300, 300 }, { 0, 300 } },
    box = {
      bg = color(200, 60, 60, 255),
      border = { width = 3, color = color(255, 255, 255, 255) },
    },
    button = {
      idle = { bg = color(100, 120, 180, 0), border = { width = 2, radius = 8, color = color(80, 100, 160, 255) } },
      hovered = { bg = color(120, 140, 200, 0), border = { width = 2, radius = 8, color = color(60, 80, 140, 255) } },
      pressed = { bg = color(80, 100, 160, 50), border = { width = 2, radius = 8, color = color(50, 70, 130, 255) } },
    },
  },
}

return display_list
