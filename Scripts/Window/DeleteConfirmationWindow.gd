extends HybridWindow
class_name DeleteConfirmationWindow

@export var playlist: PlaylistModel

@export var confirm_button: Button
@export var cancel_button: Button
@export var main_label: Label

func _ready() -> void:
	if !playlist:
		queue_free()

	confirm_button.pressed.connect(_confirm)
	cancel_button.pressed.connect(close_qf)
	close_requested.connect(close_qf)

	_set_ui()

func _set_ui() -> void:
	main_label.text = "Delete %s ?" % playlist.name

func _confirm() -> void:
	var success: bool = PlaylistManager.delete(playlist)
	if success:
		SignalBus.emit_playlist_deleted(playlist)
		SignalBus.emit_pop_msg_request("Playlist deleted")
		close_qf()
	else:
		SignalBus.emit_pop_msg_request("Error deleting playlist")
		close_qf()


func close_qf() -> void:
	self.close()
	queue_free()
