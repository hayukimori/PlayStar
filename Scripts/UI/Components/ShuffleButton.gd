class_name ShuffleButton
extends Button

signal toggle_shuffle(state: bool)

@export_group("Button UI")
@export var texture_on: Texture2D
@export var texture_off: Texture2D

func _ready() -> void:
	set_process(false)
	set_physics_process(false)

	if (icon != texture_on) or (icon != texture_off):
		if texture_off: icon = texture_off

func load_state(state: bool) -> void:
	button_pressed = state

func _change_texture(state: bool) -> void:
	if texture_on and state: icon = texture_on
	if texture_off and !state: icon = texture_off

func _toggled(toggled_on: bool) -> void:
	_change_texture(toggled_on)
	toggle_shuffle.emit(toggled_on)
