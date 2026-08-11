extends HybridWindow
class_name DynamicListsWindow

@export var hst_sc: HistoryScrollContainer
@export var mp7_sc: MP7ScrollContainer
@export var mp30_sc: MP30ScrollContainer

@export var tab_container: TabContainer
@export var name_label: Label
@export var tp_btn: ToPlaylistButton

enum TABS_IDX { HISTORY, FAVORITE, MP7, MP30, MPYEAR }

func _ready() -> void:
	hst_sc.history_songs_updated.connect(_on_songs_updated)
	mp7_sc.mp7_songs_updated.connect(_on_songs_updated)
	mp30_sc.mp30_songs_updated.connect(_on_songs_updated)

	self.close_requested.connect(_close)
	tab_container.tab_changed.connect(_on_tab_changed)

	set_tab(TABS_IDX.HISTORY)

func set_tab(tab: TABS_IDX) -> void:
	match tab:
		TABS_IDX.HISTORY:
			name_label.text = "History"
		TABS_IDX.FAVORITE:
			name_label.text = "Favorites songs"
		TABS_IDX.MP7:
			name_label.text = "Most Played Songs (7 days)"
		TABS_IDX.MP30:
			name_label.text = "Most Played Songs (30 days)"
		TABS_IDX.MPYEAR:
			name_label.text = "Most Played Songs (year)"
		_: return

func _on_tab_changed(idx: int) -> void:
	var tab = idx as TABS_IDX
	set_tab(tab)

func _on_songs_updated(songs: Array[SongModel]) -> void:
	tp_btn.content = songs

func _close() -> void:
	self.hide()
