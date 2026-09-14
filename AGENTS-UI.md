# UI quick reference

This documents only the UI options used by `view/main_view.lua` and
`style_dispaly.lua`.

## Alignment (`apply_align`)

### `absolute({ ... })`

Places an element inside its current parent window.

- `size = Size(...)`: element dimensions.
- `parent_pivot = { x, y }`: anchor point in the parent, percentages.
- `pivot = { x, y }`: anchor point in this element, percentages.

Both pivots use `0..100`: `0` = left/top, `50` = center, `100` =
right/bottom. The element is positioned by matching `pivot` to
`parent_pivot`.

Common examples:

```lua
-- Fill parent
size = Size({ pc_hor = 100, pc_vert = 100 })

-- Full width, fixed height, top-left
pivot = { x = 0, y = 0 }
parent_pivot = { x = 0, y = 0 }
size = Size({ pc_hor = 100, px_vert = 56 })

-- Fixed panel centered in parent
pivot = { x = 50, y = 50 }
parent_pivot = { x = 50, y = 50 }
size = Size({ px_hor = 638, pc_vert = 100 })
```

### `block(direction, length)`

Takes a strip from the current parent window and gives that strip to the
element.

- `Direction.Left` / `Right`: consumes width.
- `Direction.Up` / `Down`: consumes height.
- `{ pc = n }`: percentage of the current parent axis.
- `{ px = n }`: UI-scaled pixels.

`Left` and `Up` consume from the beginning of the parent: left and top.
`Right` and `Down` consume from the end of the parent: right and bottom.
Sibling order matters: each recursive child is aligned against the remaining
window after earlier block children.

For a top-to-bottom layout, put the top element first and use
`Direction.Up`, then let the next element consume the remaining space with
`Direction.Down`:

```lua
local header = ui_element({
	align = block(Direction.Up, { px = 42 }),
})
local list = ui_element({
	align = block(Direction.Down, { pc = 100 }),
})
parent:push_child(header)
parent:push_child(list)
```

Examples:

```lua
align = block(Direction.Up, { px = 44 }) -- fixed top strip
align = block(Direction.Down, { pc = 12 }) -- bottom strip
align = block(Direction.Left, { pc = 33 }) -- left third
```

### `Size({ ... })`

- `pc_hor`, `pc_vert`: percentage of parent width/height.
- `px_hor`, `px_vert`: UI-scaled pixels.
- `pc`: both axes as percentages.
- `px`: both axes as pixels.

Mixed sizes are normal, for example
`Size({ pc_hor = 100, px_vert = 56 })`.

### `:gap({ pc = n })` / `:gap({ px = n })`

Adds space after a `Block` element before the remaining window is passed to
the next sibling. It is not used by the current `main_view.lua` layouts.

### `:animation({ ... })`

Moves/resizes an absolute element during a registered transition.

- `key`: animation registry key.
- `delta_pos = { x, y }`: movement in UI-scaled pixels.
- `delta_size = { w, h }`: size change.
- `ease_fn`: `"in"`, `"out"`, or `"in_out"`.
- `length_ms`: duration in milliseconds.

The layout is recalculated each frame until the transition ends. In
`main_view.lua`, `left_p` and `right_p` animate horizontally.

## Recursive alignment (`ui_element`)

`push_child(child)` adds a child to the element.

During alignment, each element:

1. Applies its own `absolute` or `block` alignment to the window received from
   its parent.
2. Stores its resulting rectangle.
3. Passes that rectangle as the parent window to every child.

Thus a nested `block` works on its immediate parent's rectangle, not the
screen. For block siblings, the first child removes its strip from the
available window; the next child works on what remains. This is why layouts
such as `root -> padding -> left_p/right_p` build a sequence of nested
regions.

`display = "name"` selects an entry from `style_dispaly.lua`.
`widgets = { ... }` decides what is drawn in that rectangle.
`polyline = { { x, y }, ... }` changes the visible/hit-test shape from a
rectangle; points are local to the element.

