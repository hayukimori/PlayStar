extends HybridWindow
class_name AddToPlaylistWindow

@export var current_content: Variant

@export var playlists_vbc: VBoxContainer
@export var playlist_btn_scene: PackedScene
@export var new_playlist_btn: Button
@export var new_playlist_win: HybridWindow

var playlist_btn_list: Array
var _playlists: Array


func _ready() -> void:
	SignalBus.playlist_added.connect(_on_playlist_added)
	self.close_requested.connect(safe_quit)
	new_playlist_btn.pressed.connect(_on_new_playlist_btn)

	_playlists = PlaylistManager.load_playlists()
	_sort_playlists_by_order()
	_load_ui_playlists()

	change_title()


func change_title() -> void:
	var temp = "Add %s to"

	var cc = current_content
	if (cc is SongModel):
		title = temp % [cc.Title]
	elif (cc is ArtistModel):
		title = temp % [cc.Name]
	elif (cc is AlbumModel):
		title = temp % cc.AlbumArtist
	elif (cc is Array[SongModel]):
		title = temp % "songs"
	else:
		title = "Invalid window"

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
		btn.playlist_clicked.connect(_add_current_to)
		playlists_vbc.add_child(btn)
		playlist_btn_list.append(btn)


func _reload_ui_playlists() -> void:
	DevTools.wipe_btns(playlist_btn_list)
	_load_ui_playlists()


func _add_current_to(playlist: PlaylistModel) -> void:
	var cc = current_content
	if (cc is SongModel):
		PlaylistManager.insert_and_save(playlist, [cc])
		SignalBus.emit_pop_msg_request("%s added to %s" % [cc.Title, playlist.name])
		safe_quit()

	elif (cc is ArtistModel):
		var repo := NodeKeeper.song_repository
		var songs: Array[SongModel] = repo.GetSongsFromArtist(cc, 10000)
		PlaylistManager.insert_and_save(playlist, songs)
		SignalBus.emit_pop_msg_request("%s added to %s" % [cc.Name, playlist.name])
		safe_quit()

	elif (cc is AlbumModel):
		PlaylistManager.insert_and_save(playlist, cc.Songs)
		SignalBus.emit_pop_msg_request("%s added to %s" % [cc.AlbumName, playlist.name])
		safe_quit()

	elif (cc is Array[SongModel]):
		PlaylistManager.insert_and_save(playlist, cc)
		SignalBus.emit_pop_msg_request("%s added to %s" % ["songs", playlist.name])

	else:
		SignalBus.emit_pop_msg_request("Invalid content")
		safe_quit()


func safe_quit() -> void:
	close()
	queue_free()

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
	btn.playlist_clicked.connect(_add_current_to)
	playlists_vbc.add_child(btn)
	playlist_btn_list.append(btn)

func _get_playlist_btn(playlist: PlaylistModel) -> PlaylistButton:
	for btn in playlist_btn_list:
		if (btn as PlaylistButton).playlist_object == playlist:
			return btn as PlaylistButton
	return null

func _on_new_playlist_btn() -> void:
	if !new_playlist_win: return
	new_playlist_win.open()
