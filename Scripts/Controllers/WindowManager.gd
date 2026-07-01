extends Node
class_name WindowManager

@export var playlists_window: HybridWindow
@export var artists_window: HybridWindow
@export var albums_window: HybridWindow
@export var delete_playlist_window: HybridWindow
@export var config_control: Control

@export var add_to_playlist_window_fb: PackedScene


func _ready() -> void:
	SignalBus.invoke_settings_menu.connect(_open_settings)
	SignalBus.invoke_playlists_window.connect(_open_playlists)
	SignalBus.invoke_artists_window.connect(_open_artists)
	SignalBus.invoke_albums_window.connect(_open_albums)

	SignalBus.request_song_to_playlist.connect(_ivk_to_playlist_window)
	SignalBus.request_artist_to_playlist.connect(_ivk_to_playlist_window)
	SignalBus.request_album_to_playlist.connect(_ivk_to_playlist_window)


func _open_playlists() -> void:
	playlists_window.open()

func _open_albums() -> void:
	albums_window.open()


func _open_artists() -> void:
	artists_window.open()

func _open_settings() -> void:
	config_control.open()

func _ivk_to_playlist_window(content: Variant):
	if !add_to_playlist_window_fb:
		push_warning("Missing component")
		return;

	var win := add_to_playlist_window_fb.instantiate() as AddToPlaylistWindow
	if !win: push_error("Couldn't load window")

	win.current_content = content


	add_child(win)
	win.open()
