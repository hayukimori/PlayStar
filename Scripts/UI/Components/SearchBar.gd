extends LineEdit
class_name SearchBar

enum SearchMode { SONGS, ARTIST, ALBUM}
enum SearchScope { QUEUE, PLAYLIST, FULL }

signal render_results(results: Array)
signal render_default()

var _search_timer := Timer.new()
var _pending_text : String = ""

@onready var search_repo: SearchRepository

@export_category("Search scope and model")
@export var search_scope: SearchScope = SearchScope.FULL
@export var search_mode: SearchMode = SearchMode.SONGS

@export_group("Queue Scope")
@export var current_queue: Array[SongModel]

@export_group("Playlist Scope")
@export var current_playlist: PlaylistModel

@export_group("Full Scope")
@export var ignore_unknown: bool = true


func _ready():
        _search_timer.wait_time = 0.5
        _search_timer.one_shot = true
        _search_timer.timeout.connect(_search_internal)
        self.text_changed.connect(_on_text_changed)

        search_repo = SearchRepository.new()
        search_repo.Initialize(NodeKeeper.current_database)

        add_child(_search_timer)

func debounce_search(ctx):
        _pending_text = ctx
        _search_timer.start()



func _search_internal() -> void:
        match search_scope:
                SearchScope.QUEUE: _as_current_queue()
                SearchScope.PLAYLIST: _as_playlist()
                SearchScope.FULL: _as_full()




func _as_current_queue() -> void:
        if !current_queue:
                push_error("No queue array is set")
                return

        var results = get_compatible_from_array(current_queue)
        if results: render_results.emit(results)


func _as_playlist() -> void:
        if !current_playlist:
                push_error("No Playlist is set")
                return

        var results = get_compatible_from_playlist(current_playlist)
        if results: render_results.emit(results)



func _as_full() -> void:
        _do_search()


func get_compatible_from_array(obj: Array[SongModel]) -> Array[SongModel]:
        var search_term = self.text.to_lower()
        if search_term.is_empty():
                return []

        return obj.filter(func(song):
                return (search_term in song.Title.to_lower() or
                                search_term in song.Artist.to_lower() or
                                search_term in song.Album.to_lower())
        )


func get_compatible_from_playlist(obj: PlaylistModel) -> Array[SongModel]:
        return get_compatible_from_array(obj.songs)



func _do_search():
        #var results = SearchRepository.Search(_pending_text)
        print("Searching for: ", _pending_text)

        var results

        match search_mode:
                SearchMode.SONGS:
                        results = search_repo.Search(_pending_text)
                SearchMode.ARTIST:
                        results = search_repo.SearchArtists(_pending_text)
                SearchMode.ALBUM:
                        results = search_repo.SearchAlbums(_pending_text)
                _: search_repo.Search(_pending_text)


        emit_signal("render_results", results)


func _render_default() -> void:
        render_default.emit()

func _on_text_changed(new_text):
        if !new_text: _render_default(); return;

        debounce_search(new_text)
