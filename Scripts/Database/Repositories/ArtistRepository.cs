using Godot;
using Godot.Collections;
using Microsoft.Data.Sqlite;
using PlayStar.Scripts.Models;

namespace PlayStar.Scripts.Database.Repositories;

[GlobalClass]
public partial class ArtistRepository : Node
{
    private DatabaseManager _db;

    public void Initialize(DatabaseManager db) => _db = db;

    #region Read
    public Array<ArtistModel> GetArtists(int limit = 1000, bool ignoreUnknown = false)
    {
        var artists = new Array<ArtistModel>();

        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();

        var whereClause = ignoreUnknown ? "WHERE ar.name <> 'Unknown'" : "";

        cmd.CommandText = $@"
            SELECT
                ar.id,
                ar.name,
                COUNT(DISTINCT sa.song_path) AS songs_count,
                COUNT(DISTINCT al.id)        AS albums_count
            FROM artists ar
            LEFT JOIN song_artists sa ON sa.artist_id = ar.id
            LEFT JOIN albums al ON al.artist_id = ar.id
            {whereClause}
            GROUP BY ar.id
            ORDER BY ar.name ASC
            LIMIT $limit;
        ";
        cmd.Parameters.AddWithValue("$limit", limit);

        using var reader = cmd.ExecuteReader();
        while (reader.Read())
            artists.Add(MapArtist(reader));

        return artists;
    }

    public ArtistModel GetArtistByName(string name)
    {
        using var connection = _db.GetConnection();
        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            SELECT id, name, 0, 0
            FROM artists
            WHERE name = $name
            LIMIT 1;
        ";
        cmd.Parameters.AddWithValue("$name", name);

        using var reader = cmd.ExecuteReader();
        return reader.Read() ? MapArtist(reader) : null;
    }
    #endregion

    #region Write
    public long UpsertArtist(string name, SqliteConnection connection)
    {
        using var cmd = connection.CreateCommand();
        cmd.CommandText = @"
            INSERT INTO artists(name) VALUES($name)
            ON CONFLICT(name) DO UPDATE SET name = excluded.name
            RETURNING id;
        ";
        cmd.Parameters.AddWithValue("$name", name);
        var result = cmd.ExecuteScalar();
        return (long)result;
    }
    #endregion

    #region Mapping
    private static ArtistModel MapArtist(SqliteDataReader r) => new()
    {
        Id          = r.GetInt64(0),
        Name        = r.IsDBNull(1) ? "" : r.GetString(1),
        SongsCount  = r.IsDBNull(2) ? 0  : r.GetInt32(2),
        AlbumsCount = r.IsDBNull(3) ? 0  : r.GetInt32(3),
    };
    #endregion
}