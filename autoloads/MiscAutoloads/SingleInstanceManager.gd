extends Node

signal new_path_request(paths: Array[Dictionary])

const LISTEN_PORT = 39643

var _server: TCPServer
var _is_primary_instance := false

func _enter_tree() -> void:
	_server = TCPServer.new()

	if _server.listen(LISTEN_PORT) != OK:
		print("[SingleInstanceManager] Port unavailable")
		get_tree().quit()
		return

	_is_primary_instance = true
	print("[SingleInstanceManager] Listening on port %d" % LISTEN_PORT)
	set_process(true)


func _process(_delta: float) -> void:
	if not _is_primary_instance:
		return

	if _server.is_connection_available():
		var client = _server.take_connection()

		if client.get_available_bytes() > 0:
			var raw = client.get_utf8_string((client.get_available_bytes()))
			var paths = raw.split("\n", false)

			var tmp: Array[Dictionary] = []

			for path in paths:
				var payload = CommandQueueManager.get_payload(path)
				if payload: tmp.append(payload)

			new_path_request.emit(tmp)

			print("[SingleInstanceManager] %d path(s) received via tcp." % paths.size())
			client.unreference()
			get_window().grab_focus()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and _is_primary_instance:
		_server.stop()
