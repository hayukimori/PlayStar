using Godot;
using Microsoft.Data.Sqlite;

namespace PlayStar.Scripts.Database;

[GlobalClass]
public partial class DatabaseManager : Node
{
    private const int CurrentVersion = 2;

    private string _dbPath;

    public override void _Ready() { }

    #region Initialization
    public void Initialize()
    {
        _dbPath = ProjectSettings.GlobalizePath("user://songs.db");
        GD.Print($"[DatabaseManager] Path: {_dbPath}");
        CheckAndMigrate();
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

    #region Versioning
    private void CheckAndMigrate()
    {
        using var connection = GetConnection();

        // Check if db_meta exists — if not, it's a pre-versioning database
        using var checkCmd = connection.CreateCommand();
        checkCmd.CommandText = @"
            SELECT COUNT(*) FROM sqlite_master
            WHERE type='table' AND name='db_meta';
        ";
        var metaExists = (long)checkCmd.ExecuteScalar() > 0;

        if (metaExists)
        {
            using var versionCmd = connection.CreateCommand();
            versionCmd.CommandText = "SELECT value FROM db_meta WHERE key = 'version';";
            var result = versionCmd.ExecuteScalar();

            if (result != null && int.TryParse(result.ToString(), out var version) && version >= CurrentVersion)
            {
                GD.Print($"[DatabaseManager] Schema version {version} is current.");
                return;
            }
        }

        GD.Print("[DatabaseManager] Schema outdated or unversioned — wiping and reinitializing.");
        DropAllTables();
    }
    #endregion

    #region Schema
    private void InitializeDatabase()
    {
        using var connection = GetConnection();
        using var cmd = connection.CreateCommand();

        cmd.CommandText = @"
            BEGIN;

            CREATE TABLE IF NOT EXISTS db_meta (
                key   TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );

            INSERT OR IGNORE INTO db_meta(key, value) VALUES('version', $version);

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
                path                 TEXT PRIMARY KEY,
                title                TEXT,
                album_id             INTEGER REFERENCES albums(id) ON DELETE SET NULL,
                length               INTEGER,
                mtime                INTEGER,
                indexed              INTEGER NOT NULL DEFAULT 0,
                lyrics               TEXT,
                mb_track_id          TEXT,
                mb_artist_id         TEXT,
                mb_release_id        TEXT,
                mb_release_artist_id TEXT,
                mb_release_group_id  TEXT,
                mb_release_status    TEXT,
                mb_release_type      TEXT,
                mb_disc_id           TEXT,
                music_ip_id          TEXT
            );

            CREATE TABLE IF NOT EXISTS song_artists (
                song_path TEXT REFERENCES songs(path) ON DELETE CASCADE,
                artist_id INTEGER REFERENCES artists(id) ON DELETE CASCADE,
                is_main   INTEGER DEFAULT 1,
                PRIMARY KEY (song_path, artist_id)
            );

            CREATE TABLE IF NOT EXISTS scrobbles (
                id           INTEGER PRIMARY KEY AUTOINCREMENT,
                song_path    TEXT REFERENCES songs(path) ON DELETE SET NULL,
                title        TEXT NOT NULL,
                artist       TEXT,
                scrobbled_at INTEGER NOT NULL
            );

            CREATE TABLE IF NOT EXISTS starred_songs (
                song_path  TEXT PRIMARY KEY REFERENCES songs(path) ON DELETE CASCADE,
                starred_at INTEGER NOT NULL
            );

            CREATE INDEX IF NOT EXISTS idx_songs_title             ON songs(title);
            CREATE INDEX IF NOT EXISTS idx_songs_album_id          ON songs(album_id);
            CREATE INDEX IF NOT EXISTS idx_albums_title            ON albums(title);
            CREATE INDEX IF NOT EXISTS idx_artists_name            ON artists(name);
            CREATE INDEX IF NOT EXISTS idx_song_artists_artist_id  ON song_artists(artist_id);
            CREATE INDEX IF NOT EXISTS idx_scrobbles_time          ON scrobbles(scrobbled_at);
            CREATE INDEX IF NOT EXISTS idx_starred_songs_at        ON starred_songs(starred_at);

            COMMIT;
        ";
        cmd.Parameters.AddWithValue("$version", CurrentVersion.ToString());
        cmd.ExecuteNonQuery();

        GD.Print($"[DatabaseManager] Schema initialized at version {CurrentVersion}.");
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
        DropAllTables();
        GD.Print("[DatabaseManager] Database wiped.");
        InitializeDatabase();
    }

    public void DropAllTables()
    {
        CloseAll(); // clears pool
        using var connection = GetConnection();

        using var off = connection.CreateCommand();
        off.CommandText = "PRAGMA foreign_keys = OFF;";
        off.ExecuteNonQuery();

        var tables = new[]
        {
            "db_meta", "song_artists", "starred_songs",
            "scrobbles", "songs", "albums", "genres", "artists"
        };

        foreach (var table in tables)
        {
            using var cmd = connection.CreateCommand();
            cmd.CommandText = $"DROP TABLE IF EXISTS {table};";
            cmd.ExecuteNonQuery();
        }

        using var on = connection.CreateCommand();
        on.CommandText = "PRAGMA foreign_keys = ON;";
        on.ExecuteNonQuery();
    }

    private void CleanupOldScrobbles()
    {
        using var connection = GetConnection();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = "DELETE FROM scrobbles WHERE scrobbled_at < unixepoch() - (365 * 86400);";
        cmd.ExecuteNonQuery();
    }

    public void CloseAll() => SqliteConnection.ClearAllPools();
    #endregion
}
