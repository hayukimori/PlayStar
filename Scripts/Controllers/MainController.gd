extends Node
class_name MainController

signal update_current_metadata(data: SongModel)


#region Exports
@export_category("Server Settings")
@export_group("Nodes")
@export var player: VlcPlayer
@export var db: DatabaseManager
@export var indexer: MetadataIndexer
@export var mpris_service: MprisService

@export_group("UI")
@export var ui_manager: UIManager

@export_group("Engine Settings")
@export var random_mode: bool = false
@export var repeat_mode: Definitions.RepeatMode = Definitions.RepeatMode.OFF

@export_group("Dynamic Variables")
@export var current_play_queue: Array[SongModel] = []
@export var playing_now: SongModel
@export var playing_now_btn: SongButtonCovered
#endregion


var random_history: Array[SongModel] = []
var user_defaults: UserDefaults
var all_songs: Array[SongModel] = []

var song_repo: SongRepository
var artist_repo: ArtistRepository
var album_repo: AlbumRepository

var random_order: Array[SongModel] = []
var random_index: int = -1


#region Ready
func _ready() -> void:
	if !player or !db or !indexer:
		push_error("Server components not loaded.")
		return

	song_repo = SongRepository.new()
	artist_repo = ArtistRepository.new()
	album_repo = AlbumRepository.new()

	db.Initialize()
	player.Initialize()

	song_repo.Initialize(db)
	artist_repo.Initialize(db)
	album_repo.Initialize(db)

	NodeKeeper.current_database = db
	NodeKeeper.song_repository = song_repo
	NodeKeeper.artist_repository = artist_repo
	NodeKeeper.album_repository = album_repo
	NodeKeeper.vlc_player = player

	player.connect("MusicStarted", _on_music_started)
	player.connect("MusicEnded", _on_music_ended)
	player.connect("VolumeChangedExternally", _on_volume_changed_external)

	# Playback signals
	SignalBus.song_skip_next.connect(_on_ui_skip_next)
	SignalBus.song_skip_prev.connect(_on_ui_skip_prev)
	SignalBus.song_skip_prev.connect(_on_ui_skip_next)
	SignalBus.song_skip_prev.connect(_on_ui_skip_prev)
	SignalBus.pause_requested.connect(pause_process)
	SignalBus.play_requested.connect(unpause_process)
	SignalBus.seek_offset_request.connect(seek_process)
	SignalBus.seek_to_request.connect(seek_process_ms)
	SignalBus.playlist_request.connect(_on_playlist_request)
	SignalBus.load_all_songs.connect(_on_load_all_songs_request)
	SignalBus.song_request_from_current.connect(_on_req_load_song_from_queue)
	SignalBus.play_pause_requested.connect(_on_ui_play_pause)

	SignalBus.toggle_repeat.connect(next_repeat_state)
	SignalBus.toggle_shuffle.connect(next_shuffle_state)

	# SignalBus for UIManager
	SignalBus.song_selected.connect(play_song)
	SignalBus.reload_requested.connect(_on_reload_requested)
	SignalBus.volume_changed.connect(_on_volume_slider_value_changed)
	SignalBus.seek_by_percentage.connect(_on_seek_by_percentage)
	SignalBus.search_results_requested.connect(_on_search_results_requested)
	SignalBus.toggle_shuffle_to_state.connect(_change_random_mode)
	SignalBus.toggle_repeat_to_state.connect(_change_repeat_mode)

	# MPRIS -> Player state sync
	SignalBus.set_shuffle.connect(_on_mpris_set_shuffle)
	SignalBus.set_loop_status.connect(_on_mpris_set_loop_status)

	user_defaults = UserGlobals.get_defaults()
	update_by_defaults()
	load_songs()

	var song_count: int = len(all_songs)
	set_queue(all_songs.duplicate(), "All songs (%s)" % [str(song_count)])

	if ui_manager:
		ui_manager.set_search_bar_queue(current_play_queue)
		ui_manager.render_song_btns_from_list(current_play_queue)

#endregion


#region Song functions

## Plays song (updates MPRIS and Discord RPC)
func play_song(info: SongModel) -> void:
	if playing_now_btn: playing_now_btn.stop_playing_now()

	playing_now = info

	player.Load(info.FilePath)
	if player.playerModel == "vlc": player.Play()

	DiscordRp.OnMusicPlay(info, 0)
	SignalBus.emit_song_play()
	update_mpris(info)

	emit_signal("update_current_metadata", playing_now)
	SignalBus.emit_song_changed(info)

	if ui_manager:
		ui_manager.update_length_label(info)
		ui_manager.scroll_to_song(info)
		ui_manager.stop_playing_now(playing_now_btn.song_content if playing_now_btn else null)

	var btn = ui_manager.get_button_by_song(info) if ui_manager else null
	if btn: btn.start_playing_now()
	playing_now_btn = btn


