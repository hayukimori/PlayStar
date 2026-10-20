extends Node


@export_category("Panels")
@export var songlist_panel: Panel
@export var playing_now_panel: Panel
@export var cover_panel: Panel
@export var menu_panel: Panel

@export_category("Playback controls")
@export var pn_bg_panel: Panel
@export var pb_bg_cr: ColorRect ## Progress Bar bg
@export var pg_cr: ColorRect ## Progress Bar

var song_btn_theme := preload("res://UI/ComponentThemes/SongBtnTheme.tres")
var song_btn_title_ls := preload("res://UI/ComponentThemes/SongButtonTitleLabelSettings.tres")
var song_btn_artist_ls := preload("res://UI/ComponentThemes/SongButtonArtistLabelSettings.tres")

func _ready() -> void:
	print("[ThemeApplier] Theme Applier started")
	GtkThemeProvider.ColorsLoaded.connect(_on_theme_update)


## Sets a color palette (GKTColorPalette) to the player
func set_theme(palette: GTKColorPalette) -> void:
	# Set theme for all background Color Rects
	for node in get_tree().get_nodes_in_group("background_color_rects"):
		node.color = palette.WindowBgColor

	# for panels
	if playing_now_panel: update_panel_color(playing_now_panel, palette.ViewBgColor)
	if songlist_panel: update_panel_color(songlist_panel, palette.ViewBgColor)
	if cover_panel: update_panel_color(cover_panel, palette.ViewBgColor)
	if menu_panel: update_panel_color(menu_panel, palette.ViewBgColor)
	if pn_bg_panel: update_panel_color(pn_bg_panel, palette.ViewBgColor)

	# Inverted; Progress Bar
	apply_progress_bar(palette.AccentFgColor, palette.AccentColor)
	apply_ui_btns(palette.AccentColor)
	apply_ui_text(palette.AccentColor)

	# Songs
	var btn_sbx := song_btn_theme.get_stylebox("panel", "Panel").duplicate()
	btn_sbx.bg_color = palette.HeaderbarBgColor
	song_btn_theme.set_stylebox("panel", "Panel", btn_sbx)

	# Song title (songbutton)
	song_btn_title_ls.font_color = palette.ViewFgColor

	# Song Artist (songbutton)
	var artist_color = palette.ViewFgColor
	artist_color.a = 0.5
	song_btn_artist_ls.font_color = artist_color




## Applies color for ProgressBar and ProgressBar background (counterwave)
func apply_progress_bar(bgcolor: Color, fgcolor: Color) -> void:
	if pb_bg_cr:
		var shdr2 = pb_bg_cr.material as ShaderMaterial
		shdr2.set_shader_parameter("color", bgcolor)

	if pg_cr:
		var shdr = pg_cr.material as ShaderMaterial
		shdr.set_shader_parameter("color", fgcolor)


## Applies a color (modulate) to UI buttons in group "ui_buttons"
func apply_ui_btns(color: Color) -> void:
	for btn in get_tree().get_nodes_in_group("ui_buttons"):
		if btn is Button:
			btn.modulate = color

## Applies a color (modulate) to UI texts in group "ui_mod_text"
func apply_ui_text(color: Color) -> void:
	for lbl in get_tree().get_nodes_in_group("ui_mod_text") as Array:
		lbl.modulate = color

## Overrides Stylebox using current, but changing the background color
func update_panel_color(panel: Panel, color: Color) -> void:
	var sbx = panel.get_theme_stylebox("panel", "Panel").duplicate()
	sbx.bg_color = color
	panel.add_theme_stylebox_override("panel", sbx)


func _on_theme_update(palette: GTKColorPalette) -> void:
	NodeKeeper.current_theme = palette
	set_theme(palette)
