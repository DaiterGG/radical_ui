# Widgets

The UI is built from **widgets** placed inside **ui_elements**. A `ui_element` holds a
list of widgets plus a `display_key` that looks up its style in `ctx.display_list`.

- `ui_element:new(display_key, widgets)` — container with `align`, `children`, `rect`, `states`
- widgets are independent files: `box`, `button`, `icon`, `text`, `background`, `slider`
- every widget gets `(elem, ctx, data, entry)` in `draw` — `data` is its resolved style,
  `entry` is the whole display entry (shared fields like `polyline`)

```lua
local ui_element = require("ui_element")
local box = require("box")

local element = ui_element:new("top_bar", { box() })
element.align = Align():block("up", "20")   -- see Alignment below
ui_element:push_child(root, element)
```

---

## box

Plain rectangle: background + border (+ optional blur, optional polyline).

**Display data**
```lua
top_bar = {
  box = {
    bg = color(30, 30, 40, 255),                        -- fill
    border = { width = 1, radius = 5, color = color(80, 80, 100, 255) },
    -- blur = { percent = 0.2, blurSize = 2 },          -- frosted glass over the bg canvas
  },
},
```

**Usage**
```lua
local top_bar = ui_element:new("top_bar", { box() })
```

**Polyline variant** — add a shared `polyline` (raw px, scaled by `ui_scale`) to the entry;
box/button then draw that polygon instead of a rect:
```lua
poly = {
  polyline = { { 0, 0 }, { 300, 0 }, { 150, 150 }, { 300, 300 }, { 0, 300 } },
  box = { bg = color(200, 60, 60, 255), border = { width = 3, color = color(255, 255, 255, 255) } },
},
```

---

## button

Interactive (hover/press states). Pushes `action` into `ctx.action_queue` when pressed
(register the handler in `actions_poll.lua`). Optionally owns a **text or icon child element**
created in the view.

**Display data** — per-state:
```lua
btn_A = {
  button = {
    idle    = { bg = color(225, 225, 225, 255), border = { width = 1, radius = 8, color = color(200, 200, 200, 255) } },
    hovered = { bg = color(240, 240, 240, 255), border = { width = 2, radius = 8, color = color(100, 100, 100, 255) } },
    pressed = { bg = color(200, 200, 200, 255), border = { width = 2, radius = 8, color = color(80, 80, 80, 255) } },
  },
},
```

**Usage**
```lua
local label = ui_element:new("text", { text("A") })
local btn = ui_element:new("btn_A", { button({ action = "print_a", child = label }) })
```

---

## text

A line of text. Font name + size come from the display data.

**Display data**
```lua
text = {
  text = { font = "glyphter1_20", size = 20, color = color(255, 255, 255, 255) },
},
```

**Usage**
```lua
local label = ui_element:new("text", { text("Hello") })
```

---

## icon

A single icon glyph (or multi-char ligature) rendered with the icon font.
Codepoints live in `icons.lua` and are referenced by name.

**`icons.lua`**
```lua
local icons = {
  dailymotion = 0xE052,   -- from the font viewer's "unicode" field
}
```

**Display data**
```lua
icon = {
  icon = { font = "glyphter1_20", size = 20, color = color(255, 255, 255, 255) },
},
```

**Usage**
```lua
local icons = require("icons")
local el = ui_element:new("icon", { icon(icons.dailymotion) })
```

---

## background

Draws the chart background image (from `ctx.game.backgroundModel`) full-screen on the root
element, into a shared canvas (`ctx.ui.background_canvas`) so boxes can blur it.

**Usage** (usually the only widget on the root)
```lua
local root = ui_element:new("root", { background() })
```

---

## slider

Track + thumb, draggable value (thumb drawing / drag is `//TODO`).

**Display data**
```lua
slider = {
  slider = { bg = color(35, 35, 45, 255), border = { width = 1, radius = 5, color = color(70, 70, 90, 255) } },
},
```

**Usage**
```lua
local s = ui_element:new("slider", { slider({ min = 0, max = 100, value = 50 }) })
```

---

## Alignment

```lua
-- block: take a slice from one edge of the parent (percent or px strings)
Align():block("up", "20")                 -- 20% height from the top
Align():block("left", "25"):gap("2")      -- 25% width, 2% gap (to the next element, not to children)
Align():block("down", "15")               -- 15% height from the bottom

-- absolute: position by pivots + size
Align():absolute({
  pivot        = { x = 80, y = 80 },   -- which point of the element
  parent_pivot = { x = 80, y = 80 },   -- which point of the parent it aligns to
  size = Size({ percentOfHor = 30, percentOfVert = 30 }),
  -- size = Size({ justPixels = 30 }), -- fixed pixels (ui-scaled)
})
```

## Fonts

Register fonts in `fonts.lua`, then reference by name in display data:
```lua
local registrations = {
  glyphter1_20 = { file = "Glyphter.ttf", size = 20 },
  -- awesome = { file = "Font Awesome 7 Brands-Regular-400.otf", size = 20 },
}
```
`fonts:get("glyphter1_20", 32)` returns a cached `love.Font` at any size.
