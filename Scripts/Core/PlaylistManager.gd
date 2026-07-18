class_name PlaylistManager


## Creates a new queue based on a PlaylistModel
static func new_queue(queue_name: String, songs: Array[SongModel]) -> PlaylistModel:
	var queue: PlaylistModel = PlaylistModel.new()
	queue.name = queue_name
	queue.songs = songs
	return queue


## Loads all playlists in user's directory
static func load_playlists() -> Array[PlaylistModel]:
	var playlists_path := UserGlobals.USER_PLAYLISTS_PATH
	DevTools.check_and_create(playlists_path)


	var plfiles: Array[String] = get_full_dirs(playlists_path)
	if len(plfiles) == 0: return []

	var pl_array: Array[PlaylistModel] = []
	for item in plfiles:
		var pl = ResourceLoader.load(item)
		if pl is PlaylistModel:
			pl_array.append(pl)

	return pl_array


#region CRUD
## Creates a playlist
static func create(name: String, songs: Array[SongModel] = []) -> PlaylistModel:
	var dst := _get_main_path()

	var pl := PlaylistModel.new()
	var uuid = DevTools.generate_uuid_v4()
	var pl_file = uuid + ".tres"

	pl.name = name
	pl.songs = songs
	pl.path = dst.path_join(pl_file)

	ResourceSaver.save(pl, pl.path)
	return pl

## Deletes a playlist
static func delete(playlist: PlaylistModel) -> bool:
	_get_main_path()
	var pl_path := playlist.path

	if pl_path.is_empty(): return true
	if !FileAccess.file_exists(pl_path): return true

	DirAccess.remove_absolute(pl_path)
	return !FileAccess.file_exists(pl_path)

## Insert songs into a playlist and save after adding all songs
static func insert_and_save(playlist: PlaylistModel, songs: Array[SongModel]) -> void:
	for s in songs:
		playlist.add(s)
	save(playlist)


## Saves a playlist
static func save(playlist: PlaylistModel) -> void:

	if !playlist.path:
		var uuid := DevTools.generate_uuid_v4()
		var pl_filename = uuid + ".tres"
		var p1 := UserGlobals.USER_PLAYLISTS_PATH
		var p2 := p1.path_join(pl_filename)
		playlist.path = p2

	ResourceSaver.save(playlist, playlist.path)

## Renames a playlist + save [br]
## (Required) [param new_name] ([class String]) as new name for given playlist[br]
## (Required) [param playlist] [class PlaylistModel] as object to rename [br]
## (Optional) [param save_after] (true by defaullt) to save file after rename
##
## Usage:
## [codeblock]
## PlaylistManager.rename("Hello, world", current_playlist)
## [/codeblock]
static func rename(new_name: String, playlist: PlaylistModel, save_after: bool = true) -> void:
	playlist.name = new_name if new_name else "Unnamed playlist"
	if save_after: save(playlist)


# Internal functions
static func get_full_dirs(path: String) -> Array[String]:
	var file_paths: Array[String] = []
	var dir = DirAccess.open(path)

	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
				if not dir.current_is_dir():
					var full_path = dir.get_current_dir().path_join(file_name)
					file_paths.append(full_path)
				file_name = dir.get_next()

		dir.list_dir_end()
	else:
		print("Access fail: ", path)

	return file_paths


static func _get_main_path() -> String:
	var playlists_path := UserGlobals.USER_PLAYLISTS_PATH
	DevTools.check_and_create(playlists_path)

	return playlists_path


static func move_playlist_up(path: String) -> void:
	var udf: UserDefaults = UserGlobals.get_defaults()
	var idx = udf.playlist_order.find(path)

	if idx > 0:
		var temp = udf.playlist_order[idx - 1]
		udf.playlist_order[idx - 1] = udf.playlist_order[idx]
		udf.playlist_order[idx] = temp
		UserGlobals.save_defaults(udf)

static func move_playlist_down(path: String) -> void:
	var udf: UserDefaults = UserGlobals.get_defaults()

	var idx = udf.playlist_order.find(path)
	if idx < udf.playlist_order.size() - 1:
		var temp = udf.playlist_order[idx + 1]
		udf.playlist_order[idx + 1] = udf.playlist_order[idx]
		udf.playlist_order[idx] = temp
		UserGlobals.save_defaults(udf)
