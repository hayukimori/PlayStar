class_name CopyPasteFeatures


static func copy_song(song: SongModel) -> void:
	if not song: return
	var fp = song.FilePath
	MiscTools.CopyFileToClipboard(fp, false)

	SignalBus.emit_pop_msg_request("Song copied to clipboard")
