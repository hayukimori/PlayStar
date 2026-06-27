extends Control

@export var config_control: Control

func _ready() -> void:
	await get_tree().create_timer(2.0).timeout
	config_control.open()
