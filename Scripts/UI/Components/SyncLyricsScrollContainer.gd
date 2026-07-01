extends ScrollContainer
class_name SyncLyricsScrollContainer

@export var player: VlcPlayer

@export var disabled_text_lsettings: LabelSettings
@export var enabled_text_lsettings: LabelSettings

@export var vbc: VBoxContainer

var current_line_labels: Dictionary = {}
var parser: LrcParser
var song_loaded: bool = false
var current_active_line: LrcLine

var _pending_lines: Array[LrcLine]
var _batch_size: int = 20
var _generation: int = 0
var _current_generation: int = 0

var _scroll_tween: Tween

func _ready() -> void:
	pass

func clear_all():
	if current_line_labels != {}:
		for line in parser.lines:
			current_line_labels[line].hide()

		for line in parser.lines:
			current_line_labels[line].queue_free()

	current_line_labels = {}
	parser = null
	song_loaded = false
	current_active_line = null


func create_lines() -> void:
	_generation += 1
	_current_generation = _generation

	song_loaded = false
	current_active_line = null
	_pending_lines.clear()

	for child in vbc.get_children():
		child.queue_free()
	current_line_labels.clear()

	_pending_lines = parser.lines.duplicate()


func set_parser(value: LrcParser) -> void:
	parser = value

func load_file(path: String) -> void:
	parser.parse_file(path)
	create_lines()

	song_loaded = true

func load_lyrics_string(lyrics: String) -> void:
	parser.parse_string(lyrics)
	create_lines()

	song_loaded = true

func set_line_active(line: LrcLine):
	if not current_active_line:
		current_active_line = line
		var bv = current_line_labels[current_active_line]
		bv.label_settings = enabled_text_lsettings
		scroll_to_active_line()
		return

	if current_active_line and line != current_active_line:
		var av = current_line_labels[current_active_line]
		av.label_settings = disabled_text_lsettings

		current_active_line = line
		var bv = current_line_labels[current_active_line]
		bv.label_settings = enabled_text_lsettings

		scroll_to_active_line()

func scroll_to_active_line() -> void:
	if not current_active_line: return

	var lbl: Label = current_line_labels.get(current_active_line)
	if not lbl: return

	var lbl_pos = lbl.position.y
	var lbl_height = lbl.size.y
	var scr_height = size.y

	var dst = lbl_pos - (scr_height / 2.0) + (lbl_height / 2.0)
	var scroll_max = get_v_scroll_bar().max_value - scr_height
	dst = clamp(dst, 0, scroll_max)

	if _scroll_tween and _scroll_tween.is_running():
		_scroll_tween.kill()

	_scroll_tween = create_tween()
	_scroll_tween.tween_property(self, "scroll_vertical", dst, 0.5)\
		.set_trans(Tween.TRANS_QUINT)\
		.set_ease(Tween.EASE_OUT)


func _process(_delta: float) -> void:

	if not _pending_lines.is_empty():
		var count := mini(_batch_size, _pending_lines.size())
		for i in count:
			if _generation != _current_generation:
				_pending_lines.clear()
				return
			var line: LrcLine = _pending_lines[i]
			var tmp_label := Label.new()
			tmp_label.text = line.text
			tmp_label.label_settings = disabled_text_lsettings
			tmp_label.custom_minimum_size = Vector2(0, 16)
			tmp_label.autowrap_mode = TextServer.AUTOWRAP_WORD

			current_line_labels[line] = tmp_label
			vbc.add_child(tmp_label)
		_pending_lines = _pending_lines.slice(count)

		if _pending_lines.is_empty():
			song_loaded = true
		return

	if not song_loaded: return
	if not player: return
	if not parser.is_synced: return

	var ln = parser.get_line_at_time(player.Time)
	if ln: set_line_active(ln)
