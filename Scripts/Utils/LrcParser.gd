class_name LrcParser
extends RefCounted

# LrcPraser
# Usage:
	# var parser := LrcParser.new()
	# parser.parse_file("path/to/lrc.lrc")
	# var line: Strig = parser.get_at_time(32500)


## Prased Lines, ordered by time_ms
var lines: Array[LrcLine] = []

## Metadata
var title:  String = ""
var artist: String = ""
var album:  String = ""
var author: String = ""   ## tag [by:]
var offset_ms: int = 0    ## song offset (positive or negative)

var is_synced: bool = false

#region Public API
## Loads and parsers a .lrc file by path (returns true if success)
func parse_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		push_error("LrcParser: file not found: %s" % path)
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("LrcParser: could not open: %s" % path)
		return false
	var content := file.get_as_text()
	file.close()
	return parse_string(content)


## Parsers a string from lrc from a string
## returns true if it finds lines
func parse_string(content: String) -> bool:
	_reset()
	for raw_line in content.split("\n"):
		_process_line(raw_line.strip_edges())

	is_synced = lines.size() > 0

	if not is_synced:
		var idx := 0
		for raw_line in content.split("\n"):
			var stripped := raw_line.strip_edges()
			if not stripped.is_empty():
				lines.append(LrcLine.new(idx, stripped))
				idx += 1

		return lines.size() > 0

	# Applies global offset
	if offset_ms != 0:
		for lrc_line in lines:
			lrc_line.time_ms = max(0, lrc_line.time_ms + offset_ms)
	lines.sort_custom(func(a: LrcLine, b: LrcLine) -> bool:
		return a.time_ms < b.time_ms
	)
	return lines.size() > 0


## Returns text from current active line [ param time_ms ]
## (returns last line where time_ms <= argument time_ms)
## If dont reaches the first line, returns ""
func get_at_time(time_ms: int) -> String:
	if lines.is_empty():
		return ""

	var lo := 0
	var hi := lines.size() - 1
	var result := -1
	while lo <= hi:
		var mid := (lo + hi) / 2
		if lines[mid].time_ms <= time_ms:
			result = mid
			lo = mid + 1
		else:
			hi = mid - 1
	if result == -1:
		return ""
	return lines[result].text


## Returns current active line index [param time-ms]; -1 if no lines
func get_index_at_time(time_ms: int) -> int:
	if lines.is_empty():
		return -1
	var lo := 0
	var hi := lines.size() - 1
	var result := -1
	while lo <= hi:
		var mid := (lo + hi) / 2
		if lines[mid].time_ms <= time_ms:
			result = mid
			lo = mid + 1
		else:
			hi = mid - 1
	return result


## Returns an LrcLine active in [param time_ms] or null
func get_line_at_time(time_ms: int) -> LrcLine:
	var idx := get_index_at_time(time_ms)
	if idx == -1:
		return null
	return lines[idx]


## Returns last time_ms
func duration_ms() -> int:
	if lines.is_empty():
		return 0
	return lines[-1].time_ms

#endregion


#region Internals
func _reset() -> void:
	lines.clear()
	title      = ""
	artist     = ""
	album      = ""
	author     = ""
	offset_ms  = 0


## Timestamps [mm:ss.xx] | [mm:ss.xxx] regex
## Accepts [mm:ss] too
const _TIMESTAMP_PATTERN  := r"\[(\d{1,3}):(\d{2})(?:[.:](\d{2,3}))?\]"
const _META_PATTERN       := r"^\[([a-zA-Z]+):(.+)\]$"

func _process_line(raw: String) -> void:
	if raw.is_empty():
		return

	# Tries to get pure metadata
	var meta_rx := RegEx.new()
	meta_rx.compile(_META_PATTERN)
	var meta_m := meta_rx.search(raw)
	if meta_m and not _has_timestamp(raw):
		_parse_meta(meta_m.get_string(1).to_lower(), meta_m.get_string(2).strip_edges())
		return

	# Extracts all timestamps from the line
	var ts_rx := RegEx.new()
	ts_rx.compile(_TIMESTAMP_PATTERN)
	var matches := ts_rx.search_all(raw)
	if matches.is_empty():
		return

	# lyric text starts after the last timestamp
	var last_match  := matches[-1]
	var text_start  := last_match.get_start() + last_match.get_string().length()
	var lyric_text  := raw.substr(text_start).strip_edges()


	# new LrcLine for every found timestamp
	for m in matches:
		var ms := _timestamp_to_ms(m.get_string(1), m.get_string(2), m.get_string(3))
		lines.append(LrcLine.new(ms, lyric_text))


func _has_timestamp(raw: String) -> bool:
	var rx := RegEx.new()
	rx.compile(_TIMESTAMP_PATTERN)
	return rx.search(raw) != null


func _timestamp_to_ms(min_s: String, sec_s: String, frac_s: String) -> int:
	var minutes := int(min_s)
	var seconds := int(sec_s)
	var frac    := 0
	if frac_s != "":
		# normalize
		if frac_s.length() == 3:
			frac = int(frac_s) / 10
		else:
			frac = int(frac_s)
	return (minutes * 60 + seconds) * 1000 + frac * 10


func _parse_meta(tag: String, value: String) -> void:
	match tag:
		"ti":     title     = value
		"ar":     artist    = value
		"al":     album     = value
		"by":     author    = value
		"offset": offset_ms = int(value)
