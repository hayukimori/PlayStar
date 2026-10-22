extends TabContainer

func _ready() -> void:
	if NodeKeeper.current_theme:
		apply_tab_theme(NodeKeeper.current_theme)

	SignalBus.palette_applied.connect(apply_tab_theme)

func apply_tab_theme(palette: GTKColorPalette) -> void:
	# StyleBoxes
	for style_name in ["panel", "tabbar_background", "tab_unselected", "tab_hovered", "tab_selected"]:
		var sbx := get_theme_stylebox(style_name, "TabContainer").duplicate()
		match style_name:
			"panel":
				sbx.bg_color = palette.WindowBgColor
			"tabbar_background":
				sbx.bg_color = palette.HeaderbarBgColor
			"tab_unselected":
				sbx.bg_color = palette.CardBgColor
			"tab_hovered":
				sbx.bg_color = palette.ViewBgColor
				sbx.border_color = palette.ViewFgColor
			"tab_selected":
				sbx.bg_color = palette.ViewBgColor
				sbx.border_color = palette.AccentColor
		add_theme_stylebox_override(style_name, sbx)

	# Colors
	add_theme_color_override("font_selected_color",   palette.AccentColor)
	add_theme_color_override("font_hovered_color",    palette.WindowFgColor)
	add_theme_color_override("font_unselected_color", Color(palette.WindowFgColor, 0.6))
	add_theme_color_override("icon_selected_color",   palette.AccentColor)
	add_theme_color_override("icon_unselected_color",   Color(palette.WindowFgColor, 0.6))
	add_theme_color_override("icon_hovered_color",    palette.WindowFgColor)
