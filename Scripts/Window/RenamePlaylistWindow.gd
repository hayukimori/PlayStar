extends HybridWindow
class_name RenamePlaylistWindow

@export var line_edit: LineEdit
@export var confirm_btn: Button

var _playlist: PlaylistModel

func _ready() -> void:
	line_edit.text_submitted.connect(_on_submitted)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	self.close_requested.connect(resclose)

	SignalBus.request_rename_window.connect(_on_request_rename)

func reset() -> void:
	line_edit.clear()
	_playlist = null

func _on_request_rename(target: PlaylistModel) -> void:
	_playlist = target
	self.open()

func _on_confirm_pressed() -> void:
	var text = line_edit.text
	if !text: return
	rename_p(text)

func _on_submitted(text: String = "") -> void:
	if !text: self.close(); return
	rename_p(text)

func rename_p(new_name: String) -> void:
	if _playlist:
		PlaylistManager.rename(new_name, _playlist, true)
		SignalBus.emit_reload_playlists()
	resclose()


func resclose() -> void:
	reset()
	close()
