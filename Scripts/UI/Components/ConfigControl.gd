extends Control

@export var window: Window
@export var bg_color: ColorRect

func _ready() -> void:
	window.close_requested.connect(_on_close_requested)

func open() -> void:
	bg_color.show()
	pop_config()

func close() -> void:
	bg_color.hide()
	hide()

func pop_config() -> void:
	if window:
		window.popup()

func _on_close_requested() -> void:
	if Locker.is_setting_locked() or Locker.is_scan_locked():
		return
	window.hide()
	close()
