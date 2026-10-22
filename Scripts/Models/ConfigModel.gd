extends Resource
class_name ConfigModel

@export var scan_paths: Array[String] = []
@export var ignore_unknown_artists: bool = false
@export var last_scan_date: Dictionary = Time.get_date_dict_from_system()
@export var start_discord_rp: bool = true
@export var show_album_name: bool = true # Rich Presence
@export var use_native_window: bool = true
@export var auto_close_panel: bool = true
@export var use_gtk_theme: bool = false
@export var current_palette_path: String = ""
