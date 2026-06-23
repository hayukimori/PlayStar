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
signal song_changed


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
signal play_from_current(song)

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



#TODO: Make Emit functions