class_name LibraryManager


static func add_and_save_history(song: SongModel, history: HistoryModel) -> void:
	var path = Definitions.USER_HISTORY_PATH
	history.add_song(song)
	ResourceSaver.save(history, path)


static func load_history() -> HistoryModel:
	var path = Definitions.USER_HISTORY_PATH

	var rest: HistoryModel

	if FileAccess.file_exists(path):
		rest = ResourceLoader.load(path) as HistoryModel
	else:
		rest = HistoryModel.new()
		ResourceSaver.save(rest)

	return rest
