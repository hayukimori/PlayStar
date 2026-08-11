extends ScrollContainer
class_name StarredScrollContainer

signal starred_songs_updated(songs: Array[SongModel])

@export var songs_vbox: VirtualizedVBoxList
@export var song_button_cover_scene: PackedScene

var songs_cache: Array[SongModel]

func _ready() -> void:
	SignalBus.star_song.connect(_on_update_requested)
	SignalBus.unstar_song.connect(_on_update_requested)
	self.visibility_changed.connect(_on_visible_changed)
	songs_vbox.setup(self, _spawn_song_button)

	load_starred()

func _on_visible_changed() -> void:
	if !songs_cache: setup_songs()
	if visible:
		render_song_btns_from_list(songs_cache)

func _on_update_requested(_arg = null, _arg2 = null) -> void:
	load_starred()

func load_starred() -> void:
	songs_vbox.clear()
	setup_songs()
	render_song_btns_from_list(songs_cache)

func setup_songs() -> void:
	var result: Array[SongModel] = LibraryManager.starred_local()
	songs_cache = result.duplicate()
	starred_songs_updated.emit(songs_cache)

func _spawn_song_button(song: SongModel, index: int) -> Node:
	var song_button = song_button_cover_scene.instantiate() as SongButtonCovered
	song_button.song_content = song
	song_button.index = index
	song_button.song_selected.connect(play_song)
	return song_button

func render_song_btns_from_list(songs: Array) -> void:
	if !visible: return

	if songs.is_empty():
		songs_vbox.clear()
		return

	songs_vbox.set_items(songs)

func play_song(song: SongModel) -> void:
	var queue = LibraryManager.starred_as_playlist()
	var song_from_q = queue.find_by_path(song.FilePath)

	var index: int = 0
	if song_from_q: index = queue.songs.find(song_from_q)

	SignalBus.emit_request_playlist(queue, index)
