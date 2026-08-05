extends HybridWindow
class_name SingleArtistWindow

@export_group("Nodes")
@export var name_label: Label
@export var art_trr: TextureRectRounded
@export var add_to_playlist: ToPlaylistButton

@export var albums_scroll_container: ScrollContainer
@export var songs_scroll_container: ScrollContainer
@export var albums_hbox: FreezableBoxContainer
@export var songs_vbox: VirtualizedVBoxList

@export var song_button_cover_scene: PackedScene
@export var album_button_cover_scene: PackedScene

@export var default_album_art: Texture2D

var current_artist: ArtistModel
var database: DatabaseManager

var loaded_albums_buttons: Array[Button]

var songs_cache: Array[SongModel]
var albums_cache: Array[AlbumModel]

var playlist_manager: PlaylistManager

var _current_generation_b := 0
const BUILD_BUDGET_USEC := 1000

var _visibility_check_pending := false

func _ready() -> void:
	playlist_manager = PlaylistManager.new()
	database = NodeKeeper.current_database

	SignalBus.show_artist_window.connect(load_artist)
	close_requested.connect(close)

	songs_vbox.setup(songs_scroll_container, _spawn_song_button)

	if albums_scroll_container:
		albums_scroll_container.get_h_scroll_bar().value_changed.connect(_on_album_scroll_changed)



func load_artist(artist: ArtistModel, texture) -> void:
		# Wipe previous info
		DevTools.wipe_btns(loaded_albums_buttons)
		songs_vbox.clear()

		current_artist = artist
		if !current_artist: return

		name_label.text = current_artist.Name
		title = current_artist.Name

		if texture:
			art_trr.texture = texture
		else:
			art_trr.texture = default_album_art

		add_to_playlist.content = current_artist
		await setup_albums()
		await setup_songs()

		open()


func setup_songs() -> void:
	var song_repo: SongRepository = NodeKeeper.song_repository

	if !database: return
	if !song_repo: return

	var songs: Array[SongModel] = []

	if current_artist.ArtistIdSn:
		var svc = NodeKeeper.subsonic_service
		var rest = await DevTools.race_signals(svc.ArtistSongsFetched, svc.ArtistSongsFetchError, svc.GetSongsByArtist.bind(current_artist.ArtistIdSn))
		if rest.get("winner") != "a":
			push_error("Error getting artist songs")
			return
		else:
			var restb = rest.get("results")[0]
			if len(restb) > 0:
				var tmp_songs = restb[0] as Array[SongModel]
				songs.append_array(tmp_songs)


	else:
		songs = song_repo.GetSongsFromArtist(current_artist, 10000)

	if !songs: return
	songs_cache = songs.duplicate()
	render_song_btns_from_list(songs)


func setup_albums() -> void:
	var album_repo: AlbumRepository = NodeKeeper.album_repository
	if !database: return
	if !album_repo: return

	var artist_albums: Array[AlbumModel]

	if current_artist.ArtistIdSn:
		var svc = NodeKeeper.subsonic_service
		var rest = await DevTools.race_signals(
			svc.AlbumsFetched,
			svc.Error,
			svc.GetAlbumsByArtist.bind(
				current_artist.ArtistIdSn,
				true
			)
		)

		if rest.get("winner") != "a":
			push_error("Error getting artist albums")
			return
		else:
			var restb = rest.get("results")[0]
			if len(restb) > 0:
				var tmp_albums = restb[0] as Array[AlbumModel]
				artist_albums.append_array(tmp_albums)
	else:
		artist_albums = album_repo.GetAlbumsFromArtist(current_artist, 10000)

	if !artist_albums: return
	albums_cache = artist_albums.duplicate()

	for album in albums_cache:
		print("Name: %s - Songs: %d" % [album.AlbumName, len(album.Songs)])
	render_album_btns_from_list(albums_cache)


func wipe_all() -> void:
	albums_cache.clear()
	songs_cache.clear()

	DevTools.wipe_btns(loaded_albums_buttons)
	songs_vbox.clear()


## Creates a new button (requires SongModel)
func _spawn_song_button(song: SongModel, index: int) -> Node:
	var song_button = song_button_cover_scene.instantiate() as SongButtonCovered
	song_button.song_content = song
	song_button.index = index
	song_button.song_selected.connect(play_song)
	return song_button


## Creates a new button (requires Album)
func new_album_btn(album: AlbumModel, append_to: Array[Button], parent_node: Node) -> Button:
		var album_button = null

		album_button = album_button_cover_scene.instantiate() as AlbumButtonCovered

		album_button.album = album

		append_to.append(album_button)
		album_button.visible = true
		parent_node.add_child(album_button)

		_on_node_added_to_list()

		return album_button


## Renders buttons from list (argument)
func render_song_btns_from_list(songs: Array) -> void:
		if songs.is_empty():
			songs_vbox.clear()
			return
		songs_vbox.set_items(songs)


## Renders albums buttons from list (argument)
func render_album_btns_from_list(albums: Array) -> void:
		_current_generation_b += 1
		var generation := _current_generation_b

		if albums.is_empty():
			DevTools.wipe_btns(loaded_albums_buttons)
			return

		albums_hbox.freeze_layout()

		DevTools.wipe_btns(loaded_albums_buttons)
		await _build_albums_buttons_timesliced(albums, generation)

		if generation == _current_generation_b:
			albums_hbox.thaw_layout()


# ALBUMS
func _build_albums_buttons_timesliced(albums: Array, generation: int) -> void:
	var i := 0

	while i < albums.size():
		var start := Time.get_ticks_usec()

		while i < albums.size():
			if generation != _current_generation_b:
					return
			new_album_btn(albums[i], loaded_albums_buttons, albums_hbox)
			i += 1

			if Time.get_ticks_usec() - start > BUILD_BUDGET_USEC:
					await get_tree().process_frame
					if generation != _current_generation_b: return
					break


func _on_album_scroll_changed(_value):
	var visible_rect = Rect2(Vector2.ZERO, albums_scroll_container.size)
	visible_rect.position += Vector2(albums_scroll_container.scroll_horizontal, 0)

	for button in albums_hbox.get_children():
		if button is AlbumButtonCovered:
			var button_rect = Rect2(button.position, button.size)
			var b_is_visible = visible_rect.intersects(button_rect)
			button.set_art_visibility(b_is_visible)


func play_song(song: SongModel) -> void:
	var index = songs_cache.find(song)
	var queue = PlaylistManager.new_queue(current_artist.Name, songs_cache.duplicate())

	SignalBus.emit_request_playlist(queue, index)


func _on_node_added_to_list():
	if _visibility_check_pending:
		return
	_visibility_check_pending = true
	call_deferred("_run_visibility_check")

func _run_visibility_check():
	_visibility_check_pending = false
	_on_album_scroll_changed(0)


func _go_back() -> void:
		self.hide()
		wipe_all()
