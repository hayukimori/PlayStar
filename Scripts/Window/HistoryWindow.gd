extends HybridWindow
class_name HistoryWindow

@export_group("Nodes")
@export var name_label: Label
@export var art_trr: TextureRectRounded
@export var add_to_playlist: ToPlaylistButton
@export var songs_scroll_container: ScrollContainer
@export var songs_vbox: VirtualizedVBoxList

@export var song_button_cover_scene: PackedScene

var songs_cache: Array[SongModel]


func _ready() -> void:
	SignalBus.song_changed.connect(_on_update_request)
	SignalBus.request_history_update.connect(_on_update_request)
	self.visibility_changed.connect(_on_visible_changed)

	close_requested.connect(close)
	songs_vbox.setup(songs_scroll_container, _spawn_song_button)

	load_history()


func load_history() -> void:
	songs_vbox.clear()

	setup_songs()
	render_song_btns_from_list(songs_cache)


func setup_songs() -> void:
	var hist_songs: Array[SongModel] = LibraryManager.load_history_songs(true)
	songs_cache = hist_songs.duplicate()

	add_to_playlist.content = songs_cache


func wipe_all() -> void:
	songs_cache.clear()
	songs_vbox.clear()


## Creates a new button (requires SongModel)
func _spawn_song_button(song: SongModel, index: int) -> Node:
	var song_button = song_button_cover_scene.instantiate() as SongButtonCovered
	song_button.song_content = song
	song_button.index = index
	song_button.song_selected.connect(play_song)
	return song_button


## Renders buttons from list (argument)
func render_song_btns_from_list(songs: Array) -> void:
	if !visible: return

	if songs.is_empty():
		songs_vbox.clear()
		return

	songs_vbox.set_items(songs)


func play_song(song: SongModel) -> void:
	var queue = LibraryManager.load_history_as_queue(true)
	var song_from_q = queue.find_by_path(song.FilePath)

	var index: int = 0
	if song_from_q: index = queue.songs.find(song_from_q)

	SignalBus.emit_request_playlist(queue, index)

func _on_update_request(_value = null) -> void:
	load_history()

func _on_visible_changed() -> void:
	if !songs_cache:
		setup_songs()
	if visible:
		render_song_btns_from_list(songs_cache)


func _go_back() -> void:
	self.hide()
	wipe_all()
