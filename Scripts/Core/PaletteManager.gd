class_name PaletteManager

## Loads all palettes in user's directory
static func load_palettes() -> Array[GTKColorPalette]:
	var palettes_path := UserGlobals.USER_PALETTES_PATH
	DevTools.check_and_create(palettes_path)

	var pafiles: Array[String] = DevTools.get_full_dirs(palettes_path)
	if len(pafiles) == 0: return []

	var pa_array: Array[GTKColorPalette] = []
	for item in pafiles:
		var pa = ResourceLoader.load(item)
		if pa is GTKColorPalette:
			pa_array.append(pa)

	return pa_array



#region CRUD
## Creates a palette
static func create(name: String = "") -> GTKColorPalette:
	var dst := _get_main_path()

	var pa := GTKColorPalette.new()
	var uuid = DevTools.generate_uuid_v4()
	var pa_file = uuid + ".tres"
	var pa_path = dst.path_join(pa_file)

	pa.name = name if name else "New palette"

	ResourceSaver.save(pa, pa_path)
	return pa


## Deletes a playlist
static func delete(palette: GTKColorPalette) -> bool:
	_get_main_path()
	var pl_path = palette.resource_path

	if pl_path.is_empty(): return true
	if !FileAccess.file_exists(pl_path): return true

	DirAccess.remove_absolute(pl_path)
	return !FileAccess.file_exists(pl_path)


## Saves a palette
static func save(palette: GTKColorPalette) -> void:
	var palette_path = palette.resource_path

	if !palette_path:
		var uuid := DevTools.generate_uuid_v4()
		var pa_filename = uuid + ".tres"
		var p1 := _get_main_path()
		var p2 := p1.path_join(pa_filename)
		palette_path = p2

	ResourceSaver.save(palette, palette_path)



## Renames a Palette + save [br]
## (Required) [param new_name] ([class String]) as new name for given palette[br]
## (Required) [param palette] [class GTKColorPalette] as object to rename [br]
## (Optional) [param save_after] (true by defaullt) to save file after rename
##
## Usage:
## [codeblock]
## PaletteManager.rename("Hello, world", current_palette)
## [/codeblock]
static func rename(new_name: String, palette: GTKColorPalette, save_after: bool = true) -> void:
	palette.name = new_name if new_name else "Unnamed palette"
	if save_after: save(palette)



static func _get_main_path() -> String:
	var palettes_path := UserGlobals.USER_PALETTES_PATH
	DevTools.check_and_create(palettes_path)

	return palettes_path
