extends Node
class_name WindowManager

@export var playlists_window: HybridWindow
@export var artists_window: HybridWindow
@export var albums_window: HybridWindow
@export var delete_playlist_window: HybridWindow



func _ready() -> void:
	SignalBus.invoke_playlists_window.connect(_open_playlists)
	SignalBus.invoke_artists_window.connect(_open_artists)
	SignalBus.invoke_albuns_window.connect(_open_albums)



func _open_playlists() -> void:
	print("reach PlaylistWindow.open")
	playlists_window.open()

func _open_albums() -> void:
	#albums_window.open()
	push_warning("Not implemented")

func _open_artists() -> void:
	#artists_window.open()
	push_warning("Not implemented")
