extends Node
class_name WindowManager

@export_group("Windows")
@export var playlists_window: HybridWindow
@export var artists_window: HybridWindow
@export var albums_window: HybridWindow
@export var config_control: Control
@export var dynamic_playlists_window: HybridWindow
@export var palette_window: HybridWindow

@export_group("Window Scenes")
@export var add_to_playlist_window_fb: PackedScene
@export var delete_confirm_window: PackedScene

@export var about_window_packed: PackedScene

func _ready() -> void:
	SignalBus.invoke_settings_menu.connect(_open_settings)
	SignalBus.invoke_playlists_window.connect(_open_playlists)
	SignalBus.invoke_artists_window.connect(_open_artists)
	SignalBus.invoke_albums_window.connect(_open_albums)
	SignalBus.invoke_about_window.connect(_ivk_about_window)
	SignalBus.show_dynamic_playlists_window.connect(_open_dynamic)
	SignalBus.invoke_palette_window.connect(_open_palette_window)

	SignalBus.request_song_to_playlist.connect(_ivk_to_playlist_window)
	SignalBus.request_artist_to_playlist.connect(_ivk_to_playlist_window)
	SignalBus.request_album_to_playlist.connect(_ivk_to_playlist_window)
	SignalBus.request_song_array_to_playlist.connect(_ivk_to_playlist_window)

	SignalBus.request_playlist_delete.connect(_ivk_playlist_delete_popup)
	SignalBus.request_palette_delete.connect(_ivk_palette_delete_popup)


func _open_playlists() -> void:
	playlists_window.open()

func _open_albums() -> void:
	albums_window.open()

func _open_artists() -> void:
	artists_window.open()

func _open_settings() -> void:
	config_control.open()

func _open_dynamic() -> void:
	dynamic_playlists_window.open()

func _open_palette_window() -> void:
	palette_window.open()

func _ivk_about_window() -> void:
	if !about_window_packed: return

	var win = about_window_packed.instantiate() as HybridWindow
	if !win: return

	add_child(win)
	win.open()

func _ivk_playlist_delete_popup(playlist: PlaylistModel) -> void:
	_ivk_delete_popup(DeleteConfirmationWindow.DeleteMode.PLAYLIST, playlist)

func _ivk_palette_delete_popup(palette: GTKColorPalette) -> void:
	_ivk_delete_popup(DeleteConfirmationWindow.DeleteMode.PALETTE, palette)


func _ivk_delete_popup(dmode: DeleteConfirmationWindow.DeleteMode, object) -> void:
	if !delete_confirm_window: return
	var scn = delete_confirm_window.instantiate() as DeleteConfirmationWindow

	scn.as_mode = dmode

	if object is PlaylistModel:
		scn.playlist = object

	elif object is GTKColorPalette:
		scn.palette = object

	else:
		return

	add_child(scn)
	scn.open()


func _ivk_to_playlist_window(content: Variant):
	if !add_to_playlist_window_fb:
		push_warning("Missing component")
		return;

	var win := add_to_playlist_window_fb.instantiate() as AddToPlaylistWindow
	if !win: push_error("Couldn't load window")

	win.current_content = content


	add_child(win)
	win.open()
