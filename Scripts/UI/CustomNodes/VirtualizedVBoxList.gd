class_name VirtualizedVBoxList
extends VBoxContainer

signal item_spawned(item, index)

const ROW_HEIGHT := 64.0

var rows: Array = []
var row_height: float = ROW_HEIGHT
var overscan_rows: int = 6

var _scroll: ScrollContainer
var _spawner: Callable
var _top_spacer: Control
var _bottom_spacer: Control
var _live: Dictionary = {}
var _live_min := -1
var _live_max := -1
var _active: SongModel = null

func _ready() -> void:
	resized.connect(_recompute)

## Setup the virtualized list with a scroll container, a spawner callable, and an optional item height.
func setup(scroll: ScrollContainer, spawner: Callable, item_height: float = ROW_HEIGHT) -> void:
	_scroll = scroll
	_spawner = spawner
	row_height = item_height
	_ensure_spacers()
	_scroll.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)
	_recompute()


func set_items(items: Array) -> void:
	clear()
	rows = items
	custom_minimum_size.y = rows.size() * row_height
	_recompute()


func clear() -> void:
	for node in _live.values():
		if is_instance_valid(node):
			node.queue_free()
	_live.clear()
	_live_min = -1
	_live_max = -1
	rows = []
	custom_minimum_size.y = 0
	if _top_spacer:
		_top_spacer.custom_minimum_size.y = 0
	if _bottom_spacer:
		_bottom_spacer.custom_minimum_size.y = 0


func set_active(item: SongModel) -> void:
	var previous: SongModel = _active
	_active = item
	for node in _live.values():
		if not is_instance_valid(node):
			continue
		if node.song_content == previous:
			node.stop_playing_now()
		if node.song_content == item:
			node.start_playing_now()


func get_node_for(item) -> Node:
	for node in _live.values():
		if is_instance_valid(node) and node.song_content == item:
			return node
	return null


func get_item_index(item) -> int:
	return rows.find(item)


func item_count() -> int:
	return rows.size()


func _ensure_spacers() -> void:
	if _top_spacer == null:
		_top_spacer = Control.new()
		_top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_top_spacer)
		move_child(_top_spacer, 0)
	if _bottom_spacer == null:
		_bottom_spacer = Control.new()
		_bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_bottom_spacer)


func _on_scroll_changed(_value) -> void:
	_recompute()


func _recompute() -> void:
	if rows.is_empty() or _scroll == null:
		return

	var scroll_val := _scroll.scroll_vertical
	var view_h := maxf(_scroll.size.y, 1.0)
	var total := rows.size()

	var first := int(floor(scroll_val / row_height)) - overscan_rows
	first = clampi(first, 0, total - 1)
	var last := int(ceil((scroll_val + view_h) / row_height)) + overscan_rows - 1
	last = clampi(last, 0, total - 1)

	if first == _live_min and last == _live_max:
		return

	for idx in _live.keys():
		if idx < first or idx > last:
			_free_row(idx)

	for idx in range(first, last + 1):
		if not _live.has(idx):
			_insert_row(idx)

	_live_min = first
	_live_max = last
	_update_spacers()
	_sort_rows()

func _insert_row(idx: int) -> void:
	var node = _spawner.call(rows[idx], idx)
	if node == null:
		return
	node.size_flags_horizontal = SIZE_EXPAND_FILL
	_live[idx] = node
	add_child(node)
	move_child(node, 1)
	if node.has_method("set_art_visibility"):
		node.set_art_visibility(true)
	if _active != null and rows[idx] == _active and node.has_method("start_playing_now"):
		node.start_playing_now()
	item_spawned.emit(rows[idx], idx)

func _free_row(idx: int) -> void:
	var node = _live.get(idx)
	if node and is_instance_valid(node):
		node.queue_free()
	_live.erase(idx)

func _update_spacers() -> void:
	if _top_spacer:
		_top_spacer.custom_minimum_size.y = (_live_min * row_height)
	if _bottom_spacer:
		_bottom_spacer.custom_minimum_size.y = ((rows.size() - 1 - _live_max) * row_height)

func _sort_rows() -> void:
	var keys := _live.keys()
	keys.sort()
	var pos := 1
	for k in keys:
		move_child(_live[k], pos)
		pos += 1
