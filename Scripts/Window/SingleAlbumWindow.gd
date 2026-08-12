extends HybridWindow
class_name SingleAlbumWindow

@export_group("Nodes")
@export var name_label: Label
@export var art_trr: TextureRectRounded
@export var add_to_playlist: ToPlaylistButton
@export var songs_scroll_container: ScrollContainer
@export var songs_vbox: VirtualizedVBoxList

@export var song_button_cover_scene: PackedScene
@export var album_button_cover_scene: PackedScene

@export var default_album_art: Texture2D

var current_album: AlbumModel
var database: DatabaseManager

var loaded_albums_buttons: Array[Button]

var songs_cache: Array[SongModel]
var albuns_cache: Array[AlbumModel]

var playlist_manager: PlaylistManager

func _ready() -> void:
	playlist_manager = PlaylistManager.new()
	database = NodeKeeper.current_database

	SignalBus.show_album_window.connect(load_album)
	close_requested.connect(close)

	songs_vbox.setup(songs_scroll_container, _spawn_song_button)


func load_album(album: AlbumModel, texture) -> void:
		# Wipe previous info
		DevTools.wipe_btns(loaded_albums_buttons)
		songs_vbox.clear()

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
	if songs.is_empty():
		songs_vbox.clear()
		return
	songs_vbox.set_items(songs)


func play_song(song: SongModel) -> void:
	var index = songs_cache.find(song)
	var queue = PlaylistManager.new_queue(current_album.AlbumName, songs_cache.duplicate())

	SignalBus.emit_request_playlist(queue, index)

func _go_back() -> void:
	self.hide()
	wipe_all()
