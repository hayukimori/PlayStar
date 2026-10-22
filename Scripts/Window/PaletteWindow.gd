extends HybridWindow
class_name PaletteWindowControl

@export_category("Nodes & Config")
@export_group("Scene Nodes")
@export var palettes_scroll: ScrollContainer
@export var palettes_grid: FlexBoxFreezableGridContainer
@export var new_palette_btn: Button
@export var new_palette_win: HybridWindow
@export var rename_palette_win: HybridWindow
@export var save_palette_btn: Button
@export var gtk_opt_palette_item: PaletteItem

@export_group("Packed Scenes")
@export var palette_item_scn: PackedScene

var _palettes: Array[GTKColorPalette] = []
var loaded_palette_nodes: Array = []

var _current_generation := 0
const BUILD_BUDGET_USEC := 1000

# ─── Ready ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	GtkThemeProvider.ColorsLoaded.connect(_on_gtk_colors_loaded)
	_palettes = PaletteManager.load_palettes()

	palettes_grid.base_n = 148

	if new_palette_btn:
		new_palette_btn.pressed.connect(_on_new_palette_btn)

	if save_palette_btn:
		save_palette_btn.pressed.connect(_save_current_theme)

	SignalBus.palette_added.connect(_on_palette_added)
	SignalBus.palette_deleted.connect(_on_palette_deleted)
	SignalBus.palette_renamed.connect(_on_palette_renamed)

	SignalBus.request_palette_edit.connect(_on_palette_edit_request)
	SignalBus.request_palette_delete.connect(_on_palette_delete_request)

	self.close_requested.connect(self.close)

	_load_ui_palettes()


func _on_gtk_colors_loaded(palette: GTKColorPalette) -> void:
	if !gtk_opt_palette_item: return
	if !palette: return

	gtk_opt_palette_item.palette = palette
	gtk_opt_palette_item.refresh()
	gtk_opt_palette_item.show()

	if not gtk_opt_palette_item.use_palette_clicked.is_connected(SignalBus.emit_request_palette_use_gtk):
		gtk_opt_palette_item.use_palette_clicked.connect(SignalBus.emit_request_palette_use_gtk.bind(palette))



# ─── Build ────────────────────────────────────────────────────────────────────

func _load_ui_palettes() -> void:
	if _palettes.is_empty() or not palettes_grid or not palette_item_scn:
		return
	_build_palettes(_palettes)


func _reload_ui_palettes() -> void:
	_build_palettes(_palettes)


func _build_palettes(palette_list: Array) -> void:
	_current_generation += 1
	var generation := _current_generation

	palettes_grid.freeze_layout()
	_wipe_nodes()

	await _build_timesliced(palette_list, generation)

	if generation == _current_generation:
		palettes_grid.thaw_layout()
	else:
		palettes_grid.thaw_layout()
		_wipe_nodes()


func _build_timesliced(palette_list: Array, generation: int) -> void:
	var i := 0
	while i < palette_list.size():
		var start := Time.get_ticks_usec()
		while i < palette_list.size():
			if generation != _current_generation:
				return
			_new_palette_node(palette_list[i])
			i += 1
			if Time.get_ticks_usec() - start > BUILD_BUDGET_USEC:
				await get_tree().process_frame
				if generation != _current_generation:
					return
				break


func _new_palette_node(palette: GTKColorPalette) -> void:
	var node: PaletteItem = palette_item_scn.instantiate()
	node.palette = palette
	loaded_palette_nodes.append(node)
	palettes_grid.add_child(node)


func _wipe_nodes() -> void:
	for node in loaded_palette_nodes:
		node.queue_free()
	loaded_palette_nodes.clear()


# ─── Cache ────────────────────────────────────────────────────────────────────

func _add_to_cache(palette: GTKColorPalette) -> void:
	if _palettes.has(palette):
		return
	_palettes.append(palette)


func _remove_from_cache(palette: GTKColorPalette) -> void:
	var idx := _palettes.find(palette)
	if idx != -1:
		_palettes.remove_at(idx)


func _get_palette_node(palette: GTKColorPalette) -> PaletteItem:
	for node in loaded_palette_nodes:
		if (node as PaletteItem).palette == palette:
			return node as PaletteItem
	return null

func _save_current_theme() -> void:
	if not NodeKeeper.current_theme:
		return
	if new_palette_win:
		var copy := NodeKeeper.current_theme.duplicate() as GTKColorPalette
		new_palette_win.load_from(copy, true)
		new_palette_win.open()

# ─── Signal Handlers ──────────────────────────────────────────────────────────

func _on_palette_added(palette: GTKColorPalette) -> void:
	_add_to_cache(palette)
	var node: PaletteItem = palette_item_scn.instantiate()
	node.palette = palette
	loaded_palette_nodes.append(node)
	palettes_grid.add_child(node)


func _on_palette_deleted(palette: GTKColorPalette) -> void:
	_remove_from_cache(palette)
	var node := _get_palette_node(palette)
	if node:
		loaded_palette_nodes.erase(node)
		node.queue_free()


func _on_palette_renamed(palette: GTKColorPalette) -> void:
	var node := _get_palette_node(palette)
	if node:
		node.palette = palette
		node.refresh()


func _on_new_palette_btn() -> void:
	if new_palette_win:
		new_palette_win.open()


func _on_palette_edit_request(palette: GTKColorPalette) -> void:
	new_palette_win.load_from(palette, false)
	new_palette_win.open()

func _on_palette_delete_request(palette: GTKColorPalette) -> void:
	pass
