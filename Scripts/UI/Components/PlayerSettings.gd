extends Control

@export var ignore_unknown_artists_btn: CheckButton
@export var native_window_btn: CheckButton
@export var auto_close_btn: CheckButton

var current_config: ConfigModel

func _ready() -> void:
	if !ignore_unknown_artists_btn:
		push_error("Missing Component: ignore_unknown_artists_btn")
		return

	ignore_unknown_artists_btn.pressed.connect(_on_ignore_ua_pressed)
	native_window_btn.pressed.connect(_on_native_win_pressed)
	auto_close_btn.pressed.connect(_on_autoclose_pressed)

	load_default_config()


func update_config() -> void:
	current_config = UserGlobals.get_config()

func load_default_config() -> void:
	update_config()
	ignore_unknown_artists_btn.button_pressed = current_config.ignore_unknown_artists
	native_window_btn.button_pressed = current_config.use_native_window
	auto_close_btn.button_pressed = current_config.auto_close_panel


func _save_bool_config(property: String, value: bool) -> void:
	update_config()
	current_config.set(property, value)
	UserGlobals.save_config(current_config)

	SignalBus.emit_config_updated()


func _on_ignore_ua_pressed() -> void:
	var value = ignore_unknown_artists_btn.button_pressed
	_save_bool_config("ignore_unknown_artists", value)


func _on_native_win_pressed() -> void:
	var value = native_window_btn.button_pressed
	_save_bool_config("use_native_window", value)

func _on_autoclose_pressed() -> void:
	var value = auto_close_btn.button_pressed
	_save_bool_config("auto_close_panel", value)
