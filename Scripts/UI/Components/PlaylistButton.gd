extends Button
class_name PlaylistButton

signal playlist_clicked(obj: PlaylistModel)

@export var playlist_object: PlaylistModel
@export var name_label: Label
@export var song_count_label: Label

var s_count_text: String = "%s Songs"

func _ready() -> void:
	if !playlist_object: queue_free();

func _set_ui() -> void:
	if !song_count_label: return
	if !name_label: return

	song_count_label.text = s_count_text % str(int(playlist_object.songs.size()))

func _pressed() -> void:
	playlist_clicked.emit(playlist_object)
