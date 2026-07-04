extends Control

@export_category("Pop message controller")

@export_group("Nodes and PackedScene")
@export var notifications_vbox: VBoxContainer ##REQURED
@export var notification_button_scene: PackedScene

@export_group("Notification Config")
@export var animation_duration: float = 1.0
@export var autodelete_delay: float = 1.0

func _ready() -> void:
	var has_errors: bool = false

	if !notifications_vbox:
		push_error("Notifications VBoxContainer not set")
		has_errors = true

	if !notification_button_scene:
		push_error("Notification Button Scene not set.")
		has_errors = true

	if has_errors: return


	SignalBus.pop_msg_request.connect(new_msg)

func new_msg(message: String) -> void:
	var scn: NotificationButton = notification_button_scene.instantiate() as NotificationButton

	scn.message = message
	scn.animation_duration = animation_duration
	scn.autodel_delay = autodelete_delay

	notifications_vbox.add_child(scn)
