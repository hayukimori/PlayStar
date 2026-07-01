extends Node
class_name KeyboardController

var action_map: Dictionary[String, Callable] = {}
func _ready() -> void:
	setup_user_custom()

func setup_user_custom() -> void:
	action_map = {
		"play_pause": SignalBus.emit_play_pause_requested,
		"next_song": SignalBus.emit_next_track_requested,
		"previous_song": SignalBus.emit_prev_track_requested,

		"toggle_shuffle": SignalBus.emit_toggle_shuffle,
		"toggle_repeat": SignalBus.emit_toggle_repeat,
		"toggle_search": SignalBus.emit_toggle_search,

		"seek_left": SignalBus.emit_seek_offset_requested.bind(-10000), #10s
		"seek_right": SignalBus.emit_seek_offset_requested.bind(10000), #-10s

		"scroll_to_current": SignalBus.emit_scroll_to_current,
		"settings_shortcut": SignalBus.emit_invoke_settings_menu,

		"playlists_shortcut": SignalBus.emit_invoke_playlists_window,
		"artists_shortcut": SignalBus.emit_invoke_artists_window,
		"albums_shortcut": SignalBus.emit_invoke_albums_window,

		"copy_song": SignalBus.emit_copy_song,
		"capture_playing_now": SignalBus.emit_capture_now
	}


#region Keyboard Handler
func _unhandled_input(event: InputEvent) -> void:
	for action in action_map:
		if event.is_action_pressed(action):
			action_map[action].call()
#endregion
