extends Node
class_name ScrobbleProcessor

@export var main_controller: MainController
@export var user_interface_manager: UIManager

# My rules:
# min(song_duration * 0.5, 240 seconds)

var current_timer: Timer = null
var current_song: SongModel

func _ready() -> void:
	SignalBus.song_changed.connect(process_scrobble)
	SignalBus.song_pause.connect(_on_song_pause)
	SignalBus.song_play.connect(_on_song_play)

func kill_timer() -> void:
	if current_timer:
		current_timer.stop()
		current_timer.queue_free()

func new_timer(time: float) -> void:
	if current_timer:
		current_timer.stop()
		current_timer.queue_free()

	var timer = Timer.new()
	timer.wait_time = time
	timer.one_shot = true
	timer.timeout.connect(_on_timeout)

	add_child(timer)
	current_timer = timer

	timer.start()

## Creates a new timer for
func process_scrobble(song: SongModel) -> void:
	current_song = song

	var length = song.Length * 0.001
	if length < 30: return
	var minimum_time: float = min(length * 0.5, 240)

	new_timer(minimum_time)


func _on_timeout() -> void:
	if !current_song: return
	SignalBus.emit_scrobble(current_song)


func _on_song_pause(_arg = null) -> void:
	if !current_timer: return
	current_timer.paused = true


func _on_song_play(_arg = null) -> void:
	if main_controller.playing_now != current_song:
		kill_timer()
		return
	if current_timer and not current_timer.paused:
		return
	if current_timer:
		current_timer.paused = false
