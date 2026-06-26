extends Node

#region Signals
signal next_track_requested
signal prev_track_requested
signal pause_requested
signal play_requested
signal play_pause_requested
signal stop_requested

signal seek_offset_request(offset_ms: int)
signal seek_ms_request(value_ms: int)

signal song_pause
signal song_play
signal song_stop
signal song_skip_next
signal song_skip_prev
signal song_changed(song: SongModel)


# ------------ Toggle -----------------
signal toggle_shuffle
signal toggle_repeat
signal toggle_search

# ------- Mpris -> Player State ---------
signal set_shuffle(state: bool)
signal set_loop_status(loop: String)

# ----------- Invoke Window -------------
signal invoke_settings_menu
signal invoke_playlists_window
signal invoke_artists_window
signal invoke_albuns_window
signal invoke_playing_window
signal invoke_queue_window

# ------------- MISC --------------------
signal pop_msg_request(message: String)
signal play_from_current(song: SongModel)

# -> Requests a popup window to add into playlist
signal request_song_to_playlist(song: SongModel)
signal request_album_to_playlist(album: AlbumModel)
signal request_artist_to_playlist
signal request_playlist_delete(playlist: PlaylistModel)

# -> Global signals
signal load_all_songs
signal scroll_to_current
signal capture_now

signal playlist_deleted(playlist: PlaylistModel)
signal playing_now_capture(song: SongModel, texture: Texture2D)
signal update_queue_window(songs: Array[SongModel])
signal copy_song



#region Emit Signals

func emit_next_track_requested() -> void: next_track_requested.emit()
func emit_prev_track_requested() -> void: prev_track_requested.emit()
func emit_pause_requested() -> void: pause_requested.emit()
func emit_play_requested() -> void: play_requested.emit()
func emit_play_pause_requested() -> void: play_pause_requested.emit()
func emit_stop_requested() -> void: stop_requested.emit()



func emit_seek_offset_request(offset_ms: int) -> void: seek_offset_request.emit(offset_ms)
func emit_seek_ms_request(value_ms: int) -> void: seek_ms_request.emit(value_ms)

func emit_song_pause() -> void: song_pause.emit()
func emit_song_play() -> void: song_play.emit()
func emit_song_stop() -> void: song_stop.emit()
func emit_song_skip_next() -> void: song_skip_next.emit()
func emit_song_skip_prev() -> void: song_skip_prev.emit()
func emit_song_changed(song: SongModel) -> void: song_changed.emit(song)


func emit_toggle_shuffle() -> void: toggle_shuffle.emit()
func emit_toggle_repeat() -> void: toggle_repeat.emit()
func emit_toggle_search() -> void: toggle_search.emit()

func emit_set_shuffle(state: bool) -> void: set_shuffle.emit(state)
func emit_set_loop_status(loop: String) -> void: set_loop_status.emit(loop)


func emit_invoke_settings_menu() -> void: invoke_settings_menu.emit()
func emit_invoke_playlists_window() -> void: invoke_playlists_window.emit()
func emit_invoke_artists_window() -> void: invoke_artists_window.emit()
func emit_invoke_albuns_window() -> void: invoke_albuns_window.emit()
func emit_invoke_playing_window() -> void: invoke_playing_window.emit()
func emit_invoke_queue_window() -> void: invoke_queue_window.emit()



func emit_pop_msg_request(message: String) -> void: pop_msg_request.emit(message)
func emit_play_from_current(song: SongModel) -> void: play_from_current.emit(song)


func emit_request_song_to_playlist(song: SongModel) -> void: request_song_to_playlist.emit(song)
func emit_request_album_to_playlist(album: AlbumModel) -> void: request_album_to_playlist.emit(album)
func emit_request_playlist_delete(playlist: PlaylistModel) -> void: request_playlist_delete.emit(playlist)
func emit_request_artist_to_playlist() -> void: request_artist_to_playlist.emit()


func emit_load_all_songs() -> void: load_all_songs.emit()
func emit_scroll_to_current() -> void: scroll_to_current.emit()
func emit_capture_now() -> void: capture_now.emit()


func emit_playlist_deleted(playlist: PlaylistModel) -> void: playlist_deleted.emit(playlist)
func emit_playing_now_capture(song: SongModel, texture: Texture2D) -> void: playing_now_capture.emit(song, texture)
func emit_update_queue_window(songs: Array[SongModel]) -> void: update_queue_window.emit(songs)
func emit_copy_song() -> void: copy_song.emit()
