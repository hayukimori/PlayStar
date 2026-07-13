class_name PlaylistModel
extends Resource

@export var name: String = ""
@export var created_at: Dictionary = Time.get_date_dict_from_system()
@export var songs: Array[SongModel] = []
@export var path: String = ""


func find_by_path(song_path: String) -> SongModel:
	if !song_path: return null
	var rest: SongModel

	for song in songs:
		if song.FilePath == song_path:
			rest = song

	return rest if rest else null

func add(song: SongModel) -> void: songs.append(song)
func remove(song: SongModel) -> bool:
	var result: SongModel = null

	# get song by path
	var match = songs.filter(func(a: SongModel): return a.FilePath == song.FilePath)

	if match.size() > 0: result = match[0]
	else: return false

	if result:
		var idx = songs.find(result)
		if idx != -1:
			songs.remove_at(idx)
			return true

	return false
