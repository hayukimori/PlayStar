extends Control
class_name ArtistGroupControl

@export_group("Scene Nodes")
@export var nodes_scroll: ScrollContainer
@export var nodes_grid: GridContainer
@export var search_bar: SearchBar

@export_group("Scene Settings")
@export var artist_scn: PackedScene

var _visibility_check_pending := false
var _current_generation := 0
const BUILD_BUDGET_USEC := 1000

var loaded_artists_nodes: Array = []
var _artists: Array = []


func _ready() -> void:
	var cfg = UserGlobals.get_config()
	_artists = NodeKeeper.artist_repository.GetArtists(-1, cfg.ignore_unknown_artists)

	if _artists.is_empty():
		push_error("ArtistGroupControl: no artists loaded.")
		return

	if nodes_scroll:
		nodes_scroll.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)
		resized.connect(_on_scroll_changed.bind(0))
		_on_scroll_changed(0)

	if search_bar:
		search_bar.current_artists = _artists
		search_bar.render_results.connect(_on_search_bar_render_results)
		search_bar.render_default.connect(_on_search_bar_render_default)

	SignalBus.reload_artists.connect(reload_artists)
	_build_artists(_artists)


# ─── Build ────────────────────────────────────────────────────────────────────

func reload_artists() -> void:
	var cfg = UserGlobals.get_config()
	var rest =  NodeKeeper.artist_repository.GetArtists(-1, cfg.ignore_unknown_artists)
	_artists = rest if rest else []

	if search_bar:
		search_bar.current_artists = _artists
	_build_artists(_artists)


func _build_artists(ar_list: Array) -> void:
	_current_generation += 1
	var generation := _current_generation

	if ar_list.is_empty():
		_wipe_nodes()
		return

	nodes_grid.freeze_layout()
	_wipe_nodes()
	await _build_timesliced(ar_list, generation)

	if generation == _current_generation:
		nodes_grid.thaw_layout()
	else:
		nodes_grid.thaw_layout()
		_wipe_nodes()


func _build_timesliced(ar_list: Array, generation: int) -> void:
	var i := 0
	while i < ar_list.size():
		var start := Time.get_ticks_usec()
		while i < ar_list.size():
			if generation != _current_generation:
				return
			_new_artist_node(ar_list[i])
			i += 1
			if Time.get_ticks_usec() - start > BUILD_BUDGET_USEC:
				await get_tree().process_frame
				if generation != _current_generation:
					return
				break


func _new_artist_node(artist: ArtistModel) -> void:
	var node = artist_scn.instantiate()
	node.artist = artist
	node.clicked.connect(_on_artist_clicked)
	loaded_artists_nodes.append(node)
	node.visible = true
	nodes_grid.add_child(node)

	_on_node_added_to_list()


func _wipe_nodes() -> void:
	for node in loaded_artists_nodes:
		node.queue_free()
	loaded_artists_nodes.clear()


# ─── Search ───────────────────────────────────────────────────────────────────

func _on_search_bar_render_results(results: Array) -> void:
	for node in loaded_artists_nodes:
		node.visible = results.any(func(a): return a.Name == node.artist.Name)


func _on_search_bar_render_default() -> void:
	for node in loaded_artists_nodes:
		node.visible = true


# ─── Signal Handlers ──────────────────────────────────────────────────────────

func _on_artist_clicked(artist: ArtistModel, texture) -> void:
	SignalBus.emit_request_artist_window(artist, texture)


func _on_scroll_changed(_value):
	var visible_rect = Rect2(Vector2.ZERO, nodes_scroll.size)
	visible_rect.position += Vector2(0, nodes_scroll.scroll_vertical)
	visible_rect = visible_rect.grow(64)

	for button in nodes_grid.get_children():
		var button_rect = Rect2(button.position, button.size)
		var b_is_visible = visible_rect.intersects(button_rect)
		button.set_art_visibility(b_is_visible)

func _on_node_added_to_list():
	if _visibility_check_pending:
		return
	_visibility_check_pending = true
	call_deferred("_run_visibility_check")

func _run_visibility_check():
	_visibility_check_pending = false
	_on_scroll_changed(0)
