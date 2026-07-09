extends Button
class_name AlbumButtonCovered


@onready var album_art: SongArtRounded = $AlbumArtRounded
@export var album: AlbumModel
@export var default_album_art: Texture2D

var file_path: String
var image_processed: bool = false

var is_currently_visible := false

func _ready() -> void:
	if !album: queue_free(); return;

	file_path = album.Songs[0].FilePath

	set_process(false)
	set_physics_process(false)
	set_process_input(false)


	ArtService.ArtReady.connect(_on_art_ready)
	#request_art()


func set_art_visibility(b_visible: bool):
	if b_visible == is_currently_visible:
		return

	is_currently_visible = b_visible

	if b_visible:
		request_art()
	else:
		album_art.texture = default_album_art
		image_processed = false



func request_art():
	var key = file_path
	var cached = ArtService.GetIfCached(key)

	if cached:
		album_art.texture = cached
		image_processed = true
	else:
		ArtService.Request(key, file_path)


func _on_art_ready(key, texture) -> void:
	if key == album.Songs[0].FilePath:
		album_art.texture = texture
		image_processed = true


func self_destroy() -> void:
	if image_processed: queue_free(); return;

	self.hide()
	var delete_timer = Timer.new()
	delete_timer.wait_time = .35
	delete_timer.one_shot = false

	add_child(delete_timer)
	delete_timer.start()


func _pressed() -> void:
	SignalBus.emit_show_album_window(album, album_art.texture)
