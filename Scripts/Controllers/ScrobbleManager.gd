extends Node
class_name ScrobbleManager

var subsonic_enabled: bool = false
var subsonic_service: SubsonicService
var listenbrainz_service: ListenBrainzService

func _ready() -> void:
	SignalBus.scrobble.connect(_on_scrobble)

	# Subsonic check
	var sbs_svc := NodeKeeper.subsonic_service
	if sbs_svc:
		subsonic_enabled = sbs_svc.IsConnected()
		subsonic_service = sbs_svc

	var lsb_svc := NodeKeeper.listenbrainz_service
	if lsb_svc:
		listenbrainz_service = lsb_svc

## Gets most played songs [br]
## Takes [param limit (int)] and [param days (int)] [br]
## Defaults: [br]
## [code]limit=-1[/code] [br]
## [code]days=365[/code]
func get_most_played_local(limit: int = -1, days: int = 365) -> Array[SongModel]:
	var repo: SongRepository = NodeKeeper.song_repository
	var songs: Array[SongModel] = []
	if !repo: return songs

	songs = repo.GetMostPlayedSongs(limit, days)

	return songs


## Lists most played songs in the last 7 days
func most_played_week_local() -> Array[SongModel]:
	return get_most_played_local(-1, 7)

## Lists most played songs in the last 30 days
func most_played_month_local() -> Array[SongModel]:
	return get_most_played_local(-1, 30)

## Lists most played songs in the last 365 days
func most_played_year_local() -> Array[SongModel]:
	return get_most_played_local(-1, 365)


## Mark song as Scrobble into susbonic API using [class SubsonicService]
func scrobble_as_subsonic(song: SongModel):
	if !song.SongId:
		push_error("[ScrobbleManager] Song has http, but no id was found")
		return

	if !subsonic_service:
		push_error("[ScrobbleManager] Subsonic service not found")
		return

	subsonic_service.Scrobble(song.SongId)


## Marks scrobble @ internal playstar system.
func scrobble_internal(song: SongModel):
	var repo: SongRepository = NodeKeeper.song_repository
	if !repo: return

	repo.MarkScrobble(song);


func scrobble_listenbrainz(metadata: AudioMetadataResource) -> void:
	if listenbrainz_service:
		if listenbrainz_service.IsConnected():
			listenbrainz_service.Scrobble(metadata)



func _on_scrobble(song: SongModel) -> void:
	if song.FilePath.begins_with("http") and subsonic_enabled:
		scrobble_as_subsonic(song)
		return

	var tags: AudioMetadataResource = TagManager.ExtractFullMetadata(song.FilePath)
	if tags.MusicBrainzTrackId:
		scrobble_listenbrainz(tags)

	scrobble_internal(song)
