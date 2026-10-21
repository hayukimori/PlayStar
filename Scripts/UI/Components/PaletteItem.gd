extends Control

@export var palette: GTKColorPalette;
@export var is_current: bool = false;

@onready var bg_color_rect: ColorRect = $PaletteBgColor
@onready var palette_name_label: Label = $PaletteNameLabel
@onready var in_use_label: Label = $InUseLabel

@onready var c_1 = $ColorsGrid/PaletteColor1
@onready var c_2 = $ColorsGrid/PaletteColor2
@onready var c_3 = $ColorsGrid/PaletteColor3
@onready var c_4 = $ColorsGrid/PaletteColor4
@onready var c_5 = $ColorsGrid/PaletteColor5
@onready var c_6 = $ColorsGrid/PaletteColor6
@onready var c_7 = $ColorsGrid/PaletteColor7
@onready var c_8 = $ColorsGrid/PaletteColor8
@onready var c_9 = $ColorsGrid/PaletteColor9
@onready var c_10 = $ColorsGrid/PaletteColor10
@onready var c_11 = $ColorsGrid/PaletteColor11
@onready var c_12 = $ColorsGrid/PaletteColor12


func _ready() -> void:
	if is_current: in_use_label.show()
	else: in_use_label.hide()

	if palette:
		bg_color_rect.color = palette.WindowBgColor
		set_colors()



func set_colors() -> void:
	c_1.color = palette.AccentColor # 1
	c_2.color = palette.AccentBgColor # 2
	c_3.color = palette.AccentFgColor # 3
	c_4.color = palette.WindowBgColor # 4

	c_5.color = palette.WindowFgColor # 5
	c_6.color = palette.ViewBgColor # 6
	c_7.color = palette.ViewFgColor # 7
	c_8.color = palette.HeaderbarBgColor # 8

	c_9.color = palette.CardBgColor # 9
	c_10.color = palette.DestructiveColor # 10
	c_11.color = palette.SuccessColor # 11
	c_12.color = palette.WarningColor # 12
