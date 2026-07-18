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
signal seek_by_percentage(value: float)
signal seek_to_request(value: int)


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
signal invoke_albums_window
signal invoke_playing_window
signal invoke_queue_window
signal invoke_about_window

signal show_artist_window(artist: ArtistModel, texture)
signal show_album_window(album: AlbumModel, texture)
signal show_history_window
signal request_rename_window(playlist: PlaylistModel)

# ------------- MISC --------------------
signal reload_request
signal reload_playlists
signal reset_playlists
signal reload_artists
signal reload_albums
signal discord_rp_changed(value: bool)
signal pop_msg_request(message: String)
signal song_selected(song: SongModel)
signal play_from_current(song: SongModel)
signal request_playlist(playlist: PlaylistModel, index: int)
signal request_history_update

# -> Requests a popup window to add into playlist
signal request_song_to_playlist(song: SongModel)
signal request_album_to_playlist(album: AlbumModel)
signal request_artist_to_playlist(artist: ArtistModel)
signal request_song_array_to_playlist(songs: Array[SongModel])

# Requests to move playlist position, add or delete
signal request_playlist_delete(playlist: PlaylistModel)
signal request_playlist_up(playlist: PlaylistModel)
signal request_playlist_down(playlist: PlaylistModel)


# -> Global signals
signal load_all_songs
signal scroll_to_current
signal capture_now

signal playlist_deleted(playlist: PlaylistModel)
signal playlist_added(playlist: PlaylistModel)
signal playing_now_capture(song: SongModel, texture: Texture2D)
signal update_queue_window(songs: Array[SongModel])
signal search_results_requested(results: Array)
signal toggle_shuffle_to_state(state: bool)
signal toggle_repeat_to_state(state: Definitions.RepeatMode)

signal volume_changed_externally(value: int)
signal volume_changed(value: int)
signal player_pos_change(value: float) # 0.0 - 1.0

signal copy_song



#region Emit Signals

func emit_next_track_requested() -> void: next_track_requested.emit()
func emit_prev_track_requested() -> void: prev_track_requested.emit()
func emit_pause_requested() -> void: pause_requested.emit()
func emit_play_requested() -> void: play_requested.emit()
func emit_play_pause_requested() -> void: play_pause_requested.emit()
func emit_stop_requested() -> void: stop_requested.emit()

func emit_seek_to_request(value: int) -> void: seek_to_request.emit(value)



func emit_seek_offset_request(offset_ms: int) -> void: seek_offset_request.emit(offset_ms)
func emit_seek_ms_request(value_ms: int) -> void: seek_ms_request.emit(value_ms)
func emit_seek_by_percentage(value: float) -> void: seek_by_percentage.emit(value)

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
func emit_invoke_albums_window() -> void: invoke_albums_window.emit()
func emit_invoke_playing_window() -> void: invoke_playing_window.emit()
func emit_invoke_queue_window() -> void: invoke_queue_window.emit()
func emit_invoke_about_window() -> void: invoke_about_window.emit()
func emit_show_artist_window(artist: ArtistModel, texture) -> void: show_artist_window.emit(artist, texture)
func emit_show_album_window(album: AlbumModel, texture) -> void: show_album_window.emit(album, texture)
func emit_show_history_window() -> void: show_history_window.emit()
func emit_request_rename_window(playlist: PlaylistModel) -> void: request_rename_window.emit(playlist)

func emit_reload_request() -> void: reload_request.emit()
func emit_reload_playlists() -> void: reload_playlists.emit()
func emit_reset_playlists() -> void: reset_playlists.emit()
func emit_reload_artists() -> void: reload_artists.emit()
func emit_reload_albums() -> void: reload_albums.emit()
func emit_pop_msg_request(message: String) -> void: pop_msg_request.emit(message)
func emit_song_selected(song: SongModel) -> void: song_selected.emit(song)
func emit_play_from_current(song: SongModel) -> void: play_from_current.emit(song)
func emit_request_playlist(playlist: PlaylistModel, index: int) -> void:
	request_playlist.emit(playlist, index)
func emit_request_history_update() -> void: request_history_update.emit()


func emit_request_song_to_playlist(song: SongModel) -> void: request_song_to_playlist.emit(song)
func emit_request_album_to_playlist(album: AlbumModel) -> void: request_album_to_playlist.emit(album)
func emit_request_artist_to_playlist(artist: ArtistModel) -> void: request_artist_to_playlist.emit(artist)
func emit_request_song_array_to_playlist(songs: Array[SongModel]) -> void: request_song_array_to_playlist.emit(songs)

func emit_request_playlist_delete(playlist: PlaylistModel) -> void: request_playlist_delete.emit(playlist)
func emit_request_playlist_up(playlist: PlaylistModel) -> void: request_playlist_up.emit(playlist)
func emit_request_playlist_down(playlist: PlaylistModel) -> void: request_playlist_down.emit(playlist)


func emit_load_all_songs() -> void: load_all_songs.emit()
func emit_scroll_to_current() -> void: scroll_to_current.emit()
func emit_capture_now() -> void: capture_now.emit()


func emit_playlist_deleted(playlist: PlaylistModel) -> void: playlist_deleted.emit(playlist)
func emit_playlist_added(playlist: PlaylistModel) -> void: playlist_added.emit(playlist)
func emit_playing_now_capture(song: SongModel, texture: Texture2D) -> void: playing_now_capture.emit(song, texture)
func emit_update_queue_window(songs: Array[SongModel]) -> void: update_queue_window.emit(songs)


func emit_volume_changed(value: float) -> void: volume_changed.emit(value)
func emit_volume_changed_externally(value: int) -> void: volume_changed_externally.emit(value)
func emit_search_results_requested(results: Array) -> void: search_results_requested.emit(results)
func emit_toggle_shuffle_to_state(state: bool) -> void: toggle_shuffle_to_state.emit(state)
func emit_toggle_repeat_to_state(state: Definitions.RepeatMode) -> void: toggle_repeat_to_state.emit(state)

func emit_discord_rp_changed(value: bool) -> void: discord_rp_changed.emit(value)
func emit_copy_song() -> void: copy_song.emit()

func emit_player_pos_change(value: float) -> void: player_pos_change.emit(value)
