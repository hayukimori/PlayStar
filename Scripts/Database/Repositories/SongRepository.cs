using Godot;
using Godot.Collections;
using Microsoft.Data.Sqlite;
using PlayStar.Scripts.Core;
using PlayStar.Scripts.Models;

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
    #endregion

    #region Write
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
