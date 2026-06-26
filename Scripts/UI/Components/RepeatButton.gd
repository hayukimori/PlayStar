extends Button
class_name RepeatButton

signal toggle_repeat(state: Definitions.RepeatMode)

@export_group("Button UI")
@export var texture_off: ImageTexture
@export var texture_rp_one: ImageTexture
@export var texture_rp_queue: ImageTexture
@export var default_texture: ImageTexture

var current_state: Definitions.RepeatMode = Definitions.RepeatMode.OFF

func _ready() -> void:
	set_process(false)
	set_physics_process(false)


func load_state(state: Definitions.RepeatMode) -> void:
	current_state = state
	_change_texture(state)

func _change_texture(state: Definitions.RepeatMode) -> void:
	match state:
		Definitions.RepeatMode.OFF:
				icon = (
						texture_off if texture_off else default_texture
				)
		Definitions.RepeatMode.REPEAT_ONE:
				icon = (
						texture_rp_one if texture_rp_one else default_texture
			)
		Definitions.RepeatMode.REPEAT_QUEUE:
				icon = (
						texture_rp_queue if texture_rp_queue else default_texture
				)
		_:
			icon = default_texture


func next_state() -> void:
	var is_last_state = current_state >= (len(Definitions.RepeatMode) - 1)
	var local_state = current_state

	if is_last_state:
		local_state = Definitions.RepeatMode.OFF
	else:
		local_state = (current_state + 1) as Definitions.RepeatMode

	load_state(local_state)

func _pressed() -> void:
	next_state()
	toggle_repeat.emit()
