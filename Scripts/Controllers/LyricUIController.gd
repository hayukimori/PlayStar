extends Node

@export var sync_lyrics_sc: ScrollContainer
@export var lyrics_panel: Panel
@export var lrc_service: LrcLibService
@export var lrc_btn: Button

var parser: LrcParser
var last_song: SongModel
var current_metadata: SongModel

func _ready() -> void:
	parser = LrcParser.new()

	SignalBus.song_changed.connect(_update_metadata)

	lrc_service.lyrics_found.connect(_on_lyrics_found)
	lrc_service.lyrics_error.connect(_on_lyrics_error)
	lrc_btn.pressed.connect(_toggle_lyrics)


func _update_metadata(song: SongModel) -> void:
	current_metadata = song
	if lyrics_panel.visible:
		activate_lyrics()


func activate_lyrics() -> void:
	if !lrc_service: return
	if !current_metadata: return

	lrc_service.get_lyrics(current_metadata)
	sync_lyrics_sc.set_parser(parser)
	sync_lyrics_sc.load_lyrics_string("Looking for lyrics...")



func _toggle_lyrics() -> void:
	if (not lyrics_panel): return

	if lyrics_panel.visible:
		lyrics_panel.hide()

	else:
		lyrics_panel.show()
		if current_metadata != last_song:
			activate_lyrics()
			last_song = current_metadata




func _on_lyrics_found(plain: String, synced: String, _info: Dictionary) -> void:
	sync_lyrics_sc.set_parser(parser)

	if not synced.is_empty():
		sync_lyrics_sc.load_lyrics_string(synced)
	else:
		if not plain.is_empty():
			sync_lyrics_sc.load_lyrics_string(plain)


func _on_lyrics_error(msg: String) -> void:
	if msg: push_warning("Lyrics error: ", msg)

	var lyrics: String = ""


	if msg == LrcLibService.LOOKUP_LOCAL:
		if current_metadata:
			var meta_lyrics = MetadataManager.GetLyricsFromSong(current_metadata)
			if meta_lyrics and not meta_lyrics.is_empty():
				lyrics = meta_lyrics


	if lyrics.is_empty():
		lyrics = "No Lyrics."

	sync_lyrics_sc.set_parser(parser)
	sync_lyrics_sc.load_lyrics_string(lyrics)
