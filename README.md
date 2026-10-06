# Radical ui
GUI layer for an open source game

<img width="888" height="526" alt="ui5" src="https://github.com/user-attachments/assets/0ade7e18-91da-416d-aa45-63cd363bde6a" />

My second shot at ui implementation

<img align="right" width="530" height="422" alt="prev2" src="https://github.com/user-attachments/assets/a2f96a19-f796-4e97-8d8b-84046e3bd8a5" />

``` lua
local handle = ui_element({
  display = "checkbox_handle",
  widgets = { box() },
  align = absolute({
    pivot = { x = 50, y = 50 },
    parent_pivot = { x = is_on and 75 or 25, y = 50 },
    size = Size({ px = 26 }),
  }):animation({
    key = data_key,
    delta_pos = { x = is_on and -40 or 40, y = 0 },
    ease_fn = "out",
    duration = 180,
  }),
  display_animation = {
    duration = 180,
    ease = "out",
    key = data_key,
  },
})
```
``` lua
checkbox_handle = {
  box = {
    bg = theme.separator_main,
    border = { center = true, width = 1, radius = 10, color = theme.separator_main },
  },
},
```

Animations, Blur, Polylines and hot reload with error checking in under 150 line of code
