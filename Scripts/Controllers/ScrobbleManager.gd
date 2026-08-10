extends Node
class_name ScrobbleManager

var subsonic_enabled: bool = false

func _ready() -> void:
	SignalBus.scrobble.connect(_on_scrobble)

	# Subsonic check
	var sbs_svc := NodeKeeper.subsonic_service
	if sbs_svc: subsonic_enabled = sbs_svc.IsConnected()

func scrobble_as_subsonic(song: SongModel): return
func sccrobble_internal(song: SongModel): return


func _on_scrobble(song: SongModel) -> void:
	if song.FilePath.begins_with("http://") and subsonic_enabled:
		scrobble_as_subsonic(song)
		return

	sccrobble_internal(song)