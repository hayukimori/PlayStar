extends HybridWindow

@export var line_edit: LineEdit
@export var confirm_btn: Button

func _ready() -> void:
	line_edit.text_submitted.connect(_on_submitted)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	self.close_requested.connect(resclose)

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
