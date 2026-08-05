extends Node
class_name UIManager

## Manages UI elements
## Connects with MainController via signals


#region UI Node Exports
@export_category("UI Settings")
@export_group("Nodes")

@export var volume_slider: Slider
@export var progress_slider: HSlider
@export var search_results_scroll_container: ScrollContainer
@export var search_results_container: VirtualizedVBoxList
@export var shuffle_button: ShuffleButton
@export var repeat_mode_button: RepeatButton
@export var search_button: Button
@export var search_control: Control
@export var search_bar_line_edit: SearchBar
@export var songs_button_list_scroll_container: ScrollContainer
@export var songs_button_list: VirtualizedVBoxList
@export var current_time_label: Label
@export var length_count_label: Label
@export var progress_color_rect: ColorRect
@export var reload_playlist_button: Button
@export var current_queu_name_label: Label
@export var search_cover_panel: Panel
@export var copy_song_button: Button

@export_subgroup("Playing Now screen")
@export var title_label: Label
@export var artist_label: Label
@export var album_label: Label
@export var art_trr: TextureRectRounded

@export_subgroup("F12 (screenshot) screen")
@export var song_info_f12_control: SongInfoF12
@export var f12_svp: SubViewport
#endregion


#region Packed Scenes
@export_subgroup("Packed Scenes")
@export var song_btn_cvr_scn: PackedScene
#endregion

#region Extras export
@export_group("Extra export")
@export var default_album_art: Texture2D
#endregion


func _ready() -> void:
	if !shuffle_button: push_warning("Missing component: shuffle_button (toggle)")
	if !repeat_mode_button: push_warning("Missing component: repeat_mode_button")

	if shuffle_button: shuffle_button.toggle_shuffle.connect(_on_shuffle_button_toggled)
	if repeat_mode_button: repeat_mode_button.toggle_repeat.connect(_on_repeat_mode_button_toggled)
	if progress_slider: progress_slider.value_changed.connect(_on_h_slider_value_changed)
	if reload_playlist_button: reload_playlist_button.pressed.connect(_on_reload_requested)
	if volume_slider: volume_slider.value_changed.connect(_on_volume_slider_value_changed)
	if search_button: search_button.pressed.connect(_on_toggle_search)
	if copy_song_button: copy_song_button.pressed.connect(SignalBus.emit_copy_song)

	if search_bar_line_edit:
		search_bar_line_edit.render_results.connect(_on_search_bar_render_results)
		search_bar_line_edit.render_default.connect(_on_search_bar_render_default)

	SignalBus.scroll_to_current.connect(_on_scroll_to_current)
	SignalBus.volume_changed_externally.connect(_on_volume_changed_external)
	SignalBus.song_changed.connect(set_playing_now)
	SignalBus.toggle_search.connect(_on_toggle_search)

	SignalBus.capture_now.connect(capture_sifo)

	_init_virtual_lists()


func _init_virtual_lists() -> void:
	if songs_button_list and songs_button_list_scroll_container:
		songs_button_list.setup(songs_button_list_scroll_container, _spawn_main_song_button)
	if search_results_container and search_results_scroll_container:
		search_results_container.setup(search_results_scroll_container, _spawn_search_song_button)




#region Queue Label
func set_queue_label(queue_name: String) -> void:
	if current_queu_name_label:
		current_queu_name_label.text = queue_name

func set_search_bar_queue(queue: Array) -> void:
	if search_bar_line_edit:
		search_bar_line_edit.current_queue = queue
#endregion


#region Song Length Label
func update_length_label(song: SongModel) -> void:
	if length_count_label:
		length_count_label.text = MiscTools.MsToSec(song.Length)

## Updates current time label text (00:00)
func update_curr_time_label(text: String) -> void:
	if !current_time_label: return
	if text == current_time_label.text: return

	current_time_label.text = text


## Updates progress bar (vlaue is float 0.0 to 1.0)
func update_progress(value: float) -> void:
	if !progress_color_rect: return
	var vl: float = value * 100


#endregion


#region Button State (playing now indicator)
func start_playing_now(song: SongModel) -> void:
	if songs_button_list: songs_button_list.set_active(song)

func stop_playing_now(_song: SongModel) -> void:
	if songs_button_list: songs_button_list.set_active(null)
#endregion


#region Repeat / Random button state
func set_rdm_button(mode: bool) -> void:
	if not shuffle_button: return
	shuffle_button.load_state(mode)

func set_rpt_button(mode: int) -> void:
	if not repeat_mode_button: return
	repeat_mode_button.load_state(mode as Definitions.RepeatMode)
#endregion


#region Scroll
func scroll_to_song(info: SongModel) -> void:
	if not songs_button_list_scroll_container: return
	if not songs_button_list: return

	var scr_c = songs_button_list_scroll_container
	var index = songs_button_list.get_item_index(info)
	if index == -1: return

	var scr_height = scr_c.size.y
	var dst = (index * songs_button_list.row_height) - (scr_height / 2.0) + (songs_button_list.row_height / 2.0)
	var scroll_max = scr_c.get_v_scroll_bar().max_value - scr_height
	dst = clamp(dst, 0, scroll_max)

	var tween = create_tween()
	tween.tween_property(scr_c, "scroll_vertical", dst, 0.5)\
		.set_trans(Tween.TRANS_QUINT)\
		.set_ease(Tween.EASE_OUT)


#endregion

