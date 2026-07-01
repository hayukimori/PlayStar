extends RefCounted
class_name LrcLine

# Lyric line + timestamp
var time_ms: int
var text: String

func _init(p_time_ms: int = 0, p_text: String = "") -> void:
	time_ms = p_time_ms
	text = p_text

func _to_string() -> String:
	return "[%d ms] %s" % [time_ms, text]
