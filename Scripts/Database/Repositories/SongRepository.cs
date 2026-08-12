using System.Linq;
using System.IO;
using System;
using Godot;
using Godot.Collections;
using Microsoft.Data.Sqlite;
using PlayStar.Scripts.Core;
using PlayStar.Scripts.Models;
using System.Collections.Generic;


namespace PlayStar.Scripts.Database.Repositories;


[GlobalClass]
public partial class SongRepository : Node
{
    private DatabaseManager _db;
    private readonly PSMemoryManager _memory = new();

    public void Initialize(DatabaseManager db) => _db = db;

    #region Read
    public Array<SongModel> GetSongs(int limit = 1000, bool ignoreUnknown = false)
    {
        var songs = new Array<SongModel>();

        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();

        var whereClause = ignoreUnknown ? "WHERE ar.name <> 'Unknown'" : "";

        cmd.CommandText = $@"
            SELECT
                s.path, s.title, s.length, s.lyrics,
                al.id, al.title, al.art_path, al.year,
                ar.id,
                COALESCE(
                    (SELECT GROUP_CONCAT(name, ', ') FROM (
                        SELECT a.name FROM song_artists sa JOIN artists a ON sa.artist_id = a.id
                        WHERE sa.song_path = s.path ORDER BY sa.is_main DESC
                    )), ar.name
                ) AS track_artist,
                g.name,
                st.starred_at,
                s.mb_track_id, s.mb_artist_id, s.mb_release_id,
                s.mb_release_artist_id, s.mb_release_group_id,
                s.mb_release_status, s.mb_release_type,
                s.mb_disc_id, s.music_ip_id
            FROM songs s
            LEFT JOIN albums        al ON s.album_id  = al.id
            LEFT JOIN artists       ar ON al.artist_id = ar.id
            LEFT JOIN genres        g  ON al.genre_id  = g.id
            LEFT JOIN starred_songs st ON st.song_path = s.path
            {whereClause}
            ORDER BY s.title
            LIMIT $limit;
        ";
        cmd.Parameters.AddWithValue("$limit", limit);

        using var reader = cmd.ExecuteReader();
        while (reader.Read())
            songs.Add(MapSong(reader));

        _memory.RequestCleanup();
        return songs;
    }

    public Array<SongModel> GetSongsByPaths(Godot.Collections.Array<string> paths)
    {
        var songs = new Array<SongModel>();
        if (paths.Count == 0) return songs;

        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();

        var placeholders = string.Join(", ", paths.Select((_, i) => $"$p{i}"));

        cmd.CommandText = $@"
            SELECT
                s.path, s.title, s.length, s.lyrics,
                al.id, al.title, al.art_path, al.year,
                ar.id,
                COALESCE(
                    (SELECT GROUP_CONCAT(name, ', ') FROM (
                        SELECT a.name FROM song_artists sa JOIN artists a ON sa.artist_id = a.id
                        WHERE sa.song_path = s.path ORDER BY sa.is_main DESC
                    )), ar.name
                ) AS track_artist,
                g.name,
                st.starred_at,
                s.mb_track_id, s.mb_artist_id, s.mb_release_id,
                s.mb_release_artist_id, s.mb_release_group_id,
                s.mb_release_status, s.mb_release_type,
                s.mb_disc_id, s.music_ip_id
            FROM songs s
            LEFT JOIN albums        al ON s.album_id  = al.id
            LEFT JOIN artists       ar ON al.artist_id = ar.id
            LEFT JOIN genres        g  ON al.genre_id  = g.id
            LEFT JOIN starred_songs st ON st.song_path = s.path
            WHERE s.path IN ({placeholders});
        ";

        for (int i = 0; i < paths.Count; i++)
            cmd.Parameters.AddWithValue($"$p{i}", paths[i]);

        var byPath = new System.Collections.Generic.Dictionary<string, SongModel>();
        using var reader = cmd.ExecuteReader();
        while (reader.Read())
        {
            var song = MapSong(reader);
            byPath[song.FilePath] = song;
        }

        foreach (var path in paths)
            if (byPath.TryGetValue(path, out var song))
                songs.Add(song);

        _memory.RequestCleanup();
        return songs;
    }

