class_name SongButtonCovered
extends Button

signal song_selected(song: SongModel)
signal playlist_removal_request(song: SongModel)

@export var song_content: SongModel
@export var playlist_mode: bool = false
@export var index: int = 0

@export var title_label: Label
@export var artist_label: Label
@export var album_art: SongArtRounded
@export var hq_btn: Button
@export var playing_now_bar: ColorRect
@export var add_to_playlist_btn: ToPlaylistButton
@export var remove_from_current_playlist_btn: Button
@export var default_album_art: Texture2D

@onready var original_label_settings: LabelSettings = title_label.label_settings

var image_processed: bool = false
var hbc_hovered: bool = false
var click_opened: bool = false
var is_currently_visible = false


func _ready() -> void:
	if !song_content: queue_free(); return;

	set_process(false)
	set_physics_process(false)
	set_process_input(false)

	var title = song_content.Title
	var artist = song_content.Artist

	title_label.text = title
	artist_label.text = artist if artist.strip_edges() != "" else "Unknown"

	var flac = (song_content.FilePath.get_extension() == "flac")
	if flac: hq_btn.visible = true

	add_to_playlist_btn.content = song_content

	#add_to_playlist_btn.pressed.connect(_add_to_playlist)
	self.gui_input.connect(_on_button_gui_event)
	self.pressed.connect(_pressed)

	if playlist_mode:
		remove_from_current_playlist_btn.show()
		remove_from_current_playlist_btn.pressed.connect(_remove_request)

	ArtService.ArtReady.connect(_on_art_ready)



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
	var key = song_content.FilePath
	var cached = ArtService.GetIfCached(key)

	if cached:
		album_art.texture = cached
		image_processed = true
	else:
		ArtService.Request(key, song_content.FilePath)


func _on_art_ready(key, texture):
	if key == song_content.FilePath:
		album_art.texture = texture


func _pressed() -> void:
	emit_signal("song_selected", song_content)


func start_playing_now() -> void:
	var new_settings = original_label_settings.duplicate()
	var clr: Color = Color("#e75f9f")

	new_settings.font_color = clr
	new_settings.outline_size = 1
	new_settings.outline_color = clr
	title_label.label_settings = new_settings

	playing_now_bar.visible = true

func stop_playing_now() -> void:
		playing_now_bar.visible = false
		title_label.label_settings = original_label_settings

func self_destroy() -> void:
	if image_processed: queue_free(); return;

	self.hide()
	var delete_timer = Timer.new()
	delete_timer.wait_time = .35
	delete_timer.one_shot = false

	add_child(delete_timer)
	delete_timer.start()

func _add_to_playlist() -> void:
		SignalBus.emit_add_song_request(song_content)

func _on_queue_free_timer_done():
		if !image_processed: return
		queue_free()


# Only mouse input events
func _on_button_gui_event(event: InputEvent) -> void:
	if !(event is InputEventMouseButton): return

	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if click_opened:
			add_to_playlist_btn.animate_close()
			click_opened = false
		else:
			add_to_playlist_btn.animate_open()
			click_opened = true


func _remove_request() -> void:
		playlist_removal_request.emit(song_content)


func _on_mouse_exited() -> void:
	if !click_opened:
		pass
		#add_to_playlist_btn.visible = false
