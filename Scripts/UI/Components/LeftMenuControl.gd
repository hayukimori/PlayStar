extends Control
class_name LeftMenuControl

@export_group("Setup")
@export var auto_close_enabled: bool = false
@export var auto_close_time: float = 3.0

@export_group("UI Nodes")
@export var action_btn: Button # needs to be toggle button
@export var settings_btn: Button
@export var playlists_btn: Button
@export var all_songs_btn: Button
@export var artists_btn: Button
@export var albuns_btn: Button
@export var history_btn: Button
@export var about_btn: Button
@export var volume_slider: Slider

@export var panel: Panel

@export_group("Textures")
@export var close_btn_texture: Texture2D
@export var open_btn_texture: Texture2D

@export_group("Animation")

@export_subgroup("Positions")
@export var closed_pos: Vector2
@export var open_pos: Vector2

@export_subgroup("Timing")
@export var pos_animation_duration: float = 0.0
@export var alpha_animation_duration: float = 0.0


var _tween: Tween
var is_open: bool = true
var _timer: Timer

func _ready() -> void:
	SignalBus.config_updated.connect(_on_config_updated)

	hide()
	if action_btn:
		action_btn.pressed.connect(_on_action_btn_pressed)

	if settings_btn:
		settings_btn.pressed.connect(_on_settings_btn_pressed)

	if playlists_btn:
		playlists_btn.pressed.connect(_on_playlists_btn_pressed)

	if all_songs_btn:
		all_songs_btn.pressed.connect(_on_all_songs_btn_pressed)

	if artists_btn:
		artists_btn.pressed.connect(_on_artists_btn_pressed)

	if albuns_btn:
		albuns_btn.pressed.connect(_on_albuns_btn_pressed)

	if history_btn:
		history_btn.pressed.connect(_on_history_btn_pressed)

	if about_btn:
		about_btn.pressed.connect(_on_about_btn_pressed)

	close_panel()
	show()

	_timer = Timer.new()
	_timer.wait_time = auto_close_time
	_timer.timeout.connect(_on_autoclose_timeout)
	add_child(_timer)
	_on_config_updated()
	_interaction()



func show_panel() -> void:
	if !panel: return

	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", open_pos, pos_animation_duration)\
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(panel, "modulate:a", 1.0, alpha_animation_duration)

	is_open = true

	if action_btn and close_btn_texture:
		action_btn.icon = close_btn_texture


func close_panel() -> void:
	if !panel: return

	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(self, "position", closed_pos, pos_animation_duration)\
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(panel, "modulate:a", 0.0, alpha_animation_duration)

	is_open = false

	if action_btn and open_btn_texture:
		action_btn.icon = open_btn_texture


func _interaction() -> void:
	if !_timer: return
	_timer.start()

func _on_action_btn_pressed() -> void:
	if is_open: close_panel()
	else:
		show_panel()
		_interaction()

func _on_settings_btn_pressed() -> void:
	SignalBus.emit_invoke_settings_menu()
	_interaction()

func _on_playlists_btn_pressed() -> void:
	SignalBus.emit_invoke_playlists_window()
	_interaction()

func _on_all_songs_btn_pressed() -> void:
	SignalBus.emit_load_all_songs()
	_interaction()

func _on_artists_btn_pressed() -> void:
	SignalBus.emit_invoke_artists_window()
	_interaction()

func _on_albuns_btn_pressed() -> void:
	SignalBus.emit_invoke_albums_window()
	_interaction()

func _on_history_btn_pressed() -> void:
	SignalBus.emit_show_history_window()
	_interaction()

func _on_about_btn_pressed() -> void:
	SignalBus.emit_invoke_about_window()
	_interaction()


func _on_autoclose_timeout() -> void:
	if !auto_close_enabled: return
	if !is_open: return
	close_panel()


func _on_config_updated() -> void:
	var cfg: ConfigModel = UserGlobals.get_config()
	auto_close_enabled = cfg.auto_close_panel
