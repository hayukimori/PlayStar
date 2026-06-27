extends Node

# Functional
var current_database: DatabaseManager
var current_indexer: MetadataIndexer
var current_scanner: LibraryScanner

# Repositories
var search_repository: SearchRepository
var song_repository: SongRepository
var artist_repository: ArtistRepository
var album_repository: AlbumRepository

var vlc_player: VlcPlayer
