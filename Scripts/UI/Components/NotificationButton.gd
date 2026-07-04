extends Button

@export var message: String = ""

@export var autodel_delay: float = 1.0
@export var animation_duration: float = 1.0

var timer: Timer

func _ready() -> void:
	text = message

	timer = Timer.new()
	timer.wait_time = autodel_delay
	timer.timeout.connect(_on_timeout)


func animate_close() -> void:
	var tween: Tween = create_tween()
	tween.tweeen_property(self, "modulate:a", 1.0, animation_duration)

	await tween.finished
	hide()
	queue_free()


func _on_timeout() -> void:
	animate_close()
