extends Control
class_name PlaylistControl

@export_group("Scene Nodes")
@export var playlists_vbc: VBoxContainer
@export var song_btn_vbc: FreezableBoxContainer
@export var central_panel: Panel
@export var color_rect: ColorRect
@export var new_playlist_btn: Button
@export var new_playlist_win: HybridWindow

@export_group("Scene Settings")
@export_subgroup("Packed Scenes")
@export var playlist_btn_scene: PackedScene
@export var song_btn_cvr_scn: PackedScene

@export_group("Animation")
@export var open_pos: Vector2
@export var closed_pos: Vector2

const BUILD_BUDGET_USEC := 1000

var song_btn_list: Array[Button] = []
var playlist_btn_list: Array[Button] = []

var _current_selected_playlist: PlaylistModel
var _current_generation := 0
var _playlists: Array[PlaylistModel] = []


func _ready() -> void:
	_playlists = PlaylistManager.load_playlists()

	var udf = UserGlobals.get_defaults()
	if udf.playlist_order.is_empty():
		udf.playlist_order = _playlists.map(func(pl): return pl.path)
		UserGlobals.save_defaults(udf)

	_sort_playlists_by_order()

	new_playlist_btn.pressed.connect(_on_new_playlist_btn)

	SignalBus.playlist_deleted.connect(_on_playlist_deleted)
	SignalBus.playlist_added.connect(_on_playlist_added)

	SignalBus.request_playlist_up.connect(move_playlist_ui_up)
	SignalBus.request_playlist_down.connect(move_playlist_ui_down)

	self.visibility_changed.connect(_on_visibility_changed)
	_load_ui_playlists()

# ─── Playlist UI ──────────────────────────────────────────────────────────────

## Moves playlist up
func move_playlist_ui_up(playlist: PlaylistModel) -> void:
	PlaylistManager.move_playlist_up(playlist.path)
	var btn := _get_playlist_btn(playlist)
	if not btn:
		return

	var idx := btn.get_index()
	if idx > 0:
		playlists_vbc.move_child(btn, idx-1)
		var pi := _playlists.find(playlist)
		if pi > 0:
			var temp = _playlists[pi - 1]
			_playlists[pi -1] = _playlists[pi]
			_playlists[pi] = temp


## Moves playlist down
func move_playlist_ui_down(playlist: PlaylistModel) -> void:
	PlaylistManager.move_playlist_down(playlist.path)
	var btn := _get_playlist_btn(playlist)
	if not btn:
		return
	var idx := btn.get_index()
	if idx < playlists_vbc.get_child_count() - 1:
		playlists_vbc.move_child(btn, idx + 1)
		var pi := _playlists.find(playlist)
		if pi > 0:
			var temp = _playlists[pi - 1]
			_playlists[pi -1] = _playlists[pi]
			_playlists[pi] = temp


func _get_playlist_btn(playlist: PlaylistModel) -> PlaylistButton:
	for btn in playlist_btn_list:
		if (btn as PlaylistButton).playlist_object == playlist:
			return btn as PlaylistButton
	return null

func _add_to_cache(playlist: PlaylistModel) -> void:
	if _playlists.has(playlist):
		return
	var order: Array = UserGlobals.get_defaults().playlist_order
	var idx = order.find(playlist.path)
	if idx != -1 and idx < _playlists.size():
		_playlists.insert(idx, playlist)
	else:
		_playlists.append(playlist)

func _remove_from_cache(playlist: PlaylistModel) -> void:
	var idx := _playlists.find(playlist)
	if idx != -1:
		_playlists.remove_at(idx)

func _load_ui_playlists() -> void:
	if _playlists.is_empty() or not playlists_vbc or not playlist_btn_scene:
		return
	for pl in _playlists:
		var btn := playlist_btn_scene.instantiate() as PlaylistButton
		if not btn:
			continue
		btn.playlist_object = pl
		btn.playlist_clicked.connect(load_songs_playlist)
		playlists_vbc.add_child(btn)
		playlist_btn_list.append(btn)


