extends Control

@export var ignore_unknown_artists_btn: Button

var current_config: ConfigModel

func _ready() -> void:
	if !ignore_unknown_artists_btn:
		push_error("Missing Component: ignore_unknown_artists_btn")
		return

	ignore_unknown_artists_btn.pressed.connect(_on_ignore_ua_pressed)

func update_config() -> void: current_config = UserGlobals.get_config()
func save_config() -> void: UserGlobals.save_config(current_config)

func _on_ignore_ua_pressed() -> void:
	update_config()
	var value = ignore_unknown_artists_btn.button_pressed
	current_config.ignore_unknown_artists = value
	save_config()
