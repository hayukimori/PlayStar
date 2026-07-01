extends HybridWindow
class_name SingleAlbumWindow

@export_group("Nodes")
@export var name_label: Label
@export var art_trr: TextureRectRounded
@export var add_to_playlist: ToPlaylistButton
@export var songs_scroll_container: ScrollContainer
@export var songs_vbox: FreezableBoxContainer

@export var song_button_cover_scene: PackedScene
@export var album_button_cover_scene: PackedScene

@export var default_album_art: Texture2D

var current_album: AlbumModel
var database: DatabaseManager

var loaded_albums_buttons: Array[Button]
var loaded_song_buttons: Array[Button]

var songs_cache: Array[SongModel]
var albuns_cache: Array[AlbumModel]

var _current_generation := 0
const BUILD_BUDGET_USEC := 1000

var playlist_manager: PlaylistManager

func _ready() -> void:
		playlist_manager = PlaylistManager.new()
		database = NodeKeeper.current_database

		SignalBus.show_album_window.connect(load_album)
		close_requested.connect(close)


func load_album(album: AlbumModel, texture) -> void:
		# Wipe previous info
		DevTools.wipe_btns(loaded_albums_buttons)
		DevTools.wipe_btns(loaded_song_buttons)

		current_album = album
		if !current_album: return

		name_label.text = current_album.AlbumName
		title = current_album.AlbumName

		if texture:
			art_trr.texture = texture
		else:
			art_trr.texture = default_album_art

		add_to_playlist.content = current_album
		setup_songs()

		open()


func setup_songs() -> void:
		var album_songs: Array[SongModel] = current_album.Songs

		if !album_songs: return
		songs_cache = album_songs.duplicate()
		render_song_btns_from_list(album_songs)


func wipe_all() -> void:
		albuns_cache.clear()
		songs_cache.clear()

		DevTools.wipe_btns(loaded_albums_buttons)
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

		return song_button


## Renders buttons from list (argument)
func render_song_btns_from_list(songs: Array) -> void:
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
	var index = songs_cache.find(song)
	var queue = PlaylistManager.new_queue(current_album.AlbumName, songs_cache.duplicate())

	SignalBus.emit_request_playlist(queue, index)


func _on_add_to_playlist_pressed() -> void:
	pass

func _go_back() -> void:
		self.hide()
		wipe_all()
