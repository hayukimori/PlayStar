extends HybridWindow

@export var info_tree: Tree
@export var title_label: Label

func _ready() -> void:
	SignalBus.show_tags_window.connect(open_with)
	SignalBus.song_changed.connect(_verif_change_data)
	close_requested.connect(hide)


func open_with(song: SongModel) -> void:
	var data: Dictionary = get_full_metadata(song)
	set_tree(data)
	set_tt(song)
	open()

func set_tt(song: SongModel):
	title = "Tags for ' %s '" % song.Title

	if title_label:
		title_label.text = "Tags for ' %s '" % song.Title


func set_tree(data: Dictionary) -> void:
	info_tree.clear()

	var root_it = info_tree.create_item()
	info_tree.hide_root = true

	for key in data:
		var _child = info_tree.create_item(root_it)
		_child.set_text(0, key)
		_child.set_text(1, str(data[key]))


func get_full_metadata(song: SongModel) -> Dictionary:
	# HTTP SONG
	if song.FilePath.begins_with("http"):
		var raw := {
			"AlbumId": song.AlbumId,
			"Title": song.Title,
			"Artist": song.Artist,
			"Album": song.Album,
			"Genre": song.Genre,
			"Bpm": song.Bpm,
			"Length": song.Length,
			"Year": song.Year,
			"FilePath": song.FilePath,
			"FileName": song.FileName,
			"ArtPath": song.ArtPath,
			"Lyrics": song.Lyrics,
			"SongId": song.SongId,
			"AlbumArtTexture": song.AlbumArtTexture
		}
		var result: Dictionary = {}
		for key in raw:
			var value = raw[key]
			match typeof(value):
				TYPE_STRING: if not str(value).is_empty(): result[key] = value
				TYPE_INT, TYPE_FLOAT: if value != 0: result[key] = value
		return result



	var metadata: AudioMetadataResource
	metadata = TagManager.ExtractFullMetadata(song.FilePath)


	var _FilePath: String = metadata.FilePath
	var _MimeType: String = metadata.MimeType
	var _FileSize: int = metadata.FileSize

	# Audio Properties
	var _AudioBitrate: int = metadata.AudioBitrate
	var _AudioSampleRate: int = metadata.AudioSampleRate
	var _AudioChannels: int = metadata.AudioChannels
	var _BitsPerSample: int = metadata.BitsPerSample
	var _AudioCodec: String = metadata.AudioCodec
	var _DurationSeconds: int = metadata.DurationSeconds
	var _DurationFormatted: String = metadata.DurationFormatted


	# Basic tags
	var _Title: String = metadata.Title
	var _Subtitle: String = metadata.Subtitle
	var _Description: String = metadata.Description
	var _Artists: PackedStringArray = metadata.Artists
	var _AlbumArtists: PackedStringArray = metadata.AlbumArtists
	var _Composers: PackedStringArray = metadata.Composers
	var _Performers: PackedStringArray = metadata.Performers
	var _Album: String = metadata.Album
	var _Year: int = metadata.Year
	var _Track: int = metadata.Track
	var _TrackCount: int = metadata.TrackCount
	var _Disc: int = metadata.Disc
	var _DiscCount: int = metadata.DiscCount
	var _Genres: PackedStringArray = metadata.Genres
	var _Comment: String = metadata.Comment
	var _Lyrics: String = metadata.Lyrics
	var _Conductor: String = metadata.Conductor
	var _Copyright: String = metadata.Copyright
	var _Publisher: String = metadata.Publisher

	# Classification tags
	var _MusicBrainzTrackId: String = metadata.MusicBrainzTrackId
	var _MusicBrainzArtistId: String = metadata.MusicBrainzArtistId
	var _MusicBrainzReleaseId: String = metadata.MusicBrainzReleaseId
	var _MusicBrainzReleaseArtistId: String = metadata.MusicBrainzReleaseArtistId
	var _MusicBrainzReleaseGroupId: String = metadata.MusicBrainzReleaseGroupId
	var _MusicBrainzReleaseStatus: String = metadata.MusicBrainzReleaseStatus
	var _MusicBrainzReleaseType: String = metadata.MusicBrainzReleaseType
	var _MusicBrainzDiscId: String = metadata.MusicBrainzDiscId
	var _MusicIpId: String = metadata.MusicIpId

	# Media tags
	var _IsCompilation: bool = metadata.IsCompilation
	var _RemixedBy: String = metadata.RemixedBy
	var _Grouping: String = metadata.Grouping
	var _BeatsPerMinute: float = metadata.BeatsPerMinute
	var _InitialKey: String = metadata.InitialKey
	var _AmazonId: String = metadata.AmazonId


	var _CustomTags: Dictionary[String, String] = metadata.CustomTags

	# Format metadata
	var _Format: String
	var _TagTypes: String

	# ID3v2 specific
	var _Id3v2Version: String
	var _Id3v2HasFooter: bool

	# MP4 specific
	var _Mp4Rating: String
	var _Mp4IsCompilation: bool

	# FLAC specific
	var _FlacBlockSize: int

	# ASF/WMA specific
	var _AsfContentDescription: String

	var all_metadata: Dictionary = {
		"FilePath": _FilePath,
		"MimeType": _MimeType,
		"FileSize": _FileSize,
		"AudioBitrate": _AudioBitrate,
		"AudioSampleRate": _AudioSampleRate,
		"AudioChannels": _AudioChannels,
		"BitsPerSample": _BitsPerSample,
		"AudioCodec": _AudioCodec,
		"DurationSeconds": _DurationSeconds,
		"DurationFormatted": _DurationFormatted,
		"Title": _Title,
		"Subtitle": _Subtitle,
		"Description": _Description,
		"Artists": _Artists,
		"AlbumArtists": _AlbumArtists,
		"Composers": _Composers,
		"Performers": _Performers,
		"Album": _Album,
		"Year": _Year,
		"Track": _Track,
		"TrackCount": _TrackCount,
		"Disc": _Disc,
		"DiscCount": _DiscCount,
		"Genres": _Genres,
		"Comment": _Comment,
		"Lyrics": _Lyrics,
		"Conductor": _Conductor,
		"Copyright": _Copyright,
		"Publisher": _Publisher,
		"MusicBrainzTrackId": _MusicBrainzTrackId,
		"MusicBrainzArtistId": _MusicBrainzArtistId,
		"MusicBrainzReleaseId": _MusicBrainzReleaseId,
		"MusicBrainzReleaseArtistId": _MusicBrainzReleaseArtistId,
		"MusicBrainzReleaseGroupId": _MusicBrainzReleaseGroupId,
		"MusicBrainzReleaseStatus": _MusicBrainzReleaseStatus,
		"MusicBrainzReleaseType": _MusicBrainzReleaseType,
		"MusicBrainzDiscId": _MusicBrainzDiscId,
		"MusicIpId": _MusicIpId,
		"IsCompilation": _IsCompilation,
		"RemixedBy": _RemixedBy,
		"Grouping": _Grouping,
		"BeatsPerMinute": _BeatsPerMinute,
		"InitialKey": _InitialKey,
		"AmazonId": _AmazonId,

		"Format": _Format,
		"TagTypes": _TagTypes,
		"Id3v2Version": _Id3v2Version,
		"Id3v2HasFooter": _Id3v2HasFooter,
		"Mp4Rating": _Mp4Rating,
		"Mp4IsCompilation": _Mp4IsCompilation,
		"FlacBlockSize": _FlacBlockSize,
		"AsfContentDescription": _AsfContentDescription
	}

	var final_metadata: Dictionary = {}

	for key in all_metadata:
		var value = all_metadata[key]
		var has_value: bool = false

		match typeof(value):
			TYPE_STRING, TYPE_ARRAY, TYPE_DICTIONARY:
				has_value = not value.is_empty()
			TYPE_INT, TYPE_FLOAT:
				has_value = value != 0
			_:
				has_value = value != null

		if has_value:
			if typeof(value) == TYPE_PACKED_STRING_ARRAY:
				value = ",".join(value)

			final_metadata[key] = value

	if _CustomTags:
		for item in _CustomTags:
			final_metadata[item] = _CustomTags[item]

	return final_metadata


func _verif_change_data(song: SongModel) -> void:
	if !song: return
	if !visible: return

	open_with(song)
