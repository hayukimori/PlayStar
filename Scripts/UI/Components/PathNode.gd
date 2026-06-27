extends HBoxContainer
class_name PathNode

signal path_delete_request(path: String)

@onready var delete_btn: Button = $DeleteButton
@onready var path_label: Label = $PathLabel

@export var path: String

func _ready() -> void:
	if !path:
		push_error("PathNode received no path")
		queue_free()

	path_label.text = path
	delete_btn.pressed.connect(_on_delete_request)

# Queue free, requesting to remove path from user settings
func _on_delete_request() -> void:
	path_delete_request.emit(path)

	await get_tree().create_timer(.2).timeout
	queue_free()
