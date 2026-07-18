class_name LibraryManager


## Adds SongModel to HistoryModel and saves it to USER_HISTORY_PATH[br]
## Takes [param song] to convert SongModel to HistoryEntry [br]
## Takes [param history] to save history
##
## Usage
## [codeblock]
## var song: SongModel = some_song_model # variable
## var history: HistoryModel = LibraryManager.load_history()
## add_and_save_history()
## [/codeblock]
static func add_and_save_history(song: SongModel, history: HistoryModel) -> void:
	var path = Definitions.USER_HISTORY_PATH
	history.add_song(song)
	ResourceSaver.save(history, path)


## Loads history file as HistoryModel (Scripts/Models)
##
## Loads History data from [constant Definitions.USER_HISTORY_PATH] if it exists
## or creates a new one and returns [code]HistoryModel[/code]
static func load_history() -> HistoryModel:
	var path = Definitions.USER_HISTORY_PATH
	var rest: HistoryModel

	if FileAccess.file_exists(path):
		rest = ResourceLoader.load(path) as HistoryModel
	else:
		rest = HistoryModel.new()
		ResourceSaver.save(rest, path)

	return rest


## Loads songs from history file as Array[SongModel]
## [br]
## Takes [param reversed] (bool) to reverse songs (last item = most recent song)[br]
## Gets [class HistoryModel] from [method LibraryManager.load_history]
## and gets songs by paths in [class SongRepository] (if loaded in [class NodeKeeper])
## then returns the result as [code] Array[lb]SongModel[rb] [/code][br]
##
## Usage:
## [codeblock]
## var songlist: Array[SongModel] = load_history_songs(true) # recent songs becomes first items in list
## [/codeblock]
static func load_history_songs(reversed: bool = false) -> Array[SongModel]:
	var repo = NodeKeeper.song_repository
	var history: HistoryModel = load_history()
	if !repo: return []

	var strings = []
	for i in history.song_history:
		strings.append(i.file_path)

	var songs = repo.GetSongsByPaths(strings)

	if reversed:
		songs.reverse()

	return songs


## Loads history as [class PlaylistModel][br]
##
## Takes [param reversed] (bool) to reverse songs (last item = most recent song)[br]
## Takes [param queue_name] (string), it gives name to PlaylistModel (shows in player)[br]
##
## Gets current history from file as Array[SongModel] (check [method LibraryManager.load_history_songs]),
## converts it to [class PlaylistModel] and returns it.[br]
##
## Usage:
## [codeblock]
## var history_queue: PlaylistModel = LibraryManager.load_history_as_queue(true, "Today's history")
## SignalBus.emit_request_playlist(history_queue, 0)
## [/codeblock]
static func load_history_as_queue(reversed: bool = false, queue_name: String = "History") -> PlaylistModel:
	var songs = load_history_songs(reversed)

	var queue: PlaylistModel = PlaylistManager.new_queue(queue_name, songs)

	return queue


## Deletes Database file[br]
##
## CAUTION: This functions [b]deletes[/b] database content
static func delete_database():
	var _current_db: DatabaseManager = NodeKeeper.current_database

	# Just drop tables if exists.
	if _current_db:
		_current_db.DropAllTables()
		_current_db.CloseAll()
	else:
		# deletes file
		DevTools.delete_file(Definitions.DATABASE_PATH)
		DevTools.delete_file(Definitions.DATABASE_PATH + "-wal")
		DevTools.delete_file(Definitions.DATABASE_PATH + "-shm")


## Deletes Database file[br]
##
## CAUTION: This functions [b]deletes[/b] song history file
static func delete_history():
	DevTools.delete_file(Definitions.USER_HISTORY_PATH)


## Deletes Database file[br]
##
## CAUTION: This functions [b]deletes[/b] all stored json lyrics
static func delete_lyrics():
	DevTools.delete_dir(Definitions.LYRICS_PATH)

## Deletes Database file[br]
##
## CAUTION: This functions [b]deletes[/b] all playlists
static func delete_playlists():
	DevTools.delete_dir(Definitions.PLAYLISTS_PATH)

## Deletes elements form library[br]
##
## Takes [param options] as an Array of [enum Defintions.LibraryOptions]
## to delete custom items[br]
##
## Usage: [br]
## [codeblock]
## var items: Array[Definitions.LibraryOptions] = [
## 		Definitions.LibraryOptions.DATABASE, # Database
##		Definitions.LibraryOptions.PLAYLISTS # Playlists
## 	] # Can add more items using .append()
##
## LibraryManager.delete_library(items)
##
## [/codeblock]
static func delete_library(options: Array[Definitions.LibraryOptions]):
	if !options: return
	for option in options:
		match option:
			Definitions.LibraryOptions.DATABASE:
				delete_database()
			Definitions.LibraryOptions.HISTORY:
				delete_history()
			Definitions.LibraryOptions.LYRICS:
				delete_lyrics()
			Definitions.LibraryOptions.PLAYLISTS:
				delete_playlists()
			_: return
