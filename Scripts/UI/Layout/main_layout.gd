extends Control

@export var config_control: Control

func _ready() -> void:
	SignalBus.invoke_settings_menu.connect(_on_settings_ivk_requested)


func _on_settings_ivk_requested() -> void:
	if !config_control:
		push_error("Missing component: config_control")
		return

	config_control.open()
