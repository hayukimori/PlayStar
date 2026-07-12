extends Resource
class_name HistoryModel

# RULES
# it stores only the last 100 songs
@export var song_history: Array[String] = [] # Song History from song paths


# Adds song to history, if song is already in history, it is moved to the end
func add_song(song: SongModel) -> void:
	var path = song.FilePath

	# Find song
	var idx = song_history.find(path)
	if idx != -1:
		song_history.remove_at(idx)

	else:
		if song_history.size() >= 100:
			song_history.remove_at(0)


	# if song_history.contains(path):
	#     song_history.remove(path)

	song_history.append(path)
