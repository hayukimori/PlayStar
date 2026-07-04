extends Resource
class_name UserDefaults

@export var random_mode: bool = false
@export var repeat_mode: Definitions.RepeatMode = Definitions.RepeatMode.OFF
@export var playlist_order: Array = []

func move_playlist_up(path: String) -> void:
    var idx = playlist_order.find(path)
    if idx > 0:
        var temp = playlist_order[idx - 1]
        playlist_order[idx - 1] = playlist_order[idx]
        playlist_order[idx] = temp
        UserGlobals.save_defaults(self)

func move_playlist_down(path: String) -> void:
    var idx = playlist_order.find(path)
    if idx < playlist_order.size() - 1:
        var temp = playlist_order[idx + 1]
        playlist_order[idx + 1] = playlist_order[idx]
        playlist_order[idx] = temp
        UserGlobals.save_defaults(self)
