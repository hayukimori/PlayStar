class_name DevTools


static func wipe_btns(btnlist: Array) -> void:
	for btn in btnlist:
		if (btn is SongButtonCovered) or \
		   (btn is PlaylistButton):

			btn.self_destroy()
		else:
			btn.queue_free()
	btnlist.clear()

## Generates an UUID4 string
static func generate_uuid_v4() -> String:
	var bytes := Crypto.new().generate_random_bytes(16)

	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80

	return "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x" % [
		bytes[0], bytes[1], bytes[2], bytes[3],
		bytes[4], bytes[5],
		bytes[6], bytes[7],
		bytes[8], bytes[9],
		bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
	]


## Checks if path exists, if it doesn't exists, then creates
static func check_and_create(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_absolute(path)


## Converts an input text into snake_case
static func to_snake_case_sanitized(input_text: String) -> String:
	var clean_text = input_text.validate_node_name()

	var regex = RegEx.new()
	regex.compile("[\\s-]+")
	clean_text = regex.sub(clean_text, "_", true)

	clean_text = clean_text.to_lower()
	regex.compile("[_]+")
	clean_text = regex.sub(clean_text, "_", true)

	return clean_text.strip_edges().trim_prefix("_").trim_suffix("_")
