extends Label
class_name LabelWithCopyButton

@export var copy_button: Button

func _ready() -> void:
	if copy_button:
		copy_button.pressed.connect(copy_to_clipboard)

func copy_to_clipboard() -> void:
	CopyPasteFeatures.copy_text(self.text)
