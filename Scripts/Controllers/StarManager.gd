extends Node

func _ready() -> void:
	SignalBus.star_song.connect(_on_star)
	SignalBus.unstar_song.connect(_on_unstar)


func _on_star(song: SongModel, is_subsonic: bool) -> void:
	print("Star called")

	if is_subsonic:
		star_subsonic(song)
	else:
		star_local(song)

func _on_unstar(song: SongModel, is_subsonic: bool) -> void:
	if is_subsonic:
		unstar_subsonic(song)
	else:
		unstar_local(song)


## Stars song on Subsonic API (using song Id)
func star_subsonic(song: SongModel) -> void:
	var service: SubsonicService = NodeKeeper.subsonic_service
	var song_id: String = song.SongId

	if !service or !song_id:
		push_error("[StarManager] Service not found or invalid SongId, ignoring star.")
		return

	if !service.IsConnected():
		push_error("[StarManager] Subsonic service not connected, ignorig star.")
		return

	service.Star(song_id)

## Unstars song on Subsonic API (using song Id)
func unstar_subsonic(song: SongModel) -> void:
	var service: SubsonicService = NodeKeeper.subsonic_service
	var song_id: String = song.SongId

	if !service or !song_id:
		push_error("[StarManager] Service not found or invalid SongId, ignoring unstar.")
		return

	if !service.IsConnected():
		push_error("[StarManager] Subsonic service not connected, ignorig unstar.")
		return

	service.Unstar(song_id)



## Stars song locally (database)
func star_local(song: SongModel) -> void:
	var repo: SongRepository = NodeKeeper.song_repository
	if !repo:
		push_error("[StarManager] No song repository found, ignoring star.")
		return

	repo.StarSong(song.FilePath)



## Unstars song locally (database)
func unstar_local(song: SongModel) -> void:
	var repo: SongRepository = NodeKeeper.song_repository
	if !repo:
		push_error("[StarManager] No song repository found, ignoring unstar.")
		return

	repo.UnstarSong(song.FilePath)
