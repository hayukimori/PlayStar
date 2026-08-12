extends Control


@export var key_line_edit: LineEdit
@export var save_btn: Button
@export var status_label: Label

var current_service: ListenBrainzService

func _ready() -> void:
	current_service = NodeKeeper.listenbrainz_service
	if current_service:
		current_service.Configured.connect(_on_configured)

	save_btn.pressed.connect(save_config)

	current_service.Error.connect(_on_error)

	load_config()


func load_config() -> void:
	var current_config: ListenBrainzConfig = ListenBrainzConfig.LoadOrCreate()
	key_line_edit.text = current_config.ApiKey


func save_config() -> void:
	save_btn.disabled = true
	var api_key: String = key_line_edit.text
	current_service.ConfigureAndReturn(api_key, api_key != "")


func update_status(msg: String) -> void:
	status_label.text = msg
	SignalBus.emit_pop_msg_request(msg)

func _on_configured() -> void:
	save_btn.disabled = false

	var text = "ListenBrainz config saved successfully."
	update_status(text)


func _on_error(e) -> void:
	update_status(str(e))
