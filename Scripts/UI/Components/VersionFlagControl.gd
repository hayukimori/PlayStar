extends Control
class_name VersionFlagControl

@export var version: String
@onready var button: Button = $Button

var download_link: String = ""

func _ready() -> void:
	if !version:
		push_error("Version not set for VersionFlagControl")
		queue_free()

	download_link = "https://github.com/hayukimori/PlayStar/releases/%s" % version
	button.pressed.connect(_on_button_pressed)

	var autodelete_timer = Timer.new()
	autodelete_timer.wait_time = 10.0
	autodelete_timer.one_shot = true
	autodelete_timer.timeout.connect(_on_auto_delete_timeout)
	add_child(autodelete_timer)

	autodelete_timer.start()

	_set_btn()


func _set_btn() -> void:
	button.text = "New version available: v%s" % version

func _on_button_pressed() -> void: OS.shell_open(download_link)
func _on_auto_delete_timeout() -> void: queue_free()