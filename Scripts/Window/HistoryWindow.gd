extends HybridWindow
class_name HistoryWindow

@export_group("Nodes")
@export var name_label: Label
@export var art_trr: TextureRectRounded
@export var add_to_playlist: ToPlaylistButton
@export var songs_scroll_container: ScrollContainer
@export var songs_vbox: FreezableBoxContainer

@export var song_button_cover_scene: PackedScene

var loaded_song_buttons: Array[Button]
var songs_cache: Array[SongModel]

var _visibility_check_pending := false
var _current_generation := 0
const BUILD_BUDGET_USEC := 1000


func _ready() -> void:
	SignalBus.song_changed.connect(_on_update_request)
	self.visibility_changed.connect(_on_visible_changed)

	close_requested.connect(close)
	songs_scroll_container.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)

	load_history()


func load_history() -> void:
	DevTools.wipe_btns(loaded_song_buttons)

	setup_songs()
	render_song_btns_from_list(songs_cache)


func setup_songs() -> void:
	var hist_songs: Array[SongModel] = LibraryManager.load_history_songs(true)
	if !hist_songs: return

	songs_cache = hist_songs.duplicate()

	add_to_playlist.content = songs_cache


func wipe_all() -> void:
	songs_cache.clear()
	DevTools.wipe_btns(loaded_song_buttons)


## Creates a new button (requires SongModel)
func new_song_btn(song: SongModel, append_to: Array[Button], parent_node: Node) -> Button:
	var song_button = null

	song_button = song_button_cover_scene.instantiate() as SongButtonCovered

	song_button.song_content = song
	song_button.song_selected.connect(play_song)

	append_to.append(song_button)
	song_button.index = append_to.find(song_button)
	song_button.show()
	parent_node.add_child(song_button)

	_on_node_added_to_list()

	return song_button


## Renders buttons from list (argument)
func render_song_btns_from_list(songs: Array) -> void:
	if !visible: return

	_current_generation += 1
	var generation := _current_generation

	if songs.is_empty():
		DevTools.wipe_btns(loaded_song_buttons)
		return

	songs_vbox.freeze_layout()

	DevTools.wipe_btns(loaded_song_buttons)
	await _build_buttons_timesliced(songs, generation)

	if generation == _current_generation:
		songs_vbox.thaw_layout()


# SONGS
func _build_buttons_timesliced(songs: Array, generation: int) -> void:
	var i := 0

	while i < songs.size():
		var start := Time.get_ticks_usec()

		while i < songs.size():
			if generation != _current_generation:
					return
			new_song_btn(songs[i], loaded_song_buttons, songs_vbox)
			i += 1

			if Time.get_ticks_usec() - start > BUILD_BUDGET_USEC:
					await get_tree().process_frame
					if generation != _current_generation: return
					break


func play_song(song: SongModel) -> void:
	var queue = LibraryManager.load_history_as_queue(true)
	var song_from_q = queue.find_by_path(song.FilePath)

	var index: int = 0
	if song_from_q: index = queue.songs.find(song_from_q)

	SignalBus.emit_request_playlist(queue, index)

func _on_update_request(_value = null) -> void:
	load_history()

func _on_scroll_changed(_value):
	var visible_rect = Rect2(Vector2.ZERO, songs_scroll_container.size)
	visible_rect.position += Vector2(0, songs_scroll_container.scroll_vertical)
	visible_rect = visible_rect.grow(64)

	for button in songs_vbox.get_children():
		var button_rect = Rect2(button.position, button.size)
		var b_is_visible = visible_rect.intersects(button_rect)
		button.set_art_visibility(b_is_visible)

func _on_node_added_to_list():
	if _visibility_check_pending:
		return
	_visibility_check_pending = true
	call_deferred("_run_visibility_check")


func _on_visible_changed() -> void:
	if !songs_cache:
		setup_songs()
	if visible:
		render_song_btns_from_list(songs_cache)


func _run_visibility_check():
	_visibility_check_pending = false
	_on_scroll_changed(0)


func _go_back() -> void:
		self.hide()
		wipe_all()
