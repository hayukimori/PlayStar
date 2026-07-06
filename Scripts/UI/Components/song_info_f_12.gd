extends Control
class_name SongInfoF12

@export_group("Setup nodes")
@export var trr: TextureRectRounded
@export var song_label: Label
@export var artist_label: Label
@export var album_label: Label

func set_ui(song: SongModel, texture) -> void:
	if texture is Texture2D:
		trr.texture = texture

	song_label.text = song.Title
	artist_label.text = song.Artist
	album_label.text = song.Album
