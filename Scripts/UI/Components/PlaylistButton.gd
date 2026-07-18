extends Button
class_name PlaylistButton

signal playlist_clicked(obj: PlaylistModel)

@export var playlist_object: PlaylistModel
@export var name_label: Label
@export var song_count_label: Label
@export var delete_button: AnimatedOptionButton
@export var rename_button: AnimatedOptionButton

@export var show_edit_options: bool = false
@export var move_up_button: Button
@export var move_down_button: Button


var s_count_text: String = "%s Songs"
var click_opened: bool = false
var option_buttons: Array[AnimatedOptionButton]
var ignore_buttons: Array[AnimatedOptionButton]

func _ready() -> void:
	if !playlist_object: queue_free();
	_set_ui()

	delete_button.pressed.connect(_on_delete_request)
	rename_button.pressed.connect(_on_rename_pressed)
	self.gui_input.connect(_on_button_gui_event)

func _set_ui() -> void:
	if !song_count_label: return
	if !name_label: return
	if !playlist_object: print("No song object, queue free()"); queue_free(); return;

	option_buttons.append(delete_button)
	option_buttons.append(rename_button)
	option_buttons.append(move_up_button)
	option_buttons.append(move_down_button)

	if !show_edit_options:
		ignore_buttons.append(move_up_button)
		ignore_buttons.append(move_down_button)
		ignore_buttons.append(rename_button)

	move_up_button.pressed.connect(_on_playlist_up_pressed)
	move_down_button.pressed.connect(_on_playlist_down_pressed)

	name_label.text = playlist_object.name
	song_count_label.text = s_count_text % str(int(playlist_object.songs.size()))



# Only mouse input events
func _on_button_gui_event(event: InputEvent) -> void:
	if !(event is InputEventMouseButton): return
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if click_opened:
			for i in option_buttons:
				if i not in ignore_buttons:
					i.animate_close()
			click_opened = false
		else:
			for i in option_buttons:
				if i not in ignore_buttons:
					i.animate_open()
			click_opened = true


func _pressed() -> void:
	playlist_clicked.emit(playlist_object)


func _on_delete_request() -> void:
	SignalBus.emit_request_playlist_delete(playlist_object)

func _on_rename_pressed() -> void:
	SignalBus.emit_request_rename_window(playlist_object)

func _on_playlist_up_pressed() -> void:
	SignalBus.emit_request_playlist_up(playlist_object)

func _on_playlist_down_pressed() -> void:
	SignalBus.emit_request_playlist_down(playlist_object)

func self_destroy() -> void:
	queue_free()
