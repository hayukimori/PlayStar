extends Node

var _command_queue: Array[Dictionary]

func _ready() -> void:
	var user_args = OS.get_cmdline_user_args()

	print("[CommandQueueManager] Args: ", user_args)

	for arg in user_args:
		if arg.begins_with("--"):
			continue

		var payload = get_payload(arg)
		if payload: enqueue_command(payload)


func get_payload(arg) -> Dictionary:
	if FileAccess.file_exists(arg):
		return { "type": "add_path","payload": arg}

	if DirAccess.dir_exists_absolute(arg):
		return {"type": "add_folder","payload": arg}

	if ResourceLoader.exists(arg):
		return {}

	else: return {}

func enqueue_command(command: Dictionary) -> void:
	_command_queue.append(command)

func try_dequeue_command() -> Dictionary:
	if _command_queue.is_empty():
		return {}
	return _command_queue.pop_front()

func get_pending_command_count() -> int:
	return _command_queue.size()
