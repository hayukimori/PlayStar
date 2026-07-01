extends Button
class_name AnimatedOptionButton

@export var anim_duration: float = 0.3


var original_minimum_size: Vector2
var closed_minimum_size: Vector2 = Vector2.ZERO
var active_tween: Tween

func _ready() -> void:
	original_minimum_size = Vector2(24.0, 0.0)
	self.custom_minimum_size = closed_minimum_size
	self.modulate.a = 0.0

func animate_open() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	self.show()

	active_tween = create_tween()
	active_tween.set_parallel(true)

	active_tween.tween_property(self, "modulate:a", 1.0, anim_duration)
	active_tween.tween_property(self, "custom_minimum_size", original_minimum_size, anim_duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func animate_close() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	active_tween = create_tween()
	active_tween.set_parallel(true)

	active_tween.tween_property(self, "modulate:a", 0.0, anim_duration)
	active_tween.tween_property(self, "custom_minimum_size", closed_minimum_size, anim_duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	await active_tween.finished
	self.hide()
