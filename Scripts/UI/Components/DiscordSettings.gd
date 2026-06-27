extends Control
class_name DiscordSettings

@export var show_album_chkbn: CheckButton
@export var discord_rp_chkbn: CheckButton

var current_config: ConfigModel

func _ready() -> void:
	if !show_album_chkbn: push_error("Component Missing: show_album_chkbn"); return;
	if !discord_rp_chkbn: push_error("Component Missing: discord_rp_chkbn"); return;

	discord_rp_chkbn.pressed.connect(_change_rp)
	show_album_chkbn.pressed.connect(_change_album_rp)

	load_from_config()


func update_config() -> void:
	current_config = UserGlobals.get_config()

func save_config() -> void:
	UserGlobals.save_config(current_config)

func load_from_config() -> void:
	update_config()
	show_album_chkbn.button_pressed = current_config.show_album_name
	discord_rp_chkbn.button_pressed = current_config.start_discord_rp

func _change_rp() -> void:
	update_config()

	var value = discord_rp_chkbn.button_pressed
	current_config.start_discord_rp = value
	SignalBus.emit_discord_rp_changed(value)

	save_config()

func _change_album_rp() -> void:
	update_config()
	current_config.show_album_name = show_album_chkbn.button_pressed
	save_config()
