extends Control
class_name PaletteItem

@export var palette: GTKColorPalette;

@export var use_button: Button
@export var edit_button: Button
@export var delete_button: Button

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
	if !palette: queue_free()

	var is_current = palette == NodeKeeper.current_theme
	if is_current: in_use_label.show()
	else: in_use_label.hide()

	bg_color_rect.color = palette.WindowBgColor
	palette_name_label.text = palette.PaletteName

	if use_button:
		use_button.pressed.connect(_on_use_pressed)

	if edit_button:
		edit_button.pressed.connect(_on_edit_pressed)

	if delete_button:
		delete_button.pressed.connect(_on_delete_pressed)


	set_colors()


func refresh() -> void:
	var is_current = (palette == NodeKeeper.current_theme)
	if is_current: in_use_label.show()
	else: in_use_label.hide()

	bg_color_rect.color = palette.WindowBgColor
	palette_name_label.text = palette.PaletteName

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




func _on_use_pressed() -> void:
	SignalBus.emit_request_palette_use(palette)

func _on_edit_pressed() -> void:
	SignalBus.emit_request_palette_edit(palette)

func _on_delete_pressed() -> void:
	SignalBus.emit_request_palette_delete(palette)
