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
                g.name
            FROM songs s
            LEFT JOIN albums  al ON s.album_id  = al.id
            LEFT JOIN artists ar ON al.artist_id = ar.id
            LEFT JOIN genres  g  ON al.genre_id  = g.id
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

        // Placeholders
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
                g.name
            FROM songs s
            LEFT JOIN albums  al ON s.album_id  = al.id
            LEFT JOIN artists ar ON al.artist_id = ar.id
            LEFT JOIN genres  g  ON al.genre_id  = g.id
            WHERE s.path IN ({placeholders});
        ";

        for (int i = 0; i < paths.Count; i++)
            cmd.Parameters.AddWithValue($"$p{i}", paths[i]);

        // Index by path
        var byPath = new System.Collections.Generic.Dictionary<string, SongModel>();
        using var reader = cmd.ExecuteReader();
        while (reader.Read())
        {
            var song = MapSong(reader);
            byPath[song.FilePath] = song;
        }

        // Order
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
                g.name
            FROM songs s
            LEFT JOIN albums  al ON s.album_id  = al.id
            LEFT JOIN artists ar ON al.artist_id = ar.id
            LEFT JOIN genres  g  ON al.genre_id  = g.id
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
                g.name
            FROM songs s
            LEFT JOIN albums  al ON s.album_id  = al.id
            LEFT JOIN artists ar ON al.artist_id = ar.id
            LEFT JOIN genres  g  ON al.genre_id  = g.id
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

    // <summary> Gets an Array[SongModel] from most played songs, using scrobbles as reference. </summary>
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

        // Brute scrobbles

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
                // try by taglib
                var tagged = TagManager.ReadTags(path);
                if (tagged != null) songs.Add(tagged);
            }
            else
            {
                // no path
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
                title    = $title,
                album_id = $albumId,
                length   = $length,
                lyrics   = $lyrics,
                indexed  = 1
            WHERE path = $path;
        ";
        cmd.Parameters.AddWithValue("$title", song.Title ?? "");
        cmd.Parameters.AddWithValue("$albumId", albumId);
        cmd.Parameters.AddWithValue("$length", song.Length);
        cmd.Parameters.AddWithValue("$lyrics", song.Lyrics ?? "");
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
        FilePath = r.GetString(0),
        FileName = System.IO.Path.GetFileName(r.GetString(0)),
        Title = r.IsDBNull(1) ? "" : r.GetString(1),
        Length = r.IsDBNull(2) ? 0 : r.GetInt64(2),
        Lyrics = r.IsDBNull(3) ? "" : r.GetString(3),
        AlbumId = r.IsDBNull(4) ? 0 : r.GetInt64(4),
        Album = r.IsDBNull(5) ? "" : r.GetString(5),
        ArtPath = r.IsDBNull(6) ? "" : r.GetString(6),
        Year = r.IsDBNull(7) ? 0 : (uint)r.GetInt32(7),
        Artist = r.IsDBNull(9) ? "" : r.GetString(9),
        Genre = r.IsDBNull(10) ? "" : r.GetString(10),
    };
    #endregion
}
