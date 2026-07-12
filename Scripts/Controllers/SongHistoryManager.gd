extends Node

func _ready() -> void:
	SignalBus.song_changed.connect(_on_song_changed)


func _on_song_changed(song: SongModel) -> void:
	var hist = LibraryManager.load_history()
	LibraryManager.add_and_save_history(song, hist)
