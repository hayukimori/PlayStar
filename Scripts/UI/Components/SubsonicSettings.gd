extends Control

@export var url_line_edit: LineEdit
@export var username_line_edit: LineEdit
@export var password_line_edit: LineEdit

@export var save_btn: Button
@export var connect_btn: Button

@export var status_label: Label

var current_service: SubsonicService

func _ready() -> void:
	current_service = NodeKeeper.subsonic_service
	if current_service:
		current_service.Configured.connect(_on_configured)

	save_btn.pressed.connect(save_config)
	connect_btn.pressed.connect(connect_to_server)

	current_service.PingSucceeded.connect(_on_ping_success)
	current_service.PingFailed.connect(_on_ping_fail)
	current_service.Error.connect(_on_error)

	load_config()

func load_config() -> void:
	var current_config: SubsonicConfig = SubsonicConfig.LoadOrCreate()
	url_line_edit.text = current_config.ServerUrl
	username_line_edit.text = current_config.Username
	password_line_edit.text = current_config.Password


func save_config() -> void:
	save_btn.disabled = true

	var url: String = url_line_edit.text
	var username: String = username_line_edit.text
	var password: String = password_line_edit.text

	current_service.Configure(url, username, password)

func update_status(msg: String) -> void:
	status_label.text = msg
	SignalBus.emit_pop_msg_request(msg)

func _on_configured() -> void:
	save_btn.disabled = false

	var text = "Subsonic config saved successfully."
	update_status(text)


func connect_to_server() -> void:
	connect_btn.disabled = true
	current_service.Ping()

func _on_ping_success() -> void:
	connect_btn.disabled = false
	var text = "Connected successfully."
	update_status(text)

func _on_ping_fail() -> void:
	connect_btn.disabled = false
	var text = "Connection failed. Check connection and try again."
	update_status(text)


func _on_error(e) -> void:
	update_status(str(e))
