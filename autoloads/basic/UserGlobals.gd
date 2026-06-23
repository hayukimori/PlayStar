extends Node


const USER_CONFIG_PATH: String = "user://user_config.tres"
const USER_DEFAULTS_PATH: String = "user://user_default.tres"
const USER_PLAYLISTS_PATH: String = "user://playlists/"

var current_defaults #TODO: Create UserDefaults Resource
var current_config # TODO: Create ConfigModel Resource

## Gets config from user folder
func get_config():
    var res # ConfigModel
    if FileAccess.file_exists(USER_CONFIG_PATH):
        res = ResourceLoader.load(USER_CONFIG_PATH)
    else:
        res = null #TODO: Replace with ConfigModel.new()
        save_config(res)
    
    current_config = res
    return res


## Saves config into user folder
func save_config(config) -> void: ResourceSaver.save(config, USER_CONFIG_PATH)


## Gets user defaults
func get_defaults(): #TODO: Add type hint UserDefaults
    var res # UserDefaults
    if FileAccess.file_exists(USER_CONFIG_PATH):
        res = ResourceLoader.load(USER_CONFIG_PATH)
    else:
        res = null #TODO: Replace with UserDefaults.new()
        save_defaults(res)
    
    current_defaults = res
    return res


func save_defaults(defaults) -> void:
    ResourceSaver.save(defaults, USER_DEFAULTS_PATH)