    public Array<SongModel> GetSongsFromArtist(ArtistModel artist, int limit = 1000)
    {
        var songs = new Array<SongModel>();

        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            SELECT
                s.path, s.title, s.length, s.lyrics,
                al.id, al.title, al.art_path, al.year,
                ar.id,
                COALESCE(
                    (SELECT GROUP_CONCAT(name, ', ') FROM (
                        SELECT a.name FROM song_artists sa JOIN artists a ON sa.artist_id = a.id
                        WHERE sa.song_path = s.path ORDER BY sa.is_main DESC
                    )), ar.name
                ) AS track_artist,
                g.name,
                st.starred_at,
                s.mb_track_id, s.mb_artist_id, s.mb_release_id,
                s.mb_release_artist_id, s.mb_release_group_id,
                s.mb_release_status, s.mb_release_type,
                s.mb_disc_id, s.music_ip_id
            FROM songs s
            LEFT JOIN albums        al ON s.album_id  = al.id
            LEFT JOIN artists       ar ON al.artist_id = ar.id
            LEFT JOIN genres        g  ON al.genre_id  = g.id
            LEFT JOIN starred_songs st ON st.song_path = s.path
            WHERE EXISTS (
                SELECT 1 FROM song_artists sa_f
                WHERE sa_f.song_path = s.path AND sa_f.artist_id = $artistId
            )
            ORDER BY s.title
            LIMIT $limit;
        ";
        cmd.Parameters.AddWithValue("$artistId", artist.Id);
        cmd.Parameters.AddWithValue("$limit", limit);

        using var reader = cmd.ExecuteReader();
        while (reader.Read())
            songs.Add(MapSong(reader));

        _memory.RequestCleanup();
        return songs;
    }

    public SongModel GetFirstSongFromArtist(ArtistModel artist)
    {
        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            SELECT
                s.path, s.title, s.length, s.lyrics,
                al.id, al.title, al.art_path, al.year,
                ar.id,
                COALESCE(
                    (SELECT GROUP_CONCAT(name, ', ') FROM (
                        SELECT a.name FROM song_artists sa JOIN artists a ON sa.artist_id = a.id
                        WHERE sa.song_path = s.path ORDER BY sa.is_main DESC
                    )), ar.name
                ) AS track_artist,
                g.name,
                st.starred_at,
                s.mb_track_id, s.mb_artist_id, s.mb_release_id,
                s.mb_release_artist_id, s.mb_release_group_id,
                s.mb_release_status, s.mb_release_type,
                s.mb_disc_id, s.music_ip_id
            FROM songs s
            LEFT JOIN albums        al ON s.album_id  = al.id
            LEFT JOIN artists       ar ON al.artist_id = ar.id
            LEFT JOIN genres        g  ON al.genre_id  = g.id
            LEFT JOIN starred_songs st ON st.song_path = s.path
            WHERE EXISTS (
                SELECT 1 FROM song_artists sa_f
                WHERE sa_f.song_path = s.path AND sa_f.artist_id = $artistId
            )
            LIMIT 1;
        ";
        cmd.Parameters.AddWithValue("$artistId", artist.Id);

        using var reader = cmd.ExecuteReader();
        var rest = reader.Read() ? MapSong(reader) : new SongModel();

        _memory.RequestCleanup();
        return rest;
    }

    public Array<SongModel> GetStarredSongs(int limit = 1000)
    {
        var songs = new Array<SongModel>();

        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            SELECT
                s.path, s.title, s.length, s.lyrics,
                al.id, al.title, al.art_path, al.year,
                ar.id,
                COALESCE(
                    (SELECT GROUP_CONCAT(name, ', ') FROM (
                        SELECT a.name FROM song_artists sa JOIN artists a ON sa.artist_id = a.id
                        WHERE sa.song_path = s.path ORDER BY sa.is_main DESC
                    )), ar.name
                ) AS track_artist,
                g.name,
                st.starred_at,
                s.mb_track_id, s.mb_artist_id, s.mb_release_id,
                s.mb_release_artist_id, s.mb_release_group_id,
                s.mb_release_status, s.mb_release_type,
                s.mb_disc_id, s.music_ip_id
            FROM starred_songs st
            JOIN songs         s  ON s.path       = st.song_path
            LEFT JOIN albums   al ON s.album_id   = al.id
            LEFT JOIN artists  ar ON al.artist_id = ar.id
            LEFT JOIN genres   g  ON al.genre_id  = g.id
            ORDER BY st.starred_at DESC
            LIMIT $limit;
        ";
        cmd.Parameters.AddWithValue("$limit", limit);

        using var reader = cmd.ExecuteReader();
        while (reader.Read())
            songs.Add(MapSong(reader));

        _memory.RequestCleanup();
        return songs;
    }

