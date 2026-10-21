extends HybridWindow

@export var line_edit: LineEdit
@export var confirm_btn: Button

@export var accent_color_btn: ColorPickerButton
@export var accent_bg_color_btn: ColorPickerButton
@export var accent_fg_color_btn: ColorPickerButton
@export var window_bg_color_btn: ColorPickerButton
@export var window_fg_color_btn: ColorPickerButton
@export var view_bg_color_btn: ColorPickerButton
@export var view_fg_color_btn: ColorPickerButton
@export var headerbar_bg_color_btn: ColorPickerButton
@export var card_bg_color_btn: ColorPickerButton
@export var destructive_color_btn: ColorPickerButton
@export var success_color_btn: ColorPickerButton
@export var warning_color_btn: ColorPickerButton

var _default_color := Color(.5, .5, .5);

var _current # edit only
var _as_add: bool = true

func _ready() -> void:
	line_edit.text_submitted.connect(_on_submitted)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	self.close_requested.connect(resclose)

func reset() -> void:
	line_edit.clear()

	accent_color_btn.color = _default_color
	accent_bg_color_btn.color = _default_color
	accent_fg_color_btn.color = _default_color
	window_bg_color_btn.color = _default_color
	window_fg_color_btn.color = _default_color
	view_bg_color_btn.color = _default_color
	view_fg_color_btn.color = _default_color
	headerbar_bg_color_btn.color = _default_color
	card_bg_color_btn.color = _default_color
	destructive_color_btn.color = _default_color
	success_color_btn.color = _default_color
	warning_color_btn.color = _default_color

	_current = null
	_as_add = true


func _on_confirm_pressed() -> void:
	var text = line_edit.text
	if !text: return

	new_p(text, !!_current)

func _on_submitted(text: String = "") -> void:
	if !text: self.close(); return

	new_p(text, !!_current)


func load_from(pa: GTKColorPalette, as_add: bool) -> void:
	_current = pa
	_as_add = as_add

	accent_color_btn.color = pa.AccentColor
	accent_bg_color_btn.color = pa.AccentBgColor
	accent_fg_color_btn.color = pa.AccentFgColor
	window_bg_color_btn.color = pa.WindowBgColor
	window_fg_color_btn.color = pa.WindowFgColor
	view_bg_color_btn.color = pa.ViewBgColor
	view_fg_color_btn.color = pa.ViewFgColor
	headerbar_bg_color_btn.color = pa.HeaderbarBgColor
	card_bg_color_btn.color = pa.CardBgColor
	destructive_color_btn.color = pa.DestructiveColor
	success_color_btn.color = pa.SuccessColor
	warning_color_btn.color = pa.WarningColor

	line_edit.text = _current.PaletteName

func collect_colors_as_palette() -> GTKColorPalette:
	var pa = GTKColorPalette.new()
	collect_colors_into(pa)
	return pa


func collect_colors_into(pa: GTKColorPalette) -> void:
	pa.AccentColor = accent_color_btn.color
	pa.AccentBgColor = accent_bg_color_btn.color
	pa.AccentFgColor = accent_fg_color_btn.color
	pa.WindowBgColor = window_bg_color_btn.color
	pa.WindowFgColor = window_fg_color_btn.color
	pa.ViewBgColor = view_bg_color_btn.color
	pa.ViewFgColor = view_fg_color_btn.color
	pa.HeaderbarBgColor = headerbar_bg_color_btn.color
	pa.CardBgColor = card_bg_color_btn.color
	pa.DestructiveColor = destructive_color_btn.color
	pa.SuccessColor = success_color_btn.color
	pa.WarningColor = warning_color_btn.color

func new_p(p_name: String, edited: bool = false) -> void:
	if edited and _current and not _as_add:
		_current.PaletteName = p_name
		collect_colors_into(_current)
		PaletteManager.save(_current)
		SignalBus.emit_palette_renamed(_current)
	else:
		var pa = collect_colors_as_palette()
		pa.PaletteName = p_name
		PaletteManager.save(pa)
		SignalBus.emit_palette_added(pa)

	resclose()



func resclose() -> void:
	reset()
	close()
