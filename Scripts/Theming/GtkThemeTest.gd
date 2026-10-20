extends Control

@export var color_rect_group: Array[ColorRect] = []

func _ready() -> void:
	GtkThemeProvider.ColorsLoaded.connect(palette_updated)
	GtkThemeProvider.FetchColors()



func get_accent() -> Color:
	var accent: Color = DisplayServer.get_accent_color()
	return accent

func is_dark_mode() -> bool:
	if !DisplayServer.is_dark_mode_supported():
		return false
	return DisplayServer.is_dark_mode()


func palette_updated(palette: GTKColorPalette) -> void:
	print(palette.DarkMode)
	print(palette.AccentBgColor)

	var colors = [
		palette.AccentColor, # 1
		palette.AccentBgColor, # 2
		palette.AccentFgColor, # 3
		palette.WindowBgColor, # 4

		palette.WindowFgColor, # 5
		palette.ViewBgColor, # 6
		palette.ViewFgColor, # 7
		palette.HeaderbarBgColor, # 8

		palette.CardBgColor, # 9
		palette.DestructiveColor, # 10
		palette.SuccessColor, # 11
		palette.WarningColor # 12
	]

	var idx = 0
	for cr in color_rect_group:
		cr.color = colors[idx]
		idx += 1
