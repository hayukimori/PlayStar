extends Window
class_name HybridWindow


var internal_theme: Theme = preload("res://UI/ComponentThemes/HybridWindowTheme.tres")

func _ready() -> void:
	self.close_requested.connect(close)
	theme = internal_theme


## Opens window using current config (if possible)
func open() -> void:
	var current_config = UserGlobals.get_config()
	if current_config.use_native_window:
		_open_as_native()
	else:
		_open_as_internal()

## Hides window
func close() -> void:
	self.hide()

## Executes Queue Free
func self_delete() -> void:
	self.queue_free()

## Open window setting `force_native = true`
func _open_as_native() -> void:
	force_native = true
	self.show()

## Opens window setting `force_native = false`
func _open_as_internal() -> void:
	self.show()
