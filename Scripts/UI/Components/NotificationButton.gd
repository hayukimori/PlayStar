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

	if NodeKeeper.current_theme:
		set_palette(NodeKeeper.current_theme)


func set_palette(palette: GTKColorPalette) -> void:
	var sbx := get_theme_stylebox("normal", "Button").duplicate()
	sbx.bg_color = palette.HeaderbarBgColor

	add_theme_stylebox_override("normal", sbx)
	add_theme_color_override("icon_normal_color", palette.AccentColor)
	add_theme_color_override("font_color", palette.ViewFgColor)

func animate_close() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, animation_duration)

	await tween.finished
	hide()
	queue_free()


func _on_timeout() -> void:
	animate_close()
