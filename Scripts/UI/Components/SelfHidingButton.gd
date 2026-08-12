extends Button


var _tween: Tween = null

func _ready() -> void:
	self.mouse_entered.connect(_on_mouse_entered)
	self.mouse_exited.connect(_on_mouse_exited)

	await get_tree().create_timer(.6).timeout
	_fade(0.0)

func _fade(target_alpha: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "self_modulate:a", target_alpha, 0.15)

func _on_mouse_entered() -> void: _fade(1.0)
func _on_mouse_exited() -> void: _fade(0.0)
