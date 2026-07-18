class_name Definitions

enum RepeatMode { OFF, REPEAT_ONE, REPEAT_QUEUE }
enum LibraryOptions { HISTORY, DATABASE, LYRICS, PLAYLISTS }


# Static Paths
# TODO: Move static paths (user://--) to here
const USER_HISTORY_PATH  := "user://history.tres" ## songs history path (file)
const DATABASE_PATH      := "user://songs.db" ## database path (file)
const LYRICS_PATH        := "user://lyrics_cache/" ## lyrics files path (directory)
const PLAYLISTS_PATH     := "user://playlists/" ## playlist files path (directory)
