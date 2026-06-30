extends Button
class_name ToPlaylistButton

enum Ambient { SONG, ARTIST, ALBUM }
@export var  ambient: Ambient = Ambient.SONG
@export var content: Variant

@export var btn_static: bool = false


@export var anim_duration: float = 0.2
var original_minimum_size: Vector2
var closed_minimum_size: Vector2 = Vector2.ZERO

var active_tween: Tween

func _ready() -> void:
	set_process(false)
	set_physics_process(false)

	if !btn_static:
		original_minimum_size = Vector2(24.0, 0.0)
		self.custom_minimum_size = closed_minimum_size
		self.modulate.a = 0.0



func animate_open() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	self.show()

	active_tween = create_tween()
	active_tween.set_parallel(true)

	active_tween.tween_property(self, "modulate:a", 1.0, anim_duration)
	active_tween.tween_property(self, "custom_minimum_size", original_minimum_size, anim_duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)




func animate_close() -> void:
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	active_tween = create_tween()
	active_tween.set_parallel(true)

	active_tween.tween_property(self, "modulate:a", 0.0, anim_duration)
	active_tween.tween_property(self, "custom_minimum_size", closed_minimum_size, anim_duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	await active_tween.finished
	self.hide()


func call_add() -> void:
	match ambient:
		Ambient.SONG: _call_as_song()
		Ambient.ARTIST: _call_as_artist()
		Ambient.ALBUM: _call_as_album()


func _call_as_song() -> void:
	var ct = content as SongModel
	SignalBus.emit_request_song_to_playlist(ct)

func _call_as_artist() -> void:
	var ct = content as ArtistModel
	SignalBus.emit_request_artist_to_playlist(ct)

func _call_as_album() -> void:
	var ct = content as AlbumModel
	SignalBus.emit_request_album_to_playlist(ct)


func _pressed() -> void:
	call_add()
