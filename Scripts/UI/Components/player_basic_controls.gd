extends Control

@export var play_pause_btn: Button
@export var skip_btn: Button
@export var prev_btn: Button

@export var prev_btn_texture: Texture2D
@export var next_btn_texture: Texture2D
@export var pause_btn_texture: Texture2D
@export var play_btn_texture: Texture2D

func _ready() -> void:
	SignalBus.song_pause.connect(_on_pause)
	SignalBus.song_play.connect(_on_play)

	skip_btn.pressed.connect(SignalBus.emit_song_skip_next)
	prev_btn.pressed.connect(SignalBus.emit_song_skip_prev)
	play_pause_btn.pressed.connect(SignalBus.emit_play_pause_requested)

func _on_pause() -> void:
	if not play_pause_btn: return
	play_pause_btn.icon = play_btn_texture


func _on_play() -> void:
	if not play_pause_btn: return
	play_pause_btn.icon = pause_btn_texture
