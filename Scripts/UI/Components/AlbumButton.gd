extends Button
class_name AlbumButton


@export var name_label: Label
@export var art: TextureRectRounded
@export var default_album_art: Texture2D

@export var album: AlbumModel

var file_path: String
var image_processed: bool = false
var current_image: Texture2D

var is_currently_visible: bool = false

func _ready() -> void:
	if !album: queue_free()

	var song: SongModel = album.Songs[0]

	set_process(false)
	set_physics_process(false)
	set_process_input(false)

	set_ui()

	self.pressed.connect(_on_clicked)

	if song:
		file_path = song.FilePath
		ArtService.ArtReady.connect(_on_art_ready)



func set_art_visibility(b_visible: bool):
	if b_visible == is_currently_visible:
		return

	is_currently_visible = b_visible

	if b_visible:
		request_art()
	else:
		art.texture = default_album_art
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
	if album: name_label.text = album.AlbumName


func _on_clicked() -> void:
	print("album clicked")
	SignalBus.emit_show_album_window(album, current_image)
