extends ColorRect
class_name ProgressBarCR

func _ready() -> void:
	SignalBus.player_pos_change.connect(_on_pos_change)

func _on_pos_change(value: float) -> void:
	material.set("shader_parameter/progress", value)
