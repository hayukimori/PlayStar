extends HybridWindow

@export var line_edit: LineEdit
@export var confirm_btn: Button

func _ready() -> void:
	line_edit.text_submitted.connect(_on_submitted)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	self.close_requested.connect(resclose)

	if NodeKeeper.current_theme:
		apply_palette_le(NodeKeeper.current_theme)

	SignalBus.palette_applied.connect(apply_palette_le)


func apply_palette_le(palette: GTKColorPalette) -> void:
	var sbx = line_edit.get_theme_stylebox("normal", "LineEdit").duplicate()
	sbx.bg_color = palette.ViewBgColor

	var plh_color = palette.ViewFgColor
	plh_color.a = 0.6

	line_edit.add_theme_stylebox_override("normal", sbx)
	line_edit.add_theme_stylebox_override("focus", sbx)
	line_edit.add_theme_color_override("font_color", palette.ViewFgColor)
	line_edit.add_theme_color_override("font_placeholder_color", plh_color)

func reset() -> void:
	line_edit.clear()


func _on_confirm_pressed() -> void:
	var text = line_edit.text
	if !text: return
	new_p(text)

func _on_submitted(text: String = "") -> void:
	if !text: self.close(); return
	new_p(text)

func new_p(p_name: String) -> void:
	var pl: PlaylistModel = PlaylistManager.create(p_name)
	SignalBus.emit_playlist_added(pl)
	resclose()


func resclose() -> void:
	reset()
	close()
