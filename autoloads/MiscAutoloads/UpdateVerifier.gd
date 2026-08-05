extends Node


func _ready() -> void:
	print("[UpdateVerifier] Starting update check...")

	var timer: Timer = Timer.new()
	timer.wait_time = 10.0
	timer.one_shot = true
	timer.timeout.connect(check_for_updates)
	add_child(timer)
	timer.start()


## Requests server to compare current version with the latest release on GitHub. If a new version is available, it will emit a signal to notify the user.
func check_for_updates() -> void:
	print("[UpdateVerifier] Checking for updates...")

	var url: String = "https://api.github.com/repos/hayukimori/PlayStar/releases/latest"
	var http_request: HTTPRequest = HTTPRequest.new()

	add_child(http_request)
	http_request.connect("request_completed", Callable(self, "_on_request_completed"))
	http_request.request(url)


func _on_request_completed(result: int, response_code: int, _headers: Array, body: PackedByteArray) -> void:
	if result != OK or response_code != 200:
		push_error("[UpdateVerifier] Failed to fetch latest release info from GitHub.")
		return

	var json_data = JSON.parse_string(body.get_string_from_utf8())

	if json_data == null:
		push_error("[UpdateVerifier] Failed to parse JSON response.")
		return

	var latest_version_tag: String = json_data.get("tag_name", "")
	var current_version: String = ProjectSettings.get_setting("application/config/version")

	var current_tag: String = "v%s" % current_version

	if latest_version_tag == "":
		push_error("[UpdateVerifier] Latest version info not found in JSON response.")
		return

	if latest_version_tag != current_tag:
		if is_newer_version(latest_version_tag, current_tag):
			print("[UpdateVerifier] New version available: %s" % latest_version_tag)
			SignalBus.new_version_notify.emit(latest_version_tag)
		else:
			print("[UpdateVerifier] Current version is up to date.")
	else:
		print("[UpdateVerifier] Current version is up to date.")
	

func is_newer_version(latest_version: String, current_version: String) -> bool:
	var latest_parts: Array = DevTools.parse_version(latest_version)
	var current_parts: Array = DevTools.parse_version(current_version)

	for i in range(max(latest_parts.size(), current_parts.size())):
		var latest_part: int = latest_parts[i] if i < latest_parts.size() else 0
		var current_part: int = current_parts[i] if i < current_parts.size() else 0

		if latest_part > current_part:
			return true
		elif latest_part < current_part:
			return false

	return false