## updates MPRIS with song metadata
func update_mpris(song: SongModel) -> void:
	if not mpris_service: return

	var album_art_path = AlbumArtExtractor.ExtractToTempFile(song.FilePath)
	mpris_service.UpdateMetadata(
		song.Title,
		song.Artist,
		song.Album,
		song.Length,
		album_art_path
	)

	mpris_service.UpdateLoopStatus(_mpris_loop_string())
	mpris_service.UpdateShuffle(random_mode)


## Emits Seeked from MPRIS after seek (position_us = microseconds)
func update_mpris_seek(position_us: int) -> void:
	if not mpris_service: return
	mpris_service.EmitSeeked(position_us)


## Load songs from db to memory
func load_songs(from_playlist: String = "") -> void:
	if not db: return

	var cfg = user_defaults.get_config()
	var songs: Array[SongModel] = song_repo.GetSongs(10000, cfg.ignore_unknown_artists)

	if from_playlist: print("'from_playlist' not implemented yet.")

	all_songs = songs.duplicate()


func set_queue(queue: Array[SongModel], queue_name: String = "Undefined queue") -> void:
	current_play_queue = queue
	_rebuild_random_order()

	if ui_manager:
		ui_manager.set_queue_label(queue_name)

#endregion


#region Song & Button search

## Returns song index from the queue (default queue: current_play_queue - Array[SongModel])
func get_song_on_list(info: SongModel, list: Array = current_play_queue) -> int:
	return list.find(info)

#endregion


#region Song Control (process)

func update_discord_seek(value: float) -> void:
	var vlcPos: float = value / 100.0
	var totalMs = playing_now.Length
	var currentMs = totalMs * vlcPos
	DiscordRp.OnMusicSeek(currentMs)


func update_by_defaults() -> void:
	await get_tree().process_frame

	var urpm = user_defaults.repeat_mode
	var valid_rpmode = urpm < len(Definitions.RepeatMode)
	if not valid_rpmode: urpm = 0

	random_mode = user_defaults.random_mode
	repeat_mode = urpm as Definitions.RepeatMode

	if ui_manager:
		ui_manager.set_rdm_button(user_defaults.random_mode)
		ui_manager.set_rpt_button(urpm)


func pause_process() -> void:
	player.Pause()
	SignalBus.emit_song_pause()
	DiscordRp.OnMusicPause()


func stop_process() -> void:
	player.Stop()
	SignalBus.emit_song_stop()
	DiscordRp.OnMusicStop()


func unpause_process() -> void:
	player.Play()
	SignalBus.emit_song_play()
	update_discord_seek(player.Position * 100)
	update_mpris_seek(player.Time * 1000)


func seek_process(offset_ms: int) -> void:
	var current_time = player.Time + offset_ms
	var position = (current_time / float(playing_now.Length)) * 100.0
	position = clamp(position, 0.0, 100.0)

	player.SeekByPercentage(position)
	update_discord_seek(position)
	update_mpris_seek(current_time * 1000)


func seek_process_ms(value_ms: int) -> void:
	var position = (value_ms / float(playing_now.Length)) * 100.0
	position = clamp(position, 0.0, 100.0)

	player.SeekByPercentage(position)
	update_discord_seek(position)
	update_mpris_seek(value_ms * 1000)


func skip_prev_as_random() -> void:
	if random_index - 1 < 0: return
	random_index -= 1
	play_song(random_order[random_index])


func skip_next_as_random() -> void:
	if random_index + 1 >= len(random_order):
		_rebuild_random_order()
	random_index += 1
	if random_index >= len(random_order): return
	play_song(random_order[random_index])

#endregion


#region State Managers

func next_repeat_state() -> void:
	var is_last_state = repeat_mode >= (len(Definitions.RepeatMode) - 1)
	var local_state = repeat_mode

	if is_last_state:
		local_state = Definitions.RepeatMode.OFF
	else:
		local_state = (repeat_mode + 1) as Definitions.RepeatMode

	if ui_manager:
		ui_manager.set_rpt_button(local_state)

	_change_repeat_mode(local_state)


func next_shuffle_state() -> void:
	_change_random_mode(!random_mode)

	if ui_manager:
		ui_manager.set_rdm_button(random_mode)

#endregion


#region Random order

func _rebuild_random_order() -> void:
	random_order = current_play_queue.duplicate()
	random_order.shuffle()

	if playing_now:
		var idx = random_order.find(playing_now)
		if idx != -1:
			random_order.remove_at(idx)
			random_order.insert(0, playing_now)

	random_index = 0

#endregion


#region Signals

func _on_music_started():
	pass


func _on_music_ended():
	match repeat_mode:
		Definitions.RepeatMode.REPEAT_ONE:
			play_song(playing_now)

		Definitions.RepeatMode.REPEAT_QUEUE:
			if random_mode:
				if random_index == -1:
					_rebuild_random_order()
					_on_ui_skip_next()
					return

				if random_index + 1 == random_order.size():
					_rebuild_random_order()
					_on_ui_skip_next()
					return

				_on_ui_skip_next()
				return

			var idx = get_song_on_list(playing_now, current_play_queue)
			if idx == -1 or playing_now == current_play_queue[-1]:
				if current_play_queue.is_empty(): return
				play_song(current_play_queue[0])
				return
			else:
				_on_ui_skip_next()

		Definitions.RepeatMode.OFF:
			_on_ui_skip_next()


