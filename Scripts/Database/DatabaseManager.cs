using Godot;
using Microsoft.Data.Sqlite;

namespace PlayStar.Scripts.Database;

[GlobalClass]
public partial class DatabaseManager : Node
{
    private string _dbPath;

    public override void _Ready() { }

    #region Initialization
    public void Initialize()
    {
        _dbPath = ProjectSettings.GlobalizePath("user://songs.db");
        GD.Print($"[DatabaseManager] Path: {_dbPath}");
        InitializeDatabase();
    }

    public SqliteConnection GetConnection()
    {
        var connection = new SqliteConnection($"Data Source={_dbPath}");
        connection.Open();
        ApplyPragmas(connection);
        return connection;
    }
    #endregion

    #region Schema
    private void InitializeDatabase()
    {
        using var connection = GetConnection();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            BEGIN;

            CREATE TABLE IF NOT EXISTS artists (
                id   INTEGER PRIMARY KEY,
                name TEXT NOT NULL UNIQUE
            );

            CREATE TABLE IF NOT EXISTS genres (
                id   INTEGER PRIMARY KEY,
                name TEXT NOT NULL UNIQUE
            );

            CREATE TABLE IF NOT EXISTS albums (
                id        INTEGER PRIMARY KEY,
                title     TEXT NOT NULL,
                artist_id INTEGER REFERENCES artists(id) ON DELETE SET NULL,
                genre_id  INTEGER REFERENCES genres(id)  ON DELETE SET NULL,
                year      INTEGER,
                art_path  TEXT,
                UNIQUE(title, artist_id)
            );

            CREATE TABLE IF NOT EXISTS songs (
                path     TEXT PRIMARY KEY,
                title    TEXT,
                album_id INTEGER REFERENCES albums(id) ON DELETE SET NULL,
                length   INTEGER,
                mtime    INTEGER,
                indexed  INTEGER NOT NULL DEFAULT 0,
                lyrics   TEXT
            );

            CREATE TABLE IF NOT EXISTS song_artists (
                song_path TEXT REFERENCES songs(path) ON DELETE CASCADE,
                artist_id INTEGER REFERENCES artists(id) ON DELETE CASCADE,
                is_main   INTEGER DEFAULT 1,
                PRIMARY KEY (song_path, artist_id)
            );

            CREATE INDEX IF NOT EXISTS idx_songs_title    ON songs(title);
            CREATE INDEX IF NOT EXISTS idx_songs_album_id ON songs(album_id);
            CREATE INDEX IF NOT EXISTS idx_albums_title   ON albums(title);
            CREATE INDEX IF NOT EXISTS idx_artists_name   ON artists(name);
            CREATE INDEX IF NOT EXISTS idx_song_artists_artist_id ON song_artists(artist_id);

            COMMIT;
        ";
        cmd.ExecuteNonQuery();
        GD.Print("[DatabaseManager] Schema initialized.");
    }
    #endregion

    #region Utils
    private static void ApplyPragmas(SqliteConnection connection)
    {
        using var pragma = connection.CreateCommand();
        pragma.CommandText = @"
            PRAGMA journal_mode = WAL;
            PRAGMA synchronous  = NORMAL;
            PRAGMA temp_store   = MEMORY;
            PRAGMA mmap_size    = 30000000000;
            PRAGMA cache_size   = -20000;
            PRAGMA foreign_keys = ON;
        ";
        pragma.ExecuteNonQuery();
    }

    public void WipeAndReinitialize()
    {
        using var connection = GetConnection();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            BEGIN;
            DROP TABLE IF EXISTS song_artists;
            DROP TABLE IF EXISTS songs;
            DROP TABLE IF EXISTS albums;
            DROP TABLE IF EXISTS genres;
            DROP TABLE IF EXISTS artists;
            COMMIT;
        ";
        cmd.ExecuteNonQuery();
        GD.Print("[DatabaseManager] Database wiped.");
        InitializeDatabase();
    }
    #endregion
}