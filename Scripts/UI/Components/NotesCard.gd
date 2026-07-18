extends Control

@export var trect: TextureRect
@export var title_label: Label
@export var description_label: Label

var _tween: Tween
var _timer: Timer

var text_library: Array[Dictionary] = [
	{
		"title": "Memory Diet",
		"description": "PlayStar's memory footprint went from 1.1 GiB to under 800 MB after one very long optimization night."
	},
	{
		"title":"Backend Journey",
		"description": "This player has been through three different audio backends. VLC won, in the end."
	},
	{
		"title":"Solo Build",
		"description": "Every waveform, every pixel of this UI — built solo, one bug at a time."
	},
	{
		"title":"Why History Exists",
		"description": "The listen history feature exists because I kept forgetting what I played an hour ago."
	},
	{
		"title":"74 Minutes",
		"description": "The 74-minute length of audio CDs is rumored to have been chosen to fit Beethoven's 9th Symphony in full."
	},
	{
		"title":"No Gaps Allowed",
		"description": "Gapless playback became a big deal because albums like Dark Side of the Moon were mixed to flow without silence between tracks."
	},
	{
		"title": "Text On Disc",
		"description": "CD-Text, a rarely-used feature, let discs store track titles directly on the disc itself — no internet required."
	},
	{
		"title": "Before Crossfade",
		"description": "Before streaming, DJs relied on pitch-adjustable turntables just to keep two songs in sync — no crossfade button in sight."
	}
]

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = 8
	_timer.timeout.connect(_timer_timeout)

	add_child(_timer)
	_timer.start()

	display_random()

func set_texts(title: String, description: String) -> void:
	title_label.text = title
	description_label.text = description


func display_random() -> void:
	var st = text_library.pick_random()
	var tt = st.get("title")
	var ds = st.get("description")

	await animate_text_out()
	set_texts(tt, ds)
	await animate_text_in()



func animate_text_out() -> void:
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(title_label, "modulate:a", 0.0, 1.0)
	_tween.tween_property(description_label, "modulate:a", 0.0, 1.0)

	await _tween.finished

func animate_text_in() -> void:
	if _tween: _tween.kill()
	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(title_label, "modulate:a", 1.0, 1.0)
	_tween.tween_property(description_label, "modulate:a", 1.0, 1.0)

	await _tween.finished


func _timer_timeout() -> void:
	display_random()

func _process(delta: float) -> void:
	if trect:
		trect.rotation += 3 * delta
