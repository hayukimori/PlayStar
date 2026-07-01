extends HSlider

var _is_dragging := false

func _ready() -> void:
	SignalBus.player_pos_change.connect(_on_player_pos_change)


func _on_slider_drag_started() -> void:
	_is_dragging = true

func _on_slider_drag_ended(_value_changed: bool) -> void:
	_is_dragging = false
	if _value_changed:
		SignalBus.emit_seek_by_percentage(value)

func _on_player_pos_change(pos_value: float) -> void:
	if _is_dragging:
		return

	set_value_no_signal(pos_value * 100)
