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
	else:
		title = "Invalid window"

func _load_ui_playlists(
	add_to_cache: Array[PlaylistModel] = [],
	remove_from_cache: Array[PlaylistModel] = []
) -> void:
	if _playlists.is_empty() or not playlists_vbc or not playlist_btn_scene:
		return

	for pl in add_to_cache:
		_playlists.append(pl)

	for rm in remove_from_cache:
		var idx := _playlists.find(rm)
		if idx != -1:
			_playlists.remove_at(idx)

	for pl in _playlists:
		var btn := playlist_btn_scene.instantiate() as PlaylistButton
		if not btn:
			continue
		btn.playlist_object = pl
		btn.playlist_clicked.connect(_add_current_to)
		playlists_vbc.add_child(btn)
		playlist_btn_list.append(btn)


func _reload_ui_playlists(
	add_to_cache: Array[PlaylistModel] = [],
	remove_from_cache: Array[PlaylistModel] = []
) -> void:
	DevTools.wipe_btns(playlist_btn_list)
	_load_ui_playlists(add_to_cache, remove_from_cache)


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

	else:
		SignalBus.emit_pop_msg_request("Invalid content")
		safe_quit()


func safe_quit() -> void:
	close()
	queue_free()

func _on_playlist_deleted(playlist: PlaylistModel) -> void:
	_reload_ui_playlists([], [playlist])

func _on_playlist_added(playlist: PlaylistModel) -> void:
	_reload_ui_playlists([playlist], [])


func _on_new_playlist_btn() -> void:
	if !new_playlist_win: return
	new_playlist_win.open()
