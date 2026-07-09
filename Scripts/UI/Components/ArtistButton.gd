extends Button
class_name ArtistButton

signal clicked(artist: ArtistModel, texture: Texture2D)

@export var name_label: Label
@export var art: TextureRectRounded
@export var default_art: Texture2D

@export var artist: ArtistModel

var file_path: String
var image_processed: bool = false
var current_image: Texture2D

var is_currently_visible: bool = false


func _ready() -> void:
	var song_repo: SongRepository = NodeKeeper.song_repository

	if !artist: queue_free()
	if !song_repo: queue_free()

	var song: SongModel = song_repo.GetFirstSongFromArtist(artist)


	set_process(false)
	set_physics_process(false)
	set_process_input(false)


	set_ui()

	if song:
		file_path = song.FilePath
		ArtService.ArtReady.connect(_on_art_ready)
		#request_art()

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
	var key = file_path
	var cached = ArtService.GetIfCached(key)

	if cached:
		art.texture = cached
		current_image = cached
		image_processed = true
	else:
		ArtService.Request(key, file_path)


func _on_art_ready(key, texture) -> void:
	if key == file_path:
		art.texture = texture
		current_image = texture
		image_processed = true


func self_destroy() -> void:
	if image_processed: queue_free(); return;

	self.hide()
	var delete_timer = Timer.new()
	delete_timer.wait_time = .35
	delete_timer.one_shot = false

	add_child(delete_timer)
	delete_timer.start()



func set_ui() -> void:
	if artist: name_label.text = artist.Name


func _pressed() -> void:
	#clicked.emit(artist, current_image)
	print("Emitting show_artist_window")
	SignalBus.emit_show_artist_window(artist, current_image)
