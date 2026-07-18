extends Control

@export var confirmation_window_packed: PackedScene

@export_group("Nodes")
@export var del_database_button: Button
@export var del_lyrics_button: Button
@export var del_history_button: Button
@export var del_playlists_button: Button

func _ready() -> void:
	if del_database_button:
		del_database_button.pressed.connect(_on_dbdel_pressed)

	if del_lyrics_button:
		del_lyrics_button.pressed.connect(_on_lrcdel_pressed)

	if del_history_button:
		del_history_button.pressed.connect(_on_histdel_pressed)

	if del_playlists_button:
		del_playlists_button.pressed.connect(_on_pldel_pressed)



func invoke_window(text: String, confirmed_msg: String, connect_to: Callable):
	print("Calling window")
	if !confirmation_window_packed: return

	var win: ConfirmationWindow = confirmation_window_packed.instantiate() \
		as ConfirmationWindow
	if !win: return

	win.text = text
	win.confirmed_message = confirmed_msg
	win.confirmed.connect(connect_to)

	add_child(win)

	win.open()


# Button pressess
func _on_dbdel_pressed() -> void:
	var txt: String = \
	"Are you sure you want to delete the database? \
	This action cannot be undone."

	var msg_txt: String = "Database deleted."
	invoke_window(txt, msg_txt, _on_dbdel_confirm)

func _on_lrcdel_pressed() -> void:
	var txt: String = \
	"Are you sure you want to delete all lyrics? \
	This action cannot be undone."

	var msg_txt: String = "Lyric files deleted."
	invoke_window(txt, msg_txt, _on_lrcdel_confirm)

func _on_histdel_pressed() -> void:
	var txt: String = \
	"Are you sure you want to delete your recent music history? \
	This action cannot be undone."

	var msg_txt: String = "Song history deleted."
	invoke_window(txt, msg_txt, _on_histdel_confirm)

func _on_pldel_pressed() -> void:
	var txt: String = \
	"Are you sure you want to delete playlists? \
	This action cannot be undone."

	var msg_txt: String = "Playlists deleted."
	invoke_window(txt, msg_txt, _on_pldel_confirm)



# Confirm window response
func _on_dbdel_confirm() -> void:
	LibraryManager.delete_database()
	SignalBus.emit_reload_request()
	SignalBus.emit_reload_artists()
	SignalBus.emit_reload_albums()

func _on_lrcdel_confirm() -> void:
	LibraryManager.delete_lyrics()

func _on_histdel_confirm() -> void:
	LibraryManager.delete_history()
	SignalBus.emit_request_history_update()

func _on_pldel_confirm() -> void:
	LibraryManager.delete_playlists()
	SignalBus.emit_reset_playlists()