Each widget must use a dedicated display entry for its own style. Do not
nest a widget style under an unrelated container style, such as putting
`checkbox` styling inside `w_main`. Use a standalone entry such as
`checkbox = { checkbox = { ... } }` and pass that display key to the widget.

### Button children

- Put an element in `ui_element`'s `children` to draw it above the button;
  it blocks pointer interaction in its area.
- Pass an element to `button(element, ...)` to let the button manage it;
  it is drawn above the button but remains part of the clickable area.

### Settings controls

`view/main_view.lua` provides these settings-row helpers:

```lua
settings_checkbox(label, data_key, action)
input_field(label, data_key, action)
```

`data_key` is mandatory and is used directly as the `ctx.widget_reg` key.
Checkboxes store `{ is_on = ... }` at that key and add the updated `is_on`
value to the queued action. Input fields store their text-input data at the
same key.

The underlying widgets also require explicit registry keys:

```lua
checkbox(registry_key, display_key, on_press, child)
text_input(placeholder, action, { registry_key = registry_key, ... })
```

## Display styles (`style_dispaly.lua`)

### Display entry

Each named entry has widget data:

```lua
name = {
    box = { ... },
    button = { ... },
    text = { ... },
    list_view = { ... },
    spring_list = { ... },
}
```

State tables (`idle`, `hovered`, `held`, `pressed`, `released`) are drawn in
that order for every active state; `idle` stays active as the base, so later
states overdraw it rather than replace it. A plain table applies to every
state. Button-managed children inherit the button's states recursively;
regular `ui_element` children keep their own pointer-derived states.

### `box`

- `bg`: fill color.
- `gradient`: optional GPU gradient replacing `bg`:
  `{ origin = { x, y }, direction = { angle, distance }, color1, color2 }`.
  `origin` uses relative coordinates: `{ x = 0, y = 0 }` is the top-left,
  and `{ x = 1, y = 1 }` is the bottom-right. `angle` is in degrees:
  `0` points right and positive angles rotate clockwise on screen.
  `distance` is relative to the element size: `1` reaches one element width
  or height along the selected angle. Colors accept the same color formats
  as `bg` and include alpha.
- `border`: border configuration.
- `blur`: optional background blur configuration, for example
  `{ percent = 0.2, blurSize = 2 }`. `opacity` can reduce the strength of
  the blurred layer.

### `button`

Uses the same `bg` and `border` fields as `box`. Put them directly in the
button style or under `idle` / `hovered` / `held` / `pressed`.
Buttons also support the same optional `gradient` field as `box`.

### `border`

- `width`: stroke width; commonly `1`.
- `color`: stroke color.
- `center = true`: center stroke on the rectangle edge; otherwise it is inset.
- `radius`: rounded-corner radius in pixels. `999` means “as rounded as the
  rectangle allows”.

### `text`

- `font`: font name, for example `"afacad_bold"` or `"icons"`.
- `size`: font size.
- `color`: text color.
- `align_x`: `"left"`, `"center"`, or `"right"`.
- `align_y`: `"top"`, `"center"`, or the widget's supported vertical mode.
- `line_gap`: line spacing adjustment.
- `downscale`: text rendering scale reduction.

### `list_view`

- `bg`: list background color.
- `blur`: optional background blur configuration using the same fields as
  `box.blur`.
- `scroll_speed`: scroll amount per input step.
- `scroll_bar.width`: scrollbar width.
- `scroll_bar.padding`: scrollbar inset.

### `spring_list`

`main_view.lua` selects it with `spring_list = {}`. Its layout and animation
are provided by the `spring_list()` widget. It accepts the same optional
`blur` configuration as `box.blur`.

### Colors

Styles use `color("#RRGGBB")` or `color("#RRGGBB", alpha)`. Alpha is
transparency: `0` is invisible and `100` is fully opaque in the current
color helper.