func _sort_playlists_by_order() -> void:
	var order: Array = UserGlobals.get_defaults().playlist_order
	if order.is_empty():
		return

	_playlists.sort_custom(func(a, b):
		var ia = order.find(a.path)
		var ib = order.find(b.path)
		if ia == -1: ia = _playlists.size()
		if ib == -1: ib = _playlists.size()
		return ia < ib
	)

func _reload_ui_playlists() -> void:
	_sort_playlists_by_order()
	DevTools.wipe_btns(playlist_btn_list)
	_load_ui_playlists()


# ─── Song Buttons ─────────────────────────────────────────────────────────────

func load_playlist_songs(playlist: PlaylistModel) -> void:
	_current_selected_playlist = playlist
	DevTools.wipe_btns(song_btn_list)
	render_song_btns_from_list(playlist.songs.duplicate())


func load_songs_playlist(playlist: PlaylistModel) -> void:
	if not playlist.songs:
		return
	load_playlist_songs(playlist)


func render_song_btns_from_list(songs: Array) -> void:
	_current_generation += 1
	var generation := _current_generation

	if songs.is_empty():
		DevTools.wipe_btns(song_btn_list)
		return

	song_btn_vbc.freeze_layout()
	DevTools.wipe_btns(song_btn_list)
	await _build_buttons_timesliced(songs, generation)

	if generation == _current_generation:
		song_btn_vbc.thaw_layout()


func _build_buttons_timesliced(songs: Array, generation: int) -> void:
	var i := 0
	while i < songs.size():
		var start := Time.get_ticks_usec()
		while i < songs.size():
			if generation != _current_generation:
				return
			_new_song_btn(songs[i])
			i += 1
			if Time.get_ticks_usec() - start > BUILD_BUDGET_USEC:
				await get_tree().process_frame
				if generation != _current_generation:
					return
				break


func _new_song_btn(song: SongModel) -> void:
	var btn: SongButtonCovered = song_btn_cvr_scn.instantiate()
	btn.song_content = song
	btn.playlist_mode = true
	btn.song_selected.connect(play_playlist_song)
	btn.playlist_removal_request.connect(remove_song_from_current)
	song_btn_list.append(btn)
	btn.index = song_btn_list.find(btn)
	btn.visible = true
	song_btn_vbc.add_child(btn)


func remove_song_from_current(song: SongModel) -> void:
	var btn := _get_button_by_song(song)
	if not btn:
		return

	if not _current_selected_playlist.remove(song):
		push_error("PlaylistControl: couldn't remove song from playlist model.")
		return

	var idx := song_btn_list.find(btn)
	if idx == -1:
		push_error("PlaylistControl: button not found in song_btn_list.")
		return

	song_btn_list.remove_at(idx)
	btn.self_destroy()
	PlaylistManager.save(_current_selected_playlist)


func _get_button_by_song(song: SongModel) -> SongButtonCovered:
	for btn in song_btn_list:
		if (btn as SongButtonCovered).song_content == song:
			return btn as SongButtonCovered
	return null


# ─── Playback ─────────────────────────────────────────────────────────────────

func play_playlist_song(song: SongModel) -> void:
	var idx := _current_selected_playlist.songs.find(song)
	SignalBus.emit_request_playlist(_current_selected_playlist, idx)


# ─── Signal Handlers ──────────────────────────────────────────────────────────

func _on_playlist_deleted(playlist: PlaylistModel) -> void:
	_remove_from_cache(playlist)
	var btn := _get_playlist_btn(playlist)
	if btn:
		playlist_btn_list.erase(btn)
		btn.queue_free()

func _on_playlist_added(playlist: PlaylistModel) -> void:
	_add_to_cache(playlist)
	var btn := playlist_btn_scene.instantiate() as PlaylistButton
	if not btn:
		return
	btn.playlist_object = playlist
	btn.playlist_clicked.connect(load_songs_playlist)
	playlists_vbc.add_child(btn)
	playlist_btn_list.append(btn)

func delete_playlist(playlist: PlaylistModel) -> void:
	SignalBus.emit_request_playlist_delete(playlist)

func _on_new_playlist_btn() -> void:
	if !new_playlist_win: return
	new_playlist_win.open()


func _on_visibility_changed() -> void:
	if visible: _reload_ui_playlists()
