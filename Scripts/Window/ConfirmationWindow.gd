extends HybridWindow
class_name ConfirmationWindow

signal confirmed

@export var text: String = ""
@export var confirmed_message: String = ""

@export var confirm_button: Button
@export var cancel_button: Button
@export var main_label: Label

func _ready() -> void:
	confirm_button.pressed.connect(_confirm)
	cancel_button.pressed.connect(close_qf)
	close_requested.connect(close_qf)

	_set_ui()

func _set_ui() -> void:
	main_label.text = text

func _confirm() -> void:
	confirmed.emit()
	if confirmed_message:
		SignalBus.emit_pop_msg_request(confirmed_message)

	close_qf()

func close_qf() -> void:
	self.close()
	queue_free()
