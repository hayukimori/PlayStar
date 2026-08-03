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


## Deletes a file[br]
##
## Takes [param file_path] as argument (absolute path)
static func delete_file(file_path: String) -> void:
	if !FileAccess.file_exists(file_path):
		push_warning("File does not exsits: %s" % file_path)
		return

	DirAccess.remove_absolute(file_path)

## Deletes a directory recursively[br]
##
## Takes [param path] as argument (absolute path)
static func delete_dir(path: String) -> void:
	if !DirAccess.dir_exists_absolute(path):
		push_warning("Directory does not exist: %s" % path)
		return

	var dir := DirAccess.open(path)
	if dir == null:
		push_error("Failed to open directory: %s" % path)
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if entry == "." or entry == "..":
			entry = dir.get_next()
			continue

		var full_path := path.path_join(entry)
		if dir.current_is_dir():
			delete_dir(full_path) # recursive
		else:
			DirAccess.remove_absolute(full_path)

		entry = dir.get_next()
	dir.list_dir_end()

	DirAccess.remove_absolute(path)

## Awaits between one of two signals (a or b), must have an callable to trigger both
## (if no trigger is necessary, just set an callable, still works)
static func race_signals(a: Signal, b: Signal, fn: Callable) -> Dictionary[String, Variant]:
	var winner = [""]
	var results: Array[Variant] = []

	var cb_a = func(...args):
		winner[0] = "a"
		results.append(args)

	var cb_b = func(...args):
		winner[0] = "b"
		results.append(args)


	a.connect(cb_a, CONNECT_ONE_SHOT)
	b.connect(cb_b, CONNECT_ONE_SHOT)

	fn.call()

	while winner[0] == "":
		await Engine.get_main_loop().process_frame

	if a.is_connected(cb_a): a.disconnect(cb_a)
	if b.is_connected(cb_b): b.disconnect(cb_b)

	return {"winner": winner[0], "results": results}


static func await_first_signal(a: Signal, b: Signal) -> Variant:
	await await Engine.get_main_loop().process_frame
	var state = {"done": false, "winner": "", "args": []}

	var on_a := func (...args):
		if not state.done:
			state.done = true
			state.winner = "a"
			state.args = args
	var on_b := func(...args):
		if not state.done:
			state.done = true
			state.winner = "b"
			state.args = args

	a.connect(on_a.bind("a_trigger"), CONNECT_ONE_SHOT)
	b.connect(on_b.bind("b_trigger"), CONNECT_ONE_SHOT)

	while not state.done:
		await Engine.get_main_loop().process_frame

	if a.is_connected(on_a.bind("a_trigger")):
		a.disconnect(on_a.bind("a_trigger"))

	if b.is_connected(on_b.bind("b_trigger")):
		b.disconnect(on_b.bind("b_trigger"))

	return state