    public Array<SongModel> GetMostPlayedSongs(int limit = 50, int days = 1)
    {
        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();

        cmd.CommandText = @"
            SELECT song_path, title, artist, COUNT(*) AS plays
            FROM scrobbles
            WHERE scrobbled_at > unixepoch() - ($days * 86400)
            GROUP BY COALESCE(song_path, title || artist)
            ORDER BY plays DESC
            LIMIT $limit;
        ";

        cmd.Parameters.AddWithValue("$days", days);
        cmd.Parameters.AddWithValue("$limit", limit);

        var rows = new List<(string? path, string title, string? artist)>();
        using var reader = cmd.ExecuteReader();
        while (reader.Read())
            rows.Add((
                reader.IsDBNull(0) ? null : reader.GetString(0),
                reader.GetString(1),
                reader.IsDBNull(2) ? null : reader.GetString(2)
            ));

        var paths = new Godot.Collections.Array<string>(
            rows.Where(r => r.path != null).Select(r => r.path!)
        );

        var fromDb = GetSongsByPaths(paths)
            .ToDictionary(s => s.FilePath);

        var songs = new Array<SongModel>();

        foreach (var (path, title, artist) in rows)
        {
            if (path != null && fromDb.TryGetValue(path, out var dbSong))
            {
                songs.Add(dbSong);
            }
            else if (path != null && File.Exists(path))
            {
                var tagged = TagManager.ReadTags(path);
                if (tagged != null) songs.Add(tagged);
            }
            else
            {
                songs.Add(new SongModel { Title = title, FilePath = path ?? "" });
            }
        }

        _memory.RequestCleanup();
        return songs;
    }

    #endregion

    #region Write
    public void MarkScrobble(SongModel song)
    {
        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();

        cmd.CommandText = @"
            INSERT INTO scrobbles
                (song_path, title, artist, scrobbled_at)
            VALUES
                ($song_path, $title, $artist, $scrobbled_at)
        ";

        var song_path = song.FilePath;
        var title = song.Title != "" ? song.Title : null;
        var artist = song.Artist != "" ? song.Title : null;
        var scrobbled_at = DateTimeOffset.UtcNow.ToUnixTimeSeconds();

        cmd.Parameters.AddWithValue("$song_path", song_path);
        cmd.Parameters.AddWithValue("$title", title);
        cmd.Parameters.AddWithValue("$artist", artist);
        cmd.Parameters.AddWithValue("$scrobbled_at", scrobbled_at);

        cmd.ExecuteNonQuery();
    }

    public void StarSong(string path)
    {
        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            INSERT INTO starred_songs(song_path, starred_at)
            VALUES($path, $now)
            ON CONFLICT(song_path) DO NOTHING;
        ";
        cmd.Parameters.AddWithValue("$path", path);
        cmd.Parameters.AddWithValue("$now", DateTimeOffset.UtcNow.ToUnixTimeSeconds());
        cmd.ExecuteNonQuery();
    }

    public void UnstarSong(string path)
    {
        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            DELETE FROM starred_songs WHERE song_path = $path;
        ";
        cmd.Parameters.AddWithValue("$path", path);
        cmd.ExecuteNonQuery();
    }

    public static void UpsertScanEntry(string path, long mtime, SqliteConnection connection, SqliteTransaction transaction)
    {
        using var cmd = connection.CreateCommand();
        cmd.Transaction = transaction;
        cmd.CommandText = @"
            INSERT INTO songs(path, mtime, indexed)
            VALUES($path, $mtime, 0)
            ON CONFLICT(path) DO UPDATE SET
                mtime   = excluded.mtime,
                indexed = CASE
                    WHEN songs.mtime != excluded.mtime THEN 0
                    ELSE songs.indexed
                END;
        ";
        cmd.Parameters.AddWithValue("$path", path);
        cmd.Parameters.AddWithValue("$mtime", mtime);
        cmd.ExecuteNonQuery();
    }

