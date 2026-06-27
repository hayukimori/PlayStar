extends Window
class_name ScanWindow

enum ScanEvent { ScanEnd, IndexEnd }

@onready var status_label: Label = $Control/StatusLabel
@onready var progress_bar: ProgressBar = $Control/ProgressBar

var database_node: DatabaseManager
var indexer_node: MetadataIndexer
var scanner_node: LibraryScanner

var paths: Array[String] = []

var _current_path_index: int = 0

# Slots paths.size() + 1
# the last slot is dedicated to indexer

var _progress_slots: int = 0

func _ready() -> void:
	database_node = NodeKeeper.current_database
	indexer_node = NodeKeeper.current_indexer
	scanner_node = NodeKeeper.current_scanner

	scanner_node.SongsScanEnd.connect(_on_scan_end)
	indexer_node.SongsIndexEnd.connect(_on_index_end)


func set_dirs(new_paths: Array[String]) -> void:
	paths = new_paths
	_current_path_index = 0


func _track_current_progress(event: ScanEvent) -> void:
	if _progress_slots == 0:
		return

	match event:
		ScanEvent.ScanEnd:
			# Each complete path adds 1 slot, but never reaches 100%
			# last slot is indexer's
			var scans_done: int = _current_path_index + 1
			var value: float = (float(scans_done) / float(_progress_slots)) * 100.0
			progress_bar.value = minf(value, progress_bar.max_value - 1.0)

		ScanEvent.IndexEnd:
			progress_bar.value = progress_bar.max_value


func start_scan_process() -> void:
	status_label.text = ""
	progress_bar.value = 0.0

	# slots = N folders + 1 (indexer)
	_progress_slots = paths.size() + 1

	database_node.Initialize()
	database_node.WipeAndReinitialize()

	Locker.set_scan_lock(true)

	var songs_repo: SongRepository = NodeKeeper.song_repository
	var artists_repo: ArtistRepository = NodeKeeper.artist_repository
	var albums_repo: AlbumRepository = NodeKeeper.album_repository

	indexer_node.Initialize(database_node, songs_repo, artists_repo, albums_repo)
	scanner_node.Initialize(database_node, songs_repo, indexer_node)

	_current_path_index = 0
	scanner_node.MusicFolder = paths[_current_path_index]
	scanner_node.StartScan()


func start_next_scan() -> void:
	if _current_path_index + 1 >= paths.size():
		# All folders scanned, indexer time
		status_label.text = "Indexing..."
		indexer_node.Start()
		return

	_current_path_index += 1
	scanner_node.MusicFolder = paths[_current_path_index]
	scanner_node.StartScan()


func _close_requested() -> void:
	if Locker.is_scan_locked():
		return

	queue_free()


func _on_scan_end() -> void:
	_track_current_progress(ScanEvent.ScanEnd)
	start_next_scan()


func _on_index_end() -> void:
	_track_current_progress(ScanEvent.IndexEnd)
	Locker.set_scan_lock(false)
	status_label.text = "Done!\nYou can close this window now. And restart to take effect"
