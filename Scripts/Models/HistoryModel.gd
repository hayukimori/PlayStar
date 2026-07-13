extends Resource
class_name HistoryModel

@export var song_history: Array[HistoryEntry] = []

func add_song(song: SongModel) -> void:
	var path = song.FilePath

	var idx = song_history.find_custom(func(e): return e.file_path == path)
	if idx != -1:
		song_history.remove_at(idx)
	elif song_history.size() >= 100:
		song_history.remove_at(0)

	var entry = HistoryEntry.new()
	entry.file_path = path
	entry.title = song.Title
	entry.artist = song.Artist
	entry.played_at = Time.get_unix_time_from_system()

	song_history.append(entry)