#region Playing Now
var _art_generation := 0
func set_playing_now(song: SongModel) -> void:
	if title_label: title_label.text = song.Title
	if artist_label: artist_label.text = song.Artist
	if album_label: album_label.text = song.Album

	_art_generation += 1
	var generation := _art_generation

	# Local
	var texture: Texture2D = VlcPlayer.GetTextureFrom(song.FilePath)

	if texture:
		print("Adding local texture")
		art_trr.texture = texture
	elif song.ArtPath != "":
		print("Adding texture from song.ArtPath")
		art_trr.texture = default_album_art
		_fetch_art_async(song.ArtPath, generation)
	else:
		print("Using default texture")
		art_trr.texture = default_album_art

	set_sifo(song, texture)

func _fetch_art_async(url: String, generation: int) -> void:
	var http := HTTPRequest.new()
	add_child(http)

	http.request_completed.connect(
		func(result, code, _headers, body):
			http.queue_free()
			if generation != _art_generation:
				print("Differente generation")
				return
			if result != HTTPRequest.RESULT_SUCCESS or code != 200:
				print("Couldn't download art")
				return

			var img := Image.new()
			if img.load_jpg_from_buffer(body) == OK:
				art_trr.texture = ImageTexture.create_from_image(img)
			else:
				print("Invalid image.")
	)

	http.request(url)

#endregion

#region Screenshot
func render_pn_to_image() -> Image:
	f12_svp.transparent_bg = true

	await get_tree().process_frame
	var image := f12_svp.get_texture().get_image()

	return image

func capture_sifo() -> void:
	var image = await render_pn_to_image()

	var tmp_path := "user://playing_now_texure.png"
	image.save_png(tmp_path)

	MiscTools.CopyFileToClipboard(tmp_path, true)
	SignalBus.emit_pop_msg_request("Picture copied to clipboard")

func set_sifo(song: SongModel, texture) -> void:
	song_info_f12_control.set_ui(song, texture)

#endregion

#region Button Management
func _spawn_main_song_button(song: SongModel, index: int) -> Node:
	if song_btn_cvr_scn == null: return null
	var song_button = song_btn_cvr_scn.instantiate() as SongButtonCovered
	song_button.song_content = song
	song_button.index = index
	song_button.connect("song_selected", _on_song_selected)
	return song_button


func _spawn_search_song_button(song: SongModel, index: int) -> Node:
	if song_btn_cvr_scn == null: return null
	var song_button = song_btn_cvr_scn.instantiate() as SongButtonCovered
	song_button.song_content = song
	song_button.index = index
	song_button.connect("song_selected", _on_song_selected)
	return song_button


func wipe_all() -> void:
	if songs_button_list:
		songs_button_list.clear()


## (MAIN LIST) Renders buttons from an SongModel Array
func render_song_btns_from_list(songs: Array[SongModel]) -> void:
	if songs_button_list == null: return
	if songs.is_empty():
		songs_button_list.clear()
		return
	songs_button_list.set_items(songs)


## (SEARCH) Renders buttons from search results
func render_search_btns_from_list(songs: Array) -> void:
	if search_results_container == null: return
	if songs.is_empty():
		search_results_container.clear()
		return
	search_results_container.set_items(songs)


#endregion


#region Button Search
## Returns button from SongModel if it is currently instantiated
func get_button_by_song(song: SongModel) -> SongButtonCovered:
	if songs_button_list:
		return songs_button_list.get_node_for(song) as SongButtonCovered
	return null

## Returns a song index from the queue (requeres path and queue Array)
func get_index_by_path(target_path: String, queue: Array) -> int:
	return queue.find_custom(
		func(song): return song.FilePath == target_path
	)
#endregion


#region Signals -> SignalBus / MainController

func _on_song_selected(song: SongModel) -> void:
	# INTEGRATION: MainController listens SignalBus.song_selected
	print("Song selected: ", song.Title)
	SignalBus.emit_song_selected(song)

func _on_scroll_to_current() -> void:
	# INTEGRATION: MainController needs to emit scroll_to_current with current songg,
	# or UIManager can listen to scroll_to_current from a SongModel
	SignalBus.emit_scroll_to_current_requested()

func _on_shuffle_button_toggled(state: bool) -> void:
	SignalBus.emit_toggle_shuffle_to_state(state)

func _on_repeat_mode_button_toggled(state: Definitions.RepeatMode) -> void:
	SignalBus.emit_toggle_repeat_to_state(state)

func _on_reload_requested() -> void:
	SignalBus.emit_reload_requested()

func _on_volume_slider_value_changed(value: float) -> void:
	SignalBus.emit_volume_changed(value)

func _on_volume_changed_external(value: int) -> void:
	if !volume_slider: return
	if value <= -1:
		SignalBus.emit_volume_changed(volume_slider.value)
		return
	volume_slider.value = value

func _on_h_slider_value_changed(value: float) -> void:
	SignalBus.emit_seek_by_percentage(value)


func _on_toggle_search() -> void:
	if !search_bar_line_edit: return
	if !search_control: return

	var vsb = search_control.visible

	if vsb: search_control.hide()
	else: search_control.show()



func _on_search_bar_render_results(results: Array) -> void:
	# INTEGRATION: UIManager needs access to current_play_queue to filter
	# Option: MainController connects this signal and sends it with
	# a queue filtered back via public method

	# Sends signal to MainController to process and return
	SignalBus.emit_search_results_requested(results)

func _on_search_bar_render_default() -> void:
	if search_results_container and search_results_scroll_container:
		search_results_container.clear()
		search_results_scroll_container.visible = false
		songs_button_list.visible = true

	if search_cover_panel:
		search_cover_panel.hide()

#endregion


#region Public: Main Controller calls

## Call to render results when ready
func show_search_results(results_as_local: Array) -> void:
	songs_button_list.visible = true
	search_results_scroll_container.visible = true
	if search_cover_panel:
		search_cover_panel.show()
	render_search_btns_from_list(results_as_local)

#endregion
