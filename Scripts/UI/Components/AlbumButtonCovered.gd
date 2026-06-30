extends Button
class_name AlbumButtonCovered


@onready var album_art: TextureRectRounded = $TextureRectRounded
@export var album: AlbumModel

var file_path: String
var image_processed: bool = false

func _ready() -> void:
	if !album: queue_free(); return;

	file_path = album.Songs[0].FilePath

	set_process(false)
	set_physics_process(false)
	set_process_input(false)


	ArtService.ArtReady.connect(_on_art_ready)
	request_art()



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


func self_destroy() -> void:
	if image_processed: queue_free(); return;

	self.hide()
	var delete_timer = Timer.new()
	delete_timer.wait_time = .35
	delete_timer.one_shot = false

	add_child(delete_timer)
	delete_timer.start()


func _pressed() -> void:
	SignalBus.emit_show_album(album)
	print("Entering album: ", album.AlbumName)
