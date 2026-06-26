extends Node


const USER_CONFIG_PATH: String = "user://user_config.tres"
const USER_DEFAULTS_PATH: String = "user://user_default.tres"
const USER_PLAYLISTS_PATH: String = "user://playlists/"

var current_defaults: UserDefaults
var current_config: ConfigModel

## Gets config from user folder
func get_config() -> ConfigModel:
    var res: ConfigModel
    if FileAccess.file_exists(USER_CONFIG_PATH):
        res = ResourceLoader.load(USER_CONFIG_PATH)
    else:
        res = ConfigModel.new()
        save_config(res)

    current_config = res
    return res


## Saves config into user folder
func save_config(config) -> void: ResourceSaver.save(config, USER_CONFIG_PATH)


## Gets user defaults
func get_defaults() -> UserDefaults:
    var res: UserDefaults
    if FileAccess.file_exists(USER_DEFAULTS_PATH):
        res = ResourceLoader.load(USER_DEFAULTS_PATH)
    else:
        res = UserDefaults.new()
        save_defaults(res)

    current_defaults = res
    return res


func save_defaults(defaults) -> void:
    ResourceSaver.save(defaults, USER_DEFAULTS_PATH)
