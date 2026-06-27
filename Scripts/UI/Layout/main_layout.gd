extends Control

@export var config_control: Control

func _ready() -> void:
	if config_control:
		get_tree().create_timer(2.0)
		config_control.open()
