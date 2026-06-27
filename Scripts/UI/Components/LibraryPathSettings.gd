extends Control

@export_group("Extra Nodes")
@export var file_dialog: FileDialog
@export var scan_window: ScanWindow
@export var path_container: VBoxContainer
@export var scan_button: Button
@export var add_path_button: Button

@export_group("Packed Scenes")
@export var path_node: PackedScene

var current_config: ConfigModel

func _ready() -> void:
	if !file_dialog: push_error("Missing component: file_dialog"); return;
	if !path_container: push_error("Missing component: path_container"); return;
	if !path_node: push_error("Missing component: path_node"); return;
	if !scan_button: push_error("Missing component: scan_button"); return;
	if !add_path_button: push_error("Missing component: add_path_button"); return;

	#loads some configs from ConfigModel (user)
	current_config = UserGlobals.get_config()

	file_dialog.dir_selected.connect(_on_dir_selected)
	scan_button.pressed.connect(_on_scan_pressed)
	add_path_button.pressed.connect(_on_add_pressed)

	scan_button.disabled = true

	load_config_to_ui()




func _component_missing(components: Array, location: String) -> bool:
	var any_missing: bool = false
	for component in components:
		if (!component) or (component == null):
			push_error("Missing Component at %s" % location)

	return any_missing


func update_configs() -> void:
	current_config = UserGlobals.get_config()


func scan_directories(_dir_list: Array[String]) -> void:
	pass


func add_path_to_ui(path: String) -> void:
	# verify components
	if _component_missing(
		[path_node, path_container],
		"LibraryPathSettings.add_path_to_ui"
	): return;

	# verifies if scn is actually a PathNode
	var scn: PathNode = path_node.instantiate()
	if !(scn is PathNode):
		push_error("path_node is not a PathNode packed scene")
		return

	scn.path = path
	scn.path_delete_request.connect(_on_path_delete_requested)
	path_container.add_child(scn)
	print("Added to container")


func load_config_to_ui() -> void:
	update_configs()

	var paths: Array[String] = current_config.scan_paths
	for path in paths:
		print("Got path: %s. Adding to UI" % path)
		add_path_to_ui(path)

	scan_button.disabled = paths.is_empty()

#region Signals

func _on_path_delete_requested(path: String) -> void:
	if !path: push_warning("Missing path")
	update_configs()

	var _cache_paths: Array[String] = []
	_cache_paths = current_config.scan_paths.duplicate()

	var index := _cache_paths.find(path)
	if index == -1: # not in list
		return

	_cache_paths.remove_at(index)
	current_config.scan_paths = _cache_paths

	if _cache_paths.is_empty():
		if scan_button:
			scan_button.disabled = true

	UserGlobals.save_config(current_config)


func _on_scan_pressed() -> void:
	update_configs()
	if _component_missing(
		[scan_window],
		"LibraryPathSettings._on_scan_pressed"
	): return;

	var paths = current_config.scan_paths
	scan_window.set_dirs(paths)
	scan_window.show()
	scan_window.start_scan_process()

func _on_add_pressed() -> void:
	file_dialog.popup_centered()

func _on_dir_selected(path: String) -> void:
	if !path: push_warning("Missing path"); return;
	update_configs()

	var _cache_paths: Array[String] = []
	_cache_paths = current_config.scan_paths.duplicate()

	# If already exists, then quit
	for x in _cache_paths:
		if x == path:
			return

	_cache_paths.append(path)

	add_path_to_ui(path)
	current_config.scan_paths = _cache_paths

	if scan_button:
		scan_button.disabled = false

	UserGlobals.save_config(UserGlobals.current_config)

#endregion
