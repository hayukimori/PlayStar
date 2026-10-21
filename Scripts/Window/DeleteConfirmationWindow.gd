extends HybridWindow
class_name DeleteConfirmationWindow

enum DeleteMode { PLAYLIST, PALETTE }

@export var playlist: PlaylistModel
@export var palette: GTKColorPalette

@export var confirm_button: Button
@export var cancel_button: Button
@export var main_label: Label

@onready var background: ColorRect = $Control/ColorRect

var as_mode: DeleteMode = DeleteMode.PLAYLIST

func _ready() -> void:
	if as_mode == DeleteMode.PLAYLIST and !playlist:
		queue_free(); return
	if as_mode == DeleteMode.PALETTE and !palette:
		queue_free(); return

	confirm_button.pressed.connect(_confirm)
	cancel_button.pressed.connect(close_qf)
	close_requested.connect(close_qf)

	_set_ui()

	if NodeKeeper.current_theme:
		background.color = NodeKeeper.current_theme.WindowBgColor

func _set_ui() -> void:
	match as_mode:
		DeleteMode.PLAYLIST: main_label.text = "Delete %s ?" % playlist.name
		DeleteMode.PALETTE:  main_label.text = "Delete %s ?" % palette.PaletteName

func _confirm() -> void:
	match as_mode:
		DeleteMode.PLAYLIST: _confirm_playlist()
		DeleteMode.PALETTE:  _confirm_palette()

func _confirm_playlist() -> void:
	var success: bool = PlaylistManager.delete(playlist)
	if success:
		SignalBus.emit_playlist_deleted(playlist)
		SignalBus.emit_pop_msg_request("Playlist deleted")
	else:
		SignalBus.emit_pop_msg_request("Error deleting playlist")
	close_qf()

func _confirm_palette() -> void:
	var success: bool = PaletteManager.delete(palette)
	if success:
		SignalBus.emit_palette_deleted(palette)
		SignalBus.emit_pop_msg_request("Palette deleted")
	else:
		SignalBus.emit_pop_msg_request("Error deleting palette")
	close_qf()

func close_qf() -> void:
	self.close()
	queue_free()
