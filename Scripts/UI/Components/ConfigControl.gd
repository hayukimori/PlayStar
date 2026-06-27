extends Control

@export var window: Window


func _ready() -> void:
	window.close_requested.connect(_on_close_requested)

	await get_tree().create_timer(2.0).timeout
	pop_config()

func pop_config() -> void:
	if window:
		window.popup()

func _on_close_requested() -> void:
	window.hide()
