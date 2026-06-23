extends Node

var settings_lock: bool = false

func _ready() -> void:
    get_viewport().get_focus_changeed.connect(_on_focus_changed)

## Gets settings_lock
func is_setting_locked() -> bool: 
    return settings_lock

## Sets config to settings_lock
func set_settings_lock(value: bool) -> void: 
    settings_lock = value

## releases focus if the control is not LineEdit
func _on_focus_changed(node: Node) -> void:
    if node is Control and not (node is LineEdit or node is TextEdit):
        node.release_focus()

