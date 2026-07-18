class_name LrcLibService
extends Node

const CACHE_DIR = "user://lyrics_cache/"
const BASE_URL = "https://lrclib.net/api/search"
const USER_AGENT = "User-Agent: PlayStar v1.0.0 (https://github.com/hayukimori/PlayStar)"

## Default mark to use local lyrics
const LOOKUP_LOCAL = "_lookup_local"

signal lyrics_found(plain_lyrics: String, synced_lyrics: String, track_info: Dictionary)
signal lyrics_error(error_message: String)

var _http_request: HTTPRequest
var _current_requesting_song_path: String = ""


func _ready() -> void:

	_checkdir()

	_http_request = HTTPRequest.new()
	add_child(_http_request)
	_http_request.request_completed.connect(_on_request_completed)


func _checkdir() -> void:
	if not DirAccess.dir_exists_absolute(CACHE_DIR):
		DirAccess.make_dir_absolute(CACHE_DIR)

## Returns song lyric cache path
func _get_cache_path(song_path: String) -> String:
	var hash_name = song_path.md5_text()
	return CACHE_DIR + hash_name + ".json"


## Searches lyrics using [song: SongModel]. Uses cache if available
func get_lyrics(song: SongModel) -> void:
	_checkdir()
	var cache_file_path = _get_cache_path(song.FilePath)

	if FileAccess.file_exists(cache_file_path):
		var file := FileAccess.open(cache_file_path, FileAccess.READ)
		var json_text: String = file.get_as_text()
		file.close()

		var json = JSON.new()
		if json.parse(json_text) == OK:
			var data: Dictionary = json.get_data()

			# Looks for the marker to search at local song lyric (from tag)
			if data.get("info", {}).get("_lookup_local", false):
				lyrics_error.emit(LOOKUP_LOCAL)
				return

			var plain = data.get("plainLyrics", "")
			var synced = data.get("syncedLyrics", "")

			var plain_lyrics: String = plain if plain != null else ""
			var synced_lyrics: String = synced if synced != null else ""
			var info: Dictionary = data.get("info", {})

			await get_tree().process_frame
			lyrics_found.emit(plain_lyrics, synced_lyrics, info)
			return

	# No cache, get from API
	_current_requesting_song_path = song.FilePath
	_fetch_lyrics(song)



## Gets lyrics from API (LrcLib)
## Cancels previous request before starting a new one
func _fetch_lyrics(song: SongModel) -> void:
	_http_request.cancel_request()

	var artist_name = song.Artist
	var track_name = song.Title
	var album_name = song.Album if song.Album != "Unknown" else ""

	if track_name.is_empty() or artist_name.is_empty():
		_save_lookup_local(song.FilePath)
		lyrics_error.emit(LOOKUP_LOCAL)
		return

	var query_params := "?track_name=%s&artist_name=%s" % [
		track_name.uri_encode(),
		artist_name.uri_encode()
	]

	var headers: Array = [USER_AGENT]

	if not album_name.is_empty():
		query_params += "&album_name=%s" % album_name.uri_encode()

	var full_url := BASE_URL + query_params

	var error = _http_request.request(full_url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		_save_lookup_local(song.FilePath)
		lyrics_error.emit(LOOKUP_LOCAL)
		return



## Writes cache with _lookup_local
## if song has lyrics in tag, uses it
func _save_lookup_local(song_path: String) -> void:
	var cache_file_path = _get_cache_path(song_path)

	# Try getting from tag
	var local_lyrics = MetadataManager.GetLyricsFromPath(song_path)
	if local_lyrics == null or local_lyrics.is_empty():
		local_lyrics = ""

	var cache_data := {
		"plainLyrics": local_lyrics,
		"syncedLyrics": "",
		"info": {
			"_lookup_local": true,
			"_has_local_lyrics": not local_lyrics.is_empty()
		}
	}

	var file := FileAccess.open(cache_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(cache_data))
		file.close()



## Saves result from API to cache
func _save_api_result(song_path: String, plain: String, synced: String, info: Dictionary) -> void:
	var cache_file_path = _get_cache_path(song_path)
	var cache_data := {
		"plainLyrics": plain,
		"syncedLyrics": synced,
		"info": info
	}
	var file := FileAccess.open(cache_file_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(cache_data))
		file.close()

## Forces a re-search for the current song, clearing the existing cache.

func re_search(song: SongModel) -> void:
	var cache_file_path = _get_cache_path(song.FilePath)
	if FileAccess.file_exists(cache_file_path):
		DirAccess.remove_absolute(cache_file_path)

	get_lyrics(song)


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var song_path = _current_requesting_song_path
	_current_requesting_song_path = ""

	if result != HTTPRequest.RESULT_SUCCESS:
		_save_lookup_local(song_path)
		lyrics_error.emit(LOOKUP_LOCAL)
		return

	if response_code != 200:
		_save_lookup_local(song_path)
		lyrics_error.emit(LOOKUP_LOCAL)
		return

	var json_text := body.get_string_from_utf8()
	var json = JSON.new()
	var parse_err = json.parse(json_text)

	if parse_err != OK:
		_save_lookup_local(song_path)
		lyrics_error.emit(LOOKUP_LOCAL)
		return

	var response_data = json.get_data()

	if typeof(response_data) == TYPE_ARRAY and response_data.size() > 0:
		var best_match: Dictionary = response_data[0]

		var plain = best_match.get("plainLyrics", "")
		var synced = best_match.get("syncedLyrics", "")

		var plain_lyrics: String = plain if plain != null else ""
		var synced_lyrics: String = synced if synced != null else ""

		if plain_lyrics.is_empty() and synced_lyrics.is_empty():
			_save_lookup_local(song_path)
			lyrics_error.emit(LOOKUP_LOCAL)
		else:
			if not song_path.is_empty():
				_save_api_result(song_path, plain_lyrics, synced_lyrics, best_match)

			lyrics_found.emit(plain_lyrics, synced_lyrics, best_match)
	else:
		_save_lookup_local(song_path)
		lyrics_error.emit(LOOKUP_LOCAL)
