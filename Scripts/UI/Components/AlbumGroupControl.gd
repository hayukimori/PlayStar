extends Control
class_name AlbumGroupControl

@export_group("Scene Nodes")
@export var nodes_grid: GridContainer
@export var search_bar: SearchBar

@export_group("Scene Settings")
@export var album_scn: PackedScene

const BUILD_BUDGET_USEC := 1000

var _current_generation := 0
var _albums: Array = []
var loaded_album_nodes: Array = []


func _ready() -> void:
	var cfg = UserGlobals.get_config()
	_albums = NodeKeeper.album_repository.GetAllAlbums(-1, cfg.ignore_unknown_artists)


	if _albums.is_empty():
		push_error("AlbumGroupControl: no albums loaded.")
		return

	if search_bar:
		search_bar.current_albums = _albums
		search_bar.render_results.connect(_on_search_bar_render_results)
		search_bar.render_default.connect(_on_search_bar_render_default)

	_build_albums(_albums)


# ─── Build ────────────────────────────────────────────────────────────────────

func reload_albums() -> void:
	var cfg = UserGlobals.get_config()
	_albums = NodeKeeper.album_repository.GetAlbums(-1, cfg.ignore_unknown_artists)
	if search_bar:
		search_bar.current_albums = _albums
	_build_albums(_albums)


func _build_albums(al_list: Array) -> void:
	_current_generation += 1
	var generation := _current_generation

	if al_list.is_empty():
		_wipe_nodes()
		return

	nodes_grid.freeze_layout()
	_wipe_nodes()
	await _build_timesliced(al_list, generation)

	if generation == _current_generation:
		nodes_grid.thaw_layout()
	else:
		nodes_grid.thaw_layout()
		_wipe_nodes()


func _build_timesliced(al_list: Array, generation: int) -> void:
	var i := 0
	while i < al_list.size():
		var start := Time.get_ticks_usec()
		while i < al_list.size():
			if generation != _current_generation:
				return
			_new_album_node(al_list[i])
			i += 1
			if Time.get_ticks_usec() - start > BUILD_BUDGET_USEC:
				await get_tree().process_frame
				if generation != _current_generation:
					return
				break


func _new_album_node(album: AlbumModel) -> void:
	var node = album_scn.instantiate()
	node.album = album
	loaded_album_nodes.append(node)
	node.visible = true
	nodes_grid.add_child(node)


func _wipe_nodes() -> void:
	for node in loaded_album_nodes:
		node.queue_free()
	loaded_album_nodes.clear()


# ─── Search ───────────────────────────────────────────────────────────────────

func _on_search_bar_render_results(results: Array) -> void:
	for node in loaded_album_nodes:
		node.visible = results.any(func(a): return a.AlbumName == node.album.AlbumName)


func _on_search_bar_render_default() -> void:
	for node in loaded_album_nodes:
		node.visible = true
