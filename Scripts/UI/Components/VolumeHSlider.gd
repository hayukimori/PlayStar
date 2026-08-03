extends HSlider


func _ready() -> void:
	SignalBus.volume_up_request.connect(_on_volume_up_request)
	SignalBus.volume_down_request.connect(_on_volume_down_request)


# UIManager collects volume_changed_externally signal and emits volume_changed signal, which is connected to this component. This is to avoid a feedback loop when the volume is changed externally (e.g. by the system volume keys).
func _on_volume_up_request() -> void: value += 5
func _on_volume_down_request() -> void: value -= 5
