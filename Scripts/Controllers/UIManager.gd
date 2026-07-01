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
@export var search_results_container: FreezableBoxContainer
@export var shuffle_button: ShuffleButton
@export var repeat_mode_button: RepeatButton
@export var search_button: Button
@export var search_control: Control
@export var search_bar_line_edit: SearchBar
@export var songs_button_list_scroll_container: ScrollContainer
@export var songs_button_list: FreezableBoxContainer
@export var current_time_label: Label
@export var length_count_label: Label
@export var progress_color_rect: ColorRect
@export var reload_playlist_button: Button
@export var current_queu_name_label: Label
@export var search_cover_panel: Panel

@export_subgroup("Playing Now screen")
@export var title_label: Label
@export var artist_label: Label
@export var album_label: Label
@export var art_trr: TextureRectRounded
#endregion


#region Packed Scenes
@export_subgroup("Packed Scenes")
@export var song_btn_cvr_scn: PackedScene
#endregion

#region Extras export
@export_group("Extra export")
@export var default_album_art: Texture2D
#endregion

#region State
var loaded_buttons: Array[Button] = []
var loaded_search_buttons: Array[Button] = []

const BUILD_BUDGET_USEC := 4000
var _current_generation := 0
var _current_generation_search := 0
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

	if search_bar_line_edit:
		search_bar_line_edit.render_results.connect(_on_search_bar_render_results)
		search_bar_line_edit.render_default.connect(_on_search_bar_render_default)

	SignalBus.scroll_to_current.connect(_on_scroll_to_current)
	SignalBus.volume_changed_externally.connect(_on_volume_changed_external)
	SignalBus.song_changed.connect(set_playing_now)
	SignalBus.toggle_search.connect(_on_toggle_search)




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
	var btn = get_button_by_song(song)
	if btn: btn.start_playing_now()

func stop_playing_now(song: SongModel) -> void:
	var btn = get_button_by_song(song)
	if btn: btn.stop_playing_now()
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

	var scr_c = songs_button_list_scroll_container
	var btn = get_button_by_song(info)
	if not btn: return

	var btn_pos = btn.position.y
	var btn_height = btn.size.y
	var scr_height = scr_c.size.y

	var dst = btn_pos - (scr_height / 2.0) + (btn_height / 2.0)
	var scroll_max = scr_c.get_v_scroll_bar().max_value - scr_height
	dst = clamp(dst, 0, scroll_max)

	var tween = create_tween()
	tween.tween_property(scr_c, "scroll_vertical", dst, 0.5)\
		.set_trans(Tween.TRANS_QUINT)\
		.set_ease(Tween.EASE_OUT)
#endregion

#region Playing Now
func set_playing_now(song: SongModel) -> void:
	if title_label: title_label.text = song.Title
	if artist_label: artist_label.text = song.Artist
	if album_label: album_label.text = song.Album

	var texture = VlcPlayer.GetTextureFrom(song.FilePath)
	art_trr.texture = texture if texture else default_album_art

#endregion

#region Button Management
## Creates new button and adds it to parent_node
func new_song_btn(song: SongModel, append_to: Array[Button], parent_node: Node) -> Button:
	var song_button = null

	song_button = song_btn_cvr_scn.instantiate()

	song_button.song_content = song
	song_button.connect("song_selected", _on_song_selected)

	append_to.append(song_button)
	song_button.index = append_to.find(song_button)
	song_button.visible = true
	parent_node.add_child(song_button)

	return song_button


## Destroys all buttons from an array
func wipe_btns(btnlist: Array[Button]) -> void:
	if len(btnlist) > 0:
		for btn in btnlist:
			btn.self_destroy() #NOTE: Button needs to have `self_destroy` function
		btnlist.clear()


## Clears all buttons from the main list
func wipe_all() -> void:
	wipe_btns(loaded_buttons)
	# INTEGRATION: MainController needs to call stop_process() before wipe_all()


## (MAIN LIST) Renders all buttons from an SongModel Array
func render_song_btns_from_list(songs: Array[SongModel]) -> void:
	_current_generation += 1
	var generation := _current_generation

	if songs.is_empty():
		wipe_btns(loaded_buttons)
		return

	songs_button_list.freeze_layout()
	wipe_btns(loaded_buttons)
	await _build_buttons_timesliced(songs, generation)

	if generation == _current_generation:
		songs_button_list.thaw_layout()


## (SEARCH) Renders buttons from search results
func render_search_btns_from_list(songs: Array) -> void:
	_current_generation_search += 1
	var generation := _current_generation_search

	if songs.is_empty():
		wipe_btns(loaded_search_buttons)
		return

	search_results_container.freeze_layout()
	wipe_btns(loaded_search_buttons)
	await _build_search_buttons_timesliced(songs, generation)

	if generation == _current_generation_search:
		search_results_container.thaw_layout()


func _build_buttons_timesliced(songs: Array, generation: int) -> void:
	var i := 0
	while i < songs.size():
		var start := Time.get_ticks_usec()
		while i < songs.size():
			if generation != _current_generation: return
			new_song_btn(songs[i], loaded_buttons, songs_button_list)
			i += 1
			if Time.get_ticks_usec() - start > BUILD_BUDGET_USEC:
				await get_tree().process_frame
				if generation != _current_generation: return
				break


func _build_search_buttons_timesliced(songs: Array, generation: int) -> void:
	var i := 0
	while i < songs.size():
		var start := Time.get_ticks_usec()
		while i < songs.size():
			if generation != _current_generation_search: return
			new_song_btn(songs[i], loaded_search_buttons, search_results_container)
			i += 1
			if Time.get_ticks_usec() - start > BUILD_BUDGET_USEC:
				await get_tree().process_frame
				if generation != _current_generation_search: return
				break
#endregion


#region Button Search
## Returns button from SongModel if it is located to the loaded_buttons
func get_button_by_song(song: SongModel) -> SongButtonCovered:
	for button in loaded_buttons:
		if button.song_content == song:
			return button
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
		wipe_btns(loaded_search_buttons)
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