func _on_metadata_ready():
	emit_signal("update_current_metadata", playing_now)
	player.Play()


func _on_volume_changed_external(value: int) -> void:
	# INTEGRATION: UIManager emits VolumeChangedExternally via SignalBus
	if value <= -1 or (!player.IsPlaying and value == 0):
		return
	SignalBus.emit_volume_changed_externally(value)


func _on_volume_slider_value_changed(value: float) -> void:
	player.SetVolumeFromFloat(value)


func _on_seek_by_percentage(value: float) -> void:
	if not playing_now: return
	player.SeekByPercentage(value)
	update_discord_seek(value)


func _on_ui_play_pause() -> void:
	if !playing_now: return

	if player.IsPlaying:
		pause_process()
	else:
		unpause_process()


func _on_ui_skip_prev() -> void:
	if !playing_now: return

	if random_mode: skip_prev_as_random(); return

	var idx_playing = get_song_on_list(playing_now)
	if idx_playing == -1: return
	if idx_playing < 1: return

	play_song(current_play_queue[idx_playing - 1])


func _on_ui_skip_next() -> void:
	if !playing_now: return

	if ui_manager:
		var btn = ui_manager.get_button_by_song(playing_now)
		if btn: btn.stop_playing_now()

	if random_mode: skip_next_as_random(); return

	match repeat_mode:
		Definitions.RepeatMode.REPEAT_QUEUE:
			if current_play_queue.is_empty(): return

			var idx = get_song_on_list(playing_now)
			var invalid: bool = (idx == -1)
			var last: bool = (playing_now == current_play_queue.back())

			if invalid or last:
				play_song(current_play_queue[0])
				return

			_normal_skip()
		_:
			_normal_skip()


func _normal_skip() -> void:
	var idx_playing = get_song_on_list(playing_now)
	if idx_playing == -1: return
	if (idx_playing + 2) > len(current_play_queue): return

	play_song(current_play_queue[idx_playing + 1])


func _on_reload_requested() -> void:
	current_play_queue = []
	if ui_manager: ui_manager.wipe_all()

	await get_tree().process_frame

	load_songs()
	if ui_manager:
		ui_manager.render_song_btns_from_list(current_play_queue)


func _on_req_load_song_from_queue(song: SongModel) -> void:
	if ui_manager and !ui_manager.get_button_by_song(song): return
	play_song(song)


func _on_playlist_request(playlist: PlaylistModel, index: int) -> void:
	var queue = playlist.songs.duplicate()
	set_queue(queue, playlist.name)
	if ui_manager: ui_manager.render_song_btns_from_list(current_play_queue)

	var c_song = current_play_queue[index]
	play_song(c_song)


func _on_load_all_songs_request() -> void:
	var queue = all_songs.duplicate()
	set_queue(queue, "All Songs")
	if ui_manager: ui_manager.render_song_btns_from_list(current_play_queue)


# INTEGRATION: chamado via SignalBus.search_results_requested (emitido pelo UIManager)
func _on_search_results_requested(results: Array) -> void:
	var results_as_local = []
	for item in results:
		var index = -1
		if ui_manager:
			index = ui_manager.get_index_by_path(item.FilePath, current_play_queue)
		if index != -1:
			results_as_local.append(current_play_queue[index])

	if ui_manager:
		ui_manager.show_search_results(results_as_local)


func _change_random_mode(state: bool) -> void:
	random_mode = state
	user_defaults.random_mode = state
	_rebuild_random_order()
	UserGlobals.save_defaults(user_defaults)
	if mpris_service: mpris_service.UpdateShuffle(state)


func _change_repeat_mode(state: Definitions.RepeatMode) -> void:
	repeat_mode = state
	user_defaults.repeat_mode = state
	UserGlobals.save_defaults(user_defaults)
	if mpris_service: mpris_service.UpdateLoopStatus(_mpris_loop_string())


func _on_mpris_set_shuffle(state: bool) -> void:
	if random_mode != state:
		_change_random_mode(state)
		if ui_manager: ui_manager.set_rdm_button(state)


func _on_mpris_set_loop_status(loop: String) -> void:
	var target: Definitions.RepeatMode = Definitions.RepeatMode.OFF
	match loop:
		"Track": target = Definitions.RepeatMode.REPEAT_ONE
		"Playlist": target = Definitions.RepeatMode.REPEAT_QUEUE

	if repeat_mode != target:
		var btn_state = target as Definitions.RepeatMode
		_change_repeat_mode(btn_state)
		if ui_manager: ui_manager.set_rpt_button(target)


func _mpris_loop_string() -> String:
	match repeat_mode:
		Definitions.RepeatMode.REPEAT_ONE: return "Track"
		Definitions.RepeatMode.REPEAT_QUEUE: return "Playlist"
		_: return "None"

#endregion
