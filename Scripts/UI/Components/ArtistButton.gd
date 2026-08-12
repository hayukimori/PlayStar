extends Button
class_name ArtistButton

signal clicked(artist: ArtistModel, texture: Texture2D)

@export var name_label: Label
@export var art: TextureRectRounded
@export var default_art: Texture2D
@export var subsonic_indicator: TextureRect

@export var artist: ArtistModel

var key: String
var image_processed: bool = false
var current_image: Texture2D

var is_currently_visible: bool = false
var is_subsonic: bool = false

func _ready() -> void:
	var song_repo: SongRepository = NodeKeeper.song_repository

	if !artist: queue_free()
	if !song_repo: queue_free()

	subsonic_indicator.hide()

	if artist.ArtistIdSn != "":
		is_subsonic = true

	set_process(false)
	set_physics_process(false)
	set_process_input(false)

	set_ui()

	if !is_subsonic:
		var song: = song_repo.GetFirstSongFromArtist(artist)
		if !song: return
		key = song.FilePath
	else:
		key = artist.ArtistIdSn
		subsonic_indicator.show()

	ArtService.ArtReady.connect(_on_art_ready)
	self.pressed.connect(_pressed)


func set_art_visibility(b_visible: bool):
	if b_visible == is_currently_visible:
		return

	is_currently_visible = b_visible

	if b_visible:
		request_art()
	else:
		art.texture = default_art
		image_processed = false

func request_art():
	var art_key = key
	var cached = ArtService.GetIfCached(art_key)

	if cached:
		art.texture = cached
		current_image = cached
		image_processed = true
	else:
		var path = art_key if artist.ArtistIdSn != key else ""
		ArtService.Request(art_key, path, artist.ArtPath)


func _on_art_ready(art_key, texture) -> void:
	if art_key == key:
		art.texture = texture
		current_image = texture
		image_processed = true


func self_destroy() -> void:
	if !is_currently_visible:
		_cleanup_and_free()
		return

	if image_processed:
		_cleanup_and_free()
	else:
		self.hide()
		var delete_timer = Timer.new()
		delete_timer.wait_time = .35
		delete_timer.one_shot = false
		delete_timer.timeout.connect(_on_queue_free_timer_done)
		add_child(delete_timer)
		delete_timer.start()

func _on_queue_free_timer_done():
	if !image_processed: return
	_cleanup_and_free()

func _cleanup_and_free() -> void:
	if ArtService.ArtReady.is_connected(_on_art_ready):
		ArtService.ArtReady.disconnect(_on_art_ready)
	queue_free()

func set_ui() -> void:
	if artist: name_label.text = artist.Name


func _pressed() -> void:
	#clicked.emit(artist, current_image)
	print("Emitting show_artist_window")
	SignalBus.emit_show_artist_window(artist, current_image)