    public void UpdateMetadata(SongModel song, long albumId)
    {
        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            UPDATE songs SET
                title                = $title,
                album_id             = $albumId,
                length               = $length,
                lyrics               = $lyrics,
                indexed              = 1,
                mb_track_id          = $mbTrackId,
                mb_artist_id         = $mbArtistId,
                mb_release_id        = $mbReleaseId,
                mb_release_artist_id = $mbReleaseArtistId,
                mb_release_group_id  = $mbReleaseGroupId,
                mb_release_status    = $mbReleaseStatus,
                mb_release_type      = $mbReleaseType,
                mb_disc_id           = $mbDiscId,
                music_ip_id          = $musicIpId
            WHERE path = $path;
        ";
        cmd.Parameters.AddWithValue("$title", song.Title ?? "Unknown");
        cmd.Parameters.AddWithValue("$albumId", albumId);
        cmd.Parameters.AddWithValue("$length", song.Length);
        cmd.Parameters.AddWithValue("$lyrics", song.Lyrics);
        cmd.Parameters.AddWithValue("$mbTrackId",         song.MusicBrainzTrackId         ?? "");
        cmd.Parameters.AddWithValue("$mbArtistId",        song.MusicBrainzArtistId        ?? "");
        cmd.Parameters.AddWithValue("$mbReleaseId",       song.MusicBrainzReleaseId       ?? "");
        cmd.Parameters.AddWithValue("$mbReleaseArtistId", song.MusicBrainzReleaseArtistId ?? "");
        cmd.Parameters.AddWithValue("$mbReleaseGroupId",  song.MusicBrainzReleaseGroupId  ?? "");
        cmd.Parameters.AddWithValue("$mbReleaseStatus",   song.MusicBrainzReleaseStatus   ?? "");
        cmd.Parameters.AddWithValue("$mbReleaseType",     song.MusicBrainzReleaseType     ?? "");
        cmd.Parameters.AddWithValue("$mbDiscId",          song.MusicBrainzDiscId          ?? "");
        cmd.Parameters.AddWithValue("$musicIpId",         song.MusicIpId                  ?? "");
        cmd.Parameters.AddWithValue("$path", song.FilePath);
        cmd.ExecuteNonQuery();
    }

    public System.Collections.Generic.List<string> GetUnindexedPaths(int limit)
    {
        var result = new System.Collections.Generic.List<string>();

        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            SELECT path FROM songs
            WHERE indexed = 0
            LIMIT $limit;
        ";
        cmd.Parameters.AddWithValue("$limit", limit);

        using var reader = cmd.ExecuteReader();
        while (reader.Read())
            result.Add(reader.GetString(0));

        return result;
    }
    #endregion


    #region Misc
    public SongModel SongModelFromPath(string path, bool raw)
    {
        if (raw)
        {
            SongModel result = TagManager.ReadTags(path);
            return result;
        }

        Array<SongModel> results = GetSongsByPaths([path]);
        return results.Count > 0 ? results[0] : null;
    }

    public Array<SongModel> SongModelArrayFromDirectory(string path)
    {
        Array<SongModel> songs = [];
        List<string> scanResult = FolderScanner.Scan(path);

        foreach (var sPath in scanResult)
        {
            var _sng = SongModelFromPath(sPath, true);
            if (_sng != null) songs.Add(_sng);
        }

        return songs;
    }
    #endregion

    internal static SongModel MapScrobble(SqliteDataReader r) => new() {
        FilePath = r.GetString(0),
        FileName = System.IO.Path.GetFileName(r.GetString(0)),
        Title = r.IsDBNull(1) ? "" : r.GetString(1),
        Artist = r.IsDBNull(2) ? "" : r.GetString(2)
    };

    #region Mapping
    internal static SongModel MapSong(SqliteDataReader r) => new()
    {
        FilePath  = r.GetString(0),
        FileName  = System.IO.Path.GetFileName(r.GetString(0)),
        Title     = r.IsDBNull(1)  ? "" : r.GetString(1),
        Length    = r.IsDBNull(2)  ? 0  : r.GetInt64(2),
        Lyrics    = r.IsDBNull(3)  ? "" : r.GetString(3),
        AlbumId   = r.IsDBNull(4)  ? 0  : r.GetInt64(4),
        Album     = r.IsDBNull(5)  ? "" : r.GetString(5),
        ArtPath   = r.IsDBNull(6)  ? "" : r.GetString(6),
        Year      = r.IsDBNull(7)  ? 0  : (uint)r.GetInt32(7),
        Artist    = r.IsDBNull(9)  ? "" : r.GetString(9),
        Genre     = r.IsDBNull(10) ? "" : r.GetString(10),
        Starred   = !r.IsDBNull(11),
        MusicBrainzTrackId         = r.IsDBNull(12) ? "" : r.GetString(12),
        MusicBrainzArtistId        = r.IsDBNull(13) ? "" : r.GetString(13),
        MusicBrainzReleaseId       = r.IsDBNull(14) ? "" : r.GetString(14),
        MusicBrainzReleaseArtistId = r.IsDBNull(15) ? "" : r.GetString(15),
        MusicBrainzReleaseGroupId  = r.IsDBNull(16) ? "" : r.GetString(16),
        MusicBrainzReleaseStatus   = r.IsDBNull(17) ? "" : r.GetString(17),
        MusicBrainzReleaseType     = r.IsDBNull(18) ? "" : r.GetString(18),
        MusicBrainzDiscId          = r.IsDBNull(19) ? "" : r.GetString(19),
        MusicIpId                  = r.IsDBNull(20) ? "" : r.GetString(20),
    };
    #endregion
}
