extends Button
class_name NotificationButton

@export var message: String = ""

@export var autodel_delay: float = 1.0
@export var animation_duration: float = 1.0

var timer: Timer

func _ready() -> void:
	if !message: animate_close()

	text = message

	timer = Timer.new()
	timer.wait_time = autodel_delay

	add_child(timer)

	timer.timeout.connect(_on_timeout)
	timer.start()


func animate_close() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, animation_duration)

	await tween.finished
	hide()
	queue_free()


func _on_timeout() -> void:
	animate_close()
