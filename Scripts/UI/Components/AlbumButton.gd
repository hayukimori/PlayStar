extends Button
class_name AlbumButton


@export var name_label: Label
@export var art: TextureRectRounded

@export var album: AlbumModel

var file_path: String
var image_processed: bool = false
var current_image: Texture2D

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
		request_art()




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
