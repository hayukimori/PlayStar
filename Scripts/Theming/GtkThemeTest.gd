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
		palette.AccentColor,
		palette.AccentBgColor,
		palette.AccentFgColor,
		palette.WindowBgColor,
		palette.WindowFgColor,
		palette.ViewBgColor,
		palette.ViewFgColor,
		palette.HeaderbarBgColor,
		palette.CardBgColor,
		palette.DestructiveColor,
		palette.SuccessColor,
		palette.WarningColor
	]

	var idx = 0
	for cr in color_rect_group:
		cr.color = colors[idx]
		idx += 1
